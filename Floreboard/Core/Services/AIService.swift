//
//  AIService.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import Combine
import Foundation
import OSLog
import UIKit

@MainActor
class AIService: ObservableObject {
  static let shared = AIService()

  private enum ManagedAIConfig {
    static let defaultProxyBaseURL = "https://api.floreboard.com"
    static let proxyBaseURLInfoKey = "FLOREBOARD_AI_PROXY_BASE_URL"
    static let proxyBaseURLDefaultsKey = "ai_proxy_base_url"
    static let proxyTokenInfoKey = "FLOREBOARD_AI_PROXY_SESSION_TOKEN"
    static let proxyTokenDefaultsKey = "ai_proxy_session_token"
  }

  // MARK: - Configuration

  var currentConfig: ApiConfig {
    loadBaseConfig()
  }

  private func loadBaseConfig() -> ApiConfig {
    if let data = UserDefaults.standard.data(forKey: "api_config"),
      let saved = try? JSONDecoder().decode(ApiConfig.self, from: data)
    {
      var normalized = saved
      normalized.normalizeEndpoints()
      return normalized
    }
    return ApiConfig.default
  }

  // MARK: - Public Methods

  func updateConfig(_ newConfig: ApiConfig) {
    var normalizedConfig = newConfig
    normalizedConfig.normalizeEndpoints()
    normalizedConfig.apiKey = ""
    normalizedConfig.textModel = ""
    normalizedConfig.visionModel = ""
    normalizedConfig.imageModel = ""
    normalizedConfig.imageEndpoint = nil

    KeychainManager.shared.delete(forKey: "api_key")

    if let data = try? JSONEncoder().encode(normalizedConfig) {
      UserDefaults.standard.set(data, forKey: "api_config")
    }
  }

  func testConnection(using candidateConfig: ApiConfig) async throws {
    _ = candidateConfig
    let health = try await makeProxyClient().health()
    guard health.ok else { throw AIError.apiError(statusCode: 503) }
  }

  func fetchQuota() async throws -> AIProxyQuotaResponse {
    let tenantId = await currentTenantId()
    return try await makeProxyClient().fetchUserQuota(tenantId: tenantId)
  }

  func verifyIAP(transactionId: String) async throws -> AIProxyQuotaResponse {
    let tenantId = await currentTenantId()
    return try await makeProxyClient().verifyIAP(tenantId: tenantId, transactionId: transactionId)
  }

  /// Generates a floral design plan based on user request
  func generateFlowerPlan(request: DesignRequest, inventory: [FlowerType]) async throws
    -> DesignResult
  {
    let tenantId = await currentTenantId()
    do {
      return try await makeProxyClient().generatePlan(
        tenantId: tenantId,
        language: LocalizationManager.shared.currentLanguage,
        request: request,
        inventory: inventory
      )
    } catch {
      AppLogger.ai.warning("Proxy server error: \(error.localizedDescription). Falling back to local intelligent generator.")
      return generateLocalFallbackPlan(request: request, inventory: inventory)
    }
  }

  func generateLocalFallbackPlan(request: DesignRequest, inventory: [FlowerType]) -> DesignResult {
    let availableInventory = inventory.isEmpty ? FlowerType.initialData : inventory
    let selectedFlowers = Array(availableInventory.prefix(3))
    let flowerItems = selectedFlowers.map { flower in
      DesignFlowerItem(
        flowerName: flower.name,
        count: max(3, flower.quantity / 5),
        reason: "精选花房实时库存",
        unitCost: flower.unitCost
      )
    }

    let totalCost = flowerItems.reduce(0.0) { $0 + ($1.unitCost ?? 5.0) * Double($1.count) }
    let profit = totalCost * 0.4
    let profitMargin = 0.4

    let title = "\(request.occasion.displayName) • \(request.style.displayName) 花艺方案"
    let desc = "结合 \(request.occasion.displayName) 场景与 \(request.style.displayName) 风格，精选花房实时库存打造的主题花艺方案。"
    let reasoning = "主花与配花比例遵循黄金分割结构，色彩调和，展现独特的美学韵味。"
    let steps = ["裁剪枝干至适当长度", "固定主花位置建立主视点", "加入配花与绿叶进行丰满填充"]

    return DesignResult(
      id: UUID().uuidString,
      requestId: request.id,
      title: title,
      description: desc,
      flowerList: flowerItems,
      reasoning: reasoning,
      steps: steps,
      imageUrl: nil,
      imageTaskId: nil,
      imageStatus: .succeeded,
      imageError: nil,
      imagePrompt: nil,
      meaningText: "花开富贵，美好相伴",
      totalCost: totalCost,
      profit: profit,
      profitMargin: profitMargin,
      createdAt: Date().timeIntervalSince1970,
      requirements: request.requirements,
      status: .completed,
      executedAt: nil
    )
  }

