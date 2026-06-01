//
//  AIService.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import Combine
import Foundation
import UIKit

class AIService: ObservableObject {
  static let shared = AIService()

  private enum ManagedAIConfig {
    static let defaultProxyBaseURL = "https://floreboard-ai-proxy.corlin.workers.dev"
    static let proxyBaseURLInfoKey = "FLOREBOARD_AI_PROXY_BASE_URL"
    static let proxyBaseURLDefaultsKey = "ai_proxy_base_url"
    static let proxyTokenInfoKey = "FLOREBOARD_AI_PROXY_SESSION_TOKEN"
    static let proxyTokenDefaultsKey = "ai_proxy_session_token"
  }

  // MARK: - Constants from Web

  private struct StyleBoosters {
    static let base =
      "Professional floral photography, 8k resolution, highly detailed, soft cinematic lighting, depth of field, photorealistic, masterpiece, elegant background."
    static let enhancedQuality =
      "Award-winning botanical photography, tack-sharp focus on blooms with creamy bokeh background, natural color grading, subtle rim lighting highlighting petal translucency, commercial floristry portfolio."
    static let textureDetail =
      "Macro-level detail on petal veins and dewdrops, crisp leaf edges, visible flower anthers and pistils, natural imperfections adding authenticity"
  }

  private struct AIDesignResponse: Codable {
    struct FlowerItem: Codable {
      let flowerName: String
      let count: Int
      let reason: String?
    }

    let flowerList: [FlowerItem]
    let reasoning: String?
    let title: String
    let description: String
    let meaningText: String
    let steps: [String]
    let imagePrompt: String
    let estimatedCost: Double?
  }

  // MARK: - Configuration

  var currentConfig: ApiConfig {
    loadBaseConfig()
  }

  private var config: ApiConfig {
    return currentConfig
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
    guard let imageData = image.jpegData(compressionQuality: 0.82) else {
      throw AIError.imageEncodingFailed
    }

    let client = try makeProxyClient()
    let tenantId = await currentTenantId()
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
  }

  private func makeProxyClient() throws -> AIProxyClient {
    guard let baseURL = URL(string: configuredProxyBaseURL()) else {
      throw AIError.invalidURL
    }

    return AIProxyClient(
      baseURL: baseURL,
      sessionToken: configuredProxyToken()
    )
  }

  private func configuredProxyBaseURL() -> String {
    if let value = Bundle.main.object(forInfoDictionaryKey: ManagedAIConfig.proxyBaseURLInfoKey)
      as? String,
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    if let value = UserDefaults.standard.string(forKey: ManagedAIConfig.proxyBaseURLDefaultsKey),
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return ManagedAIConfig.defaultProxyBaseURL
  }

