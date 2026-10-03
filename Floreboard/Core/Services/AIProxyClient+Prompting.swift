//
//  AIProxyClient+Prompting.swift
//  Floreboard
//
//  Server-side prompting payloads and resilient parsing of plan responses.
//

import Foundation
import OSLog

extension AIProxyClient {
  // MARK: - Server-side Prompting
  //
  // 提示词与花艺领域知识全部在服务端（generate_plan / analyze_image）。
  // 客户端只发送结构化参数，不再携带任何 prompt，也不再自行传 messages / model。

  func localeCode(for language: Language) -> String {
    switch language {
    case .zh: return "zh-CN"
    case .en: return "en-US"
    case .ja: return "ja-JP"
    case .ko: return "ko-KR"
    case .fr: return "fr-FR"
    }
  }

  func planRequestPayload(_ request: DesignRequest) -> [String: Any] {
    var dict: [String: Any] = [
      "occasion": request.occasion.rawValue,
      "recipient": request.recipient.rawValue,
      "style": request.style.rawValue,
      "budget": request.budget ?? 500
    ]
    // 可选参数：有值才发送
    let optionalFields: [String: Any?] = [
      "requirements": request.requirements,
      "colorPalette": request.colorPalette?.rawValue,
      "format": request.format?.rawValue,
      "school": request.school,
      "technique": request.technique,
      "designMode": request.designMode,
      "proportionRule": request.proportionRule,
      "seasonality": request.seasonality,
      "culturalContext": request.culturalContext,
      "scalePreference": request.scalePreference,
      "moodPreference": request.moodPreference,
      "formPreference": request.formPreference,
      "backgroundStyle": request.backgroundStyle
    ]
    for (key, value) in optionalFields {
      if let value { dict[key] = value }
    }
    return dict
  }

  /// 仅作为云端尚无库存时的兜底；服务端以 D1 库存为准
  func inventoryPayload(_ inventory: [FlowerType]) -> [[String: Any]] {
    inventory.map { flower in
      [
        "id": flower.id,
        "name": flower.name,
        "color": flower.color,
        "quantity": flower.quantity,
        "unitCost": flower.unitCost,
        "retailPrice": flower.retailPrice,
        "category": flower.category.rawValue
      ]
    }
  }

