import Foundation

// MARK: - General Enums

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
  case graduation, opening, apology, valentine
  case motherDay = "mother_day" // 与服务端/翻译键保持一致
  case other

  var displayName: String { Tx.t("enum.occasion.\(rawValue)") }
  var id: String { self.rawValue }
}

enum RecipientType: String, Codable, CaseIterable, Identifiable {
  case partner, parent, friend, elder
  case selfRecipient = "self" // `self` 是关键字，原始值保持 "self"
  case colleague, child

  var id: String { self.rawValue }
  var displayName: String { Tx.t("enum.recipient.\(rawValue)") }
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
  case generating = "GENERATING"
  case succeeded = "SUCCEEDED"
  case failed = "FAILED"
}

enum DesignStatus: String, Codable {
  case draft
  case completed
}

// MARK: - Culture Types

enum CultureType: String {
  case japanese, chinese, western

  var icon: String {
    switch self {
    case .japanese: return "🎴"
    case .chinese: return "🏮"
    case .western: return "🌹"
    }
  }
}

enum OrderStatus: String, Codable, CaseIterable, Identifiable {
  case draft
  case quoted
  case confirmed
  case inProduction
  case delivered
  case cancelled

  var id: String { self.rawValue }

  var displayName: String { Tx.t("order.status.\(rawValue)") }
}
