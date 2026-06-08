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
  @Published var userQuota: AIProxyQuotaResponse?

  private var aiService: AIService?

  init() {
    // Initial config is empty, will be set in setup
    self.config = ApiConfig.default
  }

  func setup(with service: AIService) {
    guard self.aiService == nil else { return }
    self.aiService = service
    self.config = service.currentConfig
    fetchQuota()
  }

  func fetchQuota() {
    guard let service = aiService else { return }
    Task {
      do {
        let quota = try await service.fetchQuota()
        await MainActor.run {
          self.userQuota = quota
        }
      } catch {
        AppLogger.ai.warning("Failed to fetch quota: \(error.localizedDescription)")
      }
    }
  }

  func save() {
    config.normalizeEndpoints()
    aiService?.updateConfig(config)
    statusMessage = Tx.t("settings.saveSuccess")
    isStatusError = false
  }

  func testConnection() {
    guard !isTestingConnection, let service = aiService else { return }

    isTestingConnection = true
    statusMessage = nil
    isStatusError = false

    Task {
      do {
        try await service.testConnection(using: config)
        await MainActor.run {
          self.statusMessage = Tx.t("settings.test.success")
          self.isStatusError = false
          self.isTestingConnection = false
        }
      } catch {
        await MainActor.run {
          self.statusMessage = AppError(from: error).localizedDescription
          self.isStatusError = true
          self.isTestingConnection = false
        }
      }
    }
  }
}
