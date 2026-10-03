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
    guard health.status == "ok" || health.service != nil else { throw AIError.apiError(statusCode: 503) }
  }

  func fetchCredits() async throws -> CreditsData {
    let tenantId = await currentTenantId()
    return try await makeProxyClient().fetchCredits(tenantId: tenantId)
  }

  func appleAccountToken() async throws -> UUID {
    let tenantId = await currentTenantId()
    return try await makeProxyClient().fetchAppleAccountToken(tenantId: tenantId)
  }

  func verifyApplePurchase(
    transactionId: String,
    productId: String,
    jws: String? = nil,
    originalTransactionId: String? = nil
  ) async throws -> AppleVerifyResponse {
    let tenantId = await currentTenantId()
    return try await makeProxyClient().verifyAppleIAP(
      tenantId: tenantId,
      transactionId: transactionId,
      productId: productId,
      jws: jws,
      originalTransactionId: originalTransactionId
    )
  }

  func generateFloralImage(prompt: String) async throws -> String {
    let tenantId = await currentTenantId()
    return try await makeProxyClient().generateFloralImage(tenantId: tenantId, prompt: prompt)
  }

  /// Generates a floral design plan based on user request
  func generateFlowerPlan(request: DesignRequest, inventory: [FlowerType]) async throws
    -> DesignResult
  {
    let tenantId = await currentTenantId()
    return try await makeProxyClient().generatePlan(
      tenantId: tenantId,
      language: LocalizationManager.shared.currentLanguage,
      request: request,
      inventory: inventory
    )
  }

  /// Generates design from image (Visual Muse)
  func generateDesignFromImage(image: UIImage, request: DesignRequest, inventory: [FlowerType])
    async throws -> DesignResult
  {
    let client = try makeProxyClient()
    let tenantId = await currentTenantId()
    return try await client.submitVisualDesign(
      tenantId: tenantId,
      language: LocalizationManager.shared.currentLanguage,
      request: request,
      inventory: inventory,
      image: image
    )
  }

  func makeProxyClient() throws -> AIProxyClient {
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

  /// Generates an image through the managed backend and returns the URL string.
  func generateImage(prompt: String, requestId: String) async throws -> String {
    let tenantId = await currentTenantId()
    let client = try makeProxyClient()
    return try await client.generateFloralImage(tenantId: tenantId, prompt: prompt)
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
