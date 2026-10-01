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

    // 先把上次没推成功的修改发出去，再拉取云端
    await SyncOutbox.shared.flush()

    do {
      let client = try AIService.shared.makeProxyClient()
      let cloudDesigns = try await client.fetchDesigns(tenantId: tenantId)

      var toPush: [DesignResult] = []

      for cloud in cloudDesigns {
        let designID = cloud.id
        // 本机有尚未推送成功的删除：不要把云端旧副本拉回来（会让已删除的方案复活）
        if SyncOutbox.shared.has(.designDelete, id: designID) { continue }
        // 本机有尚未推送成功的修改：本地更新，保留并稍后推送，不让旧的云端数据覆盖
        if SyncOutbox.shared.has(.designUpsert, id: designID) { continue }
        var descriptor = FetchDescriptor<DesignRecord>(
          predicate: #Predicate { $0.id == designID }
        )
        descriptor.fetchLimit = 1

        if let existing = try? context.fetch(descriptor).first {
          // 云端可能是一份旧副本（以前 iOS 的修改从未同步上去）。已执行/图片/评分这类“只会向前推进”的字段
          // 以更靠前的一方为准，并把合并结果推回云端，而不是让旧的云端数据覆盖本地进度。
          let merged = DesignMerge.merge(local: existing.toDesignResult(), cloud: cloud)
          existing.update(from: merged)
          existing.tenantId = tenantId
          if DesignMerge.needsPush(merged: merged, cloud: cloud) { toPush.append(merged) }
        } else {
          let record = DesignRecord(from: cloud)
          record.tenantId = tenantId
          context.insert(record)
        }
      }

      // 注意：不会把“云端没有而本机有”的方案推回云端——它们可能是在别的设备上被删除的，推回去会让已删除的方案复活。

      try? context.save()
      loadDesigns()

      for design in toPush {
        SyncOutbox.shared.enqueue(.designUpsert, id: design.id)
      }
    } catch {
      print("[HistoryService] Cloud sync skipped or failed: \(error.localizedDescription)")
    }

    // 补传仍指向本地文件名的图片（历史遗留），换成可跨设备访问的 URL
    await ImageSyncService.shared.healLocalImages(history: self)
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

    // Replicate to cloud（失败会进入发件箱自动重试）
    SyncOutbox.shared.enqueue(.designUpsert, id: design.id)
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

    SyncOutbox.shared.enqueue(.designDelete, id: id)
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
