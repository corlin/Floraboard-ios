//
//  InventoryService.swift
//  Floreboard
//
//  Cloud-First with local SwiftData cache inventory service.
//

import Combine
import Foundation
import OSLog
import SwiftData

@MainActor
class InventoryService: ObservableObject {
  @Published var flowers: [FlowerType] = []
  @Published var isSyncing: Bool = false

  static let shared = InventoryService()

  struct StockShortage: Identifiable, Hashable {
    let flowerName: String
    let requested: Int
    let available: Int

    var id: String { flowerName }
  }

  struct DeductionItem: Identifiable, Hashable {
    let flowerId: String
    let amount: Int

    var id: String { flowerId }
  }

  var modelContext: ModelContext?

  private init() {}

  func configure(with context: ModelContext) {
    self.modelContext = context
    loadInventory()
    Task {
      await syncWithCloud()
    }
  }

  func loadInventory() {
    guard let context = modelContext, let tenantId = AuthService.shared.currentTenant?.id else {
      self.flowers = []
      return
    }

    let descriptor = FetchDescriptor<FlowerRecord>(
      predicate: #Predicate { $0.tenantId == tenantId }
    )
    do {
      let records = try context.fetch(descriptor)
      if records.isEmpty {
        let initialFlowers = FlowerType.initialData
        for flower in initialFlowers {
          let record = FlowerRecord(from: flower)
          record.tenantId = tenantId
          context.insert(record)
        }
        try? context.save()
        self.flowers = initialFlowers
      } else {
        self.flowers = records.map { $0.toFlowerType() }
      }
    } catch {
      print("Failed to load inventory from SwiftData: \(error)")
      self.flowers = FlowerType.initialData
    }
  }

  func syncWithCloud() async {
    guard let tenantId = AuthService.shared.currentTenant?.id,
          let context = modelContext else { return }

    isSyncing = true
    defer { isSyncing = false }

    // 先把上次没推成功的库存修改发出去；仍有未推送的修改时不用云端覆盖本地缓存
    await SyncOutbox.shared.flush()

    do {
      let client = try AIService.shared.makeProxyClient()
      let cloudFlowers = try await client.fetchInventory(tenantId: tenantId)

      if SyncOutbox.shared.hasPending(designs: false) {
        AppLogger.sync.info("inventory has unsent local changes; keeping local copy this round")
      } else if !cloudFlowers.isEmpty {
        // Cloud has records: replace local cache with cloud records
        let descriptor = FetchDescriptor<FlowerRecord>(
          predicate: #Predicate { $0.tenantId == tenantId }
        )
        let oldRecords = (try? context.fetch(descriptor)) ?? []
        for r in oldRecords {
          context.delete(r)
        }

        for f in cloudFlowers {
          let rec = FlowerRecord(from: f)
          rec.tenantId = tenantId
          context.insert(rec)
        }
        try? context.save()
        self.flowers = cloudFlowers
      } else if AuthService.shared.isNewlyRegistered {
        // New store registered: initialize cloud inventory with default flowers
        let initial = FlowerType.initialData
        for f in initial {
          _ = try? await client.createFlower(tenantId: tenantId, flower: f)
        }
        AuthService.shared.isNewlyRegistered = false
      }
    } catch {
      print("[InventoryService] Cloud sync skipped or failed: \(error.localizedDescription)")
    }
  }

  func addFlower(_ flower: FlowerType) {
    guard let context = modelContext, let tenantId = AuthService.shared.currentTenant?.id else { return }

    flowers.append(flower)
    let record = FlowerRecord(from: flower)
    record.tenantId = tenantId
    context.insert(record)
    try? context.save()

    SyncOutbox.shared.enqueue(.flowerUpsert, id: flower.id)
  }

  func updateFlower(_ flower: FlowerType) {
    guard let context = modelContext, let tenantId = AuthService.shared.currentTenant?.id else { return }

    if let index = flowers.firstIndex(where: { $0.id == flower.id }) {
      flowers[index] = flower

      let flowerID = flower.id
      var descriptor = FetchDescriptor<FlowerRecord>(
        predicate: #Predicate { $0.id == flowerID }
      )
      descriptor.fetchLimit = 1

      if let existing = try? context.fetch(descriptor).first {
        existing.update(from: flower)
        existing.tenantId = tenantId
      } else {
        let record = FlowerRecord(from: flower)
        record.tenantId = tenantId
        context.insert(record)
      }
      try? context.save()

      SyncOutbox.shared.enqueue(.flowerUpsert, id: flower.id)
    }
  }

  func deleteFlower(_ id: String) {
    guard let context = modelContext, let tenantId = AuthService.shared.currentTenant?.id else { return }

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

    SyncOutbox.shared.enqueue(.flowerDelete, id: id)
  }

  func deductStock(flowerId: String, amount: Int) {
    adjustStock(flowerId: flowerId, delta: -amount)
  }

  func adjustStock(flowerId: String, delta: Int) {
    if let index = flowers.firstIndex(where: { $0.id == flowerId }) {
      var updated = flowers[index]
      updated.quantity = max(0, updated.quantity + delta)
      if delta < 0 {
        updated.totalUsed = (updated.totalUsed ?? 0) + abs(delta)
      }
      updateFlower(updated)
    }
  }

  func deductInventory(for flowerItems: [DesignFlowerItem]) -> [StockShortage] {
    var shortages: [StockShortage] = []

    for item in flowerItems {
      if let index = flowers.firstIndex(where: {
        $0.name.localizedCaseInsensitiveCompare(item.flowerName) == .orderedSame
      }) {
        let available = flowers[index].quantity
        if available < item.count {
          shortages.append(
            StockShortage(
              flowerName: item.flowerName,
              requested: item.count,
              available: available
            )
          )
          var updated = flowers[index]
          updated.quantity = 0
          updated.totalUsed = (updated.totalUsed ?? 0) + available
          updateFlower(updated)
        } else {
          var updated = flowers[index]
          updated.quantity -= item.count
          updated.totalUsed = (updated.totalUsed ?? 0) + item.count
          updateFlower(updated)
        }
      } else {
        shortages.append(
          StockShortage(
            flowerName: item.flowerName,
            requested: item.count,
            available: 0
          )
        )
      }
    }

    return shortages
  }

  func deductInventoryExact(items: [DeductionItem]) {
    for item in items {
      adjustStock(flowerId: item.flowerId, delta: -item.amount)
    }
  }
}
