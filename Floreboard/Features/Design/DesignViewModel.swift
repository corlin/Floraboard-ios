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
  @Published var isRegeneratingImage = false

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
          // Persist the reference image so it can be restored or used as fallback later
          if let refFilename = imagePersistence.saveImage(image, name: "ref_\(result.id)") {
            result.referenceImageUrl = refFilename
          }
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

          // Double-layer resilience: 1 silent retry before surfacing error to user
          var generatedImage: UIImage? = nil
          var generatedRemoteURL: String? = nil
          var lastError: Error? = nil

          for attempt in 1...2 {
            do {
              let imageUrlString = try await aiService.generateImage(
                prompt: prompt,
                requestId: result.syncId ?? result.requestId
              )
              AppLogger.ai.debug("Attempt \(attempt): Received image string length: \(imageUrlString.count)")

              generatedRemoteURL = DesignMerge.isRemoteImage(imageUrlString) ? imageUrlString : nil
              generatedImage = try await resolveGeneratedImage(from: imageUrlString)
              if generatedImage != nil {
                lastError = nil
                break
              }
            } catch {
              lastError = error
              AppLogger.ai.warning("Image generation attempt \(attempt) failed: \(error.localizedDescription)")
              if attempt < 2 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
              }
            }
          }

          // Save generated image or record structured error
          if let validImage = generatedImage {
            // 优先保存云端可访问的 URL（跨设备可见）；没有 URL 就上传；都失败才退回本地文件名
            if let stored = await ImageSyncService.shared.storedImageValue(
              image: validImage, remoteURL: generatedRemoteURL, designId: result.id, persistence: imagePersistence)
            {
              result.imageUrl = stored
              result.imageStatus = .succeeded
              result.imageError = nil
            } else {
              AppLogger.image.error("Failed to save image to disk")
              result.imageError = localizationManager.t("error.saveImage")
              result.imageStatus = .failed
            }
          } else if let error = lastError {
            AppLogger.ai.error("Image generation completely failed after retries: \(error)")
            result.imageError = AppError(from: error).localizedDescription
            result.imageStatus = .failed
          } else {
            AppLogger.image.error("Failed to decode image from response")
            result.imageError = localizationManager.t("error.invalidImageData")
            result.imageStatus = .failed
          }
        } else if let selectedImg = selectedImage {
          // Visual Muse: Fallback to input image if no imagePrompt returned
          if let stored = await ImageSyncService.shared.storedImageValue(
            image: selectedImg, remoteURL: nil, designId: result.id, persistence: imagePersistence)
          {
            result.imageUrl = stored
            result.imageStatus = .succeeded
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

  func retryImageGeneration() {
    guard var result = generatedResult,
          let prompt = result.imagePrompt, !prompt.isEmpty,
          let aiService = aiService,
          let imagePersistence = imagePersistence,
          let historyService = historyService,
          !isRegeneratingImage else { return }

    isRegeneratingImage = true
    result.imageError = nil
    result.imageStatus = .generating
    self.generatedResult = result

    Task {
      do {
        let imageUrlString = try await aiService.generateImage(
          prompt: prompt,
          requestId: result.syncId ?? result.requestId
        )
        let image = try await resolveGeneratedImage(from: imageUrlString)

        if let validImage = image {
          if let stored = await ImageSyncService.shared.storedImageValue(
            image: validImage,
            remoteURL: DesignMerge.isRemoteImage(imageUrlString) ? imageUrlString : nil,
            designId: result.id, persistence: imagePersistence)
          {
            result.imageUrl = stored
            result.imageError = nil
            result.imageStatus = .succeeded
          } else {
            result.imageError = localizationManager?.t("error.saveImage")
            result.imageStatus = .failed
          }
        } else {
          result.imageError = localizationManager?.t("error.invalidImageData")
          result.imageStatus = .failed
        }
      } catch {
        AppLogger.ai.error("Image retry failed: \(error)")
        result.imageError = AppError(from: error).localizedDescription
        result.imageStatus = .failed
      }

      let updatedResult = result
      await MainActor.run {
        self.generatedResult = updatedResult
        self.isRegeneratingImage = false
        historyService.saveDesign(updatedResult)
      }
    }
  }

  /// Adopts the uploaded reference image as the primary design visual
  func useReferenceImageAsFinal() {
    guard var result = generatedResult,
          let refPath = result.referenceImageUrl,
          let imagePersistence = imagePersistence,
          let historyService = historyService else { return }

    if let refImage = imagePersistence.loadImage(named: refPath) {
      Task {
        if let stored = await ImageSyncService.shared.storedImageValue(
          image: refImage, remoteURL: nil, designId: result.id, persistence: imagePersistence)
        {
          var updated = result
          updated.imageUrl = stored
          updated.imageError = nil
          updated.imageStatus = .succeeded
          await MainActor.run {
            self.generatedResult = updated
            historyService.saveDesign(updated)
          }
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

    // Check for Standard URL with retry
    if let url = URL(string: imageString),
      let scheme = url.scheme?.lowercased(),
      scheme == "http" || scheme == "https"
    {
      return try await AIProxyClient.downloadImageWithRetry(from: url, maxRetries: 2)
    }

    // Try decoding raw base64 if other checks fail
    if let data = Data(base64Encoded: imageString, options: .ignoreUnknownCharacters) {
      return UIImage(data: data)
    }

    return nil
  }
}
