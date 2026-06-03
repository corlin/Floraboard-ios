import Combine
import Foundation
import OSLog
import SwiftUI

// MARK: - Settings View Model

class SettingsViewModel: ObservableObject {
  @Published var config: ApiConfig
  @Published var statusMessage: String?
  @Published var isStatusError = false
  @Published var isTestingConnection = false

  init() {
    self.config = AIService.shared.currentConfig
  }

  func save() {
    config.normalizeEndpoints()
    AIService.shared.updateConfig(config)
    statusMessage = Tx.t("settings.saveSuccess")
    isStatusError = false
  }

  func testConnection() {
    guard !isTestingConnection else { return }

    isTestingConnection = true
    statusMessage = nil
    isStatusError = false

    Task {
      do {
        try await AIService.shared.testConnection(using: config)
        await MainActor.run {
          self.statusMessage = Tx.t("settings.test.success")
          self.isStatusError = false
          self.isTestingConnection = false
        }
      } catch {
        await MainActor.run {
          self.statusMessage = error.localizedDescription
          self.isStatusError = true
          self.isTestingConnection = false
        }
      }
    }
  }
}
