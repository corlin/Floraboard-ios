//
//  HistoryService.swift
//  Floreboard
//
//  Migrated from UserDefaults to SwiftData.
//

import Combine
import Foundation
import SwiftData

@MainActor
class HistoryService: ObservableObject {
  @Published var savedDesigns: [DesignResult] = []

  static let shared = HistoryService()

  var modelContext: ModelContext?

  private init() {
    // Do not load here; wait for configure(with:)
  }

  func configure(with context: ModelContext) {
    self.modelContext = context
    loadDesigns()
  }

  func saveDesign(_ design: DesignResult) {
    guard modelContext != nil else { return }

    // Check if exists, update if so, else insert at front
    if let index = savedDesigns.firstIndex(where: { $0.id == design.id }) {
      savedDesigns[index] = design
    } else {
      savedDesigns.insert(design, at: 0)  // Newest first
    }
    persist(design)
  }

  func executeDesign(_ design: DesignResult, mappedItems: [InventoryService.DeductionItem]? = nil) {
    guard design.status != .completed else { return }

    // 1. Deduct Inventory Exact if provided, otherwise fallback
    if let mapped = mappedItems {
      InventoryService.shared.deductInventoryExact(items: mapped)
    } else {
      let _ = InventoryService.shared.deductInventory(for: design.flowerList)
    }

    // 2. Update Design Status
    var updatedDesign = design
    updatedDesign.status = .completed
    updatedDesign.executedAt = Date().timeIntervalSince1970

    saveDesign(updatedDesign)
  }

  func deleteDesign(id: String) {
    guard let context = modelContext else { return }

    savedDesigns.removeAll { $0.id == id }

    let designID = id
    var descriptor = FetchDescriptor<DesignRecord>(
      predicate: #Predicate { $0.id == designID }
    )
    descriptor.fetchLimit = 1

    if let existing = try? context.fetch(descriptor).first {
      context.delete(existing)
      try? context.save()
    }
  }

  private func loadDesigns() {
    guard let context = modelContext else { return }

    let descriptor = FetchDescriptor<DesignRecord>(
      sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
    )
    do {
      let records = try context.fetch(descriptor)
      self.savedDesigns = records.map { $0.toDesignResult() }
    } catch {
      print("Failed to load designs: \(error)")
      self.savedDesigns = []
    }
  }

  /// Persist a single design (upsert).
  private func persist(_ design: DesignResult) {
    guard let context = modelContext else { return }

    let designID = design.id
    var descriptor = FetchDescriptor<DesignRecord>(
      predicate: #Predicate { $0.id == designID }
    )
    descriptor.fetchLimit = 1

    if let existing = try? context.fetch(descriptor).first {
      existing.update(from: design)
    } else {
      context.insert(DesignRecord(from: design))
    }
    try? context.save()
  }
}
