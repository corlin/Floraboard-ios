import Combine
import Foundation
import OSLog
import SwiftUI

class DesignViewModel: ObservableObject {
  // Input State
  @Published var request = DesignRequest()
  @Published var selectedImage: UIImage?
  @Published var isProfessionalMode = false

  // UI State
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var generatedResult: DesignResult?
  @Published var showResult = false
  @Published var showPaywall = false

  // UX State
  @Published var cultureFilter: CultureFilter = .all
  @Published var loadingStep: Int = 0
  @Published var loadingStatus: String = ""

  private var inventoryService: InventoryService?
  private var aiService: AIService?
  private var imagePersistence: ImagePersistence?
  private var historyService: HistoryService?
  private var localizationManager: LocalizationManager?

  init() {}

  func setup(
    inventoryService: InventoryService,
    aiService: AIService,
    imagePersistence: ImagePersistence,
    historyService: HistoryService,
    localizationManager: LocalizationManager
  ) {
    guard self.inventoryService == nil else { return }
    self.inventoryService = inventoryService
    self.aiService = aiService
    self.imagePersistence = imagePersistence
    self.historyService = historyService
    self.localizationManager = localizationManager
  }

  enum CultureFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case japanese = "Japanese"
    case chinese = "Chinese"
    case western = "Western"
    var id: String { rawValue }
  }

  // Data Options
  let allSchools: [(id: String, culture: CultureFilter)] = [
    ("japanese_ikenobo", .japanese), ("japanese_ohara", .japanese), ("japanese_sogetsu", .japanese),
    ("chinese_literati", .chinese), ("chinese_zen", .chinese),
    ("western_biedermeier", .western), ("western_english", .western),
    ("fusion", .western),
  ]

  let allTechniques: [(id: String, cultures: [CultureFilter])] = [
    ("kenzan", [.japanese]),
    ("spiral_hand_tied", [.western]),
    ("parallel", [.western, .japanese]),
    ("pave", [.western]),
    ("cascade", [.western, .chinese]),
    ("oasis", [.western, .chinese, .japanese]),
    ("wiring", [.western]),
  ]

  var filteredSchools: [String] {
    if cultureFilter == .all { return allSchools.map { $0.id } }
    return allSchools.filter { $0.culture == cultureFilter }.map { $0.id }
  }

  var filteredTechniques: [String] {
    if cultureFilter == .all { return allTechniques.map { $0.id } }
    return allTechniques.filter { $0.cultures.contains(cultureFilter) }.map { $0.id }
  }

  func generateDesign() {
    guard !isLoading, let aiService = aiService, let inventoryService = inventoryService, let localizationManager = localizationManager, let historyService = historyService, let imagePersistence = imagePersistence else { return }

    isLoading = true
    loadingStep = 0
    loadingStatus = localizationManager.t("design.loading.analyze")  // "Analyzing Request..."
    errorMessage = nil

    Task {
      do {
        // Simulate Steps
        try await Task.sleep(nanoseconds: 800_000_000)
        await MainActor.run {
          self.loadingStep = 1
          self.loadingStatus = localizationManager.t("design.loading.technique")
        }  // "Selecting Technique..."

        try await Task.sleep(nanoseconds: 800_000_000)
        await MainActor.run {
          self.loadingStep = 2
          self.loadingStatus = localizationManager.t("design.loading.match")
        }  // "Matching Inventory..."

        try await Task.sleep(nanoseconds: 800_000_000)
        await MainActor.run {
          self.loadingStep = 3
          self.loadingStatus = localizationManager.t("design.loading.generate")
        }  // "Generating Design..."

        let inventory = inventoryService.flowers
        var result: DesignResult

        if let image = selectedImage {
          // Visual Muse Mode
          result = try await aiService.generateDesignFromImage(
            image: image, request: request, inventory: inventory)
        } else {
          // Standard Mode
          // Update request with professional mode flags
          var currentRequest = request
          if isProfessionalMode {
            currentRequest.designMode = "professional"
          }
          result = try await aiService.generateFlowerPlan(
            request: currentRequest, inventory: inventory)
        }

        // Image Generation Step
        if let prompt = result.imagePrompt, !prompt.isEmpty {
          await MainActor.run {
            self.loadingStatus = localizationManager.t("design.loading.dreaming")  // "Dreaming up visual..."
          }

          do {
            // 1. Generate Image URL (or Base64)
            let imageUrlString = try await aiService.generateImage(
              prompt: prompt,
              requestId: result.syncId ?? result.requestId
            )
            AppLogger.ai.debug("Received image string length: \(imageUrlString.count)")

            let image = try await resolveGeneratedImage(from: imageUrlString)

            // 3. Save to Persistence
            if let validImage = image {
              if let filename = imagePersistence.saveImage(validImage, name: result.id) {
                result.imageUrl = filename
              } else {
                AppLogger.image.error("Failed to save image to disk")
                result.imageError = localizationManager.t("error.saveImage")
              }
            } else {
              AppLogger.image.error("Failed to decode image from string: \(imageUrlString.prefix(100))...")
              result.imageError = localizationManager.t("error.invalidImageData")
            }
          } catch {
            AppLogger.ai.error("Image generation failed: \(error)")
            result.imageError = AppError(from: error).localizedDescription
          }
        } else if let selectedImg = selectedImage {
          // Visual Muse: Save input image as the design image
          if let filename = imagePersistence.saveImage(selectedImg, name: result.id) {
            result.imageUrl = filename
          }
        }

        let finalizedResult = result
        await MainActor.run {
          self.generatedResult = finalizedResult
          self.showResult = true
          self.isLoading = false
          // Save to History
          historyService.saveDesign(finalizedResult)
        }

      } catch {
        await MainActor.run {
          let appError = AppError(from: error)
          if case AppError.quotaExceeded = appError {
            self.showPaywall = true
          } else {
            self.errorMessage = appError.localizedDescription
          }
          self.isLoading = false
        }
      }
    }
  }

  private func resolveGeneratedImage(from imageString: String) async throws -> UIImage? {
    // Check for Base64 Data URI
    if imageString.hasPrefix("data:image") {
      let base64String = imageString.components(separatedBy: ",").last ?? imageString
      if let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) {
        return UIImage(data: data)
      }
      return nil
    }

    // Check for Standard URL
    if let url = URL(string: imageString),
      let scheme = url.scheme?.lowercased(),
      scheme == "http" || scheme == "https"
    {
      let (data, response) = try await URLSession.shared.data(from: url)
      if let httpResponse = response as? HTTPURLResponse,
        !(200...299).contains(httpResponse.statusCode)
      {
        throw AIError.apiError(statusCode: httpResponse.statusCode)
      }
      return UIImage(data: data)
    }

    // Try decoding raw base64 if other checks fail
    if let data = Data(base64Encoded: imageString, options: .ignoreUnknownCharacters) {
      return UIImage(data: data)
    }

    return nil
  }
}
