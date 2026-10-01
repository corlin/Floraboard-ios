//
//  ProductionChecks.swift
//  Floreboard
//
//  制作稿的确定性分析：只用库存与方案数据计算，不依赖 AI。口径与网页端 production-checks.ts 一致。
//  纯 Swift（不依赖 UIKit/SwiftUI），便于单独测试。
//

import Foundation

enum StemRole: String { case main, filler, foliage }

enum ProductionCheckLevel { case ok, warn, error }

struct ProductionCheck: Equatable {
  let id: String
  let level: ProductionCheckLevel
  /// 供文案插值（{{name}} 等）
  let params: [String: String]
}

/// 分析输入：一行花材（已按库存解析好角色、价格、库存）
struct ProductionItem {
  var name: String
  var count: Int
  var role: StemRole
  var unitCost: Double
  var retailPrice: Double
  /// 库存数量；不在库存中为 nil
  var stock: Int?
  var colorHex: String?
}

struct ProductionRow: Identifiable {
  var id: String { item.name }
  let item: ProductionItem
  let costSubtotal: Double
  let retailSubtotal: Double
  /// 库存缺口（>0 表示不足）；已执行方案不再检查
  let shortBy: Int
  let inInventory: Bool
}

struct ProductionAnalysis {
  let rows: [ProductionRow]
  let stems: Int
  let cost: Double
  let retail: Double
  let price: Double
  let profit: Double
  let margin: Double
  let checks: [ProductionCheck]
}

enum ProductionChecks {
  /// - Parameters:
  ///   - price: 成交价（本应用中为 totalCost + profit）；<= 0 时不做预算/利润检查
  ///   - executed: 方案已执行时库存已扣过，不再检查缺口
  static func analyze(items: [ProductionItem], price: Double, executed: Bool) -> ProductionAnalysis {
    let rows: [ProductionRow] = items.filter { $0.count > 0 }.map { item in
      let inInv = item.stock != nil
      let short = (!executed && inInv) ? max(0, item.count - (item.stock ?? 0)) : 0
      return ProductionRow(
        item: item,
        costSubtotal: item.unitCost * Double(item.count),
        retailSubtotal: item.retailPrice * Double(item.count),
        shortBy: short,
        inInventory: inInv)
    }

    let stems = rows.reduce(0) { $0 + $1.item.count }
    let cost = rows.reduce(0.0) { $0 + $1.costSubtotal }
    let retail = rows.reduce(0.0) { $0 + $1.retailSubtotal }
    let profit = price - cost
    let margin = price > 0 ? profit / price : 0

    func stemsOf(_ role: StemRole) -> Int { rows.filter { $0.item.role == role }.reduce(0) { $0 + $1.item.count } }
    let main = stemsOf(.main), filler = stemsOf(.filler), foliage = stemsOf(.foliage)

    var checks: [ProductionCheck] = []

    for r in rows where r.shortBy > 0 {
      checks.append(.init(id: "stockShort", level: .error, params: [
        "name": r.item.name, "need": String(r.item.count), "have": String(r.item.stock ?? 0), "short": String(r.shortBy),
      ]))
    }
    for r in rows where !r.inInventory {
      checks.append(.init(id: "notInInventory", level: .warn, params: ["name": r.item.name]))
    }

    if price > 0 {
      if cost > price {
        checks.append(.init(id: "budgetOver", level: .error, params: ["cost": String(Int(cost.rounded())), "budget": String(Int(price.rounded()))]))
      } else if cost < price * 0.3 {
        checks.append(.init(id: "budgetUnder", level: .warn, params: ["cost": String(Int(cost.rounded())), "budget": String(Int(price.rounded()))]))
      }
      if cost <= price && margin < 0.35 {
        checks.append(.init(id: "lowMargin", level: .warn, params: ["margin": String(Int((margin * 100).rounded()))]))
      }
    }

    if stems > 0 && main == 0 {
      checks.append(.init(id: "noMainFlower", level: .warn, params: [:]))
    }
    if stems >= 8 && Double(foliage + filler) / Double(stems) > 0.75 {
      checks.append(.init(id: "foliageHeavy", level: .warn, params: ["pct": String(Int((Double(foliage + filler) / Double(stems) * 100).rounded()))]))
    }

    return ProductionAnalysis(rows: rows, stems: stems, cost: cost, retail: retail, price: price, profit: profit, margin: margin, checks: checks)
  }
}
