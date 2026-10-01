//
//  SyncOutboxState.swift
//  Floreboard
//
//  同步发件箱的纯逻辑（无 IO、无时钟依赖，便于独立测试）。
//  只记录“哪条数据需要推到云端”(kind,id)，重试时读取本地最新状态，因此多次修改自然合并为一次推送。
//

import Foundation

struct SyncOp: Codable, Hashable {
  enum Kind: String, Codable {
    case designUpsert, designDelete, flowerUpsert, flowerDelete

    /// 同一条数据上互相抵消的操作（后发生的覆盖先发生的）
    var counterpart: Kind {
      switch self {
      case .designUpsert: return .designDelete
      case .designDelete: return .designUpsert
      case .flowerUpsert: return .flowerDelete
      case .flowerDelete: return .flowerUpsert
      }
    }

    var isDesign: Bool { self == .designUpsert || self == .designDelete }
  }

  let kind: Kind
  let id: String
}

enum SyncFailureKind {
  /// 没网/超时：不是这条数据的问题，不累计失败次数，网络恢复或回到前台时再试
  case network
  /// 暂时无法发起（未登录/缺少配置）：不累计，等下一次触发
  case deferred
  /// 服务端拒绝或 5xx：累计失败次数，指数退避
  case failure
}

struct OutboxEntry: Codable, Equatable {
  var op: SyncOp
  var failures: Int = 0
  var nextAttemptAt: Double = 0
  var lastError: String? = nil
}

struct OutboxState: Codable, Equatable {
  var entries: [OutboxEntry] = []

  static let baseDelay: Double = 5
  static let maxDelay: Double = 300
  static let networkDelay: Double = 15
  static let deferredDelay: Double = 60

  /// 5s, 10s, 20s ... 封顶 5 分钟
  static func backoff(failures: Int) -> Double {
    let n = max(0, failures - 1)
    return min(baseDelay * pow(2, Double(min(n, 10))), maxDelay)
  }

  /// 入队：与同一数据上相反的操作互相抵消；重复入队合并并立刻可重试（有了新的本地修改）
  mutating func enqueue(_ op: SyncOp, now: Double) {
    entries.removeAll { $0.op.id == op.id && $0.op.kind == op.kind.counterpart }
    if let i = entries.firstIndex(where: { $0.op == op }) {
      entries[i].failures = 0
      entries[i].nextAttemptAt = now
      entries[i].lastError = nil
    } else {
      entries.append(OutboxEntry(op: op, failures: 0, nextAttemptAt: now))
    }
  }

  func due(now: Double) -> [OutboxEntry] {
    entries.filter { $0.nextAttemptAt <= now }
  }

  mutating func complete(_ op: SyncOp) {
    entries.removeAll { $0.op == op }
  }

  mutating func fail(_ op: SyncOp, kind: SyncFailureKind, now: Double, message: String?) {
    guard let i = entries.firstIndex(where: { $0.op == op }) else { return }
    entries[i].lastError = message
    switch kind {
    case .network:
      entries[i].nextAttemptAt = now + Self.networkDelay
    case .deferred:
      entries[i].nextAttemptAt = now + Self.deferredDelay
    case .failure:
      entries[i].failures += 1
      entries[i].nextAttemptAt = now + Self.backoff(failures: entries[i].failures)
    }
  }

  /// 立刻允许重试（回到前台/网络恢复时）。不清零失败次数，避免对持续被拒的数据疯狂重试。
  mutating func releaseWaiting(now: Double) {
    for i in entries.indices where entries[i].failures == 0 { entries[i].nextAttemptAt = min(entries[i].nextAttemptAt, now) }
  }

  func has(_ kind: SyncOp.Kind, id: String) -> Bool {
    entries.contains { $0.op.kind == kind && $0.op.id == id }
  }

  func hasPending(designs: Bool) -> Bool {
    entries.contains { $0.op.kind.isDesign == designs }
  }

  func nextWake(now: Double) -> Double? {
    entries.map(\.nextAttemptAt).min().map { max($0, now) }
  }
}
