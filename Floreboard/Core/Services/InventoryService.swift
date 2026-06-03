//
//  InventoryService.swift
//  Floreboard
//
//  Migrated from UserDefaults to SwiftData.
//

import Combine
import Foundation
import SwiftData

@MainActor
class InventoryService: ObservableObject {
  @Published var flowers: [FlowerType] = []

  static let shared = InventoryService()

  struct StockShortage: Identifiable, Hashable {
    let flowerName: String
    let requested: Int
    let available: Int

    var id: String { flowerName }
  }

  var modelContext: ModelContext?

  private init() {
    // Do not load here; wait for configure(with:)
  }

  func configure(with context: ModelContext) {
    self.modelContext = context
    loadInventory()
  }

  func loadInventory() {
    guard let context = modelContext else { return }

    let descriptor = FetchDescriptor<FlowerRecord>()
    do {
      let records = try context.fetch(descriptor)
      if records.isEmpty {
        // Seed with initial data
        let initialFlowers = FlowerType.initialData
        for flower in initialFlowers {
          context.insert(FlowerRecord(from: flower))
        }
        try context.save()
        self.flowers = initialFlowers
      } else {
        self.flowers = records.map { $0.toFlowerType() }
      }
    } catch {
      print("Failed to load inventory: \(error)")
      self.flowers = FlowerType.initialData
    }
  }

  func addFlower(_ flower: FlowerType) {
    guard let context = modelContext else { return }

    flowers.append(flower)
    context.insert(FlowerRecord(from: flower))
    try? context.save()
  }

  func updateFlower(_ flower: FlowerType) {
    guard let context = modelContext else { return }

    if let index = flowers.firstIndex(where: { $0.id == flower.id }) {
      flowers[index] = flower

      // Update existing record or insert new one
      let flowerID = flower.id
      var descriptor = FetchDescriptor<FlowerRecord>(
        predicate: #Predicate { $0.id == flowerID }
      )
      descriptor.fetchLimit = 1

      if let existing = try? context.fetch(descriptor).first {
        existing.update(from: flower)
      } else {
        context.insert(FlowerRecord(from: flower))
      }
      try? context.save()
    }
  }

  func deleteFlower(_ id: String) {
    guard let context = modelContext else { return }

    flowers.removeAll { $0.id == id }

    let flowerID = id
    var descriptor = FetchDescriptor<FlowerRecord>(
      predicate: #Predicate { $0.id == flowerID }
    )
    descriptor.fetchLimit = 1

    if let existing = try? context.fetch(descriptor).first {
      context.delete(existing)
      try? context.save()
    }
  }

  private func saveInventory() {
    guard let context = modelContext else { return }

    // Sync all in-memory flowers to persistent records
    let descriptor = FetchDescriptor<FlowerRecord>()
    let existingRecords = (try? context.fetch(descriptor)) ?? []
    let existingMap = Dictionary(uniqueKeysWithValues: existingRecords.map { ($0.id, $0) })

    var processedIDs = Set<String>()
    for flower in flowers {
      if let record = existingMap[flower.id] {
        record.update(from: flower)
      } else {
        context.insert(FlowerRecord(from: flower))
      }
      processedIDs.insert(flower.id)
    }

    // Remove records that are no longer in the flowers array
    for record in existingRecords where !processedIDs.contains(record.id) {
      context.delete(record)
    }

    try? context.save()
  }

  // Helper to get formatted string for AI prompt
  func getInventoryListString(lowStockThreshold: Int = 10) -> String {
    return flowers.map { flower in
      let isLowStock = flower.quantity <= lowStockThreshold
      let stockMarker = isLowStock ? " (LOW STOCK!)" : ""
      return
        "- \(flower.name) (Color: \(flower.color), Qty: \(flower.quantity)\(stockMarker), Cost: \(CurrencyFormat.compact(flower.unitCost))/stem, Category: \(flower.category.rawValue))"
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

  func stockShortages(for items: [DesignFlowerItem]) -> [StockShortage] {
    items.compactMap { item in
      guard let flower = findFlower(named: item.flowerName, in: flowers),
        item.count > flower.quantity
      else {
        return nil
      }

      return StockShortage(
        flowerName: item.flowerName,
        requested: item.count,
        available: flower.quantity
      )
    }
  }

  private func findFlower(named name: String, in flowerList: [FlowerType]) -> FlowerType? {
    flowerList.first {
      $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        || $0.name.localizedCaseInsensitiveContains(name)
        || name.localizedCaseInsensitiveContains($0.name)
    }
  }
}
