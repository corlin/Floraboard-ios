//
//  HistoryService.swift
//  Floreboard
//
//  Cloud-First with local SwiftData cache history design service.
//

import Combine
import Foundation
import SwiftData

@MainActor
class HistoryService: ObservableObject {
  @Published var savedDesigns: [DesignResult] = []
  @Published var isSyncing: Bool = false

  static let shared = HistoryService()

  var modelContext: ModelContext?

  private init() {}

  func configure(with context: ModelContext) {
    self.modelContext = context
    loadDesigns()
    Task {
      await syncWithCloud()
    }
  }

  func syncWithCloud() async {
    guard let tenantId = AuthService.shared.currentTenant?.id,
          let context = modelContext else { return }

    isSyncing = true
    defer { isSyncing = false }

    do {
      let client = try AIService.shared.makeProxyClient()
      let cloudDesigns = try await client.fetchDesigns(tenantId: tenantId)

      if !cloudDesigns.isEmpty {
        // Upsert into local SwiftData
        for design in cloudDesigns {
          let designID = design.id
          var descriptor = FetchDescriptor<DesignRecord>(
            predicate: #Predicate { $0.id == designID }
          )
          descriptor.fetchLimit = 1

          if let existing = try? context.fetch(descriptor).first {
            existing.update(from: design)
            existing.tenantId = tenantId
          } else {
            let record = DesignRecord(from: design)
            record.tenantId = tenantId
            context.insert(record)
          }
        }
        try? context.save()
        loadDesigns()
      }
    } catch {
      print("[HistoryService] Cloud sync skipped or failed: \(error.localizedDescription)")
    }
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

    // Replicate to cloud
    if let tenantId = AuthService.shared.currentTenant?.id {
      Task {
        if let client = try? AIService.shared.makeProxyClient() {
          try? await client.saveDesign(tenantId: tenantId, design: design)
        }
      }
    }
  }

  func executeDesign(_ design: DesignResult, mappedItems: [InventoryService.DeductionItem]? = nil) {
    guard design.status != .completed else { return }

    if let mapped = mappedItems {
      InventoryService.shared.deductInventoryExact(items: mapped)
    } else {
      let _ = InventoryService.shared.deductInventory(for: design.flowerList)
    }

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

    if let tenantId = AuthService.shared.currentTenant?.id {
      Task {
        if let client = try? AIService.shared.makeProxyClient() {
          try? await client.deleteDesign(tenantId: tenantId, designId: id)
        }
      }
    }
  }

  func loadDesigns() {
    guard let context = modelContext, let tenantId = AuthService.shared.currentTenant?.id else {
      self.savedDesigns = []
      return
    }

    let descriptor = FetchDescriptor<DesignRecord>(
      predicate: #Predicate { $0.tenantId == tenantId },
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

  private func persist(_ design: DesignResult) {
    guard let context = modelContext, let tenantId = AuthService.shared.currentTenant?.id else { return }

    let designID = design.id
    var descriptor = FetchDescriptor<DesignRecord>(
      predicate: #Predicate { $0.id == designID }
    )
    descriptor.fetchLimit = 1

    if let existing = try? context.fetch(descriptor).first {
      existing.update(from: design)
      existing.tenantId = tenantId
    } else {
      let record = DesignRecord(from: design)
      record.tenantId = tenantId
      context.insert(record)
    }

    try? context.save()
  }
}
