//
//  StoreKitManager.swift
//  Floreboard
//
//  Production-grade StoreKit 2 manager for Apple In-App Purchases, auto-renewable subscriptions,
//  instant entitlement checks, and restore purchases.
//

import Combine
import Foundation
import StoreKit
import UIKit

@MainActor
class StoreKitManager: ObservableObject {
  static let shared = StoreKitManager()

  @Published var products: [Product] = []
  @Published var purchasedProductIDs = Set<String>()
  @Published var isPurchasing = false
  @Published var isRestoring = false
  @Published var purchaseError: Error?
  @Published var isProMember = false
  @Published var subscriptionExpirationDate: Date? = nil

  /// Comprehensive product IDs supporting standard reverse-domain and shorthand IDs
  let productIDs: [String] = [
    "cn.corlin.Floreboard.pro.monthly",
    "cn.corlin.Floreboard.pro.yearly",
    "cn.corlin.Floreboard.credits.100",
    "cn.corlin.Floreboard.credits.300",
    "com.floreboard.pro.monthly",
    "com.floreboard.pro.yearly",
    "com.floreboard.credits.100",
    "com.floreboard.credits.300",
    "pro_monthly",
    "pro_yearly",
    "credit_pack_100",
    "credit_pack_300"
  ]

  private var updatesTask: Task<Void, Never>? = nil

  init() {
    updatesTask = listenForTransactions()
    Task {
      await checkEntitlements()
    }
  }

  deinit {
    updatesTask?.cancel()
  }

  // MARK: - Product Catalog Loading

  func loadProducts() async {
    do {
      let loaded = try await Product.products(for: productIDs)
      self.products = loaded.sorted { $0.price < $1.price }
    } catch {
      print("[StoreKitManager] Failed to load products: \(error)")
    }
  }

  // MARK: - Purchase Flow

  func purchase(_ product: Product) async throws {
    isPurchasing = true
    defer { isPurchasing = false }

    // 把这笔购买绑定到当前店铺（Apple 会把 token 签进交易，续费也会继承）。
    // 取不到 token 就不发起购买：否则这笔钱可能记不到任何店铺上。
    let accountToken: UUID
    do {
      accountToken = try await AIService.shared.appleAccountToken()
    } catch {
      throw StoreError.accountUnavailable
    }
    let result = try await product.purchase(options: [.appAccountToken(accountToken)])

    switch result {
    case .success(let verification):
      let (transaction, jws) = try checkVerified(verification)
      await handleVerifiedTransaction(transaction, jws: jws)
      await transaction.finish()
    case .userCancelled:
      break
    case .pending:
      print("[StoreKitManager] Purchase pending family authorization or bank check")
    @unknown default:
      break
    }
  }

  // MARK: - Entitlements & Subscription Status

  /// Checks current active entitlements directly from Apple's cryptographically secured local StoreKit database
  func checkEntitlements() async {
    var hasActivePro = false
    var latestExpiry: Date? = nil

    for await result in Transaction.currentEntitlements {
      do {
        let (transaction, _) = try checkVerified(result)

        // Only active, un-revoked transactions
        if transaction.revocationDate == nil {
          purchasedProductIDs.insert(transaction.productID)

          if isSubscriptionProduct(transaction.productID) {
            hasActivePro = true
            if let exp = transaction.expirationDate {
              if latestExpiry == nil || exp > latestExpiry! {
                latestExpiry = exp
              }
            }
          }
        }
      } catch {
        print("[StoreKitManager] Entitlement verification failed: \(error)")
      }
    }

    self.isProMember = hasActivePro
    self.subscriptionExpirationDate = latestExpiry
  }

  // MARK: - Restore Purchases (App Store Guideline 3.1.1 Mandatory)

  /// Restores previous purchases by synchronizing with Apple App Store
  /// Returns `true` if active subscriptions were restored
  func restorePurchases() async throws -> Bool {
    isRestoring = true
    defer { isRestoring = false }

    try await AppStore.sync()
    await checkEntitlements()

    // Send latest entitlements to backend for credit/status synchronization
    for await result in Transaction.currentEntitlements {
      if let (transaction, jws) = try? checkVerified(result) {
        await handleVerifiedTransaction(transaction, jws: jws)
      }
    }

    return isProMember
  }

  // MARK: - Transaction Observer

  private func listenForTransactions() -> Task<Void, Never> {
    Task.detached(priority: .background) {
      for await result in Transaction.updates {
        do {
          let (transaction, jws) = try await MainActor.run {
            try self.checkVerified(result)
          }
          await self.handleVerifiedTransaction(transaction, jws: jws)
          await transaction.finish()
        } catch {
          print("[StoreKitManager] Transaction update verification failed: \(error)")
        }
      }
    }
  }

  private func checkVerified(_ result: VerificationResult<Transaction>) throws -> (Transaction, String) {
    switch result {
    case .unverified:
      throw StoreError.failedVerification
    case .verified(let safe):
      return (safe, result.jwsRepresentation)
    }
  }

  @MainActor
  private func handleVerifiedTransaction(_ transaction: Transaction, jws: String? = nil) async {
    purchasedProductIDs.insert(transaction.productID)

    if isSubscriptionProduct(transaction.productID) {
      self.isProMember = true
      if let exp = transaction.expirationDate {
        self.subscriptionExpirationDate = exp
      }
    }

    do {
      let res = try await AIService.shared.verifyApplePurchase(
        transactionId: String(transaction.id),
        productId: transaction.productID,
        jws: jws,
        originalTransactionId: String(transaction.originalID)
      )
      print("[StoreKitManager] Transaction verified with backend: \(res)")
      NotificationCenter.default.post(name: NSNotification.Name("FloreboardCreditsUpdated"), object: nil)
    } catch {
      print("[StoreKitManager] Backend sync note (local entitlement preserved): \(error)")
      NotificationCenter.default.post(name: NSNotification.Name("FloreboardCreditsUpdated"), object: nil)
    }
  }

  // MARK: - Manage Subscriptions

  func openManageSubscriptions() {
    Task { @MainActor in
      if let windowScene = UIApplication.shared.connectedScenes.first(where: {
        $0.activationState == .foregroundActive
      }) as? UIWindowScene {
        do {
          try await AppStore.showManageSubscriptions(in: windowScene)
          return
        } catch {
          print("[StoreKitManager] showManageSubscriptions error: \(error)")
        }
      }
      if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
        await UIApplication.shared.open(url)
      }
    }
  }

  // MARK: - Helpers

  func isSubscriptionProduct(_ productID: String) -> Bool {
    let lower = productID.lowercased()
    return lower.contains("pro") || lower.contains("monthly") || lower.contains("yearly")
  }

  enum StoreError: Error, LocalizedError {
    case failedVerification
    case accountUnavailable

    var errorDescription: String? {
      switch self {
      case .failedVerification:
        return "Transaction signature verification failed."
      case .accountUnavailable:
        return "Could not reach the server to link this purchase to your shop. Please check your connection and try again."
      }
    }
  }
}
