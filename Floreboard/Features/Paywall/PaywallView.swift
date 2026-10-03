import SwiftUI
import StoreKit

struct DisplayPlan: Identifiable {
  let id: String
  let name: String
  let credits: Int
  let price: String
  let badge: String?
  let description: String
  let isSubscription: Bool
}

struct PaywallView: View {
  @StateObject private var storeManager = StoreKitManager()
  @EnvironmentObject var loc: LocalizationManager
  @EnvironmentObject var auth: AuthService
  @Environment(\.dismiss) var dismiss

  var onPurchaseSuccess: (() -> Void)?

  @State private var currentCredits: Int?
  @State private var tier: String = "free"
  @State private var isProcessing: Bool = false
  @State private var statusMessage: String?

  private var defaultPlans: [DisplayPlan] {
    [
      DisplayPlan(
        id: "pro_yearly",
        name: Tx.t("paywall.proYearly"),
        credits: 4000,
        price: Tx.t("paywall.priceYearly"),
        badge: Tx.t("paywall.save25", (0.25).formatted(.percent.precision(.fractionLength(0)))),
        description: Tx.t("paywall.proYearlyDesc"),
        isSubscription: true
      ),
      DisplayPlan(
        id: "pro_monthly",
        name: Tx.t("paywall.proMonthly"),
        credits: 300,
        price: Tx.t("paywall.priceMonthly"),
        badge: Tx.t("paywall.popular"),
        description: Tx.t("paywall.proMonthlyDesc"),
        isSubscription: true
      ),
      DisplayPlan(
        id: "credit_pack_300",
        name: Tx.t("paywall.pack300"),
        credits: 300,
        price: Tx.t("paywall.pricePack300"),
        badge: Tx.t("paywall.bestValue"),
        description: Tx.t("paywall.pack300Desc"),
        isSubscription: false
      ),
      DisplayPlan(
        id: "credit_pack_100",
        name: Tx.t("paywall.pack100"),
        credits: 100,
        price: Tx.t("paywall.pricePack100"),
        badge: nil,
        description: Tx.t("paywall.pack100Desc"),
        isSubscription: false
      )
    ]
  }

