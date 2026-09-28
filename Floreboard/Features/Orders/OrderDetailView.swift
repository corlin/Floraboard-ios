//
//  OrderDetailView.swift
//  Floreboard
//
//  Detail view for managing order status transitions and items.
//

import SwiftUI

struct OrderDetailView: View {
  @EnvironmentObject var orderService: OrderService
  @Environment(\.dismiss) var dismiss
  let order: OrderRecord
  @State private var showWorkbench = false

  var body: some View {
    ZStack {
      PremiumBackgroundView()

      ScrollView {
        VStack(spacing: 20) {
          // Workbench Mode Launch Card
          if order.status == .inProduction || order.status == .confirmed {
            Button {
              showWorkbench = true
            } label: {
              HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                  .font(.system(size: 18, weight: .bold))
                Text(Tx.t("workbench.enter_button"))
                  .font(AppTheme.sansFont(size: 16, weight: .bold))
                Spacer()
                Image(systemName: "arrow.up.right")
                  .font(.system(size: 14, weight: .semibold))
              }
              .padding(.horizontal, 20)
              .padding(.vertical, 16)
              .background(
                LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
              .foregroundColor(Color.white)
              .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
              .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
          }

          // Order Header
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text(order.customerName)
                .font(AppTheme.serifFont(size: 22, weight: .bold))
                .foregroundColor(AppTheme.foreground)

              Spacer()

              StatusBadgeView(status: order.status)
            }

            if !order.customerPhone.isEmpty {
              Text(order.customerPhone)
                .font(AppTheme.sansFont(size: 14))
                .foregroundColor(AppTheme.mutedText)
            }
          }
          .padding(20)
          .glassmorphic()

          // Status Change Selector
          VStack(alignment: .leading, spacing: 12) {
            Text(Tx.t("order.detail.update_status"))
              .font(AppTheme.sansFont(size: 14, weight: .semibold))
              .foregroundColor(AppTheme.mutedText)

            Picker("Status", selection: Binding(
              get: { order.status },
              set: { newStatus in
                orderService.updateOrderStatus(order, newStatus: newStatus)
              }
            )) {
              ForEach(OrderStatus.allCases) { status in
                Text(Tx.t("order.status.\(status.rawValue)")).tag(status)
              }
            }
            .pickerStyle(.segmented)
          }
          .padding(20)
          .glassmorphic()

          // Order Items
          VStack(alignment: .leading, spacing: 16) {
            Text(Tx.t("order.detail.items"))
              .font(AppTheme.serifFont(size: 18, weight: .bold))
              .foregroundColor(AppTheme.foreground)

            ForEach(order.items) { item in
              HStack {
                Text(item.flowerName)
                  .font(AppTheme.sansFont(size: 16, weight: .medium))
                  .foregroundColor(AppTheme.foreground)

                Spacer()

                Text("x\(item.count)")
                  .font(AppTheme.sansFont(size: 14, weight: .bold))
                  .foregroundColor(AppTheme.mutedText)

                Text("¥\(String(format: "%.2f", item.unitPrice * Double(item.count)))")
                  .font(AppTheme.sansFont(size: 16, weight: .bold))
                  .foregroundColor(AppTheme.primary)
                  .frame(width: 80, alignment: .trailing)
              }
              .padding(.vertical, 4)

              if item.id != order.items.last?.id {
                Divider().background(Color.white.opacity(0.1))
              }
            }

            Divider()

            HStack {
              Text(Tx.t("order.detail.total"))
                .font(AppTheme.sansFont(size: 16, weight: .bold))
                .foregroundColor(AppTheme.foreground)

              Spacer()

              Text("¥\(String(format: "%.2f", order.totalAmount))")
                .font(AppTheme.serifFont(size: 22, weight: .bold))
                .foregroundColor(AppTheme.primary)
            }
          }
          .padding(20)
          .glassmorphic()
        }
        .padding()
      }
    }
    .navigationTitle(Tx.t("order.detail.title"))
    .navigationBarTitleDisplayMode(.inline)
    .fullScreenCover(isPresented: $showWorkbench) {
      FloristWorkbenchView(order: order)
    }
  }
}
