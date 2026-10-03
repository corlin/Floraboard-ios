import Combine
import Foundation
import OSLog
import SwiftUI

// MARK: - Inventory View Model

class InventoryViewModel: ObservableObject {
  @Published var flowers: [FlowerType] = []
  @Published var searchText: String = ""
  @Published var selectedCategory: FlowerCategory?

  private var inventoryService: InventoryService?
  private var cancellables = Set<AnyCancellable>()

  init() {}

  func setup(with service: InventoryService) {
    guard self.inventoryService == nil else { return }
    self.inventoryService = service
    // Bind to service
    service.$flowers
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

  /// 新增花材：初始库存即当前数量
  func addFlower(_ draft: FlowerType) {
    var flower = draft
    flower.initialStock = draft.quantity
    inventoryService?.addFlower(flower)
  }

  func updateFlower(_ flower: FlowerType) {
    inventoryService?.updateFlower(flower)
  }

  func delete(at offsets: IndexSet) {
    offsets.forEach { index in
      let flower = filteredFlowers[index]
      inventoryService?.deleteFlower(flower.id)
    }
  }

  func delete(_ flower: FlowerType) {
    inventoryService?.deleteFlower(flower.id)
  }
}
