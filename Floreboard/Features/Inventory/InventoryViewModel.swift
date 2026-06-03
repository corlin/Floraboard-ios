import Combine
import Foundation
import OSLog
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
