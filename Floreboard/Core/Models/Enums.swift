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
