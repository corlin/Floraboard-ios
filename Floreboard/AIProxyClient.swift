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
    requestId: String
  ) async throws -> AIProxyJobStatus {
    let payload = AIProxyImageGenerationRequest(tenantId: tenantId, requestId: requestId)
    return try await post("v1/images/generate", body: payload)
  }

  func jobStatus(jobId: String) async throws -> AIProxyJobStatus {
    try await get("v1/jobs/\(jobId)")
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

  private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
    let (data, response) = try await urlSession.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw AIProxyError.invalidResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      if let error = try? JSONDecoder().decode(AIProxyErrorResponse.self, from: data) {
        throw AIProxyError.rejected(error)
      }
      throw AIProxyError.httpStatus(httpResponse.statusCode)
    }

    return try JSONDecoder().decode(Response.self, from: data)
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
