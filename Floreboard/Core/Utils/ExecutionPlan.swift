//
//  ExecutionPlan.swift
//  Floreboard
//
//  “执行方案”时的库存扣减预期，与服务端 POST /designs/:id/execute 的匹配规则一致
//  （按名称忽略空白与大小写匹配库存；每行数量取整，单项上限 1,000,000）。
//  只有当用户确认的扣减与服务端会做的完全一致时，才走服务端原子执行；否则（用户手动改了映射）走本地路径。
//  纯函数，便于独立测试。
//

import Foundation

enum ExecutionPlan {
  static func norm(_ name: String) -> String {
    name.components(separatedBy: .whitespacesAndNewlines).joined().lowercased()
  }

  /// 服务端会扣减的库存：[库存 id: 数量]
  static func expectedDeductions(
    rows: [(name: String, count: Int)], inventory: [(id: String, name: String)]
  ) -> [String: Int] {
    var byName: [String: String] = [:]
    for f in inventory where byName[norm(f.name)] == nil { byName[norm(f.name)] = f.id }
    var out: [String: Int] = [:]
    for r in rows where r.count > 0 {
      guard let id = byName[norm(r.name)] else { continue }
      out[id] = min(1_000_000, (out[id] ?? 0) + r.count)
    }
    return out
  }

  /// 用户确认的扣减是否与服务端预期一致（未指定映射视为一致：本地路径同样按名称匹配）
  static func matchesServer(mapped: [(id: String, amount: Int)]?, expected: [String: Int]) -> Bool {
    guard let mapped else { return true }
    var got: [String: Int] = [:]
    for m in mapped where m.amount > 0 { got[m.id, default: 0] += m.amount }
    return got == expected
  }
}
