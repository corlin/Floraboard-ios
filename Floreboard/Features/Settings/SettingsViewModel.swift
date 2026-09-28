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
  @Published var creditsData: CreditsData?
  @Published var isLoadingCredits = false

  private var aiService: AIService?
  private var cancellables = Set<AnyCancellable>()

  init() {
    self.config = ApiConfig.default
    NotificationCenter.default.publisher(for: NSNotification.Name("FloreboardCreditsUpdated"))
      .sink { [weak self] _ in
        self?.fetchCredits()
      }
      .store(in: &cancellables)
  }

  func setup(with service: AIService) {
    guard self.aiService == nil else { return }
    self.aiService = service
    self.config = service.currentConfig
    fetchCredits()
  }

  func fetchCredits() {
    guard let service = aiService else { return }
    isLoadingCredits = true
    Task {
      do {
        let credits = try await service.fetchCredits()
        await MainActor.run {
          self.creditsData = credits
          self.isLoadingCredits = false
        }
      } catch {
        await MainActor.run {
          self.isLoadingCredits = false
        }
        AppLogger.ai.warning("Failed to fetch credits: \(error.localizedDescription)")
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
