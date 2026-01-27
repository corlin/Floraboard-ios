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

  // MARK: - Constants from Web

  private struct StyleBoosters {
    static let base =
      "Professional floral photography, 8k resolution, highly detailed, soft cinematic lighting, depth of field, photorealistic, masterpiece, elegant background."
    static let enhancedQuality =
      "Award-winning botanical photography, tack-sharp focus on blooms with creamy bokeh background, natural color grading, subtle rim lighting highlighting petal translucency, commercial floristry portfolio."
    static let textureDetail =
      "Macro-level detail on petal veins and dewdrops, crisp leaf edges, visible flower anthers and pistils, natural imperfections adding authenticity"
  }

  // MARK: - Configuration
  // MARK: - Configuration

  var currentConfig: ApiConfig {
    // Load base config
    var cfg = loadBaseConfig()
    // Inject secure key
    if let key = KeychainManager.shared.load(forKey: "api_key") {
      cfg.apiKey = key
    }
    return cfg
  }

  private var config: ApiConfig {
    return currentConfig
  }

  private func loadBaseConfig() -> ApiConfig {
    if let data = UserDefaults.standard.data(forKey: "api_config"),
      let saved = try? JSONDecoder().decode(ApiConfig.self, from: data)
    {
      return saved
    }
    return ApiConfig.default
  }

  // MARK: - Public Methods

  func updateConfig(_ newConfig: ApiConfig) {
    // 1. Save API Key to Keychain
    if !newConfig.apiKey.isEmpty {
      _ = KeychainManager.shared.save(newConfig.apiKey, forKey: "api_key")
    }

    // 2. Clear API Key for storage
    var secureConfig = newConfig
    secureConfig.apiKey = ""  // Do not save to UserDefaults

    // 3. Save rest to UserDefaults
    if let data = try? JSONEncoder().encode(secureConfig) {
      UserDefaults.standard.set(data, forKey: "api_config")
    }
  }

  /// Generates a floral design plan based on user request
  func generateFlowerPlan(request: DesignRequest, inventory: [FlowerType]) async throws
    -> DesignResult
  {
    guard !config.apiKey.isEmpty else {
      throw AIError.missingApiKey
    }

    // 1. Prepare Prompts
    // 1. Prepare Prompts
    let inventoryList = InventoryService.shared.getInventoryListString(
      lowStockThreshold: config.lowStockThreshold)
    let systemPrompt = constructSystemPrompt(inventoryList: inventoryList, request: request)
    let userPrompt = constructUserPrompt(request: request)

    // 2. Call API
    let jsonResponse = try await callChatCompletion(
      systemHelper: systemPrompt, userMessage: userPrompt, model: config.textModel)

    // 3. Parse Response

    // The AI returns a JSON structure which we need to map to our internal DesignResult
    // expecting: { flowerList: [], title, description, meaningText, steps, imagePrompt, estimatedCost }
    struct AIResponse: Codable {
      struct FlowerItem: Codable {
        let flowerName: String
        let count: Int
        let reason: String?
      }
      let flowerList: [FlowerItem]
      let reasoning: String?  // Added for CoT
      let title: String
      let description: String
      let meaningText: String
      let steps: [String]
      let imagePrompt: String
      let estimatedCost: Double?
    }

    let aiData = try JSONDecoder().decode(AIResponse.self, from: Data(jsonResponse.utf8))

    // 4. Convert to DesignResult
    // Map flower names back to inventory items if possible (or just keep name)
    let designItems = aiData.flowerList.map { item in
      DesignFlowerItem(
        flowerName: item.flowerName, count: item.count, reason: item.reason, unitCost: 0)  // Cost calculation could be improved
    }

    return DesignResult(
      id: UUID().uuidString,
      requestId: request.id,
      title: aiData.title,
      description: aiData.description,
      flowerList: designItems,
      reasoning: aiData.reasoning,
      steps: aiData.steps,
      imageUrl: nil,  // Image generated separately
      imagePrompt: aiData.imagePrompt,
      meaningText: aiData.meaningText,
      totalCost: aiData.estimatedCost ?? 0,
      profit: 0,
      profitMargin: 0,
      createdAt: Date().timeIntervalSince1970,
      requirements: request.requirements,
      status: .draft
    )
  }

  /// Generates design from image (Visual Muse)
  func generateDesignFromImage(image: UIImage, request: DesignRequest, inventory: [FlowerType])
    async throws -> DesignResult
  {
    guard !config.apiKey.isEmpty else {
      throw AIError.missingApiKey
    }

    guard let imageData = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
      throw AIError.imageEncodingFailed
    }

    // Implementation of Visual Muse logic
    // This requires a Multi-modal model call (GPT-4o or Qwen-VL)

    let inventoryList = InventoryService.shared.getInventoryListString(
      lowStockThreshold: config.lowStockThreshold)
    let languageName =
      LocalizationManager.shared.currentLanguage == .zh ? "Simplified Chinese" : "English"
    let systemPrompt = """
      You are a world-class Floral Art Director, Botanical Photographer, and Master Florist.

      **YOUR MISSION Analysis:**
      1. **Practical Flower BOM**: A list of flowers from inventory to physically recreate the design.
      2. **Visual Reproduction Prompt**: A structured prompt to generate an image that EXACTLY matches the reference.

      **CRITICAL INSTRUCTION: MULTILINGUAL OUTPUT**
      The visual analysis and image prompt generation must be done in English to ensure precision.
      Review the user's language: \(languageName).
      For the Final JSON Output, the "title", "description", "meaningText", "steps", and "reason" (in flowerList) fields MUST be written in \(languageName).
      Everything else (including visualAnalysis and imagePrompt) should remain in English.

      > **CRITICAL RULE**: The Visual Reproduction Prompt is NOT constrained by inventory. You may describe ANY materials (driftwood, willow, coral branches, etc.) that appear in the reference image, even if they're not in the flower inventory.

      ---

      ## PHASE 1: MANDATORY VISUAL ANALYSIS (Mental Scratchpad)

      ### A. SCALE DETECTION
      Identify reference objects and estimate dimensions (Micro <30cm, Small 30-60cm, Medium 60-120cm, Large 1-3m, Monumental >3m).

      ### B. STRUCTURAL DNA
      Analyze the geometry (Fan, Dome, Asymmetrical, Linear, Architectural).

      ### C. COLOR PALETTE
      Identify dominant hues, accents, and color harmony (Monochromatic, Analogous, Complementary).

      ---

      ## PHASE 2: INVENTORY MAPPING
      Map the visual elements to available inventory.
      - If exact match exists (e.g., Red Rose), use it.
      - If unavailable, find the best texture/color substitute from inventory.
      - Only list flowers that physically exist in the 'Inventory' list below.

      Inventory:
      \(inventoryList)

      ---

      ## PROMPT CONSTRUCTION GUIDE
      Construct 'imagePrompt' by combining:
      1. [Scale/Type Declaration] (e.g. "A large architectural floral installation...")
      2. [Structure Description]
      3. [Central Focal Flowers]
      4. [Supporting Elements]
      5. [Setting/Lighting Context]
      6. Style Booster: "\(StyleBoosters.enhancedQuality) \(StyleBoosters.textureDetail)"
      """

    let userPrompt = "Analyze this image and create a floral design."

    // Call Vision API
    let jsonResponse = try await callVisionCompletion(
      systemHelper: systemPrompt, userMessage: userPrompt, imageBase64: imageData,
      model: config.visionModel)

    // Parse logic similar to above... (Simplified for brevity in this step)
    // Re-using the same AIResponse struct for now
    struct AIResponse: Codable {
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

    let aiData = try JSONDecoder().decode(AIResponse.self, from: Data(jsonResponse.utf8))

    let designItems = aiData.flowerList.map { item in
      DesignFlowerItem(
        flowerName: item.flowerName, count: item.count, reason: item.reason, unitCost: 0)
    }

    return DesignResult(
      id: UUID().uuidString,
      requestId: request.id,
      title: aiData.title,
      description: aiData.description,
      flowerList: designItems,
      steps: aiData.steps,
      imageUrl: nil,
      imagePrompt: aiData.imagePrompt,
      meaningText: aiData.meaningText,
      totalCost: aiData.estimatedCost ?? 0,
      profit: 0,
      profitMargin: 0,
      createdAt: Date().timeIntervalSince1970,
      requirements: request.requirements,
      status: .draft
    )
  }

  // MARK: - Private Helpers

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

  /// Generates an image from a prompt and returns the URL string
  /// Generates an image from a prompt and returns the URL string
  func generateImage(prompt: String) async throws -> String {
    guard !config.apiKey.isEmpty else { throw AIError.missingApiKey }

    let endpoint = config.imageEndpoint ?? config.endpoint

    // Aliyun Wanx Special Handling
    if config.imageModel.lowercased().contains("wanx") {
      return try await generateImageAliyun(prompt: prompt)
    }

    // OpenRouter Special Handling
    if endpoint.contains("openrouter") {
      return try await generateImageOpenRouter(prompt: prompt)
    }

    // Standard OpenAI DALL-E Handling
    guard let url = URL(string: "\(endpoint)/images/generations") else {
      throw AIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
      "model": config.imageModel,
      "prompt": prompt,
      "n": 1,
      "size": "1024x1024",
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      if let errText = String(data: data, encoding: .utf8) {
        print("Image Gen Error: \(errText)")
      }
      throw AIError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500)
    }

    struct ImageResponse: Codable {
      struct DataItem: Codable {
        let url: String?
        let b64_json: String?
      }
      let data: [DataItem]
    }

    let decoded = try JSONDecoder().decode(ImageResponse.self, from: data)
    return decoded.data.first?.url ?? ""
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
  private func generateImageOpenRouter(prompt: String) async throws -> String {
    guard let url = URL(string: "\(config.endpoint)/chat/completions") else {
      throw AIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("https://floreboard.app", forHTTPHeaderField: "HTTP-Referer")
    request.addValue("Floreboard", forHTTPHeaderField: "X-Title")

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
