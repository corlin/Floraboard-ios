//
//  Services.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import Combine
import Foundation

// MARK: - Auth Service

class AuthService: ObservableObject {
  @Published var isAuthenticated: Bool = false
  @Published var currentTenant: Tenant?

  static let shared = AuthService()

  private init() {
    // Check local storage for existing session
    if let savedName = UserDefaults.standard.string(forKey: "tenant_name") {
      self.currentTenant = Tenant(id: UUID().uuidString, name: savedName)
      self.isAuthenticated = true
    }
  }

  func login(storeName: String) async -> Bool {
    // Simulate network delay
    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s

    DispatchQueue.main.async {
      let tenant = Tenant(id: UUID().uuidString, name: storeName)
      self.currentTenant = tenant
      self.isAuthenticated = true

      // Persist
      UserDefaults.standard.set(storeName, forKey: "tenant_name")
    }
    return true
  }

  func logout() {
    DispatchQueue.main.async {
      self.currentTenant = nil
      self.isAuthenticated = false
      UserDefaults.standard.removeObject(forKey: "tenant_name")
    }
  }
}

// MARK: - Inventory Service

class InventoryService: ObservableObject {
  @Published var flowers: [FlowerType] = []

  static let shared = InventoryService()

  init() {
    loadInventory()
  }

  func loadInventory() {
    // In a real app, this would fetch from Supabase
    // For now, load mocks or from UserDefaults
    if let data = UserDefaults.standard.data(forKey: "inventory"),
      let saved = try? JSONDecoder().decode([FlowerType].self, from: data)
    {
      self.flowers = saved
    } else {
      self.flowers = FlowerType.initialData
    }
  }

  func addFlower(_ flower: FlowerType) {
    flowers.append(flower)
    saveInventory()
  }

  func updateFlower(_ flower: FlowerType) {
    if let index = flowers.firstIndex(where: { $0.id == flower.id }) {
      flowers[index] = flower
      saveInventory()
    }
  }

  func deleteFlower(_ id: String) {
    flowers.removeAll { $0.id == id }
    saveInventory()
  }

  private func saveInventory() {
    if let data = try? JSONEncoder().encode(flowers) {
      UserDefaults.standard.set(data, forKey: "inventory")
    }
  }

  // Helper to get formatted string for AI prompt
  func getInventoryListString(lowStockThreshold: Int = 10) -> String {
    return flowers.map { flower in
      let isLowStock = flower.quantity <= lowStockThreshold
      let stockMarker = isLowStock ? " (LOW STOCK!)" : ""
      return
        "- \(flower.name) (Color: \(flower.color), Qty: \(flower.quantity)\(stockMarker), Cost: ¥\(flower.unitCost)/stem, Category: \(flower.category.rawValue))"
    }.joined(separator: "\n")
  }

  func deductInventory(for items: [DesignFlowerItem]) -> [FlowerType] {
    var changedFlowers: [FlowerType] = []

    // Create a mutable copy of flowers to work on safely
    var currentFlowers = self.flowers

    for item in items {
      // Fuzzy match: exact name first, then contains
      if let index = currentFlowers.firstIndex(where: {
        $0.name.localizedCaseInsensitiveCompare(item.flowerName) == .orderedSame
          || $0.name.localizedCaseInsensitiveContains(item.flowerName)
          || item.flowerName.localizedCaseInsensitiveContains($0.name)
      }) {
        var flower = currentFlowers[index]
        let deductAmount = item.count

        flower.quantity = max(0, flower.quantity - deductAmount)
        flower.totalUsed = (flower.totalUsed ?? 0) + deductAmount
        flower.updatedAt = Date().timeIntervalSince1970

        currentFlowers[index] = flower
        changedFlowers.append(flower)
      }
    }

    // Commit changes
    if !changedFlowers.isEmpty {
      self.flowers = currentFlowers
      saveInventory()
    }
    return changedFlowers
  }
}

// MARK: - History Service

class HistoryService: ObservableObject {
  @Published var savedDesigns: [DesignResult] = []

  static let shared = HistoryService()

  private init() {
    loadDesigns()
  }

  func saveDesign(_ design: DesignResult) {
    // Check if exists, update if so, else append
    if let index = savedDesigns.firstIndex(where: { $0.id == design.id }) {
      savedDesigns[index] = design
    } else {
      savedDesigns.insert(design, at: 0)  // Newest first
    }
    persist()
  }

  func executeDesign(_ design: DesignResult) {
    guard design.status != .completed else { return }

    // 1. Deduct Inventory
    let _ = InventoryService.shared.deductInventory(for: design.flowerList)

    // 2. Update Design Status
    var updatedDesign = design
    updatedDesign.status = .completed
    updatedDesign.executedAt = Date().timeIntervalSince1970

    saveDesign(updatedDesign)
  }

  func deleteDesign(id: String) {
    savedDesigns.removeAll { $0.id == id }
    persist()
  }

  private func loadDesigns() {
    if let data = UserDefaults.standard.data(forKey: "saved_designs"),
      let decoded = try? JSONDecoder().decode([DesignResult].self, from: data)
    {
      self.savedDesigns = decoded
    }
  }

  private func persist() {
    if let data = try? JSONEncoder().encode(savedDesigns) {
      UserDefaults.standard.set(data, forKey: "saved_designs")
    }
  }
}
