//
//  Localization.swift
//  Floreboard
//
//  Migrated to String Catalog (.xcstrings) backed localization with multi-language cascading fallback.
//

import Combine
import Foundation

enum Language: String, CaseIterable, Identifiable {
  case zh
  case en
  case ja
  case ko
  case fr

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .zh: return "简体中文"
    case .en: return "English"
    case .ja: return "日本語"
    case .ko: return "한국어"
    case .fr: return "Français"
    }
  }

  /// The lproj directory name used by Apple localization
  var lprojName: String {
    switch self {
    case .zh: return "zh-Hans"
    case .en: return "en"
    case .ja: return "ja"
    case .ko: return "ko"
    case .fr: return "fr"
    }
  }
}

private let bundleLock = NSLock()
private var _sharedLanguage: Language = .zh
private var _sharedBundle: Bundle = .main
private var _sharedEnBundle: Bundle? = loadLprojBundle(for: Language.en.lprojName)
private var _sharedZhBundle: Bundle? = loadLprojBundle(for: Language.zh.lprojName)

private func loadLprojBundle(for lprojName: String) -> Bundle? {
  if let path = Bundle.main.path(forResource: lprojName, ofType: "lproj") {
    return Bundle(path: path)
  }
  let bundle = Bundle(for: LocalizationManager.self)
  if let path = bundle.path(forResource: lprojName, ofType: "lproj") {
    return Bundle(path: path)
  }
  return nil
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
  private(set) var enBundle: Bundle?
  private(set) var zhBundle: Bundle?

  private init() {
    if let saved = UserDefaults.standard.string(forKey: "app_language"),
      let lang = Language(rawValue: saved) {
      self.currentLanguage = lang
    } else {
      let deviceLang = Locale.current.language.languageCode?.identifier ?? "en"
      if deviceLang.hasPrefix("zh") {
        self.currentLanguage = .zh
      } else if deviceLang.hasPrefix("ja") {
        self.currentLanguage = .ja
      } else if deviceLang.hasPrefix("ko") {
        self.currentLanguage = .ko
      } else if deviceLang.hasPrefix("fr") {
        self.currentLanguage = .fr
      } else {
        self.currentLanguage = .en
      }
    }

    let en = _sharedEnBundle ?? loadLprojBundle(for: Language.en.lprojName)
    let zh = _sharedZhBundle ?? loadLprojBundle(for: Language.zh.lprojName)
    self.enBundle = en
    self.zhBundle = zh

    bundleLock.lock()
    _sharedEnBundle = en
    _sharedZhBundle = zh
    bundleLock.unlock()

    updateBundle()
  }

  private func updateBundle() {
    if let bundle = loadLprojBundle(for: currentLanguage.lprojName) {
      localizedBundle = bundle
    } else {
      localizedBundle = .main
    }

    bundleLock.lock()
    _sharedLanguage = currentLanguage
    _sharedBundle = localizedBundle
    _sharedEnBundle = enBundle
    _sharedZhBundle = zhBundle
    bundleLock.unlock()
  }

  func t(_ key: String, _ args: [String: String] = [:]) -> String {
    Tx.t(key, args)
  }

  func t(_ key: String, _ arguments: CVarArg...) -> String {
    let format = Tx.t(key)
    return String(format: format, arguments: arguments)
  }
}

// Helper for easier access in Views
// Usage: Tx.t("key")
struct Tx {
  static func t(_ key: String, _ args: [String: String] = [:]) -> String {
    bundleLock.lock()
    let currentLanguage = _sharedLanguage
    let currentBundle = _sharedBundle
    let enBundle = _sharedEnBundle
    let zhBundle = _sharedZhBundle
    bundleLock.unlock()

    // 1. Query current bundle
    var value = currentBundle.localizedString(forKey: key, value: "__NOT_FOUND__", table: nil)

    // 2. If not found and current language is not English, fallback to en bundle
    if value == "__NOT_FOUND__" && currentLanguage != .en {
      if let en = enBundle {
        value = en.localizedString(forKey: key, value: "__NOT_FOUND__", table: nil)
      }
    }

    // 3. If still not found and current language is not Chinese, fallback to zh-Hans bundle
    if value == "__NOT_FOUND__" && currentLanguage != .zh {
      if let zh = zhBundle {
        value = zh.localizedString(forKey: key, value: "__NOT_FOUND__", table: nil)
      }
    }

    // 4. If still not found, fallback to key itself
    if value == "__NOT_FOUND__" {
      value = key
    }

    // Parameter interpolation
    for (placeholder, replacement) in args {
      value = value.replacingOccurrences(of: "{{\(placeholder)}}", with: replacement)
    }
    return value
  }

  static func t(_ key: String, _ arguments: CVarArg...) -> String {
    let format = Tx.t(key)
    return String(format: format, arguments: arguments)
  }
}
