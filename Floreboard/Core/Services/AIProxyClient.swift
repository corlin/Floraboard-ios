//
//  AIProxyClient.swift
//  Floreboard
//
//  Client boundary for the managed Floreboard AI backend.
//

import Foundation

struct AIProxyClient {
  let baseURL: URL
  var sessionToken: String?
  var urlSession: URLSession = .shared

  func generatePlan(
    tenantId: String,
    language: Language,
    request: DesignRequest,
    inventory: [FlowerType]
  ) async throws -> DesignResult {
    let payload = AIProxyDesignRequest(
      tenantId: tenantId,
      language: language.proxyCode,
      request: request,
      inventory: inventory.map(AIProxyFlowerSnapshot.init)
    )

    let response: AIProxyDesignResponse = try await post("v1/designs/plan", body: payload)
    return response.toDesignResult(localRequestId: request.id, inventory: inventory)
  }

  func createReferenceImageUpload(
    tenantId: String,
    contentType: String,
    byteCount: Int
  ) async throws -> AIProxyUploadSlot {
    let payload = AIProxyUploadSlotRequest(
      tenantId: tenantId,
      contentType: contentType,
      byteCount: byteCount
    )

    return try await post("v1/uploads/reference-image", body: payload)
  }

  func submitVisualDesign(
    tenantId: String,
    language: Language,
    request: DesignRequest,
    inventory: [FlowerType],
    imageUploadId: String
  ) async throws -> AIProxyJobStatus {
    let payload = AIProxyVisualDesignRequest(
      tenantId: tenantId,
      language: language.proxyCode,
      request: request,
      inventory: inventory.map(AIProxyFlowerSnapshot.init),
      imageUploadId: imageUploadId
    )

    return try await post("v1/designs/visual", body: payload)
  }

  func requestImageGeneration(
    tenantId: String,
    requestId: String,
    prompt: String
  ) async throws -> AIProxyJobStatus {
    let payload = AIProxyImageGenerationRequest(
      tenantId: tenantId,
      requestId: requestId,
      prompt: prompt
    )
    return try await post("v1/images/generate", body: payload)
  }

  func jobStatus(jobId: String) async throws -> AIProxyJobStatus {
    try await get("v1/jobs/\(jobId)")
  }

  func health() async throws -> AIProxyHealthResponse {
    try await get("health")
  }

  func fetchUserQuota(tenantId: String) async throws -> AIProxyQuotaResponse {
    var request = try makeRequest(path: "v1/users/quota", method: "GET")
    request.url = URL(string: "v1/users/quota?tenantId=\(tenantId)", relativeTo: baseURL)?.absoluteURL
    return try await perform(request)
  }

  func verifyIAP(tenantId: String, transactionId: String) async throws -> AIProxyQuotaResponse {
    let payload = AIProxyIAPVerifyRequest(tenantId: tenantId, transactionId: transactionId)
    var request = try makeRequest(path: "v1/iap/verify", method: "POST")
    request.httpBody = try JSONEncoder().encode(payload)
    return try await perform(request)
  }

  func uploadReferenceImage(slot: AIProxyUploadSlot, data: Data, contentType: String) async throws {
    var request = URLRequest(url: slot.uploadUrl)
    request.httpMethod = "PUT"
    request.addValue(contentType, forHTTPHeaderField: "Content-Type")
    request.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")

    let (_, response) = try await urlSession.upload(for: request, from: data)
    guard let httpResponse = response as? HTTPURLResponse,
      (200..<300).contains(httpResponse.statusCode)
    else {
      throw AIProxyError.invalidResponse
    }
  }

  private func get<Response: Decodable>(_ path: String) async throws -> Response {
    let request = try makeRequest(path: path, method: "GET")
    return try await perform(request)
  }

  private func post<Body: Encodable, Response: Decodable>(
    _ path: String,
    body: Body
  ) async throws -> Response {
    var request = try makeRequest(path: path, method: "POST")
    request.httpBody = try JSONEncoder().encode(body)
    return try await perform(request)
  }

  private func makeRequest(path: String, method: String) throws -> URLRequest {
    guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
      throw AIProxyError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = method
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    if let sessionToken, !sessionToken.isEmpty {
      request.addValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
    }
    return request
  }

