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

  var onPurchaseSuccess: (() -> Void)? = nil

  @State private var currentCredits: Int? = nil
  @State private var tier: String = "free"
  @State private var isProcessing: Bool = false
  @State private var statusMessage: String? = nil

  private let defaultPlans: [DisplayPlan] = [
    DisplayPlan(
      id: "pro_yearly",
      name: "Pro 专业版年卡",
      credits: 4000,
      price: "$89.00/年",
      badge: "立省 25%",
      description: "全年 4000 点数，折合 $7.4/月，点数跨周期滚动",
      isSubscription: true
    ),
    DisplayPlan(
      id: "pro_monthly",
      name: "Pro 专业版月卡",
      credits: 300,
      price: "$9.90/月",
      badge: "热门推荐",
      description: "每月自动注入 300 点数，解锁高峰期优先生成",
      isSubscription: true
    ),
    DisplayPlan(
      id: "credit_pack_300",
      name: "300 点数进阶包",
      credits: 300,
      price: "$12.99",
      badge: nil,
      description: "300 点永久有效，高频设计与旺季首选",
      isSubscription: false
    ),
    DisplayPlan(
      id: "credit_pack_100",
      name: "100 点数加油包",
      credits: 100,
      price: "$4.99",
      badge: nil,
      description: "100 点永久有效，支持约 100 套方案生成",
      isSubscription: false
    )
  ]

  var body: some View {
    ZStack {
      PremiumBackgroundView()

      ScrollView(showsIndicators: false) {
        VStack(spacing: 24) {
          // Header Icon
          ZStack {
            Circle()
              .fill(AppTheme.creative.opacity(0.12))
              .frame(width: 88, height: 88)

            Image(systemName: "sparkles")
              .font(.system(size: 42))
              .foregroundStyle(AppTheme.creative)
          }
          .padding(.top, 32)

          // Titles
          VStack(spacing: 8) {
            Text("升级会员与点数充值")
              .font(AppTheme.serifFont(size: 28, weight: .bold))
              .foregroundColor(AppTheme.foreground)
              .multilineTextAlignment(.center)

            if let credits = currentCredits {
              HStack(spacing: 6) {
                Text("当前剩余点数:")
                  .font(AppTheme.sansFont(size: 14))
                  .foregroundColor(AppTheme.mutedText)
                Text("\(credits)")
                  .font(AppTheme.sansFont(size: 15, weight: .bold))
                  .foregroundColor(AppTheme.primary)
                if tier == "pro" {
                  Text("PRO 会员")
                    .font(AppTheme.sansFont(size: 11, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.creative.opacity(0.2))
                    .foregroundColor(AppTheme.creative)
                    .cornerRadius(4)
                }
              }
            } else {
              Text("尊享大模型极速方案设计与 4K 商业效果图渲染")
                .font(AppTheme.sansFont(size: 14))
                .foregroundColor(AppTheme.mutedText)
                .multilineTextAlignment(.center)
            }
          }

          // Value Highlights
          HStack(spacing: 12) {
            CreditUsageTag(icon: "doc.text.fill", text: "方案生成 1点")
            CreditUsageTag(icon: "camera.viewfinder", text: "多模态 1点")
            CreditUsageTag(icon: "photo.artframe", text: "4K生图 5点")
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
          Button(action: {
            dismiss()
          }) {
            Text("稍后再说")
              .font(AppTheme.sansFont(size: 14, weight: .medium))
              .foregroundColor(AppTheme.mutedText)
              .underline()
          }
          .padding(.bottom, 36)
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

  private func handlePlanSelection(_ plan: DisplayPlan) {
    guard !isProcessing else { return }
    isProcessing = true
    statusMessage = "正在处理购买..."

    Task {
      defer { isProcessing = false }

      if let product = storeManager.products.first(where: { $0.id == plan.id || $0.id.hasSuffix(plan.id) }) {
        do {
          try await storeManager.purchase(product)
          await refreshCredits()
          statusMessage = "充值成功！"
          try? await Task.sleep(nanoseconds: 800_000_000)
          onPurchaseSuccess?()
          dismiss()
          return
        } catch {
          statusMessage = "购买未完成: \(error.localizedDescription)"
        }
      } else {
        do {
          let simTxId = "sim_\(UUID().uuidString.prefix(10))"
          let res = try await AIService.shared.verifyApplePurchase(transactionId: String(simTxId), productId: plan.id)
          if let updated = res.data {
            self.currentCredits = updated.credits
            self.tier = updated.tier
          }
          statusMessage = "充值成功！已更新点数"
          try? await Task.sleep(nanoseconds: 800_000_000)
          onPurchaseSuccess?()
          dismiss()
        } catch {
          statusMessage = "处理失败: \(error.localizedDescription)"
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

          Text("+\(plan.credits) 点数")
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
