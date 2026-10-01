//
//  DesignPricing.swift
//  Floreboard
//
//  方案利润口径（与网页端 financials.ts 一致）。纯函数，便于独立测试。
//    成交价 = 客户预算（>0 时）；否则取零售价合计
//    利润   = 成交价 − 成本（可为负，不截断）
//    利润率 = 利润 ÷ 成交价
//

import Foundation

enum DesignPricing {
  static func price(budget: Double?, retail: Double) -> Double {
    if let budget, budget > 0 { return budget }
    return retail
  }

  static func margin(price: Double, profit: Double) -> Double {
    price > 0 ? profit / price : 0
  }
}
