import SwiftUI
import StoreKit

struct PaywallView: View {
  @StateObject private var storeManager = StoreKitManager()
  @Environment(\.dismiss) var dismiss

  var body: some View {
    ZStack {
      AppTheme.premiumGradient.ignoresSafeArea()

      ScrollView(showsIndicators: false) {
        VStack(spacing: 32) {
          
          // Header Icon
          ZStack {
            Circle()
              .fill(AppTheme.aiDesign.opacity(0.15))
              .frame(width: 100, height: 100)
            
            Image(systemName: "wand.and.stars")
              .font(.system(size: 48))
              .foregroundStyle(AppTheme.creative)
          }
          .padding(.top, 40)

          // Titles
          VStack(spacing: 12) {
            Text("Unlock Floreboard Pro")
              .font(AppTheme.serifFont(size: 32, weight: .bold))
              .foregroundColor(AppTheme.foreground)
              .multilineTextAlignment(.center)

            Text("Experience unlimited AI generation, premium visual muses, and priority processing.")
              .font(AppTheme.sansFont(size: 16))
              .foregroundColor(AppTheme.mutedText)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 24)
          }

          // Features List
          VStack(alignment: .leading, spacing: 20) {
            FeatureRow(icon: "infinity", title: "Unlimited AI Designs", subtitle: "Generate as many concepts as you need")
            FeatureRow(icon: "sparkles.tv", title: "4K Resolution Export", subtitle: "Crystal clear presentations for clients")
            FeatureRow(icon: "bolt.fill", title: "Priority Processing", subtitle: "Skip the queue with dedicated servers")
          }
          .padding(24)
          .glassmorphic()
          .padding(.horizontal, 24)

          // Subscription Options
          VStack(spacing: 16) {
            if storeManager.products.isEmpty {
              ProgressView()
                .padding()
            } else {
              ForEach(storeManager.products) { product in
                Button(action: {
                  Task {
                    try? await storeManager.purchase(product)
                    dismiss()
                  }
                }) {
                  HStack {
                    VStack(alignment: .leading, spacing: 4) {
                      Text(product.displayName)
                        .font(AppTheme.sansFont(size: 18, weight: .bold))
                      Text(product.description)
                        .font(AppTheme.sansFont(size: 13))
                        .foregroundColor(AppTheme.mutedText)
                    }
                    Spacer()
                    Text(product.displayPrice)
                      .font(AppTheme.sansFont(size: 20, weight: .bold))
                      .foregroundColor(AppTheme.foreground)
                  }
                  .padding(20)
                  .background(AppTheme.surfaceElevated)
                  .cornerRadius(AppTheme.containerRadius)
                  .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.containerRadius)
                      .stroke(AppTheme.primary, lineWidth: 2)
                  )
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(.horizontal, 24)

          // Skip Button
          Button(action: {
            dismiss()
          }) {
            Text("Maybe Later")
              .font(AppTheme.sansFont(size: 16, weight: .medium))
              .foregroundColor(AppTheme.mutedText)
              .underline()
          }
          .padding(.bottom, 40)
          
        }
      }
    }
    .task {
      await storeManager.loadProducts()
    }
  }
}

struct FeatureRow: View {
  let icon: String
  let title: String
  let subtitle: String

  var body: some View {
    HStack(spacing: 16) {
      ZStack {
        Circle()
          .fill(AppTheme.surfaceElevated)
          .frame(width: 44, height: 44)
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundColor(AppTheme.primary)
      }
      
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(AppTheme.sansFont(size: 16, weight: .semibold))
          .foregroundColor(AppTheme.foreground)
        Text(subtitle)
          .font(AppTheme.sansFont(size: 13))
          .foregroundColor(AppTheme.mutedText)
      }
    }
  }
}