  /// 解包服务端返回的 { success, data: { plan } }
  func extractPlan(from data: Data, inventory: [FlowerType]) throws -> AIProxyDesignResponse {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw AIProxyError.invalidResponse
    }
    if let error = json["error"] as? String {
      throw AIProxyError.rejected(AIProxyErrorResponse(message: error))
    }
    guard let root = json["data"] as? [String: Any],
          let plan = root["plan"] as? [String: Any] else {
      throw AIProxyError.invalidResponse
    }
    return buildDesignResponse(from: plan, fallbackInventory: inventory)
  }

  private func extractAssistantMessage(from data: Data) throws -> String {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw AIProxyError.invalidResponse
    }
    if let error = json["error"] as? String {
      throw AIProxyError.rejected(AIProxyErrorResponse(message: error))
    }
    if let errorObj = json["error"] as? [String: Any] {
      let msg = errorObj["message"] as? String ?? errorObj["code"] as? String ?? "Unknown proxy error"
      let code = errorObj["code"] as? String
      throw AIProxyError.rejected(AIProxyErrorResponse(code: code, message: msg))
    }
    // Unwrap { success: true, data: { choices: [...] } }
    let root = (json["data"] as? [String: Any]) ?? json
    if let choices = root["choices"] as? [[String: Any]],
       let first = choices.first,
       let msg = first["message"] as? [String: Any],
       let content = msg["content"] as? String {
      return content
    }
    throw AIProxyError.invalidResponse
  }

  private func parseDesignResponse(from text: String, inventory: [FlowerType] = []) throws -> AIProxyDesignResponse {
    let cleanText = stripMarkdownAndThinkingTags(text.trimmingCharacters(in: .whitespacesAndNewlines))

    // Tier 1: Strict standard JSONDecoder decoding within outer '{' ... '}'
    if let range = findOuterJSONRange(in: cleanText) {
      let candidate = String(cleanText[range])
      if let data = candidate.data(using: .utf8),
         let decoded = try? JSONDecoder().decode(AIProxyDesignResponse.self, from: data) {
        return decoded
      }
    }

    // Tier 2: Sanitize control characters, repair unescaped newlines/quotes, close unclosed braces
    let sanitized = sanitizeAndRepairJSON(cleanText)
    if let data = sanitized.data(using: .utf8) {
      if let decoded = try? JSONDecoder().decode(AIProxyDesignResponse.self, from: data) {
        return decoded
      }
      if let dict = (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) as? [String: Any] {
        return buildDesignResponse(from: dict, fallbackInventory: inventory)
      }
    }

    // Tier 3: Lenient field-level regex extraction with auto-healing
    AppLogger.ai.warning("Executing Tier 3 resilient regex field extraction for AI response")
    return extractDesignResponseLeniently(from: cleanText, inventory: inventory)
  }

  private func stripMarkdownAndThinkingTags(_ input: String) -> String {
    var text = input
    // Strip <think>...</think>
    if let startTag = text.range(of: "<think>"),
       let endTag = text.range(of: "</think>", range: startTag.upperBound..<text.endIndex) {
      text.removeSubrange(startTag.lowerBound..<endTag.upperBound)
    }
    // Strip markdown code fences
    if text.contains("```json") {
      text = text.replacingOccurrences(of: "```json", with: "")
    }
    if text.contains("```") {
      text = text.replacingOccurrences(of: "```", with: "")
    }
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func findOuterJSONRange(in input: String) -> Range<String.Index>? {
    guard let firstBrace = input.firstIndex(of: "{"),
          let lastBrace = input.lastIndex(of: "}"),
          firstBrace < lastBrace else {
      return nil
    }
    return firstBrace..<input.index(after: lastBrace)
  }

  /// 修复模型输出里常见的 JSON 问题：字符串内的裸控制字符、截断导致的未闭合字符串/括号、多余逗号
  private func sanitizeAndRepairJSON(_ input: String) -> String {
    var result = ""
    var inString = false
    var isEscaped = false
    var openBraces = 0
    var openBrackets = 0

    // 从第一个 { 开始
    guard let start = input.firstIndex(of: "{") else { return "" }
    for char in input[start...] {
      if isEscaped {
        result.append(char)
        isEscaped = false
      } else if char == "\\" {
        result.append(char)
        isEscaped = true
      } else if char == "\"" {
        inString.toggle()
        result.append(char)
      } else if inString {
        result.append(Self.escapedInsideString(char))
      } else {
        switch char {
        case "{": openBraces += 1
        case "}": openBraces = max(0, openBraces - 1)
        case "[": openBrackets += 1
        case "]": openBrackets = max(0, openBrackets - 1)
        default: break
        }
        result.append(char)
      }
    }
    // 截断在字符串中间时先把字符串闭合
    if inString { result.append("\"") }
    return Self.closeTruncated(result, openBraces: openBraces, openBrackets: openBrackets)
  }

  /// JSON 字符串里不允许裸换行/制表符等控制字符
  private static func escapedInsideString(_ char: Character) -> String {
    switch char {
    case "\n": return "\\n"
    case "\r": return ""
    case "\t": return "\\t"
    default:
      if let ascii = char.asciiValue, ascii < 32 { return " " }
      return String(char)
    }
  }

  /// 去掉结尾多余的逗号，并补齐未闭合的 ] 与 }
  private static func closeTruncated(_ text: String, openBraces: Int, openBrackets: Int) -> String {
    var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    while trimmed.hasSuffix(",") {
      trimmed = String(trimmed.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    trimmed += String(repeating: "]", count: openBrackets) + String(repeating: "}", count: openBraces)
    // 去掉 `, }` / `, ]` 这类多余逗号
    return trimmed.replacingOccurrences(of: ",\\s*([}\\]])", with: "$1", options: .regularExpression)
  }

  /// 成本可能是 Double、Int 或 "¥500" 这样的字符串
  private static func parseCost(_ value: Any?) -> Double? {
    if let number = value as? Double { return number }
    if let integer = value as? Int { return Double(integer) }
    if let text = value as? String { return Double(text.filter { "0123456789.".contains($0) }) }
    return nil
  }

  private func buildDesignResponse(from dict: [String: Any], fallbackInventory: [FlowerType]) -> AIProxyDesignResponse {
    let title = (dict["title"] as? String) ?? (dict["name"] as? String) ?? "专属花艺定制方案"
    let description = (dict["description"] as? String) ?? (dict["concept"] as? String) ?? "精选花艺美学设计方案"
    let meaningText = (dict["meaningText"] as? String) ?? (dict["meaning"] as? String) ?? "花开向阳，美意延绵"
    let reasoning = (dict["reasoning"] as? String) ?? (dict["rationale"] as? String)
    let imagePrompt = (dict["imagePrompt"] as? String) ?? (dict["image_prompt"] as? String)

    let cost = Self.parseCost(dict["estimatedCost"])

    var steps: [String] = []
    if let sArr = dict["steps"] as? [String] {
      steps = sArr
    } else if let sArr = dict["instructions"] as? [String] {
      steps = sArr
    } else if let sStr = dict["steps"] as? String {
      steps = sStr.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    if steps.isEmpty {
      steps = [
        "修剪主花确立构架高度与比例",
        "按流派技法固定于容器视点核心",
        "配花及衬叶点缀增强自然呼吸感"
      ]
    }

    var flowerList: [AIProxyFlowerItem] = []
    let rawList = (dict["flowerList"] as? [[String: Any]])
      ?? (dict["flowers"] as? [[String: Any]])
      ?? (dict["materials"] as? [[String: Any]])
      ?? []
    for item in rawList {
      let name = (item["flowerName"] as? String) ?? (item["name"] as? String) ?? "精选花材"
      let count = (item["count"] as? Int) ?? (item["quantity"] as? Int) ?? 3
      let unitCost = (item["unitCost"] as? Double) ?? (item["cost"] as? Double)
      let reason = (item["reason"] as? String) ?? (item["desc"] as? String)
      flowerList.append(AIProxyFlowerItem(flowerName: name, count: count, unitCost: unitCost, reason: reason))
    }

    if flowerList.isEmpty {
      flowerList = autoHealFlowers(from: fallbackInventory)
    }

    var production: DesignProduction?
    if let prodDict = dict["production"] as? [String: Any],
       let data = try? JSONSerialization.data(withJSONObject: prodDict),
       let decoded = try? JSONDecoder().decode(DesignProduction.self, from: data),
       decoded.hasContent {
      production = decoded
    }

    return AIProxyDesignResponse(
      title: title,
      description: description,
      meaningText: meaningText,
      reasoning: reasoning,
      steps: steps,
      imagePrompt: imagePrompt,
      estimatedCost: cost,
      flowerList: flowerList,
      production: production
    )
  }

  private func extractDesignResponseLeniently(from text: String, inventory: [FlowerType]) -> AIProxyDesignResponse {
    let title = extractRegexMatch(pattern: "\"title\"\\s*:\\s*\"([^\"]+)\"", in: text)
      ?? extractRegexMatch(pattern: "\"name\"\\s*:\\s*\"([^\"]+)\"", in: text)
      ?? "大师级花艺定制方案"

    let description = extractRegexMatch(pattern: "\"description\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"", in: text)
      ?? extractRegexMatch(pattern: "\"concept\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"", in: text)
      ?? "依循流派技法与空间美学所呈现的意境花作"

    let meaningText = extractRegexMatch(pattern: "\"meaningText\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"", in: text)
      ?? extractRegexMatch(pattern: "\"meaning\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"", in: text)
      ?? "气韵生动，天地和谐"

    let reasoning = extractRegexMatch(pattern: "\"reasoning\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"", in: text)
    let imagePrompt = extractRegexMatch(pattern: "\"imagePrompt\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"", in: text)

    var steps: [String] = []
    if let stepsMatch = extractRegexMatch(pattern: "\"steps\"\\s*:\\s*\\[([^\\]]*)\\]", in: text) {
      let stepItems = stepsMatch.components(separatedBy: ",")
        .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \"\n\r\t")) }
        .filter { !$0.isEmpty }
      if !stepItems.isEmpty {
        steps = stepItems
      }
    }
    if steps.isEmpty {
      steps = [
        "修剪主花确立构架高度与比例",
        "按流派技法固定于容器视点核心",
        "配花及衬叶点缀增强自然呼吸感"
      ]
    }

    var flowerList: [AIProxyFlowerItem] = []
    // Regex scan for items
    let pattern = "\\{[^}]*?\"(?:flowerName|name)\"\\s*:\\s*\"([^\"]+)\"[^}]*?\"(?:count|quantity)\"\\s*:\\s*(\\d+)[^}]*?\\}"
    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
      let nsString = text as NSString
      let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
      for match in matches where match.numberOfRanges >= 3 {
        let name = nsString.substring(with: match.range(at: 1))
        let countStr = nsString.substring(with: match.range(at: 2))
        let count = Int(countStr) ?? 3
        flowerList.append(AIProxyFlowerItem(flowerName: name, count: count, unitCost: nil, reason: nil))
      }
    }

    if flowerList.isEmpty {
      flowerList = autoHealFlowers(from: inventory)
    }

    return AIProxyDesignResponse(
      title: title,
      description: description,
      meaningText: meaningText,
      reasoning: reasoning,
      steps: steps,
      imagePrompt: imagePrompt,
      estimatedCost: nil,
      flowerList: flowerList
    )
  }

  private func extractRegexMatch(pattern: String, in text: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
      return nil
    }
    let nsString = text as NSString
    guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length)),
          match.numberOfRanges >= 2 else {
      return nil
    }
    let rawResult = nsString.substring(with: match.range(at: 1))
    return rawResult
      .replacingOccurrences(of: "\\n", with: "\n")
      .replacingOccurrences(of: "\\\"", with: "\"")
      .replacingOccurrences(of: "\\\\", with: "\\")
  }

  private func autoHealFlowers(from inventory: [FlowerType]) -> [AIProxyFlowerItem] {
    if inventory.isEmpty {
      return [
        AIProxyFlowerItem(flowerName: "红玫瑰", count: 5, unitCost: 15.0, reason: "核心主花，奠定雅致基调"),
        AIProxyFlowerItem(flowerName: "尤加利叶", count: 3, unitCost: 8.0, reason: "线条衬叶，增添自然灵动")
      ]
    }
    let available = inventory.filter { $0.quantity > 0 }
    let selected = (available.isEmpty ? inventory : available).prefix(3)
    return selected.map { flower in
      AIProxyFlowerItem(
        flowerName: flower.name,
        count: max(1, min(flower.quantity, 3)),
        unitCost: flower.unitCost,
        reason: "精选店内优质花材，契合空间语境与设计意向"
      )
    }
  }
}