  private func configuredProxyToken() -> String? {
    if let value = Bundle.main.object(forInfoDictionaryKey: ManagedAIConfig.proxyTokenInfoKey)
      as? String,
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    if let value = UserDefaults.standard.string(forKey: ManagedAIConfig.proxyTokenDefaultsKey),
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
    maxAttempts: Int = 8
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

  // MARK: - Private Helpers

  private func applyProviderHeaders(to request: inout URLRequest, endpoint: String) {
    if endpoint.contains("openrouter") {
      request.addValue("https://floreboard.app", forHTTPHeaderField: "HTTP-Referer")
      request.addValue("Floreboard", forHTTPHeaderField: "X-Title")
    }
  }

  private func decodeDesignResponse(from response: String) throws -> AIDesignResponse {
    let jsonString = extractJSONObject(from: response)
    return try JSONDecoder().decode(AIDesignResponse.self, from: Data(jsonString.utf8))
  }

  private func extractJSONObject(from response: String) -> String {
    var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

    if cleaned.hasPrefix("```") {
      cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
      cleaned = cleaned.replacingOccurrences(of: "```JSON", with: "")
      cleaned = cleaned.replacingOccurrences(of: "```", with: "")
      cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    if let start = cleaned.firstIndex(of: "{"),
      let end = cleaned.lastIndex(of: "}"),
      start <= end
    {
      return String(cleaned[start...end])
    }

    return cleaned
  }

  private func mapDesignItems(
    _ items: [AIDesignResponse.FlowerItem], inventory: [FlowerType]
  ) -> [DesignFlowerItem] {
    items.map { item in
      let matchedFlower = findFlower(named: item.flowerName, in: inventory)
      return DesignFlowerItem(
        flowerName: item.flowerName,
        count: item.count,
        reason: item.reason,
        unitCost: matchedFlower?.unitCost
      )
    }
  }

  private func findFlower(named name: String, in inventory: [FlowerType]) -> FlowerType? {
    inventory.first {
      $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        || $0.name.localizedCaseInsensitiveContains(name)
        || name.localizedCaseInsensitiveContains($0.name)
    }
  }

  private func calculateCost(for items: [DesignFlowerItem]) -> Double {
    items.reduce(0) { total, item in
      total + Double(item.count) * (item.unitCost ?? 0)
    }
  }

  private func resolvedCost(estimatedCost: Double?, fallbackCost: Double) -> Double {
    guard let estimatedCost, estimatedCost > 0 else {
      return fallbackCost
    }
    return estimatedCost
  }

  private func constructSystemPrompt(inventoryList: String, request: DesignRequest) -> String {
    let languageName =
      LocalizationManager.shared.currentLanguage == .zh ? "Simplified Chinese" : "English"

    // Detailed style rules can be injected here
    return """
      You are a master florist with profound knowledge of Eastern and Western floral arts.
      Design a stunning arrangement based on the user request and available inventory.

      # Design Philosophies
      - Western (Romantic/English): Emphasize mass, symmetry or abundance. Use main flowers + fillers + foliage.
      - Eastern (Zen/Ikenobo): Emphasize line, negative space (Ma), and asymmetry. Less is more.
      - Modern: Focus on texture, grouping, and bold color blocking.

      # Process
      1. Analyze the Request (Occasion, Recipient, Style).
      2. Check Inventory constraints (Budget, Stock).
      3. Formulate a creative concept.
      4. Select materials (prioritize in-stock).

      # Output Requirements
      - Language: \(languageName) (except imagePrompt).
      - Output strictly valid JSON.
      - "imagePrompt" must be a highly detailed English visual description.

      Inventory:
      \(inventoryList)
      """
  }

  private func getBudgetComplexityGuidance(budget: Double) -> String {
    if budget <= 200 {
      return "SIMPLE design: 3-5 stems total, 2-3 flower types, economical choices."
    }
    if budget <= 500 { return "STANDARD design: 8-15 stems total, 3-5 flower types, balanced mix." }
    if budget <= 1000 {
      return "PREMIUM design: 15-25 stems total, 4-6 flower types, include premium flowers."
    }
    if budget <= 2000 {
      return "LUXURY design: 25-40 stems total, 5-8 flower types, prioritize premium flowers."
    }
    return
      "GRAND LUXURY design: 40+ stems total, 6-10 flower types, use the most premium flowers available."
  }

  private func constructUserPrompt(request: DesignRequest) -> String {
    let budgetGuidance = getBudgetComplexityGuidance(budget: request.budget ?? 0)

    return """
      Request:
      - Occasion: \(request.occasion.rawValue)
      - Recipient: \(request.recipient.rawValue)
      - Style: \(request.style.rawValue)
      - Budget: \(request.budget ?? 0)
      - Professional Mode: \(request.school ?? "None") / \(request.technique ?? "None")

      **Budget Guidance**: \(budgetGuidance)

      Return JSON:
      {
        "reasoning": "Step-by-step design logic...",
        "flowerList": [{"flowerName": "name", "count": n, "reason": "reason"}],
        "estimatedCost": number,
        "title": "Title",
        "description": "Desc",
        "meaningText": "Meaning",
        "steps": ["Step 1", "Step 2"],
        "imagePrompt": "Detailed visual prompt"
      }
      """
  }

  private func callChatCompletion(systemHelper: String, userMessage: String, model: String)
    async throws -> String
  {
    // Simple implementation for OpenAI compatible API
    guard let url = URL(string: "\(config.endpoint)/chat/completions") else {
      throw AIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    applyProviderHeaders(to: &request, endpoint: config.endpoint)

    let body: [String: Any] = [
      "model": model,
      "messages": [
        ["role": "system", "content": systemHelper],
        ["role": "user", "content": userMessage],
      ],
      "temperature": 0.7,
      "response_format": ["type": "json_object"],
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      if let errText = String(data: data, encoding: .utf8) {
        print("AI Error: \(errText)")
      }
      throw AIError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500)
    }

    // Parse OpenAI response structure
    struct OpenAIChoice: Codable {
      struct Message: Codable {
        let content: String
      }
      let message: Message
    }
    struct OpenAIResponse: Codable {
      let choices: [OpenAIChoice]
    }

    let responseData = try JSONDecoder().decode(OpenAIResponse.self, from: data)
    return responseData.choices.first?.message.content ?? "{}"
  }

  private func callVisionCompletion(
    systemHelper: String, userMessage: String, imageBase64: String, model: String
  ) async throws -> String {
    // Vision API call structure (compatible with OpenAI/Qwen-VL)
    guard let url = URL(string: "\(config.endpoint)/chat/completions") else {
      throw AIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    applyProviderHeaders(to: &request, endpoint: config.endpoint)

    let body: [String: Any] = [
      "model": model,
      "messages": [
        ["role": "system", "content": systemHelper],
        [
          "role": "user",
          "content": [
            ["type": "text", "text": userMessage],
            ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(imageBase64)"]],
          ],
        ],
      ],
      "max_tokens": 2000,
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw AIError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500)
    }

    struct OpenAIChoice: Codable {
      struct Message: Codable {
        let content: String
      }
      let message: Message
    }
    struct OpenAIResponse: Codable {
      let choices: [OpenAIChoice]
    }

    let responseData = try JSONDecoder().decode(OpenAIResponse.self, from: data)

    // Clean markdown if present
    var content = responseData.choices.first?.message.content ?? "{}"
    content = content.replacingOccurrences(of: "```json", with: "").replacingOccurrences(
      of: "```", with: "")

    return content
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

  // MARK: - Aliyun Wanx Support

  private func generateImageAliyun(prompt: String) async throws -> String {
    // 1. Submit Task
    let endpoint = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis"
    guard let url = URL(string: endpoint) else { throw AIError.invalidURL }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("enable", forHTTPHeaderField: "X-DashScope-Async")

    let body: [String: Any] = [
      "model": config.imageModel,
      "input": ["prompt": prompt],
      "parameters": ["size": "1024*1024", "n": 1],
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    // Check submission success
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      if let errText = String(data: data, encoding: .utf8) {
        print("Aliyun Submit Error: \(errText)")
      }
      throw AIError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500)
    }

    struct AliyunSubmitResponse: Codable {
      struct Output: Codable { let task_id: String }
      let output: Output
    }

    let submitRes = try JSONDecoder().decode(AliyunSubmitResponse.self, from: data)
    let taskId = submitRes.output.task_id

    // 2. Poll for Result
    var attempts = 0
    while attempts < 30 {  // Timeout after ~60s
      try await Task.sleep(nanoseconds: 2_000_000_000)  // 2s

      let taskUrl = URL(string: "https://dashscope.aliyuncs.com/api/v1/tasks/\(taskId)")!
      var taskReq = URLRequest(url: taskUrl)
      taskReq.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

      let (taskData, _) = try await URLSession.shared.data(for: taskReq)

      struct AliyunTaskResponse: Codable {
        struct Output: Codable {
          let task_status: String
          let results: [ResultItem]?
          struct ResultItem: Codable { let url: String }
        }
        let output: Output
      }

      let taskRes = try JSONDecoder().decode(AliyunTaskResponse.self, from: taskData)

      switch taskRes.output.task_status {
      case "SUCCEEDED":
        return taskRes.output.results?.first?.url ?? ""
      case "FAILED":
        throw AIError.imageEncodingFailed  // Generic error for failed task
      default:
        break  // Continue polling (PENDING, RUNNING)
      }

      attempts += 1
    }

    throw AIError.apiError(statusCode: 408)  // Timeout
  }

  // MARK: - OpenRouter Image Support
  private func generateImageOpenRouter(prompt: String, endpoint: String) async throws -> String {
    guard let url = URL(string: "\(endpoint)/chat/completions") else {
      throw AIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    applyProviderHeaders(to: &request, endpoint: endpoint)

    // OpenRouter format: Chat Completion with "image" modality (optional but recommended for some models)
    // Some models might just take text and output markdown image.
    // But search says "modalities": ["image", "text"]

    let body: [String: Any] = [
      "model": config.imageModel,
      "messages": [
        ["role": "user", "content": prompt]
      ],
      "modalities": ["image", "text"],  // Required for Gemini image generation models
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      if let errText = String(data: data, encoding: .utf8) { print("OpenRouter Error: \(errText)") }
      throw AIError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500)
    }

    // Flexible parsing
    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]

    // Check for "choices" -> "message"
    if let choice = (json?["choices"] as? [[String: Any]])?.first,
      let message = choice["message"] as? [String: Any]
    {

      // 1. Check for 'images' array in message (OpenRouter specific for some models)
      // Structure according to user: choices[0].message.images[0].image_url.url
      if let imagesArray = message["images"] as? [[String: Any]],
        let firstImageObj = imagesArray.first,
        let imageUrlObj = firstImageObj["image_url"] as? [String: Any],
        let urlString = imageUrlObj["url"] as? String
      {
        print("AIService: Found image nested in images[0].image_url.url")
        return urlString
      }

      // Fallback: Check if it is a simple array of strings
      if let images = message["images"] as? [String], let firstImage = images.first {
        print("AIService: Found image in 'images' string array")
        return firstImage
      }

      // 2. Check content for Markdown or URL
      if let content = message["content"] as? String {
        // Check for Markdown image ![...](url)
        let pattern = "\\!\\[.*?\\]\\((.*?)\\)"
        if let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(
            in: content, range: NSRange(content.startIndex..., in: content)),
          let urlRange = Range(match.range(at: 1), in: content)
        {
          return String(content[urlRange])
        }
        // If content IS a URL
        if content.hasPrefix("http") || content.hasPrefix("data:image") {
          return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
      }
    }

    // Fallback or Error Logging
    print("OpenRouter Parse Failed. Response: \(String(describing: json))")
    throw AIError.imageEncodingFailed
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
