//
//  Localization.swift
//  Floreboard
//
//  Migrated to String Catalog (.xcstrings) backed localization.
//

import Combine
import Foundation

enum Language: String, CaseIterable, Identifiable {
  case en = "en"
  case zh = "zh"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .en: return "English"
    case .zh: return "简体中文"
    }
  }

  /// The lproj directory name used by Apple localization
  var lprojName: String {
    switch self {
    case .en: return "en"
    case .zh: return "zh-Hans"
    }
  }
}

@MainActor
class LocalizationManager: ObservableObject {
  static let shared = LocalizationManager()

  @Published var currentLanguage: Language {
    didSet {
      UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
      updateBundle()
    }
  }

  private(set) var localizedBundle: Bundle = .main

  private init() {
    if let saved = UserDefaults.standard.string(forKey: "app_language"),
      let lang = Language(rawValue: saved)
    {
      self.currentLanguage = lang
    } else {
      // Default to device language if matches, else en
      let deviceLang = Locale.current.language.languageCode?.identifier ?? "en"
      self.currentLanguage = deviceLang.contains("zh") ? .zh : .en
    }
    updateBundle()
  }

  private func updateBundle() {
    if let path = Bundle.main.path(forResource: currentLanguage.lprojName, ofType: "lproj"),
      let bundle = Bundle(path: path)
    {
      localizedBundle = bundle
    } else {
      localizedBundle = .main
    }
  }

  func t(_ key: String, _ args: [String: String] = [:]) -> String {
    var value = localizedBundle.localizedString(forKey: key, value: key, table: nil)
    for (k, v) in args {
      value = value.replacingOccurrences(of: "{{\(k)}}", with: v)
    }
    return value
  }
}

// Helper for easier access in Views
// Usage: Tx.t("key")
struct Tx {
  static func t(_ key: String, _ args: [String: String] = [:]) -> String {
    LocalizationManager.shared.t(key, args)
  }
}

