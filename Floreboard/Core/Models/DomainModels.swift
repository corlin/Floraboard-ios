import Foundation

// MARK: - Domain Models

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

// MARK: - Professional Mode Models

struct FloralSchool: Identifiable, Hashable {
  let id: String
  let culture: CultureType
  let _descKey: String

  var name: String { Tx.t("pro.school.\(id).name") }
}

struct FloralTechnique: Identifiable, Hashable {
  let id: String
  let cultures: [CultureType]
  var name: String { Tx.t("pro.tech.\(id).name") }
}

struct ProportionRule: Identifiable, Hashable {
  let id: String
  let cultures: [CultureType]
  var name: String { Tx.t("pro.prop.\(id).name") }
}

struct FloralSeason: Identifiable, Hashable {
  let id: String
  let cultures: [CultureType]
  var name: String { Tx.t("pro.season.\(id).name") }
}

// Data Sources

let SCHOOLS: [FloralSchool] = [
  FloralSchool(id: "japanese_ikenobo", culture: .japanese, _descKey: ""),
  FloralSchool(id: "japanese_ohara", culture: .japanese, _descKey: ""),
  FloralSchool(id: "japanese_sogetsu", culture: .japanese, _descKey: ""),
  FloralSchool(id: "chinese_literati", culture: .chinese, _descKey: ""),
  FloralSchool(id: "chinese_zen", culture: .chinese, _descKey: ""),
  FloralSchool(id: "western_biedermeier", culture: .western, _descKey: ""),
  FloralSchool(id: "western_english", culture: .western, _descKey: ""),
  FloralSchool(id: "fusion", culture: .western, _descKey: ""),
]

let TECHNIQUES: [FloralTechnique] = [
  FloralTechnique(id: "kenzan", cultures: [.japanese]),
  FloralTechnique(id: "spiral_hand_tied", cultures: [.western]),
  FloralTechnique(id: "parallel", cultures: [.western, .japanese]),
  FloralTechnique(id: "pave", cultures: [.western]),
  FloralTechnique(id: "cascade", cultures: [.western, .chinese]),
  FloralTechnique(id: "oasis", cultures: [.western, .chinese, .japanese]),
  FloralTechnique(id: "wiring", cultures: [.western]),
]

let PROPORTIONS: [ProportionRule] = [
  ProportionRule(id: "7_5_3", cultures: [.japanese]),
  ProportionRule(id: "golden_ratio", cultures: [.western]),
  ProportionRule(id: "free", cultures: [.japanese, .chinese, .western]),
]

let SEASONS: [FloralSeason] = [
  FloralSeason(id: "spring", cultures: [.japanese, .chinese, .western]),
  FloralSeason(id: "summer", cultures: [.japanese, .chinese, .western]),
  FloralSeason(id: "autumn", cultures: [.japanese, .chinese, .western]),
  FloralSeason(id: "winter", cultures: [.japanese, .chinese, .western]),
  FloralSeason(id: "all", cultures: [.japanese, .chinese, .western]),
]
