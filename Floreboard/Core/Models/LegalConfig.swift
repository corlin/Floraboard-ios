//
//  LegalConfig.swift
//  Floreboard
//
//  Centralized legal URLs, contact information, and policy endpoints.
//  Synchronized with floreboard-web (https://floreboard.com).
//

import Foundation

enum LegalDocumentType: String, Identifiable, CaseIterable {
  case privacy
  case terms
  case refund

  var id: String { rawValue }

  var titleKey: String {
    switch self {
    case .privacy: return "legal.privacyPolicy"
    case .terms: return "legal.termsOfService"
    case .refund: return "legal.refundPolicy"
    }
  }

  var iconName: String {
    switch self {
    case .privacy: return "hand.raised.fill"
    case .terms: return "doc.text.fill"
    case .refund: return "arrow.uturn.backward.circle.fill"
    }
  }

  var webURL: URL {
    switch self {
    case .privacy:
      return LegalConfig.privacyPolicyURL
    case .terms:
      return LegalConfig.termsOfServiceURL
    case .refund:
      return LegalConfig.refundPolicyURL
    }
  }
}

struct LegalConfig {
  static let contactEmail = "corlin@qq.com"

  /// Official Web URL corresponding to floreboard-web deployment
  static let baseWebURL = "https://floreboard.com"

  static var privacyPolicyURL: URL {
    URL(string: "\(baseWebURL)/privacy") ?? URL(string: "https://floreboard.com/privacy")!
  }

  static var termsOfServiceURL: URL {
    URL(string: "\(baseWebURL)/terms") ?? URL(string: "https://floreboard.com/terms")!
  }

  static var refundPolicyURL: URL {
    URL(string: "\(baseWebURL)/refund") ?? URL(string: "https://floreboard.com/refund")!
  }

  static var pricingURL: URL {
    URL(string: "\(baseWebURL)/pricing") ?? URL(string: "https://floreboard.com/pricing")!
  }

  static var supportMailURL: URL? {
    URL(string: "mailto:\(contactEmail)?subject=Floreboard%20Support%20%26%20Inquiry")
  }
}
