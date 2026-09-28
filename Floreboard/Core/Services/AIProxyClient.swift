//
//  AIProxyClient.swift
//  Floreboard
//
//  Unified client for Cloudflare Worker AI Proxy, Payments, and Cloud Data Sync.
//

import Foundation
import UIKit

struct AIProxyClient {
  let baseURL: URL
  var sessionToken: String?
  var urlSession: URLSession = .shared

  // MARK: - AI Generation via /api/v1/proxy

  /// Generates a floral design plan via proxy chat action
  func generatePlan(
    tenantId: String,
    language: Language,
    request: DesignRequest,
    inventory: [FlowerType]
  ) async throws -> DesignResult {
    let systemPrompt = buildSystemPrompt(language: language, request: request, inventory: inventory)
    let userPrompt = buildUserPrompt(request: request)

    let body: [String: Any] = [
      "tenantId": tenantId,
      "action": "chat",
      "payload": [
        "messages": [
          ["role": "system", "content": systemPrompt],
          ["role": "user", "content": userPrompt]
        ],
        "temperature": 0.7
      ]
    ]

    let responseData = try await postRaw("api/v1/proxy", jsonObject: body, tenantId: tenantId)
    let jsonContent = try extractAssistantMessage(from: responseData)
    let designResp = try parseDesignResponse(from: jsonContent)
    return designResp.toDesignResult(localRequestId: request.id, inventory: inventory)
  }

  /// Generates a design plan from an inspiration image
  func submitVisualDesign(
    tenantId: String,
    language: Language,
    request: DesignRequest,
    inventory: [FlowerType],
    image: UIImage
  ) async throws -> DesignResult {
    guard let jpegData = image.jpegData(compressionQuality: 0.82) else {
      throw AIError.imageEncodingFailed
    }
    let base64String = "data:image/jpeg;base64," + jpegData.base64EncodedString()
    let systemPrompt = buildSystemPrompt(language: language, request: request, inventory: inventory)
    let userPrompt = buildUserPrompt(request: request) + "\nAnalyze the reference image and incorporate its color palette, structure, and aesthetic into the design."

    let body: [String: Any] = [
      "tenantId": tenantId,
      "action": "vision",
      "payload": [
        "messages": [
          ["role": "system", "content": systemPrompt],
          [
            "role": "user",
            "content": [
              ["type": "text", "text": userPrompt],
              ["type": "image_url", "image_url": ["url": base64String]]
            ]
          ]
        ],
        "imageBase64": base64String
      ]
    ]

    let responseData = try await postRaw("api/v1/proxy", jsonObject: body, tenantId: tenantId)
    let jsonContent = try extractAssistantMessage(from: responseData)
    let designResp = try parseDesignResponse(from: jsonContent)
    return designResp.toDesignResult(localRequestId: request.id, inventory: inventory)
  }

  /// Requests 4K image generation and polls until completed (persisted to R2 by backend)
  func generateFloralImage(tenantId: String, prompt: String) async throws -> String {
    let body: [String: Any] = [
      "tenantId": tenantId,
      "action": "image_generation",
      "payload": [
        "prompt": prompt
      ]
    ]

    let responseData = try await postRaw("api/v1/proxy", jsonObject: body, tenantId: tenantId)

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
      if let items = dataObj["data"] as? [[String: Any]],
         let url = items.first?["url"] as? String {
        return url
      }
    }