  private func perform<Response: Decodable>(_ request: URLRequest, maxRetries: Int = 3) async throws -> Response {
    var attempt = 0
    var lastError: Error?

    while attempt <= maxRetries {
      do {
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
          throw AIProxyError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
          if httpResponse.statusCode == 402 {
            throw AIProxyError.insufficientQuota
          }
          if httpResponse.statusCode >= 500 {
            throw AIProxyError.httpStatus(httpResponse.statusCode)
          }
          if let error = try? JSONDecoder().decode(AIProxyErrorResponse.self, from: data) {
            if error.code == "insufficient_quota" {
              throw AIProxyError.insufficientQuota
            }
            throw AIProxyError.rejected(error)
          }
          throw AIProxyError.httpStatus(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(Response.self, from: data)
      } catch let error as AIProxyError {
        if case .httpStatus(let code) = error, code >= 500 {
          lastError = error
        } else {
          throw error
        }
      } catch {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
          lastError = error
        } else {
          throw error
        }
      }

      attempt += 1
      if attempt <= maxRetries {
        let delay = UInt64(pow(2.0, Double(attempt - 1))) * 1_000_000_000
        try await Task.sleep(nanoseconds: delay)
      }
    }

    throw lastError ?? AIProxyError.invalidResponse
  }
}

struct AIProxyDesignRequest: Codable {
  var tenantId: String
  var language: String
  var request: DesignRequest
  var inventory: [AIProxyFlowerSnapshot]
}

struct AIProxyVisualDesignRequest: Codable {
  var tenantId: String
  var language: String
  var request: DesignRequest
  var inventory: [AIProxyFlowerSnapshot]
  var imageUploadId: String
}

struct AIProxyImageGenerationRequest: Codable {
  var tenantId: String
  var requestId: String
  var prompt: String
}

struct AIProxyUploadSlotRequest: Codable {
  var tenantId: String
  var contentType: String
  var byteCount: Int
}

struct AIProxyFlowerSnapshot: Codable {
  var id: String
  var name: String
  var color: String
  var quantity: Int
  var category: FlowerCategory
  var unitCost: Double
  var retailPrice: Double
  var meaning: String?
  var cultureTags: [String]

  init(flower: FlowerType) {
    id = flower.id
    name = flower.name
    color = flower.color
    quantity = flower.quantity
    category = flower.category
    unitCost = flower.unitCost
    retailPrice = flower.retailPrice
    meaning = flower.meaning
    cultureTags = flower.cultureTags ?? []
  }
}

struct AIProxyDesignResponse: Codable {
  var requestId: String
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
        unitCost: matched?.unitCost
      )
    }

    let fallbackCost = items.reduce(0) { total, item in
      total + (item.unitCost ?? 0) * Double(item.count)
    }

    return DesignResult(
      id: UUID().uuidString,
      requestId: localRequestId,
      title: title,
      description: description,
      flowerList: items,
      reasoning: reasoning,
      steps: steps,
      imageUrl: nil,
      imagePrompt: imagePrompt,
      meaningText: meaningText,
      totalCost: estimatedCost ?? fallbackCost,
      profit: 0,
      profitMargin: 0,
      createdAt: Date().timeIntervalSince1970,
      status: .draft,
      syncId: requestId
    )
  }
}

struct AIProxyFlowerItem: Codable {
  var flowerName: String
  var count: Int
  var reason: String?
}

struct AIProxyUploadSlot: Codable {
  var uploadId: String
  var uploadUrl: URL
  var expiresAt: Double
}

struct AIProxyJobStatus: Codable {
  enum Status: String, Codable {
    case queued
    case running
    case succeeded
    case failed
  }

  var jobId: String
  var status: Status
  var pollAfterSeconds: Int?
  var result: AIProxyDesignResponse?
  var imageUrl: URL?
  var error: AIProxyErrorResponse?
}

struct AIProxyHealthResponse: Codable {
  var ok: Bool
  var service: String
  var environment: String
}

struct AIProxyQuotaResponse: Codable {
  var tenantId: String
  var tier: String
  var balance: Int
}

struct AIProxyIAPVerifyRequest: Codable {
  var tenantId: String
  var transactionId: String
}

struct AIProxyErrorResponse: Codable, Error {
  var requestId: String?
  var code: String
  var message: String
}

enum AIProxyError: LocalizedError {
  case invalidURL
  case invalidResponse
  case httpStatus(Int)
  case rejected(AIProxyErrorResponse)
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
    case .insufficientQuota:
      return Tx.t("error.api.insufficientQuota")
    }
  }
}

private extension Language {
  var proxyCode: String {
    switch self {
    case .zh: return "zh"
    case .en: return "en"
    }
  }
}