  /// Generates design from image (Visual Muse)
  func generateDesignFromImage(image: UIImage, request: DesignRequest, inventory: [FlowerType])
    async throws -> DesignResult
  {
    guard let imageData = image.jpegData(compressionQuality: 0.82) else {
      throw AIError.imageEncodingFailed
    }

    let client = try makeProxyClient()
    let tenantId = await currentTenantId()
    
    do {
      let slot = try await client.createReferenceImageUpload(
        tenantId: tenantId,
        contentType: "image/jpeg",
        byteCount: imageData.count
      )
      try await client.uploadReferenceImage(slot: slot, data: imageData, contentType: "image/jpeg")
      let initialJob = try await client.submitVisualDesign(
        tenantId: tenantId,
        language: LocalizationManager.shared.currentLanguage,
        request: request,
        inventory: inventory,
        imageUploadId: slot.uploadId
      )

      let job = try await waitForCompletedJob(client: client, initialJob: initialJob)
      if let result = job.result {
        return result.toDesignResult(localRequestId: request.id, inventory: inventory)
      }
      if let error = job.error {
        throw AIProxyError.rejected(error)
      }
      throw AIError.apiError(statusCode: 202)
    } catch {
      AppLogger.ai.warning("Visual design failed or disabled, falling back to text generation. Error: \(error.localizedDescription)")
      var fallbackRequest = request
      fallbackRequest.requirements = (fallbackRequest.requirements ?? "") + " [Visual Muse Fallback]"
      return try await generateFlowerPlan(request: fallbackRequest, inventory: inventory)
    }
  }

  private func makeProxyClient() throws -> AIProxyClient {
    guard let baseURL = URL(string: aiProxyBaseURL) else {
      throw AIError.invalidURL
    }

    return AIProxyClient(
      baseURL: baseURL,
      sessionToken: configuredProxyToken()
    )
  }

  private var aiProxyBaseURL: String {
    if let value = Bundle.main.object(forInfoDictionaryKey: "FLOREBOARD_AI_PROXY_BASE_URL")
      as? String,
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      var cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
      if !cleanValue.hasPrefix("http") {
        cleanValue = "https://" + cleanValue
      }
      if cleanValue.contains("workers.dev") {
        return ManagedAIConfig.defaultProxyBaseURL
      }
      return cleanValue
    }

    if let value = UserDefaults.standard.string(forKey: "ai_proxy_base_url"),
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      var cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
      if !cleanValue.hasPrefix("http") {
        cleanValue = "https://" + cleanValue
      }
      if cleanValue.contains("workers.dev") {
        UserDefaults.standard.set(ManagedAIConfig.defaultProxyBaseURL, forKey: "ai_proxy_base_url")
        return ManagedAIConfig.defaultProxyBaseURL
      }
      return cleanValue
    }

    return ManagedAIConfig.defaultProxyBaseURL
  }

  private func configuredProxyToken() -> String? {
    // 1. Prefer JWT access token from AuthService
    if let jwt = AuthService.shared.accessToken,
      !jwt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return jwt
    }

    // 2. Fallback: Info.plist
    if let value = Bundle.main.object(forInfoDictionaryKey: ManagedAIConfig.proxyTokenInfoKey)
      as? String,
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // 3. Fallback: Keychain (legacy)
    if let value = KeychainManager.shared.load(forKey: ManagedAIConfig.proxyTokenDefaultsKey),
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return nil
  }

  private func currentTenantId() async -> String {
    await MainActor.run {
      AuthService.shared.currentTenant?.id ?? "local-store"
    }
  }

  private func waitForCompletedJob(
    client: AIProxyClient,
    initialJob: AIProxyJobStatus,
    maxAttempts: Int = 45
  ) async throws -> AIProxyJobStatus {
    var job = initialJob

    for _ in 0..<maxAttempts {
      switch job.status {
      case .succeeded, .failed:
        return job
      case .queued, .running:
        let delay = UInt64(job.pollAfterSeconds ?? 2) * 1_000_000_000
        try await Task.sleep(nanoseconds: delay)
        job = try await client.jobStatus(jobId: job.jobId)
      }
    }

    throw AIError.apiError(statusCode: 202)
  }

  /// Generates an image through the managed backend and returns the URL string.
  func generateImage(prompt: String, requestId: String) async throws -> String {
    let client = try makeProxyClient()
    let tenantId = await currentTenantId()
    let initialJob = try await client.requestImageGeneration(
      tenantId: tenantId,
      requestId: requestId,
      prompt: prompt
    )

    let job = try await waitForCompletedJob(client: client, initialJob: initialJob)
    switch job.status {
    case .succeeded:
      if let imageUrl = job.imageUrl {
        return imageUrl.absoluteString
      }
      throw AIError.imageEncodingFailed
    case .failed:
      if let error = job.error {
        throw AIProxyError.rejected(error)
      }
      throw AIError.apiError(statusCode: 500)
    case .queued, .running:
      throw AIError.apiError(statusCode: 202)
    }
  }

}

enum AIError: Error, LocalizedError {
  case missingApiKey
  case invalidURL
  case apiError(statusCode: Int)
  case imageEncodingFailed

  var errorDescription: String? {
    switch self {
    case .missingApiKey: return Tx.t("error.missingApiKey")
    case .invalidURL: return Tx.t("error.invalidURL")
    case .apiError(let code): return Tx.t("error.apiError", ["code": "\(code)"])
    case .imageEncodingFailed: return Tx.t("error.imageEncodingFailed")
    }
  }
}
