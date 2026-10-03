//
//  PurchaseOrderGenerator.swift
//  Floreboard
//
//  Generates formatted restocking summaries for suppliers.
//

import Foundation

struct PurchaseOrderGenerator {
  static func generateRestockingSummary(flowers: [FlowerType]) -> String {
    let lowStockItems = flowers.filter { $0.quantity <= 10 }

    if lowStockItems.isEmpty {
      return Tx.t("purchase.no_low_stock")
    }

    let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
    var summary = "📦 \(Tx.t("purchase.title")) (\(today))\n"
    summary += "-----------------------------------\n"

    var totalCost: Double = 0.0

    for flower in lowStockItems {
      let deficit = max(20, flower.initialStock - flower.quantity)
      let cost = Double(deficit) * flower.unitCost
      totalCost += cost
      let costText = "\(Tx.t("purchase.cost")) ¥\(String(format: "%.2f", cost))"
      let stockText = "\(Tx.t("inventory.stock")) \(flower.quantity)"
      summary += "• \(flower.name): \(stockText) -> \(Tx.t("purchase.need")) +\(deficit) (\(costText))\n"
    }

    summary += "-----------------------------------\n"
    summary += "💰 \(Tx.t("purchase.estimated_total")): ¥\(String(format: "%.2f", totalCost))\n"
    summary += "📌 \(Tx.t("purchase.notes")): \(Tx.t("purchase.supplier_note"))"

    return summary
  }
}
