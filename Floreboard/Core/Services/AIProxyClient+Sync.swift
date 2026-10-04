//
//  AIProxyClient+Sync.swift
//  Floreboard
//
//  Payments, credits and cloud data sync (inventory / designs).
//

import Foundation

extension AIProxyClient {
  // MARK: - Payments & Credits

  /// 当前店铺的 appAccountToken：购买时放进 Product.PurchaseOption.appAccountToken，
  /// Apple 会把它签进交易，服务端据此拒绝把这笔购买记到别的店铺。
  func fetchAppleAccountToken(tenantId: String) async throws -> UUID {
    let req = try makeRequest(path: "api/v1/payments/apple-account-token", method: "GET", tenantId: tenantId)
    let wrapper: APIResponseWrapper<AppleAccountTokenData> = try await perform(req)
    guard let raw = wrapper.data?.appAccountToken, let token = UUID(uuidString: raw) else {
      throw AIProxyError.invalidResponse
    }
    return token
  }

  func fetchCredits(tenantId: String) async throws -> CreditsData {
    let req = try makeRequest(path: "api/v1/payments/credits", method: "GET", tenantId: tenantId)
    let wrapper: APIResponseWrapper<CreditsData> = try await perform(req)
    guard let data = wrapper.data else {
      throw AIProxyError.invalidResponse
    }
    return data
  }

  func fetchPaymentPlans() async throws -> [PaymentPlanItem] {
    let req = try makeRequest(path: "api/v1/payments/plans", method: "GET")
    let wrapper: APIResponseWrapper<[PaymentPlanItem]> = try await perform(req)
    return wrapper.data ?? []
  }

  func verifyAppleIAP(
    tenantId: String,
    transactionId: String,
    productId: String,
    jws: String? = nil,
    originalTransactionId: String? = nil
  ) async throws -> AppleVerifyResponse {
    var payload: [String: String] = [
      "transactionId": transactionId,
      "productId": productId
    ]
    if let jws = jws {
      payload["jws"] = jws
    }
    if let origId = originalTransactionId {
      payload["originalTransactionId"] = origId
    }
    let res: AppleVerifyResponse = try await post("api/v1/payments/apple-verify", body: payload, tenantId: tenantId)
    return res
  }

  // MARK: - Cloud Data Sync (Inventory)

  func fetchInventory(tenantId: String) async throws -> [FlowerType] {
    let req = try makeRequest(path: "api/v1/inventory", method: "GET", tenantId: tenantId)
    let wrapper: APIResponseWrapper<[FlowerType]> = try await perform(req)
    return wrapper.data ?? []
  }

  func createFlower(tenantId: String, flower: FlowerType) async throws -> FlowerType {
    let wrapper: APIResponseWrapper<FlowerType> = try await post("api/v1/inventory", body: flower, tenantId: tenantId)
    guard let data = wrapper.data else { throw AIProxyError.invalidResponse }
    return data
  }

  func updateFlower(tenantId: String, flower: FlowerType) async throws -> FlowerType {
    var req = try makeRequest(path: "api/v1/inventory/\(flower.id)", method: "PUT", tenantId: tenantId)
    req.httpBody = try JSONEncoder().encode(flower)
    let wrapper: APIResponseWrapper<FlowerType> = try await perform(req)
    guard let data = wrapper.data else { throw AIProxyError.invalidResponse }
    return data
  }

  func deleteFlower(tenantId: String, flowerId: String) async throws {
    let req = try makeRequest(path: "api/v1/inventory/\(flowerId)", method: "DELETE", tenantId: tenantId)
    let _: EmptyResponse = try await perform(req)
  }

  // MARK: - Cloud Data Sync (Designs)

  func fetchDesigns(tenantId: String) async throws -> [DesignResult] {
    let req = try makeRequest(path: "api/v1/designs", method: "GET", tenantId: tenantId)
    let wrapper: APIResponseWrapper<[DesignResult]> = try await perform(req)
    // 云端时间戳是毫秒，本地使用秒
    return (wrapper.data ?? []).map { DesignMerge.normalizedTimestamps($0) }
  }

  @discardableResult
  func saveDesign(tenantId: String, design: DesignResult) async throws -> DesignFindings? {
    var req = try makeRequest(path: "api/v1/designs", method: "POST", tenantId: tenantId)
    req.httpBody = try JSONEncoder().encode(design)
    return Self.findings(in: try await performRaw(req))
  }

