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
        "inventory": inventoryPayload(inventory)
      ]
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
        "imageBase64": base64String
      ]
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
        let progress = "\(consecutiveTransientErrors)/\(maxConsecutiveTransientErrors)"
        AppLogger.ai.warning("Polling task \(taskId) transient failure (\(progress)): \(error.localizedDescription)")
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

  // MARK: - Networking Core

  func postRaw(
    _ path: String,
    jsonObject: [String: Any],
    tenantId: String? = nil,
    customSession: URLSession? = nil
  ) async throws -> Data {
    var req = try makeRequest(path: path, method: "POST", tenantId: tenantId)
    req.httpBody = try JSONSerialization.data(withJSONObject: jsonObject)
    return try await performRaw(req, session: customSession)
  }

  func post<Body: Encodable, Response: Decodable>(
    _ path: String,
    body: Body,
    tenantId: String? = nil
  ) async throws -> Response {
    var request = try makeRequest(path: path, method: "POST", tenantId: tenantId)
    request.httpBody = try JSONEncoder().encode(body)
    return try await perform(request)
  }

  func makeRequest(path: String, method: String, tenantId: String? = nil) throws -> URLRequest {
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

  /// 一次 HTTP 响应的处理结果
  private enum Outcome {
    case success(Data)
    case fatal(Error)
    case retryable(Error)
  }

  /// 2xx 成功；点数不足（402）与 429 以外的 4xx 立即失败；429 与 5xx 可重试
  private static func outcome(status: Int, data: Data) -> Outcome {
    if (200..<300).contains(status) { return .success(data) }
    let errResp = try? JSONDecoder().decode(AIProxyErrorResponse.self, from: data)
    if status == 402 || errResp?.code == "INSUFFICIENT_CREDITS" {
      return .fatal(AIProxyError.insufficientCredits(
        required: errResp?.requiredCredits ?? 1,
        current: errResp?.currentCredits ?? 0))
    }
    let error = errResp.map { AIProxyError.rejected($0) } ?? AIProxyError.httpStatus(status)
    let clientError = (400..<500).contains(status) && status != 429
    return clientError ? .fatal(error) : .retryable(error)
  }

  func performRaw(
    _ request: URLRequest,
    session: URLSession? = nil,
    maxRetries: Int = 2
  ) async throws -> Data {
    let activeSession = session ?? urlSession
    var lastError: Error = AIProxyError.invalidResponse

    for attempt in 0...max(0, maxRetries) {
      if attempt > 0 {
        // Exponential backoff with jitter (~1s, ~2s, ~4s; capped at 5s)
        let backoff = min(pow(2.0, Double(attempt - 1)) + Double.random(in: 0.1...0.3), 5.0)
        try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
      }

      let data: Data
      let response: URLResponse
      do {
        (data, response) = try await activeSession.data(for: request)
      } catch {
        lastError = error // 网络层错误可重试
        continue
      }
      guard let httpResponse = response as? HTTPURLResponse else {
        lastError = AIProxyError.invalidResponse
        continue
      }

      switch Self.outcome(status: httpResponse.statusCode, data: data) {
      case .success(let body): return body
      case .fatal(let error): throw error
      case .retryable(let error): lastError = error
      }
    }
    throw lastError
  }

  func perform<Response: Decodable>(_ request: URLRequest, maxRetries: Int = 2) async throws -> Response {
    let data = try await performRaw(request, maxRetries: maxRetries)
    return try JSONDecoder().decode(Response.self, from: data)
  }
}
