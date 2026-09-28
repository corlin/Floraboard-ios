import Foundation

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
    endpoint: "https://api.floreboard.com",
    textModel: "",
    visionModel: "",
    imageModel: "",
    budget: 500,
    alertThreshold: 5,
    lowStockThreshold: 10
  )
}

extension ApiConfig {
  static func normalizeEndpoint(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed != "/" else { return "" }
    return trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
  }

  mutating func normalizeEndpoints() {
    endpoint = Self.normalizeEndpoint(endpoint)
    if let imageEndpoint {
      let normalizedImageEndpoint = Self.normalizeEndpoint(imageEndpoint)
      self.imageEndpoint = normalizedImageEndpoint.isEmpty ? nil : normalizedImageEndpoint
    }
  }
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
  var ownerId: String?
  var credits: Int?
  var tier: String?
  var subscriptionExpiresAt: String?

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case ownerId = "owner_id"
    case credits
    case tier
    case subscriptionExpiresAt = "subscription_expires_at"
  }
}

// MARK: - Credits & Payment Models

struct CreditTransaction: Codable, Identifiable, Hashable {
  var id: String
  var tenantId: String?
  var type: String
  var amount: Int
  var balanceAfter: Int
  var description: String?
  var referenceId: String?
  var createdAt: String

  enum CodingKeys: String, CodingKey {
    case id
    case tenantId
    case type
    case amount
    case balanceAfter
    case description
    case referenceId
    case createdAt
  }
}

struct CreditsData: Codable {
  var tenantId: String?
  var credits: Int
  var tier: String
  var subscriptionExpiresAt: String?
  var activePlanId: String?
  var transactions: [CreditTransaction]
}

struct PaymentPlanItem: Codable, Identifiable, Hashable {
  var id: String
  var name: String
  var type: String // "subscription" | "credit_pack"
  var credits: Int
  var price: String
  var currency: String
  var billingCycle: String?
  var badge: String?
  var description: String
  var features: [String]?
  var recommended: Bool?
}

struct AppleVerifyResponse: Codable {
  var success: Bool
  var message: String?
  var data: AppleVerifyData?

  struct AppleVerifyData: Codable {
    var tenantId: String?
    var credits: Int
    var tier: String
    var subscriptionExpiresAt: String?
    var creditsAdded: Int?
  }
}
