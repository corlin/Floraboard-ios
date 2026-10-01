//
//  AIProxyClient.swift
//  Floreboard
//
//  Unified client for Cloudflare Worker AI Proxy, Payments, and Cloud Data Sync.
//

import Foundation
import OSLog
import UIKit

struct AIProxyClient {
  let baseURL: URL
  var sessionToken: String?
  var urlSession: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 60
    config.timeoutIntervalForResource = 90
    return URLSession(configuration: config)
  }()
  var imageURLSession: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 90
    config.timeoutIntervalForResource = 120
    return URLSession(configuration: config)
  }()

  // MARK: - AI Generation via /api/v1/proxy

  /// Generates a floral design plan (prompt assembled server-side via generate_plan)
  func generatePlan(
    tenantId: String,
    language: Language,
    request: DesignRequest,
    inventory: [FlowerType]
  ) async throws -> DesignResult {
    let body: [String: Any] = [
      "action": "generate_plan",
      "payload": [
        "request": planRequestPayload(request),
        "language": localeCode(for: language),
        "inventory": inventoryPayload(inventory),
      ],
    ]

    let responseData = try await postRaw("api/v1/proxy", jsonObject: body, tenantId: tenantId)
    let designResp = try extractPlan(from: responseData, inventory: inventory)
    return designResp.toDesignResult(request: request, language: localeCode(for: language), inventory: inventory)
  }

  /// Generates a design plan from an inspiration image (analyze_image, server-side prompting)
  func submitVisualDesign(
    tenantId: String,
    language: Language,
    request: DesignRequest,
    inventory: [FlowerType],
    image: UIImage
  ) async throws -> DesignResult {
    // Compress and scale down to 1280px max dimension to prevent network timeouts and gateway 413/OOM
    guard let jpegData = ImageCompressor.compressImage(image, maxDimension: 1280, quality: 0.75)
            ?? image.jpegData(compressionQuality: 0.8) else {
      throw AIError.imageEncodingFailed
    }
    let base64String = "data:image/jpeg;base64," + jpegData.base64EncodedString()

    let body: [String: Any] = [
      "action": "analyze_image",
      "payload": [
        "request": planRequestPayload(request),
        "language": localeCode(for: language),
        "inventory": inventoryPayload(inventory),
        "imageBase64": base64String,
      ],
    ]

    let responseData = try await postRaw("api/v1/proxy", jsonObject: body, tenantId: tenantId)
    let designResp = try extractPlan(from: responseData, inventory: inventory)
    return designResp.toDesignResult(request: request, language: localeCode(for: language), inventory: inventory)
  }

  /// Requests 4K image generation and polls until completed (persisted to R2 by backend)
  func generateFloralImage(tenantId: String, prompt: String) async throws -> String {
    let body: [String: Any] = [
      
      "action": "image_generation",
      "payload": [
        "prompt": prompt
      ]
    ]

    let responseData = try await postRaw(
      "api/v1/proxy",
      jsonObject: body,
      tenantId: tenantId,
      customSession: imageURLSession
    )

    // Check if immediate URL is returned
    if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
       let dataObj = json["data"] as? [String: Any] {
      // Aliyun output or OpenAI data
      if let output = dataObj["output"] as? [String: Any] {
        if let taskId = output["task_id"] as? String {
          // Async task — poll status
          return try await pollImageTask(tenantId: tenantId, taskId: taskId)
        }
        if let results = output["results"] as? [[String: Any]],
           let url = results.first?["url"] as? String {
          return url
        }
      }
      if let items = dataObj["data"] as? [[String: Any]] {
        if let url = items.first?["url"] as? String, !url.isEmpty {
          return url
        }
        if let b64 = items.first?["b64_json"] as? String, !b64.isEmpty {
          return b64.hasPrefix("data:") ? b64 : "data:image/jpeg;base64,\(b64)"
        }
      }
    }

    throw AIProxyError.invalidResponse
  }

  private func pollImageTask(tenantId: String, taskId: String, maxAttempts: Int = 40) async throws -> String {
    var consecutiveTransientErrors = 0
    let maxConsecutiveTransientErrors = 3

    for attempt in 0..<maxAttempts {
      // Progressive polling interval: 2.0s for first 10 cycles, 2.5s for remaining cycles (total ~95s window)
      let waitSeconds = attempt < 10 ? 2.0 : 2.5
      try await Task.sleep(nanoseconds: UInt64(waitSeconds * 1_000_000_000))

      let pollBody: [String: Any] = [
        
        "action": "image_task_status",
        "payload": ["taskId": taskId]
      ]

      let resData: Data
      do {
        resData = try await postRaw("api/v1/proxy", jsonObject: pollBody, tenantId: tenantId)
        consecutiveTransientErrors = 0
      } catch {
        consecutiveTransientErrors += 1
        AppLogger.ai.warning("Polling task \(taskId) transient failure (\(consecutiveTransientErrors)/\(maxConsecutiveTransientErrors)): \(error.localizedDescription)")
        if consecutiveTransientErrors >= maxConsecutiveTransientErrors {
          throw error
        }
        continue
      }

      guard let json = try? JSONSerialization.jsonObject(with: resData) as? [String: Any],
            let dataObj = json["data"] as? [String: Any],
            let output = dataObj["output"] as? [String: Any] else {
        continue
      }

      let status = output["task_status"] as? String ?? ""
      if status == "SUCCEEDED" {
        if let results = output["results"] as? [[String: Any]],
           let url = results.first?["url"] as? String {
          return url
        }
        if let directUrl = output["url"] as? String, !directUrl.isEmpty {
          return directUrl
        }
      } else if status == "FAILED" {
        let msg = output["message"] as? String ?? "Image rendering failed"
        throw AIProxyError.rejected(AIProxyErrorResponse(message: msg))
      }
    }
    throw AIProxyError.invalidResponse
  }

  /// Downloads an image from CDN/R2 with retry and exponential backoff
  static func downloadImageWithRetry(from url: URL, maxRetries: Int = 2) async throws -> UIImage? {
    var lastError: Error?
    for attempt in 0...maxRetries {
      do {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResponse = response as? HTTPURLResponse {
          if (200...299).contains(httpResponse.statusCode), let image = UIImage(data: data) {
            return image
          }
          if [401, 403, 404].contains(httpResponse.statusCode) {
            throw AIError.apiError(statusCode: httpResponse.statusCode)
          }
        }
      } catch {
        lastError = error
      }

      if attempt < maxRetries {
        let backoff = Double(attempt + 1) * 0.8 + Double.random(in: 0.1...0.25)
        try? await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
      }
    }

    if let error = lastError {
      throw error
    }
    return nil
  }

  // MARK: - Payments & Credits

  func fetchCredits(tenantId: String) async throws -> CreditsData {
    let req = try makeRequest(path: "api/v1/payments/credits", method: "GET", tenantId: tenantId)
    let wrapper: APIResponseWrapper<CreditsData> = try await perform(req)
    guard let data = wrapper.data else {
      throw AIProxyError.invalidResponse
    }
    return data
  }

  func fetchPaymentPlans() async throws -> [PaymentPlanItem] {
    let req = try makeRequest(path: "api/v1/payments/plans", method: "GET")
    let wrapper: APIResponseWrapper<[PaymentPlanItem]> = try await perform(req)
    return wrapper.data ?? []
  }

  func verifyAppleIAP(
    tenantId: String,
    transactionId: String,
    productId: String,
    jws: String? = nil,
    originalTransactionId: String? = nil
  ) async throws -> AppleVerifyResponse {
    var payload: [String: String] = [
      "transactionId": transactionId,
      "productId": productId
    ]
    if let jws = jws {
      payload["jws"] = jws
    }
    if let origId = originalTransactionId {
      payload["originalTransactionId"] = origId
    }
    let res: AppleVerifyResponse = try await post("api/v1/payments/apple-verify", body: payload, tenantId: tenantId)
    return res
  }

  // MARK: - Cloud Data Sync (Inventory)

  func fetchInventory(tenantId: String) async throws -> [FlowerType] {
    let req = try makeRequest(path: "api/v1/inventory", method: "GET", tenantId: tenantId)
    let wrapper: APIResponseWrapper<[FlowerType]> = try await perform(req)
    return wrapper.data ?? []
  }

  func createFlower(tenantId: String, flower: FlowerType) async throws -> FlowerType {
    let wrapper: APIResponseWrapper<FlowerType> = try await post("api/v1/inventory", body: flower, tenantId: tenantId)
    guard let data = wrapper.data else { throw AIProxyError.invalidResponse }
    return data
  }

  func updateFlower(tenantId: String, flower: FlowerType) async throws -> FlowerType {
    var req = try makeRequest(path: "api/v1/inventory/\(flower.id)", method: "PUT", tenantId: tenantId)
    req.httpBody = try JSONEncoder().encode(flower)
    let wrapper: APIResponseWrapper<FlowerType> = try await perform(req)
    guard let data = wrapper.data else { throw AIProxyError.invalidResponse }
    return data
  }

  func deleteFlower(tenantId: String, flowerId: String) async throws {
    let req = try makeRequest(path: "api/v1/inventory/\(flowerId)", method: "DELETE", tenantId: tenantId)
    let _: EmptyResponse = try await perform(req)
  }

  // MARK: - Cloud Data Sync (Designs)

  func fetchDesigns(tenantId: String) async throws -> [DesignResult] {
    let req = try makeRequest(path: "api/v1/designs", method: "GET", tenantId: tenantId)
    let wrapper: APIResponseWrapper<[DesignResult]> = try await perform(req)
    // 云端时间戳是毫秒，本地使用秒
    return (wrapper.data ?? []).map { DesignMerge.normalizedTimestamps($0) }
  }

  @discardableResult
  func saveDesign(tenantId: String, design: DesignResult) async throws -> DesignFindings? {
    var req = try makeRequest(path: "api/v1/designs", method: "POST", tenantId: tenantId)
    req.httpBody = try JSONEncoder().encode(design)
    return Self.findings(in: try await performRaw(req))
  }

  /// 服务端在创建/更新时按已存数据重算专业校验，随响应返回
  private static func findings(in data: Data) -> DesignFindings? {
    struct Body: Decodable { struct D: Decodable { var findings: DesignFindings? }; var data: D? }
    return (try? JSONDecoder().decode(Body.self, from: data))?.data?.findings
  }

  struct ExecuteResult {
    var executed: Bool
    var executedAt: Double?
    var inventory: [FlowerType]
  }

  /// 服务端原子执行：在一个事务里扣减库存并标记已执行，并发/重复请求安全（只会扣一次）。
  func executeDesign(tenantId: String, designId: String) async throws -> ExecuteResult {
    struct Body: Decodable {
      struct D: Decodable { var executed: Bool?; var executedAt: Double?; var inventory: [FlowerType]? }
      var data: D?
    }
    let req = try makeRequest(path: "api/v1/designs/\(designId)/execute", method: "POST", tenantId: tenantId)
    let data = try await performRaw(req)
    guard let d = (try? JSONDecoder().decode(Body.self, from: data))?.data else { throw AIProxyError.invalidResponse }
    return ExecuteResult(
      executed: d.executed ?? false,
      executedAt: d.executedAt.map { DesignMerge.seconds($0) },
      inventory: d.inventory ?? [])
  }

  /// 创建或更新方案：先 PUT（更新已有），云端还没有（NOT_FOUND）再 POST（创建）。
  /// 之前只会 POST，而云端对已存在的 id 不做更新，所以出图重试结果、评分、已执行状态等后续修改从未同步到云端。
  @discardableResult
  func upsertDesign(tenantId: String, design: DesignResult) async throws -> DesignFindings? {
    var req = try makeRequest(path: "api/v1/designs/\(design.id)", method: "PUT", tenantId: tenantId)
    req.httpBody = try JSONEncoder().encode(design)
    do {
      return Self.findings(in: try await performRaw(req))
    } catch AIProxyError.rejected(let err) where err.code == "NOT_FOUND" || err.message == "Design not found" {
      // 云端还没有这条方案：创建（兼容尚未返回 NOT_FOUND 错误码的旧服务端）
      return try await saveDesign(tenantId: tenantId, design: design)
    } catch AIProxyError.httpStatus(404) {
      return try await saveDesign(tenantId: tenantId, design: design)
    }
  }

  /// 上传图片到云端存储（R2），返回可跨设备访问的公开 URL。
  /// 服务端按文件头校验类型，只接受 JPEG/PNG/WebP/GIF，最大 10MB。
  func uploadImage(_ data: Data, contentType: String = "image/jpeg", tenantId: String?) async throws -> String {
    var req = try makeRequest(path: "api/v1/storage/upload?bucket=reference", method: "POST", tenantId: tenantId)
    req.setValue(contentType, forHTTPHeaderField: "Content-Type")
    req.httpBody = data
    let responseData = try await performRaw(req, session: imageURLSession)
    guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
          let url = json["url"] as? String, DesignMerge.isRemoteImage(url) else {
      throw AIProxyError.invalidResponse
    }
    return url
  }

  func deleteDesign(tenantId: String, designId: String) async throws {
    let req = try makeRequest(path: "api/v1/designs/\(designId)", method: "DELETE", tenantId: tenantId)
    let _: EmptyResponse = try await perform(req)
  }

  func health() async throws -> AIProxyHealthResponse {
    let req = try makeRequest(path: "health", method: "GET")
    return try await perform(req)
  }

  // MARK: - Server-side Prompting
  //
  // 提示词与花艺领域知识全部在服务端（generate_plan / analyze_image）。
  // 客户端只发送结构化参数，不再携带任何 prompt，也不再自行传 messages / model。

  private func localeCode(for language: Language) -> String {
    switch language {
    case .zh: return "zh-CN"
    case .en: return "en-US"
    case .ja: return "ja-JP"
    case .ko: return "ko-KR"
    case .fr: return "fr-FR"
    }
  }

  private func planRequestPayload(_ request: DesignRequest) -> [String: Any] {
    var dict: [String: Any] = [
      "occasion": request.occasion.rawValue,
      "recipient": request.recipient.rawValue,
      "style": request.style.rawValue,
      "budget": request.budget ?? 500,
    ]
    if let v = request.requirements { dict["requirements"] = v }
    if let v = request.colorPalette { dict["colorPalette"] = v.rawValue }
    if let v = request.format { dict["format"] = v.rawValue }
    if let v = request.school { dict["school"] = v }
    if let v = request.technique { dict["technique"] = v }
    if let v = request.designMode { dict["designMode"] = v }
    if let v = request.proportionRule { dict["proportionRule"] = v }
    if let v = request.seasonality { dict["seasonality"] = v }
    if let v = request.culturalContext { dict["culturalContext"] = v }
    if let v = request.scalePreference { dict["scalePreference"] = v }
    if let v = request.moodPreference { dict["moodPreference"] = v }
    if let v = request.formPreference { dict["formPreference"] = v }
    if let v = request.backgroundStyle { dict["backgroundStyle"] = v }
    return dict
  }

  /// 仅作为云端尚无库存时的兜底；服务端以 D1 库存为准
  private func inventoryPayload(_ inventory: [FlowerType]) -> [[String: Any]] {
    inventory.map { f in
      [
        "id": f.id,
        "name": f.name,
        "color": f.color,
        "quantity": f.quantity,
        "unitCost": f.unitCost,
        "retailPrice": f.retailPrice,
        "category": f.category.rawValue,
      ]
    }
  }

  /// 解包服务端返回的 { success, data: { plan } }
  private func extractPlan(from data: Data, inventory: [FlowerType]) throws -> AIProxyDesignResponse {
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

  private func sanitizeAndRepairJSON(_ input: String) -> String {
    var result = ""
    var inString = false
    var isEscaped = false
    var openBraces = 0
    var openBrackets = 0
    var hasStarted = false

    for char in input {
      if !hasStarted {
        if char == "{" {
          hasStarted = true
          openBraces += 1
          result.append(char)
        }
        continue
      }

      if isEscaped {
        result.append(char)
        isEscaped = false
        continue
      }

      if char == "\\" {
        result.append(char)
        isEscaped = true
        continue
      }

      if char == "\"" {
        inString.toggle()
        result.append(char)
        continue
      }

      if inString {
        if char == "\n" {
          result.append("\\n")
        } else if char == "\r" {
          // ignore CR
        } else if char == "\t" {
          result.append("\\t")
        } else if let ascii = char.asciiValue, ascii < 32 {
          result.append(" ")
        } else {
          result.append(char)
        }
      } else {
        if char == "{" {
          openBraces += 1
        } else if char == "}" {
          openBraces = max(0, openBraces - 1)
        } else if char == "[" {
          openBrackets += 1
        } else if char == "]" {
          openBrackets = max(0, openBrackets - 1)
        }
        result.append(char)
      }
    }

    // Auto-close string if ended while inString
    if inString {
      result.append("\"")
    }

    // Trim trailing whitespace and trailing commas
    var trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
    while trimmed.hasSuffix(",") {
      trimmed = String(trimmed.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Auto-close missing brackets and braces
    for _ in 0..<openBrackets {
      trimmed.append("]")
    }
    for _ in 0..<openBraces {
      trimmed.append("}")
    }

    // Remove trailing commas before closing braces/brackets like `, }` or `, ]`
    trimmed = trimmed.replacingOccurrences(
      of: ",\\s*([}\\]])",
      with: "$1",
      options: .regularExpression
    )

    return trimmed
  }

  private func buildDesignResponse(from dict: [String: Any], fallbackInventory: [FlowerType]) -> AIProxyDesignResponse {
    let title = (dict["title"] as? String) ?? (dict["name"] as? String) ?? "专属花艺定制方案"
    let description = (dict["description"] as? String) ?? (dict["concept"] as? String) ?? "精选花艺美学设计方案"
    let meaningText = (dict["meaningText"] as? String) ?? (dict["meaning"] as? String) ?? "花开向阳，美意延绵"
    let reasoning = (dict["reasoning"] as? String) ?? (dict["rationale"] as? String)
    let imagePrompt = (dict["imagePrompt"] as? String) ?? (dict["image_prompt"] as? String)

    var cost: Double? = nil
    if let d = dict["estimatedCost"] as? Double { cost = d }
    else if let i = dict["estimatedCost"] as? Int { cost = Double(i) }
    else if let s = dict["estimatedCost"] as? String {
      let filtered = s.filter { "0123456789.".contains($0) }
      cost = Double(filtered)
    }

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
    let rawList = (dict["flowerList"] as? [[String: Any]]) ?? (dict["flowers"] as? [[String: Any]]) ?? (dict["materials"] as? [[String: Any]]) ?? []
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

    var production: DesignProduction? = nil
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
      for match in matches {
        if match.numberOfRanges >= 3 {
          let name = nsString.substring(with: match.range(at: 1))
          let countStr = nsString.substring(with: match.range(at: 2))
          let count = Int(countStr) ?? 3
          flowerList.append(AIProxyFlowerItem(flowerName: name, count: count, unitCost: nil, reason: nil))
        }
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

  // MARK: - Networking Core

  private func postRaw(
    _ path: String,
    jsonObject: [String: Any],
    tenantId: String? = nil,
    customSession: URLSession? = nil
  ) async throws -> Data {
    var req = try makeRequest(path: path, method: "POST", tenantId: tenantId)
    req.httpBody = try JSONSerialization.data(withJSONObject: jsonObject)
    return try await performRaw(req, session: customSession)
  }

  private func post<Body: Encodable, Response: Decodable>(
    _ path: String,
    body: Body,
    tenantId: String? = nil
  ) async throws -> Response {
    var request = try makeRequest(path: path, method: "POST", tenantId: tenantId)
    request.httpBody = try JSONEncoder().encode(body)
    return try await perform(request)
  }

  private func makeRequest(path: String, method: String, tenantId: String? = nil) throws -> URLRequest {
    let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
    guard let url = URL(string: cleanPath, relativeTo: baseURL)?.absoluteURL else {
      throw AIProxyError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = method
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    if let sessionToken, !sessionToken.isEmpty {
      request.addValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
    }
    if let tenantId, !tenantId.isEmpty {
      request.addValue(tenantId, forHTTPHeaderField: "X-Tenant-Id")
    }
    return request
  }

  private func performRaw(
    _ request: URLRequest,
    session: URLSession? = nil,
    maxRetries: Int = 2
  ) async throws -> Data {
    let activeSession = session ?? urlSession
    var attempt = 0
    var lastError: Error?

    while attempt <= maxRetries {
      do {
        let (data, response) = try await activeSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
          throw AIProxyError.invalidResponse
        }

        // Fast-fail on non-retryable 402
        if httpResponse.statusCode == 402 {
          let errResp = try? JSONDecoder().decode(AIProxyErrorResponse.self, from: data)
          throw AIProxyError.insufficientCredits(
            required: errResp?.requiredCredits ?? 1,
            current: errResp?.currentCredits ?? 0
          )
        }

        if (200..<300).contains(httpResponse.statusCode) {
          return data
        }

        // Parse structured error payload if available
        let errResp = try? JSONDecoder().decode(AIProxyErrorResponse.self, from: data)
        if errResp?.code == "INSUFFICIENT_CREDITS" {
          throw AIProxyError.insufficientCredits(
            required: errResp?.requiredCredits ?? 1,
            current: errResp?.currentCredits ?? 0
          )
        }

        let statusCode = httpResponse.statusCode
        // Fast-fail non-retryable 4xx client errors (except 429 rate limit)
        if (400..<500).contains(statusCode) && statusCode != 429 {
          if let errResp {
            throw AIProxyError.rejected(errResp)
          }
          throw AIProxyError.httpStatus(statusCode)
        }

        // 429 or 5xx are retryable
        let errorToRecord: Error
        if let errResp {
          errorToRecord = AIProxyError.rejected(errResp)
        } else {
          errorToRecord = AIProxyError.httpStatus(statusCode)
        }
        lastError = errorToRecord

      } catch let error as AIProxyError {
        switch error {
        case .insufficientCredits, .insufficientQuota, .invalidURL:
          // Immediately rethrow non-retryable errors
          throw error
        case .rejected(let errResp):
          if errResp.code == "INSUFFICIENT_CREDITS" {
            throw error
          }
          lastError = error
        case .httpStatus(let code):
          if (400..<500).contains(code) && code != 429 {
            throw error
          }
          lastError = error
        case .invalidResponse:
          lastError = error
        }
      } catch {
        lastError = error
      }

      attempt += 1
      if attempt <= maxRetries {
        // Exponential backoff with jitter (e.g., ~1.0s, ~2.0s, ~4.0s)
        let backoff = min(pow(2.0, Double(attempt - 1)) * 1.0 + Double.random(in: 0.1...0.3), 5.0)
        try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
      }
    }

    throw lastError ?? AIProxyError.invalidResponse
  }

  private func perform<Response: Decodable>(_ request: URLRequest, maxRetries: Int = 2) async throws -> Response {
    let data = try await performRaw(request, maxRetries: maxRetries)
    return try JSONDecoder().decode(Response.self, from: data)
  }
}

// MARK: - Generic API Response Wrappers

struct APIResponseWrapper<T: Codable>: Codable {
  var success: Bool
  var data: T?
  var error: String?
  var code: String?
  var currentCredits: Int?
  var requiredCredits: Int?
}

struct EmptyResponse: Codable {
  var success: Bool?
}

// MARK: - Models

struct AIProxyDesignResponse: Codable {
  var title: String
  var description: String
  var meaningText: String
  var reasoning: String?
  var steps: [String]
  var imagePrompt: String?
  var estimatedCost: Double?
  var flowerList: [AIProxyFlowerItem]
  var production: DesignProduction? = nil
  var findings: [DesignFinding]? = nil

  enum CodingKeys: String, CodingKey {
    case findings
    case title, name
    case description, concept, desc, summary
    case meaningText, meaning, flowerMeaning, significance
    case reasoning, rationale, thought, analysis
    case steps, instructions
    case imagePrompt, image_prompt, visualPrompt, prompt
    case estimatedCost, cost, totalCost, budget
    case flowerList, flowers, materials, items
    case production
  }

  init(
    title: String,
    description: String,
    meaningText: String,
    reasoning: String? = nil,
    steps: [String],
    imagePrompt: String? = nil,
    estimatedCost: Double? = nil,
    flowerList: [AIProxyFlowerItem] = [],
    production: DesignProduction? = nil
  ) {
    self.title = title
    self.description = description
    self.meaningText = meaningText
    self.reasoning = reasoning
    self.steps = steps
    self.imagePrompt = imagePrompt
    self.estimatedCost = estimatedCost
    self.flowerList = flowerList
    self.production = production
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.title = (try? container.decodeIfPresent(String.self, forKey: .title))
      ?? (try? container.decodeIfPresent(String.self, forKey: .name))
      ?? "专属花艺定制方案"

    self.description = (try? container.decodeIfPresent(String.self, forKey: .description))
      ?? (try? container.decodeIfPresent(String.self, forKey: .concept))
      ?? (try? container.decodeIfPresent(String.self, forKey: .desc))
      ?? (try? container.decodeIfPresent(String.self, forKey: .summary))
      ?? "精选花艺美学设计方案"

    self.meaningText = (try? container.decodeIfPresent(String.self, forKey: .meaningText))
      ?? (try? container.decodeIfPresent(String.self, forKey: .meaning))
      ?? (try? container.decodeIfPresent(String.self, forKey: .flowerMeaning))
      ?? (try? container.decodeIfPresent(String.self, forKey: .significance))
      ?? "花开向阳，美意延绵"

    self.reasoning = (try? container.decodeIfPresent(String.self, forKey: .reasoning))
      ?? (try? container.decodeIfPresent(String.self, forKey: .rationale))
      ?? (try? container.decodeIfPresent(String.self, forKey: .thought))
      ?? (try? container.decodeIfPresent(String.self, forKey: .analysis))

    self.imagePrompt = (try? container.decodeIfPresent(String.self, forKey: .imagePrompt))
      ?? (try? container.decodeIfPresent(String.self, forKey: .image_prompt))
      ?? (try? container.decodeIfPresent(String.self, forKey: .visualPrompt))
      ?? (try? container.decodeIfPresent(String.self, forKey: .prompt))

    // Flexible cost decoding (Double, Int, or String like "¥500")
    if let doubleCost = try? container.decodeIfPresent(Double.self, forKey: .estimatedCost) {
      self.estimatedCost = doubleCost
    } else if let intCost = try? container.decodeIfPresent(Int.self, forKey: .estimatedCost) {
      self.estimatedCost = Double(intCost)
    } else if let strCost = try? container.decodeIfPresent(String.self, forKey: .estimatedCost) {
      let filtered = strCost.filter { "0123456789.".contains($0) }
      self.estimatedCost = Double(filtered)
    } else if let doubleCost = try? container.decodeIfPresent(Double.self, forKey: .cost) {
      self.estimatedCost = doubleCost
    } else if let doubleCost = try? container.decodeIfPresent(Double.self, forKey: .totalCost) {
      self.estimatedCost = doubleCost
    } else {
      self.estimatedCost = nil
    }

    // Flexible steps decoding: [String], or [{"step": "..."}], or single string
    if let stringSteps = try? container.decodeIfPresent([String].self, forKey: .steps) {
      self.steps = stringSteps
    } else if let stringSteps = try? container.decodeIfPresent([String].self, forKey: .instructions) {
      self.steps = stringSteps
    } else if let singleString = try? container.decodeIfPresent(String.self, forKey: .steps) {
      self.steps = singleString.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    } else {
      self.steps = [
        "裁剪花材至高低错落结构",
        "定位主花建立黄金视点",
        "融入配花与绿叶丰富空间层次"
      ]
    }

    // Flexible flowerList decoding
    if let list = try? container.decodeIfPresent([AIProxyFlowerItem].self, forKey: .flowerList) {
      self.flowerList = list
    } else if let list = try? container.decodeIfPresent([AIProxyFlowerItem].self, forKey: .flowers) {
      self.flowerList = list
    } else if let list = try? container.decodeIfPresent([AIProxyFlowerItem].self, forKey: .materials) {
      self.flowerList = list
    } else if let list = try? container.decodeIfPresent([AIProxyFlowerItem].self, forKey: .items) {
      self.flowerList = list
    } else {
      self.flowerList = []
    }

    self.production = try? container.decodeIfPresent(DesignProduction.self, forKey: .production)
    self.findings = try? container.decodeIfPresent([DesignFinding].self, forKey: .findings)
  }

  /// 利润口径与网页端一致（见 web 的 financials.ts）：
  /// 成交价 = 客户预算（有预算时），否则取各花材零售价合计；利润 = 成交价 − 成本（可为负）；利润率 = 利润 ÷ 成交价。
  func toDesignResult(request: DesignRequest, language: String, inventory: [FlowerType]) -> DesignResult {
    let items = flowerList.map { item in
      let matched = inventory.first {
        $0.name.localizedCaseInsensitiveCompare(item.flowerName) == .orderedSame
      }
      return DesignFlowerItem(
        flowerName: item.flowerName,
        count: item.count,
        reason: item.reason,
        unitCost: matched?.unitCost ?? item.unitCost
      )
    }

    let fallbackCost = items.reduce(0.0) { total, item in
      total + (item.unitCost ?? 5.0) * Double(item.count)
    }
    let cost = estimatedCost ?? fallbackCost
    let retail = flowerList.reduce(0.0) { total, item in
      let matched = inventory.first {
        $0.name.localizedCaseInsensitiveCompare(item.flowerName) == .orderedSame
      }
      return total + (matched?.retailPrice ?? 0) * Double(item.count)
    }
    let price = DesignPricing.price(budget: request.budget, retail: retail)
    let profit = price - cost
    let margin = DesignPricing.margin(price: price, profit: profit)

    return DesignResult(
      id: UUID().uuidString,
      requestId: request.id,
      title: title,
      description: description,
      flowerList: items,
      reasoning: reasoning,
      steps: steps,
      imageUrl: nil,
      imageTaskId: nil,
      imageStatus: .pending,
      imageError: nil,
      imagePrompt: imagePrompt,
      meaningText: meaningText,
      totalCost: cost,
      profit: profit,
      profitMargin: margin,
      createdAt: Date().timeIntervalSince1970,
      requirements: nil,
      rating: nil,
      feedback: nil,
      status: .draft,
      executedAt: nil,
      production: production,
      request: DesignRequestSnapshot(request, language: language),
      findings: findings.map { DesignFindings(v: "plan", at: "", items: $0) }
    )
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(title, forKey: .title)
    try container.encode(description, forKey: .description)
    try container.encode(meaningText, forKey: .meaningText)
    try container.encodeIfPresent(reasoning, forKey: .reasoning)
    try container.encode(steps, forKey: .steps)
    try container.encodeIfPresent(imagePrompt, forKey: .imagePrompt)
    try container.encodeIfPresent(estimatedCost, forKey: .estimatedCost)
    try container.encode(flowerList, forKey: .flowerList)
    try container.encodeIfPresent(production, forKey: .production)
  }
}

struct AIProxyFlowerItem: Codable {
  var flowerName: String
  var count: Int
  var unitCost: Double?
  var reason: String?

  enum CodingKeys: String, CodingKey {
    case flowerName, name, flower, title
    case count, quantity, amount, stems
    case unitCost, cost, price
    case reason, explanation, desc
  }

  init(flowerName: String, count: Int, unitCost: Double? = nil, reason: String? = nil) {
    self.flowerName = flowerName
    self.count = count
    self.unitCost = unitCost
    self.reason = reason
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.flowerName = (try? container.decodeIfPresent(String.self, forKey: .flowerName))
      ?? (try? container.decodeIfPresent(String.self, forKey: .name))
      ?? (try? container.decodeIfPresent(String.self, forKey: .flower))
      ?? (try? container.decodeIfPresent(String.self, forKey: .title))
      ?? "精选花材"

    // Flexible count decoding (Int, Double, or String like "3枝")
    if let intCount = try? container.decodeIfPresent(Int.self, forKey: .count) {
      self.count = intCount
    } else if let intCount = try? container.decodeIfPresent(Int.self, forKey: .quantity) {
      self.count = intCount
    } else if let intCount = try? container.decodeIfPresent(Int.self, forKey: .amount) {
      self.count = intCount
    } else if let intCount = try? container.decodeIfPresent(Int.self, forKey: .stems) {
      self.count = intCount
    } else if let strCount = try? container.decodeIfPresent(String.self, forKey: .count) {
      let digits = strCount.filter { "0123456789".contains($0) }
      self.count = Int(digits) ?? 3
    } else {
      self.count = 3
    }

    // Flexible unitCost decoding
    if let doubleCost = try? container.decodeIfPresent(Double.self, forKey: .unitCost) {
      self.unitCost = doubleCost
    } else if let intCost = try? container.decodeIfPresent(Int.self, forKey: .unitCost) {
      self.unitCost = Double(intCost)
    } else if let doubleCost = try? container.decodeIfPresent(Double.self, forKey: .cost) {
      self.unitCost = doubleCost
    } else if let doubleCost = try? container.decodeIfPresent(Double.self, forKey: .price) {
      self.unitCost = doubleCost
    } else if let strCost = try? container.decodeIfPresent(String.self, forKey: .unitCost) {
      let filtered = strCost.filter { "0123456789.".contains($0) }
      self.unitCost = Double(filtered) ?? 5.0
    } else {
      self.unitCost = 5.0
    }

    self.reason = (try? container.decodeIfPresent(String.self, forKey: .reason))
      ?? (try? container.decodeIfPresent(String.self, forKey: .explanation))
      ?? (try? container.decodeIfPresent(String.self, forKey: .desc))
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(flowerName, forKey: .flowerName)
    try container.encode(count, forKey: .count)
    try container.encodeIfPresent(unitCost, forKey: .unitCost)
    try container.encodeIfPresent(reason, forKey: .reason)
  }
}

struct AIProxyHealthResponse: Codable {
  var status: String?
  var service: String?
  var region: String?
}

struct AIProxyErrorResponse: Codable, Error {
  var requestId: String?
  var code: String?
  var message: String
  var currentCredits: Int?
  var requiredCredits: Int?

  enum CodingKeys: String, CodingKey {
    case requestId
    case code
    case message
    case error
    case currentCredits
    case requiredCredits
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    requestId = try container.decodeIfPresent(String.self, forKey: .requestId)
    code = try container.decodeIfPresent(String.self, forKey: .code)
    let msg = try container.decodeIfPresent(String.self, forKey: .message)
    let err = try container.decodeIfPresent(String.self, forKey: .error)
    message = msg ?? err ?? "Unknown error"
    currentCredits = try container.decodeIfPresent(Int.self, forKey: .currentCredits)
    requiredCredits = try container.decodeIfPresent(Int.self, forKey: .requiredCredits)
  }

  init(requestId: String? = nil, code: String? = nil, message: String, currentCredits: Int? = nil, requiredCredits: Int? = nil) {
    self.requestId = requestId
    self.code = code
    self.message = message
    self.currentCredits = currentCredits
    self.requiredCredits = requiredCredits
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(requestId, forKey: .requestId)
    try container.encodeIfPresent(code, forKey: .code)
    try container.encode(message, forKey: .message)
    try container.encodeIfPresent(currentCredits, forKey: .currentCredits)
    try container.encodeIfPresent(requiredCredits, forKey: .requiredCredits)
  }
}

enum AIProxyError: LocalizedError {
  case invalidURL
  case invalidResponse
  case httpStatus(Int)
  case rejected(AIProxyErrorResponse)
  case insufficientCredits(required: Int, current: Int)
  case insufficientQuota

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return Tx.t("error.invalidURL")
    case .invalidResponse:
      return Tx.t("error.api.invalidResponse")
    case .httpStatus(let statusCode):
      return Tx.t("error.apiError", ["code": "\(statusCode)"])
    case .rejected(let error):
      return error.message
    case .insufficientCredits(let required, let current):
      return "点数不足：本次操作需要 \(required) 点，当前余额仅剩 \(current) 点。请前往充值。"
    case .insufficientQuota:
      return Tx.t("error.api.insufficientQuota")
    }
  }
}
