//
//  OrderService.swift
//  Floreboard
//
//  Manages customer orders, status transitions, and automatic stock deduction.
//

import Combine
import Foundation
import SwiftData

@MainActor
class OrderService: ObservableObject {
  @Published var orders: [OrderRecord] = []

  static let shared = OrderService()

  var modelContext: ModelContext?

  private init() {}

  func configure(with context: ModelContext) {
    self.modelContext = context
    loadOrders()
  }

  func loadOrders() {
    guard let context = modelContext, let tenantId = AuthService.shared.currentTenant?.id else {
      self.orders = []
      return
    }

    let descriptor = FetchDescriptor<OrderRecord>(
      predicate: #Predicate { $0.tenantId == tenantId },
      sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
    )
    do {
      self.orders = try context.fetch(descriptor)
    } catch {
      print("Failed to fetch orders: \(error)")
      self.orders = []
    }
  }

  @discardableResult
  func createOrder(
    customerName: String,
    customerPhone: String = "",
    status: OrderStatus = .draft,
    designId: String? = nil,
    totalAmount: Double,
    items: [OrderItem],
    notes: String? = nil
  ) -> OrderRecord? {
    guard let context = modelContext, let tenantId = AuthService.shared.currentTenant?.id else { return nil }

    let record = OrderRecord(
      tenantId: tenantId,
      customerName: customerName,
      customerPhone: customerPhone,
      status: status,
      designId: designId,
      totalAmount: totalAmount,
      items: items,
      notes: notes
    )
    context.insert(record)

    do {
      try context.save()
      loadOrders()

      // If created directly in confirmed state, lock stock
      if status == .confirmed {
        lockStock(for: record)
      }

      return record
    } catch {
      print("Failed to save order: \(error)")
      return nil
    }
  }

  func updateOrderStatus(_ order: OrderRecord, newStatus: OrderStatus) {
    let oldStatus = order.status
    order.status = newStatus
    order.updatedAt = Date().timeIntervalSince1970

    do {
      try modelContext?.save()
      loadOrders()

      // Auto deduct/lock stock if transition to confirmed
      if oldStatus != .confirmed && newStatus == .confirmed {
        lockStock(for: order)
      }
    } catch {
      print("Failed to update order status: \(error)")
    }
  }

  private func lockStock(for order: OrderRecord) {
    for item in order.items {
      if let flowerId = item.flowerId {
        InventoryService.shared.deductStock(flowerId: flowerId, amount: item.count)
      }
    }
  }

  func deleteOrder(_ order: OrderRecord) {
    guard let context = modelContext else { return }
    context.delete(order)
    try? context.save()
    loadOrders()
  }
}
