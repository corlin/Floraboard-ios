//
//  CurrencyFormatter.swift
//  Floreboard
//
//  Centralized currency formatting to avoid hardcoded ¥ symbols.
//

import Foundation

enum CurrencyFormat {
  /// Formats a Double value as a localized currency string.
  /// Uses CNY (¥) as default, but respects locale for formatting rules.
  static func format(_ value: Double, showDecimal: Bool = false) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "CNY"
    formatter.currencySymbol = "¥"
    formatter.maximumFractionDigits = showDecimal ? 2 : 0
    formatter.minimumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? "¥\(Int(value))"
  }

  /// Compact format for inline display: "¥500"
  static func compact(_ value: Double) -> String {
    "¥\(Int(value))"
  }

  /// Label for cost fields in forms, e.g. "Cost (¥)"
  static var currencyUnit: String { "¥" }
}