  /// 服务端在创建/更新时按已存数据重算专业校验，随响应返回
  private static func findings(in data: Data) -> DesignFindings? {
    struct Body: Decodable { struct Payload: Decodable { var findings: DesignFindings? }; var data: Payload? }
    return (try? JSONDecoder().decode(Body.self, from: data))?.data?.findings
  }

  struct ExecuteResult {
    var executed: Bool
    var executedAt: Double?
    var inventory: [FlowerType]
  }

  /// 服务端原子执行：在一个事务里扣减库存并标记已执行，并发/重复请求安全（只会扣一次）。
  /// 生成（或沿用）分享链接并更新“是否显示报价”
  func shareDesign(tenantId: String, designId: String, showPrice: Bool) async throws -> ProposalShare {
    var req = try makeRequest(path: "api/v1/designs/\(designId)/share", method: "POST", tenantId: tenantId)
    req.httpBody = try JSONSerialization.data(withJSONObject: ["showPrice": showPrice])
    let wrapper: APIResponseWrapper<ProposalShare> = try await perform(req)
    guard let share = wrapper.data else { throw AIProxyError.invalidResponse }
    return share
  }

  /// 撤销分享链接（旧链接立即失效）
  func unshareDesign(tenantId: String, designId: String) async throws {
    let req = try makeRequest(path: "api/v1/designs/\(designId)/share", method: "DELETE", tenantId: tenantId)
    _ = try await performRaw(req)
  }

  func executeDesign(tenantId: String, designId: String) async throws -> ExecuteResult {
    struct Body: Decodable {
      struct Payload: Decodable { var executed: Bool?; var executedAt: Double?; var inventory: [FlowerType]? }
      var data: Payload?
    }
    let req = try makeRequest(path: "api/v1/designs/\(designId)/execute", method: "POST", tenantId: tenantId)
    let data = try await performRaw(req)
    guard let payload = (try? JSONDecoder().decode(Body.self, from: data))?.data else { throw AIProxyError.invalidResponse }
    return ExecuteResult(
      executed: payload.executed ?? false,
      executedAt: payload.executedAt.map { DesignMerge.seconds($0) },
      inventory: payload.inventory ?? [])
  }

  /// 创建或更新方案：先 PUT（更新已有），云端还没有（NOT_FOUND）再 POST（创建）。
  /// 之前只会 POST，而云端对已存在的 id 不做更新，所以出图重试结果、评分、已执行状态等后续修改从未同步到云端。
  @discardableResult
  func upsertDesign(tenantId: String, design: DesignResult) async throws -> DesignFindings? {
    var req = try makeRequest(path: "api/v1/designs/\(design.id)", method: "PUT", tenantId: tenantId)
    req.httpBody = try JSONEncoder().encode(design)
    do {
      return Self.findings(in: try await performRaw(req))
    } catch AIProxyError.rejected(let err) where err.code == "NOT_FOUND" || err.message == "Design not found" {
      // 云端还没有这条方案：创建（兼容尚未返回 NOT_FOUND 错误码的旧服务端）
      return try await saveDesign(tenantId: tenantId, design: design)
    } catch AIProxyError.httpStatus(404) {
      return try await saveDesign(tenantId: tenantId, design: design)
    }
  }

  /// 上传图片到云端存储（R2），返回可跨设备访问的公开 URL。
  /// 服务端按文件头校验类型，只接受 JPEG/PNG/WebP/GIF，最大 10MB。
  func uploadImage(_ data: Data, contentType: String = "image/jpeg", tenantId: String?) async throws -> String {
    var req = try makeRequest(path: "api/v1/storage/upload?bucket=reference", method: "POST", tenantId: tenantId)
    req.setValue(contentType, forHTTPHeaderField: "Content-Type")
    req.httpBody = data
    let responseData = try await performRaw(req, session: imageURLSession)
    guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
          let url = json["url"] as? String, DesignMerge.isRemoteImage(url) else {
      throw AIProxyError.invalidResponse
    }
    return url
  }

  func deleteDesign(tenantId: String, designId: String) async throws {
    let req = try makeRequest(path: "api/v1/designs/\(designId)", method: "DELETE", tenantId: tenantId)
    let _: EmptyResponse = try await perform(req)
  }

  func health() async throws -> AIProxyHealthResponse {
    let req = try makeRequest(path: "health", method: "GET")
    return try await perform(req)
  }
}
