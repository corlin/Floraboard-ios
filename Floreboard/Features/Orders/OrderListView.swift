//
//  OrderListView.swift
//  Floreboard
//
//  UI view displaying list of customer orders with status filter tabs.
//

import SwiftUI

struct OrderListView: View {
  @EnvironmentObject var orderService: OrderService
  @StateObject private var viewModel = OrderViewModel()

  var body: some View {
    NavigationStack {
      ZStack {
        PremiumBackgroundView()

        ScrollView {
          VStack(spacing: 16) {
            // Search Bar
            WorkbenchSearchField(
              placeholder: Tx.t("general.search") + "...",
              text: $viewModel.searchText
            )
            .padding(.horizontal)

            // Filter Tabs
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                FilterTabButton(
                  title: Tx.t("general.all"),
                  isSelected: viewModel.selectedFilter == nil
                ) {
                  viewModel.selectedFilter = nil
                }

                ForEach(OrderStatus.allCases) { status in
                  FilterTabButton(
                    title: Tx.t("order.status." + status.rawValue),
                    isSelected: viewModel.selectedFilter == status
                  ) {
                    viewModel.selectedFilter = status
                  }
                }
              }
              .padding(.horizontal)
            }

            // List or Empty
            let orders = viewModel.filteredOrders(from: orderService.orders)
            if orders.isEmpty {
              VStack(spacing: 12) {
                Image(systemName: "shippingbox")
                  .font(.system(size: 48))
                  .foregroundColor(AppTheme.primary.opacity(0.6))
                Text(Tx.t("order.list.empty"))
                  .font(AppTheme.serifFont(size: 18, weight: .bold))
                  .foregroundColor(AppTheme.foreground)
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 60)
              .glassmorphic()
              .padding(.horizontal)
            } else {
              LazyVStack(spacing: 12) {
                ForEach(orders) { order in
                  NavigationLink(destination: OrderDetailView(order: order)) {
                    OrderRowCard(order: order)
                  }
                  .buttonStyle(.plain)
                }
              }
              .padding(.horizontal)
            }
          }
          .padding(.vertical)
        }
      }
      .navigationTitle(Tx.t("order.list.title"))
    }
  }
}

struct OrderRowCard: View {
  let order: OrderRecord

  var body: some View {
    let priceText = String(format: "%.2f", order.totalAmount)
    let itemsText = Tx.t("order.items_count")
    let subtitleText = "¥\(priceText) • \(order.items.count) \(itemsText)"

    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(order.customerName)
          .font(AppTheme.sansFont(size: 16, weight: .bold))
          .foregroundColor(AppTheme.foreground)

        Spacer()

        StatusBadgeView(status: order.status)
      }

      Text(subtitleText)
        .font(AppTheme.sansFont(size: 14))
        .foregroundColor(AppTheme.mutedText)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassmorphic()
  }
}

struct StatusBadgeView: View {
  let status: OrderStatus

  var color: Color {
    switch status {
    case .draft: return AppTheme.mutedText
    case .quoted: return AppTheme.info
    case .confirmed: return AppTheme.primary
    case .inProduction: return AppTheme.secondary
    case .delivered: return AppTheme.success
    case .cancelled: return AppTheme.danger
    }
  }

  var body: some View {
    let titleText: String = Tx.t("order.status." + status.rawValue)
    Text(titleText)
      .font(AppTheme.sansFont(size: 12, weight: .semibold))
      .padding(.horizontal, 10)
      .padding(.vertical, 4)
      .background(color.opacity(0.15), in: Capsule())
      .foregroundColor(color)
  }
}

struct FilterTabButton: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(AppTheme.sansFont(size: 14, weight: isSelected ? .bold : .medium))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isSelected ? AppTheme.primary : AppTheme.surfaceGlass, in: Capsule())
        .foregroundColor(isSelected ? Color.white : AppTheme.foreground)
    }
    .buttonStyle(.plain)
  }
}
