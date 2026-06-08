import SwiftUI
import StoreKit

struct PaywallView: View {
  @StateObject private var storeManager = StoreKitManager()
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          Image(systemName: "wand.and.stars")
            .font(.system(size: 60))
            .foregroundColor(.purple)
            .padding(.top, 40)

          Text("Upgrade to Pro")
            .font(.largeTitle.bold())

          Text("Unlock unlimited AI flower designs and stunning visual concepts without limits.")
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .padding(.horizontal)

          VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "sparkles", text: "1,000,000 Credits Monthly")
            FeatureRow(icon: "photo.on.rectangle.angled", text: "High-Quality Image Generations")
            FeatureRow(icon: "bolt.fill", text: "Priority Fast Queueing")
          }
          .padding()
          .background(Color.secondary.opacity(0.1))
          .cornerRadius(16)
          .padding(.horizontal)

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
                  VStack(alignment: .leading) {
                    Text(product.displayName)
                      .font(.headline)
                    Text(product.description)
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  Spacer()
                  Text(product.displayPrice)
                    .bold()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
              }
              .padding(.horizontal)
            }
          }

          Spacer()
        }
      }
      .navigationBarItems(trailing: Button("Close") { dismiss() })
      .task {
        await storeManager.loadProducts()
      }
    }
  }
}

struct FeatureRow: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .foregroundColor(.purple)
        .frame(width: 24)
      Text(text)
        .font(.subheadline)
    }
  }
}

#Preview {
  PaywallView()
}
