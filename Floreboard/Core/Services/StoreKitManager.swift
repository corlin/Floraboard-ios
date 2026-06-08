import Foundation
import StoreKit
import Combine

@MainActor
class StoreKitManager: ObservableObject {
  @Published var products: [Product] = []
  @Published var purchasedProductIDs = Set<String>()
  @Published var isPurchasing = false
  @Published var purchaseError: Error?

  private let productIDs = [
    "com.floreboard.pro.monthly",
    "com.floreboard.credits.500k"
  ]

  private var updatesTask: Task<Void, Never>? = nil

  init() {
    updatesTask = listenForTransactions()
  }

  deinit {
    updatesTask?.cancel()
  }

  func loadProducts() async {
    do {
      products = try await Product.products(for: productIDs)
        .sorted { $0.price < $1.price }
    } catch {
      print("Failed to load products: \(error)")
    }
  }

  func purchase(_ product: Product) async throws {
    isPurchasing = true
    defer { isPurchasing = false }

    let result = try await product.purchase()

    switch result {
    case .success(let verification):
      // Check whether the transaction is verified. If it's verified, unlock content.
      let transaction = try checkVerified(verification)

      // The transaction is verified. Unlock content here.
      await handleVerifiedTransaction(transaction)

      // Always finish a transaction.
      await transaction.finish()
    case .userCancelled, .pending:
      break
    @unknown default:
      break
    }
  }

  private func listenForTransactions() -> Task<Void, Never> {
    return Task {
      for await result in Transaction.updates {
        do {
          let transaction = try self.checkVerified(result)
          await self.handleVerifiedTransaction(transaction)
          await transaction.finish()
        } catch {
          print("Transaction failed verification")
        }
      }
    }
  }

  private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
      throw StoreError.failedVerification
    case .verified(let safe):
      return safe
    }
  }

  @MainActor
  private func handleVerifiedTransaction(_ transaction: Transaction) async {
    purchasedProductIDs.insert(transaction.productID)
    
    do {
      let _ = try await AIService.shared.verifyIAP(transactionId: String(transaction.id))
      print("Transaction verified with backend successfully.")
    } catch {
      print("Failed to verify transaction with backend: \(error)")
    }
  }

  enum StoreError: Error {
    case failedVerification
  }
}
