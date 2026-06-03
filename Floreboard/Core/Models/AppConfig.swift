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
    endpoint: "https://floreboard-ai-proxy.cybercorlin.workers.dev",
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
}
