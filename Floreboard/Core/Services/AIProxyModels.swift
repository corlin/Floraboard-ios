//
//  AIProxyModels.swift
//  Floreboard
//
//  Response models and errors for the Cloudflare Worker API.
//

import Foundation

// MARK: - Generic API Response Wrappers

struct AppleAccountTokenData: Codable {
  var appAccountToken: String
}

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
  var production: DesignProduction?
  var findings: [DesignFinding]?

  enum CodingKeys: String, CodingKey {
    case findings
    case title, name
    case description, concept, desc, summary
    case meaningText, meaning, flowerMeaning, significance
    case reasoning, rationale, thought, analysis
    case steps, instructions
    case imagePrompt, visualPrompt, prompt
    case imagePromptSnake = "image_prompt"
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

  /// 模型输出字段名不稳定：每个字段按顺序尝试多个别名
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    title = container.first(String.self, .title, .name) ?? "专属花艺定制方案"
    description = container.first(String.self, .description, .concept, .desc, .summary) ?? "精选花艺美学设计方案"
    meaningText = container.first(String.self, .meaningText, .meaning, .flowerMeaning, .significance) ?? "花开向阳，美意延绵"
    reasoning = container.first(String.self, .reasoning, .rationale, .thought, .analysis)
    imagePrompt = container.first(String.self, .imagePrompt, .imagePromptSnake, .visualPrompt, .prompt)
    estimatedCost = Self.decodeCost(container)
    steps = Self.decodeSteps(container)
    flowerList = container.first([AIProxyFlowerItem].self, .flowerList, .flowers, .materials, .items) ?? []
    production = try? container.decodeIfPresent(DesignProduction.self, forKey: .production)
    findings = try? container.decodeIfPresent([DesignFinding].self, forKey: .findings)
  }

  /// 成本：Double、Int 或 "¥500" 这样的字符串；estimatedCost 缺失时再看 cost / totalCost
  private static func decodeCost(_ container: KeyedDecodingContainer<CodingKeys>) -> Double? {
    if let value = container.first(Double.self, .estimatedCost) { return value }
    if let value = container.first(Int.self, .estimatedCost) { return Double(value) }
    if let text = container.first(String.self, .estimatedCost) {
      return Double(text.filter { "0123456789.".contains($0) })
    }
    return container.first(Double.self, .cost, .totalCost)
  }

  /// 步骤：[String]、按行分隔的单个字符串，缺失时给出通用步骤
  private static func decodeSteps(_ container: KeyedDecodingContainer<CodingKeys>) -> [String] {
    if let list = container.first([String].self, .steps, .instructions) { return list }
    if let text = container.first(String.self, .steps) {
      return text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    return ["裁剪花材至高低错落结构", "定位主花建立黄金视点", "融入配花与绿叶丰富空间层次"]
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
      findings: findings.map { DesignFindings(version: "plan", at: "", items: $0) }
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

private extension KeyedDecodingContainer {
  /// 依次尝试多个字段名，返回第一个存在且能解码成该类型的值
  func first<T: Decodable>(_ type: T.Type, _ keys: Key...) -> T? {
    for key in keys {
      if let value = try? decodeIfPresent(type, forKey: key) { return value }
    }
    return nil
  }
}
