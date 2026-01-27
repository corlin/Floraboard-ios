//
//  Models.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import Foundation

// MARK: - Enums

enum BackendRegion: String, Codable, CaseIterable {
  case supabase
  case aliyun
  case local
}

enum FlowerCategory: String, Codable, CaseIterable, Identifiable {
  case main
  case filler
  case foliage

  var id: String { self.rawValue }

  var displayName: String { Tx.t("enum.category.\(rawValue)") }
}

enum OccasionType: String, Codable, CaseIterable, Identifiable {
  case wedding, birthday, comfort, home
  case graduation, opening, apology, valentine, mother_day, other

  var displayName: String { Tx.t("enum.occasion.\(rawValue)") }
  var id: String { self.rawValue }
}

enum RecipientType: String, Codable, CaseIterable, Identifiable {
  case partner, parent, friend, elder
  case self_recipient = "self"
  case colleague, child

  var id: String { self.rawValue }
}

enum StyleType: String, Codable, CaseIterable, Identifiable {
  case romantic, fresh, vintage, passionate, minimalist, wild, elegant

  var displayName: String { Tx.t("enum.style.\(rawValue)") }
  var id: String { self.rawValue }
}

enum ColorPaletteType: String, Codable, CaseIterable, Identifiable {
  case warm, cool, pastel, vibrant, monochrome, auto

  var displayName: String { Tx.t("color.\(rawValue)") }

  var id: String { self.rawValue }
}

enum FormatType: String, Codable, CaseIterable, Identifiable {
  case bouquet, vase, box, basket

  var displayName: String { Tx.t("enum.format.\(rawValue)") }

  var id: String { self.rawValue }
}

enum ImageStatus: String, Codable {
  case pending = "PENDING"
  case succeeded = "SUCCEEDED"
  case failed = "FAILED"
}

enum DesignStatus: String, Codable {
  case draft
  case completed
}

// MARK: - Models

struct FlowerType: Codable, Identifiable, Hashable {
  var id: String
  var name: String
  var color: String
  var quantity: Int
  var initialStock: Int
  var category: FlowerCategory
  var unitCost: Double
  var retailPrice: Double
  var meaning: String?
  var totalUsed: Int?
  var cultureTags: [String]?
  var createdAt: Double?
  var updatedAt: Double?

  var syncId: String?
  var syncVersion: Int?
  var syncedAt: Double?

  init(
    id: String = UUID().uuidString, name: String, color: String, quantity: Int, initialStock: Int,
    category: FlowerCategory, unitCost: Double, retailPrice: Double, meaning: String? = nil
  ) {
    self.id = id
    self.name = name
    self.color = color
    self.quantity = quantity
    self.initialStock = initialStock
    self.category = category
    self.unitCost = unitCost
    self.retailPrice = retailPrice
    self.meaning = meaning
  }
}

struct DesignRequest: Codable, Identifiable {
  var id: String
  var occasion: OccasionType
  var recipient: RecipientType
  var style: StyleType
  var colorPalette: ColorPaletteType?
  var format: FormatType?
  var budget: Double?
  var requirements: String?

  // Professional Mode Fields
  var school: String?
  var technique: String?
  var designMode: String?  // "professional" or "quick"
  var proportionRule: String?
  var seasonality: String?
  var culturalContext: String?

  // Visual Muse Fields
  var scalePreference: String?
  var moodPreference: String?
  var formPreference: String?  // Added for Deep Porting
  var backgroundStyle: String?  // Added for Deep Porting

  init(
    id: String = UUID().uuidString,
    occasion: OccasionType = .home,
    recipient: RecipientType = .self_recipient,
    style: StyleType = .fresh
  ) {
    self.id = id
    self.occasion = occasion
    self.recipient = recipient
    self.style = style
  }
}

struct DesignFlowerItem: Codable, Identifiable {
  var id: String { flowerName }  // Use name as ID since it comes from AI without ID sometimes
  var flowerName: String
  var count: Int
  var reason: String?
  var unitCost: Double?
}

