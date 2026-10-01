//
//  SyncOutbox.swift
//  Floreboard
//
//  本地修改 → 云端的可靠推送：失败不再被吞掉，而是持久化排队、指数退避重试，
//  并在回到前台/网络恢复时再次尝试。重试时读取本地最新状态（队列里只存 kind+id）。
//

import Foundation
import Network
import OSLog
import UIKit

@MainActor
final class SyncOutbox {
  static let shared = SyncOutbox()

  private var state = OutboxState()
  private var loadedTenant: String?
  private var flushing = false
  private var timer: Task<Void, Never>?
  private let monitor = NWPathMonitor()
  private var started = false
  private var wasOffline = false

  private init() {}

  // MARK: - Lifecycle

  /// App 启动时调用一次：监听回到前台与网络恢复
  func start() {
    guard !started else { return }
    started = true
    NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { [weak self] _ in
      Task { @MainActor in self?.kick(reason: "foreground") }
    }
    monitor.pathUpdateHandler = { [weak self] path in
      Task { @MainActor in
        guard let self else { return }
        if path.status == .satisfied {
          if self.wasOffline { self.kick(reason: "network") }
          self.wasOffline = false
        } else {
          self.wasOffline = true
        }
      }
    }
    monitor.start(queue: DispatchQueue(label: "floreboard.sync.path"))
  }

  // MARK: - Public API

  func enqueue(_ kind: SyncOp.Kind, id: String) {
    guard loadState() else { return }
    state.enqueue(SyncOp(kind: kind, id: id), now: now())
    save()
    Task { await flush() }
  }

  func hasPending(designs: Bool) -> Bool {
    guard loadState() else { return false }
    return state.hasPending(designs: designs)
  }

  func has(_ kind: SyncOp.Kind, id: String) -> Bool {
    guard loadState() else { return false }
    return state.has(kind, id: id)
  }

  /// 前台/网络恢复：让等待中的（非持续被拒的）条目立刻可重试
  func kick(reason: String) {
    guard loadState() else { return }
    state.releaseWaiting(now: now())
    save()
    Task { await flush() }
  }

  /// 发送所有到期条目；单飞，避免并发重复推送
  func flush() async {
    guard !flushing, loadState() else { return }
    flushing = true
    defer { flushing = false }

    while let entry = state.due(now: now()).first {
      let op = entry.op
      do {
        try await execute(op)
        state.complete(op)
        AppLogger.sync.info("pushed \(op.kind.rawValue, privacy: .public) \(op.id, privacy: .public)")
      } catch let failure as OpFailure {
        state.fail(op, kind: failure.kind, now: now(), message: failure.message)
        AppLogger.sync.error("\(op.kind.rawValue, privacy: .public) \(op.id, privacy: .public) failed (\(failure.message, privacy: .public)); will retry")
      } catch {
        state.fail(op, kind: .failure, now: now(), message: error.localizedDescription)
      }
      save()
    }
    scheduleWake()
  }

  // MARK: - Execution

  private struct OpFailure: Error {
    let kind: SyncFailureKind
    let message: String
  }

  private func execute(_ op: SyncOp) async throws {
    guard let tenantId = AuthService.shared.currentTenant?.id else {
      throw OpFailure(kind: .deferred, message: "not signed in")
    }
    let client: AIProxyClient
    do {
      client = try AIService.shared.makeProxyClient()
    } catch {
      throw OpFailure(kind: .deferred, message: error.localizedDescription)
    }

    do {
      switch op.kind {
      case .designUpsert:
        // 本地已经没有这条（被删除/被清理）：无需再推
        guard let design = HistoryService.shared.savedDesigns.first(where: { $0.id == op.id }) else { return }
        try await client.upsertDesign(tenantId: tenantId, design: design)
      case .designDelete:
        try await client.deleteDesign(tenantId: tenantId, designId: op.id)
      case .flowerUpsert:
        guard let flower = InventoryService.shared.flowers.first(where: { $0.id == op.id }) else { return }
        do {
          _ = try await client.updateFlower(tenantId: tenantId, flower: flower)
        } catch where Self.isNotFound(error) {
          _ = try await client.createFlower(tenantId: tenantId, flower: flower)
        }
      case .flowerDelete:
        try await client.deleteFlower(tenantId: tenantId, flowerId: op.id)
      }
    } catch {
      // 删除一条云端本来就没有的数据，等同于成功
      if (op.kind == .designDelete || op.kind == .flowerDelete) && Self.isNotFound(error) { return }
      throw OpFailure(kind: Self.classify(error), message: Self.describe(error))
    }
  }

  nonisolated static func isNotFound(_ error: Error) -> Bool {
    switch error {
    case AIProxyError.httpStatus(404): return true
    case AIProxyError.rejected(let e): return e.code == "NOT_FOUND"
    default: return false
    }
  }

  nonisolated static func classify(_ error: Error) -> SyncFailureKind {
    if error is URLError { return .network }
    if case AIProxyError.invalidURL = error { return .deferred }
    return .failure
  }

  nonisolated static func describe(_ error: Error) -> String {
    switch error {
    case AIProxyError.httpStatus(let code): return "HTTP \(code)"
    case AIProxyError.rejected(let e): return e.code ?? e.message
    case let e as URLError: return "network \(e.code.rawValue)"
    default: return error.localizedDescription
    }
  }

  // MARK: - Scheduling & persistence

  private func scheduleWake() {
    timer?.cancel()
    guard let wake = state.nextWake(now: now()) else { return }
    let delay = max(1, wake - now())
    timer = Task { [weak self] in
      try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
      guard !Task.isCancelled else { return }
      await self?.flush()
    }
  }

  private func now() -> Double { Date().timeIntervalSince1970 }

  private func key(_ tenant: String) -> String { "syncOutbox.v1.\(tenant)" }

  /// 加载当前租户的队列（切换租户时重新加载）。未登录返回 false。
  private func loadState() -> Bool {
    guard let tenant = AuthService.shared.currentTenant?.id else { return false }
    if loadedTenant != tenant {
      loadedTenant = tenant
      if let data = UserDefaults.standard.data(forKey: key(tenant)),
         let decoded = try? JSONDecoder().decode(OutboxState.self, from: data) {
        state = decoded
      } else {
        state = OutboxState()
      }
    }
    return true
  }

  private func save() {
    guard let tenant = loadedTenant, let data = try? JSONEncoder().encode(state) else { return }
    UserDefaults.standard.set(data, forKey: key(tenant))
  }
}