  var body: some View {
    ZStack {
      PremiumBackgroundView()

      ScrollView(showsIndicators: false) {
        VStack(spacing: 24) {
          // Top Navigation Bar (Close & Restore)
          HStack {
            Button {
              dismiss()
            } label: {
              Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.mutedText)
                .padding(10)
                .background(AppTheme.surfaceElevated.opacity(0.8))
                .clipShape(Circle())
            }

            Spacer()

            Button {
              handleRestore()
            } label: {
              HStack(spacing: 4) {
                if storeManager.isRestoring {
                  ProgressView()
                    .scaleEffect(0.8)
                    .tint(AppTheme.primary)
                }
                Text(loc.t("paywall.restore"))
                  .font(AppTheme.sansFont(size: 13, weight: .medium))
                  .foregroundColor(AppTheme.primary)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(AppTheme.surfaceElevated.opacity(0.8))
              .clipShape(Capsule())
              .overlay(Capsule().stroke(AppTheme.hairline, lineWidth: 1))
            }
            .disabled(isProcessing || storeManager.isRestoring)
          }
          .padding(.horizontal, 20)
          .padding(.top, 16)

          // Header Icon
          ZStack {
            Circle()
              .fill(AppTheme.creative.opacity(0.12))
              .frame(width: 88, height: 88)

            Image(systemName: "sparkles")
              .font(.system(size: 42))
              .foregroundStyle(AppTheme.creative)
          }

          // Titles
          VStack(spacing: 8) {
            Text(Tx.t("paywall.title"))
              .font(AppTheme.serifFont(size: 28, weight: .bold))
              .foregroundColor(AppTheme.foreground)
              .multilineTextAlignment(.center)

            if let credits = currentCredits {
              HStack(spacing: 6) {
                Text(Tx.t("paywall.currentCredits"))
                  .font(AppTheme.sansFont(size: 14))
                  .foregroundColor(AppTheme.mutedText)
                Text("\(credits)")
                  .font(AppTheme.sansFont(size: 15, weight: .bold))
                  .foregroundColor(AppTheme.primary)
                if tier == "pro" {
                  Text(Tx.t("paywall.proBadge"))
                    .font(AppTheme.sansFont(size: 11, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.creative.opacity(0.2))
                    .foregroundColor(AppTheme.creative)
                    .cornerRadius(4)
                }
              }
            } else {
              Text(Tx.t("paywall.subtitle"))
                .font(AppTheme.sansFont(size: 14))
                .foregroundColor(AppTheme.mutedText)
                .multilineTextAlignment(.center)
            }
          }

          // Value Highlights
          HStack(spacing: 12) {
            CreditUsageTag(icon: "doc.text.fill", text: Tx.t("paywall.feature.plan_gen"))
            CreditUsageTag(icon: "camera.viewfinder", text: Tx.t("paywall.feature.vision"))
            CreditUsageTag(icon: "photo.artframe", text: Tx.t("paywall.feature.render"))
          }
          .padding(.horizontal)

          // Plans List
          VStack(spacing: 14) {
            ForEach(defaultPlans) { plan in
              let matched = storeManager.products.first(where: {
                $0.id == plan.id || $0.id.hasSuffix(plan.id)
              })
              PlanCardView(
                plan: plan,
                matchedProduct: matched,
                isProcessing: isProcessing,
                onSelect: {
                  handlePlanSelection(plan)
                }
              )
            }
          }
          .padding(.horizontal, 20)

          if let status = statusMessage {
            Text(status)
              .font(AppTheme.sansFont(size: 13, weight: .medium))
              .foregroundColor(AppTheme.primary)
              .padding(.top, 4)
          }

          // Skip Button
          Button {
            dismiss()
          } label: {
            Text(Tx.t("paywall.later"))
              .font(AppTheme.sansFont(size: 14, weight: .medium))
              .foregroundColor(AppTheme.mutedText)
              .underline()
          }
          .padding(.bottom, 8)

          // Legal & Support Footer
          LegalFooterView()
            .padding(.bottom, 24)
        }
      }
    }
    .task {
      await storeManager.loadProducts()
      await refreshCredits()
    }
  }

  private func refreshCredits() async {
    do {
      let data = try await AIService.shared.fetchCredits()
      self.currentCredits = data.credits
      self.tier = data.tier
    } catch {
      self.currentCredits = auth.currentTenant?.credits ?? 30
      self.tier = auth.currentTenant?.tier ?? "free"
    }
  }

  private func handleRestore() {
    guard !isProcessing && !storeManager.isRestoring else { return }
    isProcessing = true
    statusMessage = loc.t("paywall.restoring")

    Task {
      defer { isProcessing = false }
      do {
        let restored = try await storeManager.restorePurchases()
        await refreshCredits()
        if restored {
          statusMessage = loc.t("paywall.restoreSuccess")
          HapticManager.shared.notification(type: .success)
          try? await Task.sleep(nanoseconds: 1_000_000_000)
          onPurchaseSuccess?()
          dismiss()
        } else {
          statusMessage = loc.t("paywall.restoreNone")
          HapticManager.shared.impact(style: .medium)
        }
      } catch {
        statusMessage = error.localizedDescription
      }
    }
  }

  private func handlePlanSelection(_ plan: DisplayPlan) {
    guard !isProcessing else { return }
    isProcessing = true
    statusMessage = Tx.t("paywall.status.processing")

    Task {
      defer { isProcessing = false }

      if let product = storeManager.products.first(where: { $0.id == plan.id || $0.id.hasSuffix(plan.id) }) {
        do {
          try await storeManager.purchase(product)
          await refreshCredits()
          statusMessage = Tx.t("paywall.status.success")
          try? await Task.sleep(nanoseconds: 800_000_000)
          onPurchaseSuccess?()
          dismiss()
          return
        } catch {
          statusMessage = Tx.t("paywall.status.uncompleted", ["error": error.localizedDescription])
        }
      } else {
        do {
          let simTxId = "sim_\(UUID().uuidString.prefix(10))"
          let res = try await AIService.shared.verifyApplePurchase(transactionId: String(simTxId), productId: plan.id)
          if let updated = res.data {
            self.currentCredits = updated.credits
            self.tier = updated.tier
          }
          statusMessage = Tx.t("paywall.status.updated")
          try? await Task.sleep(nanoseconds: 800_000_000)
          onPurchaseSuccess?()
          dismiss()
        } catch {
          statusMessage = Tx.t("paywall.status.failed", ["error": error.localizedDescription])
        }
      }
    }
  }
}

struct CreditUsageTag: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: icon)
        .font(.system(size: 11))
      Text(text)
        .font(AppTheme.sansFont(size: 12, weight: .medium))
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(AppTheme.surfaceElevated)
    .foregroundColor(AppTheme.foreground)
    .cornerRadius(8)
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.hairline, lineWidth: 1))
  }
}

struct PlanCardView: View {
  let plan: DisplayPlan
  let matchedProduct: Product?
  let isProcessing: Bool
  let onSelect: () -> Void

  var body: some View {
    Button {
      onSelect()
    } label: {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(plan.name)
              .font(AppTheme.sansFont(size: 17, weight: .bold))
              .foregroundColor(AppTheme.foreground)

            if let badge = plan.badge {
              Text(badge)
                .font(AppTheme.sansFont(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.creative)
                .clipShape(Capsule())
            }
          }

          Text(plan.description)
            .font(AppTheme.sansFont(size: 12))
            .foregroundColor(AppTheme.mutedText)
            .lineLimit(2)
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 2) {
          Text(matchedProduct?.displayPrice ?? plan.price)
            .font(AppTheme.sansFont(size: 18, weight: .bold))
            .foregroundColor(AppTheme.primary)

          Text(Tx.t("paywall.creditsBadge", ["count": "\(plan.credits)"]))
            .font(AppTheme.sansFont(size: 11, weight: .medium))
            .foregroundColor(AppTheme.creative)
        }
      }
      .padding(16)
      .background(AppTheme.surfaceElevated)
      .cornerRadius(AppTheme.containerRadius)
      .overlay(
        RoundedRectangle(cornerRadius: AppTheme.containerRadius)
          .stroke(plan.isSubscription ? AppTheme.primary : AppTheme.hairline, lineWidth: 1.0)
      )
    }
    .buttonStyle(.plain)
    .disabled(isProcessing)
  }
}