struct DesignResult: Codable, Identifiable {
  var id: String
  var requestId: String
  var title: String
  var description: String
  var flowerList: [DesignFlowerItem]
  var reasoning: String? = nil  // Added for CoT
  var steps: [String]
  var imageUrl: String? = nil
  var imageTaskId: String? = nil
  var imageStatus: ImageStatus? = nil
  var imageError: String? = nil
  var imagePrompt: String? = nil  // Added for image generation
  var meaningText: String
  var totalCost: Double
  var profit: Double
  var profitMargin: Double
  var createdAt: Double
  var requirements: String? = nil
  var rating: Int? = nil
  var feedback: String? = nil
  var status: DesignStatus
  var executedAt: Double? = nil

  var syncId: String? = nil
  var syncVersion: Int? = nil
  var syncedAt: Double? = nil
}

struct ApiConfig: Codable, Identifiable {
  var id: String?
  var apiKey: String
  var endpoint: String
  var textModel: String
  var visionModel: String
  var imageModel: String
  var imageEndpoint: String?
  var budget: Double
  var alertThreshold: Int
  var lowStockThreshold: Int
  var updatedAt: Double?

  static let `default` = ApiConfig(
    apiKey: "",
    endpoint: "https://dashscope.aliyuncs.com/compatible-mode/v1",
    textModel: "qwen-plus",
    visionModel: "qwen-vl-max",
    imageModel: "wanx-v1",
    budget: 500,
    alertThreshold: 5,
    lowStockThreshold: 10
  )
}

struct UsageRecord: Codable, Identifiable {
  var id: String
  var date: Double
  var tokens: Int
  var type: String
  var cost: Double
}

struct Tenant: Codable, Identifiable {
  var id: String
  var name: String
}

struct AIProvider: Identifiable {
  let id: String
  let name: String
  let endpoint: String
  let models: [String]
  let visionModels: [String]
  let imageEndpoint: String
  let imageModels: [String]

  static let all: [AIProvider] = [
    AIProvider(
      id: "aliyun",
      name: "Aliyun (Qwen/Wanx)",
      endpoint: "https://dashscope.aliyuncs.com/compatible-mode/v1",
      models: ["qwen-plus", "qwen-max", "qwen-turbo"],
      visionModels: ["qwen-vl-max", "qwen-vl-plus"],
      imageEndpoint: "https://dashscope.aliyuncs.com",
      imageModels: ["wanx-v1", "wan2.1-t2i-turbo"]
    ),
    AIProvider(
      id: "openrouter",
      name: "OpenRouter (Claude/Gemini)",
      endpoint: "https://openrouter.ai/api/v1",
      models: ["anthropic/claude-3.5-sonnet", "google/gemini-pro", "openai/gpt-4o"],
      visionModels: ["google/gemini-1.5-pro", "openai/gpt-4o", "anthropic/claude-3.5-sonnet"],
      imageEndpoint: "https://openrouter.ai/api/v1",
      imageModels: ["google/gemini-3-pro-image-preview"]
    ),
    AIProvider(
      id: "deepseek",
      name: "DeepSeek",
      endpoint: "https://api.deepseek.com",
      models: ["deepseek-chat", "deepseek-coder"],
      visionModels: [],
      imageEndpoint: "",
      imageModels: []
    ),
    AIProvider(
      id: "openai",
      name: "OpenAI (Official)",
      endpoint: "https://api.openai.com/v1",
      models: ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"],
      visionModels: ["gpt-4o", "gpt-4-turbo"],
      imageEndpoint: "https://api.openai.com/v1",
      imageModels: ["dall-e-3", "dall-e-2"]
    ),
    AIProvider(
      id: "custom",
      name: "Custom / Other",
      endpoint: "",
      models: [],
      visionModels: [],
      imageEndpoint: "",
      imageModels: []
    ),
  ]
}

// MARK: - Extension for Mock Data

extension FlowerType {
  static let mocks: [FlowerType] = [
    FlowerType(
      name: "Red Rose", color: "Red", quantity: 50, initialStock: 100, category: .main,
      unitCost: 5.0, retailPrice: 15.0, meaning: "Love"),
    FlowerType(
      name: "White Lily", color: "White", quantity: 30, initialStock: 50, category: .main,
      unitCost: 8.0, retailPrice: 20.0, meaning: "Purity"),
    FlowerType(
      name: "Baby's Breath", color: "White", quantity: 200, initialStock: 200, category: .filler,
      unitCost: 1.0, retailPrice: 3.0),
    FlowerType(
      name: "Eucalyptus", color: "Green", quantity: 80, initialStock: 100, category: .foliage,
      unitCost: 2.0, retailPrice: 5.0),
  ]
}