    throw AIProxyError.invalidResponse
  }

  private func pollImageTask(tenantId: String, taskId: String, maxAttempts: Int = 30) async throws -> String {
    for _ in 0..<maxAttempts {
      try await Task.sleep(nanoseconds: 2_000_000_000) // wait 2s

      let pollBody: [String: Any] = [
        "tenantId": tenantId,
        "action": "image_task_status",
        "payload": ["taskId": taskId]
      ]

      let resData = try await postRaw("api/v1/proxy", jsonObject: pollBody, tenantId: tenantId)
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
      } else if status == "FAILED" {
        let msg = output["message"] as? String ?? "Image rendering failed"
        throw AIProxyError.rejected(AIProxyErrorResponse(message: msg))
      }
    }
    throw AIProxyError.invalidResponse
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

  func verifyAppleIAP(tenantId: String, transactionId: String, productId: String) async throws -> AppleVerifyResponse {
    let payload = [
      "transactionId": transactionId,
      "productId": productId
    ]
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
    return wrapper.data ?? []
  }

  func saveDesign(tenantId: String, design: DesignResult) async throws {
    let _: EmptyResponse = try await post("api/v1/designs", body: design, tenantId: tenantId)
  }

  func deleteDesign(tenantId: String, designId: String) async throws {
    let req = try makeRequest(path: "api/v1/designs/\(designId)", method: "DELETE", tenantId: tenantId)
    let _: EmptyResponse = try await perform(req)
  }

  func health() async throws -> AIProxyHealthResponse {
    let req = try makeRequest(path: "health", method: "GET")
    return try await perform(req)
  }

  // MARK: - Prompt Builders

  private func buildSystemPrompt(language: Language, request: DesignRequest, inventory: [FlowerType]) -> String {
    let langName = language == .zh ? "Simplified Chinese (简体中文)" : "English"
    let invList = inventory.map { "- \($0.name) (\($0.color)): \($0.quantity) stems, cost ¥\($0.unitCost)" }.joined(separator: "\n")
    let budget = request.budget ?? 500

    if request.designMode == "professional" {
      return """
      You are a world-class master florist and floral art director.
      Design a masterwork arrangement based on the inventory.

      CRITICAL MULTILINGUAL INSTRUCTION:
      The response must be in \(langName).
      Write title, description, meaningText, reasoning, steps, and reasons in \(langName).
      Keep imagePrompt in English.
      Keep flowerName exactly matching the inventory names.

      Budget: ¥\(budget)
      Available Inventory:
      \(invList)

      Return strictly valid JSON in this exact shape:
      {
        "title": "String",
        "description": "String",
        "meaningText": "String",
        "reasoning": "String",
        "steps": ["String", "String"],
        "imagePrompt": "A photorealistic floral arrangement in English...",
        "estimatedCost": \(budget),
        "flowerList": [
          {"flowerName": "name", "count": 5, "unitCost": 10.0, "reason": "reason"}
        ]
      }
      """
    } else {
      return """
      You are an expert floral designer. Create an exquisite floral arrangement based on the inventory.

      CRITICAL MULTILINGUAL INSTRUCTION:
      The response must be in \(langName).
      Write title, description, meaningText, reasoning, steps, and reasons in \(langName).
      Keep imagePrompt in English.
      Keep flowerName matching the inventory names.

      Target Budget: ¥\(budget)
      Available Inventory:
      \(invList)

      Return strictly valid JSON in this exact shape:
      {
        "title": "String",
        "description": "String",
        "meaningText": "String",
        "reasoning": "String",
        "steps": ["String", "String"],
        "imagePrompt": "A photorealistic floral arrangement in English...",
        "estimatedCost": \(budget),
        "flowerList": [
          {"flowerName": "name", "count": 5, "unitCost": 10.0, "reason": "reason"}
        ]
      }
      """
    }
  }

  private func buildUserPrompt(request: DesignRequest) -> String {
    return """
    Design Request:
    - Occasion: \(request.occasion.displayName)
    - Recipient: \(request.recipient.displayName)
    - Style: \(request.style.displayName)
    - Budget: ¥\(request.budget ?? 500)
    - Special Notes: \(request.requirements ?? "None")
    \(request.school != nil ? "- Floral School: \(request.school!)" : "")
    \(request.technique != nil ? "- Technique: \(request.technique!)" : "")
    \(request.seasonality != nil ? "- Season: \(request.seasonality!)" : "")
    """
  }

  private func extractAssistantMessage(from data: Data) throws -> String {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw AIProxyError.invalidResponse
    }
    if let error = json["error"] as? String {
      throw AIProxyError.rejected(AIProxyErrorResponse(message: error))
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

  private func parseDesignResponse(from text: String) throws -> AIProxyDesignResponse {
    var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if clean.hasPrefix("```json") {
      clean = clean.replacingOccurrences(of: "```json", with: "")
    }
    if clean.hasPrefix("```") {
      clean = clean.replacingOccurrences(of: "```", with: "")
    }
    if clean.hasSuffix("```") {
      clean = String(clean.dropLast(3))
    }
    clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)

    guard let data = clean.data(using: .utf8) else {
      throw AIProxyError.invalidResponse
    }
    return try JSONDecoder().decode(AIProxyDesignResponse.self, from: data)
  }

  // MARK: - Networking Core

  private func postRaw(_ path: String, jsonObject: [String: Any], tenantId: String? = nil) async throws -> Data {
    var req = try makeRequest(path: path, method: "POST", tenantId: tenantId)
    req.httpBody = try JSONSerialization.data(withJSONObject: jsonObject)
    return try await performRaw(req)
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

  private func performRaw(_ request: URLRequest, maxRetries: Int = 2) async throws -> Data {
    var attempt = 0
    var lastError: Error?

    while attempt <= maxRetries {
      do {
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
          throw AIProxyError.invalidResponse
        }

        if httpResponse.statusCode == 402 {
          let errResp = try? JSONDecoder().decode(AIProxyErrorResponse.self, from: data)
          throw AIProxyError.insufficientCredits(
            required: errResp?.requiredCredits ?? 1,
            current: errResp?.currentCredits ?? 0
          )
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
          if let errResp = try? JSONDecoder().decode(AIProxyErrorResponse.self, from: data) {
            if errResp.code == "INSUFFICIENT_CREDITS" {
              throw AIProxyError.insufficientCredits(
                required: errResp.requiredCredits ?? 1,
                current: errResp.currentCredits ?? 0
              )
            }
            throw AIProxyError.rejected(errResp)
          }
          throw AIProxyError.httpStatus(httpResponse.statusCode)
        }

        return data
      } catch let error as AIProxyError {
        throw error
      } catch {
        lastError = error
      }

      attempt += 1
      if attempt <= maxRetries {
        try await Task.sleep(nanoseconds: 1_000_000_000)
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

  func toDesignResult(localRequestId: String, inventory: [FlowerType]) -> DesignResult {
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
    let profit = cost * 0.4
    let margin = 0.4

    return DesignResult(
      id: UUID().uuidString,
      requestId: localRequestId,
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
      executedAt: nil
    )
  }
}

struct AIProxyFlowerItem: Codable {
  var flowerName: String
  var count: Int
  var unitCost: Double?
  var reason: String?
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
