//
//  ViewModels.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Inventory View Model

class InventoryViewModel: ObservableObject {
  @Published var flowers: [FlowerType] = []
  @Published var searchText: String = ""
  @Published var selectedCategory: FlowerCategory? = nil

  private var cancellables = Set<AnyCancellable>()

  init() {
    // Bind to service
    InventoryService.shared.$flowers
      .assign(to: \.flowers, on: self)
      .store(in: &cancellables)
  }

  var filteredFlowers: [FlowerType] {
    flowers.filter { flower in
      let matchesSearch =
        searchText.isEmpty || flower.name.localizedCaseInsensitiveContains(searchText)
      let matchesCategory = selectedCategory == nil || flower.category == selectedCategory
      return matchesSearch && matchesCategory
    }
  }

  func addFlower(
    name: String, color: String, quantity: Int, cost: Double, price: Double,
    category: FlowerCategory, cultureTags: [String] = [], meaning: String = ""
  ) {
    let newFlower = FlowerType(
      name: name, color: color, quantity: quantity, initialStock: quantity, category: category,
      unitCost: cost, retailPrice: price, meaning: meaning)
    var flower = newFlower
    flower.cultureTags = cultureTags
    InventoryService.shared.addFlower(flower)
  }

  func updateFlower(_ flower: FlowerType) {
    InventoryService.shared.updateFlower(flower)
  }

  func delete(at offsets: IndexSet) {
    offsets.forEach { index in
      let flower = filteredFlowers[index]
      InventoryService.shared.deleteFlower(flower.id)
    }
  }

  func delete(_ flower: FlowerType) {
    InventoryService.shared.deleteFlower(flower.id)
  }
}

// MARK: - Design View Model

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

  // UX State
  @Published var cultureFilter: CultureFilter = .all
  @Published var loadingStep: Int = 0
  @Published var loadingStatus: String = ""

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
    guard !isLoading else { return }

    isLoading = true
    loadingStep = 0
    loadingStatus = Tx.t("design.loading.analyze")  // "Analyzing Request..."
    errorMessage = nil

    Task {
      do {
        // Simulate Steps
        try await Task.sleep(nanoseconds: 800_000_000)
        await MainActor.run {
          self.loadingStep = 1
          self.loadingStatus = Tx.t("design.loading.technique")
        }  // "Selecting Technique..."

        try await Task.sleep(nanoseconds: 800_000_000)
        await MainActor.run {
          self.loadingStep = 2
          self.loadingStatus = Tx.t("design.loading.match")
        }  // "Matching Inventory..."

        try await Task.sleep(nanoseconds: 800_000_000)
        await MainActor.run {
          self.loadingStep = 3
          self.loadingStatus = Tx.t("design.loading.generate")
        }  // "Generating Design..."

        let inventory = InventoryService.shared.flowers
        var result: DesignResult

        if let image = selectedImage {
          // Visual Muse Mode
          result = try await AIService.shared.generateDesignFromImage(
            image: image, request: request, inventory: inventory)
        } else {
          // Standard Mode
          // Update request with professional mode flags
          var currentRequest = request
          if isProfessionalMode {
            currentRequest.designMode = "professional"
          }
          result = try await AIService.shared.generateFlowerPlan(
            request: currentRequest, inventory: inventory)
        }

        // Image Generation Step
        if let prompt = result.imagePrompt, !prompt.isEmpty {
          await MainActor.run {
            self.loadingStatus = Tx.t("design.loading.dreaming")  // "Dreaming up visual..."
          }

          do {
            // 1. Generate Image URL (or Base64)
            let imageUrlString = try await AIService.shared.generateImage(prompt: prompt)
            print("Received image string length: \(imageUrlString.count)")

            var image: UIImage? = nil

            // Check for Base64 Data URI
            if imageUrlString.hasPrefix("data:image") {
              let base64String = imageUrlString.components(separatedBy: ",").last ?? imageUrlString
              if let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) {
                image = UIImage(data: data)
              }
            }
            // Check for Standard URL
            else if let url = URL(string: imageUrlString), let data = try? Data(contentsOf: url) {
              image = UIImage(data: data)
            }
            // Try decoding raw base64 if other checks fail
            else if let data = Data(
              base64Encoded: imageUrlString, options: .ignoreUnknownCharacters)
            {
              image = UIImage(data: data)
            }

            // 3. Save to Persistence
            if let validImage = image {
              if let filename = ImagePersistence.shared.saveImage(validImage, name: result.id) {
                result.imageUrl = filename
              } else {
                print("Failed to save image to disk")
                result.imageError = Tx.t("error.saveImage")
              }
            } else {
              print("Failed to decode image from string: \(imageUrlString.prefix(100))...")
              result.imageError = Tx.t("error.invalidImageData")
            }
          } catch {
            print("Image generation failed: \(error)")
            result.imageError = error.localizedDescription
          }
        } else if let selectedImg = selectedImage {
          // Visual Muse: Save input image as the design image
          if let filename = ImagePersistence.shared.saveImage(selectedImg, name: result.id) {
            result.imageUrl = filename
          }
        }

        await MainActor.run {
          self.generatedResult = result
          self.showResult = true
          self.isLoading = false
          // Save to History
          HistoryService.shared.saveDesign(result)
        }

      } catch {
        await MainActor.run {
          self.errorMessage = error.localizedDescription
          self.isLoading = false
        }
      }
    }
  }
}

// MARK: - Settings View Model

class SettingsViewModel: ObservableObject {
  @Published var config: ApiConfig
  @Published var selectedProviderID: String = "custom"

  init() {
    // Load initial config from service (which loads from UserDefaults)
    // We access the private config via a new public getter if needed, but for now we reconstruct or load directly
    self.config = AIService.shared.currentConfig

    // Auto-detect provider
    if let match = AIProvider.all.first(where: { $0.endpoint == config.endpoint }) {
      self.selectedProviderID = match.id
    } else {
      self.selectedProviderID = "custom"
    }
  }

  func updateProvider(_ providerId: String) {
    self.selectedProviderID = providerId
    if let provider = AIProvider.all.first(where: { $0.id == providerId }), providerId != "custom" {
      // Auto-fill defaults
      self.config.endpoint = provider.endpoint
      self.config.textModel = provider.models.first ?? ""
      self.config.visionModel = provider.visionModels.first ?? ""
      self.config.imageEndpoint = provider.imageEndpoint.isEmpty ? nil : provider.imageEndpoint
      self.config.imageModel = provider.imageModels.first ?? ""
    }
  }

  func save() {
    AIService.shared.updateConfig(config)
  }
}
