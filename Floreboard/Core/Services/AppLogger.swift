//
//  AppLogger.swift
//  Floreboard
//
//  Structured logging facade using OSLog.
//

import OSLog

enum AppLogger {
  static let ai = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.floreboard", category: "AI")
  static let image = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.floreboard", category: "Image")
  static let inventory = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.floreboard", category: "Inventory")
  static let general = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.floreboard", category: "General")
}
