//
//  OrderHubView.swift
//  Floreboard
//
//  Unified Order and Inspiration Hub with glassmorphic Segmented Control.
//

import SwiftUI

struct OrderHubView: View {
  @EnvironmentObject var orderService: OrderService
  @EnvironmentObject var historyService: HistoryService
  @Environment(\.hapticManager) var hapticManager

  @State private var selectedSegment: Int = 0 // 0: Orders, 1: Archive
  @State private var orderSearchText = ""
  @State private var historySearchText = ""
  @State private var selectedOrderStatus: OrderStatus?
  @State private var animateItems = false

  var onStartDesign: (() -> Void)?

  var filteredOrders: [OrderRecord] {
    var list = orderService.orders
    if let filter = selectedOrderStatus {
      list = list.filter { $0.status == filter }
    }
    if !orderSearchText.isEmpty {
      list = list.filter {
        $0.customerName.localizedCaseInsensitiveContains(orderSearchText)
          || $0.customerPhone.localizedCaseInsensitiveContains(orderSearchText)
      }
    }
    return list
  }

  var filteredDesigns: [DesignResult] {
    if historySearchText.isEmpty {
      return historyService.savedDesigns
    } else {
      return historyService.savedDesigns.filter { design in
        design.title.localizedCaseInsensitiveContains(historySearchText)
          || design.description.localizedCaseInsensitiveContains(historySearchText)
          || design.meaningText.localizedCaseInsensitiveContains(historySearchText)
      }
    }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        PremiumBackgroundView()

        VStack(spacing: 0) {
          // Top Glassmorphic Segmented Control
          segmentedHeader
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

          // Content based on selection
          if selectedSegment == 0 {
            ordersContent
              .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .leading)),
                removal: .opacity.combined(with: .move(edge: .trailing))
              ))
          } else {
            archiveContent
              .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal: .opacity.combined(with: .move(edge: .leading))
              ))
          }
        }
      }
      .navigationTitle(Tx.t("app.nav.orders_hub"))
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  // MARK: - Segmented Header
  private var segmentedHeader: some View {
    HStack(spacing: 0) {
      Button {
        hapticManager.impact(style: .light)
        withAnimation(AppTheme.interactiveSpring) {
          selectedSegment = 0
        }
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "shippingbox.fill")
            .font(.system(size: 13, weight: .semibold))
          Text(Tx.t("order.hub.tab.orders"))
            .font(AppTheme.sansFont(size: 14, weight: selectedSegment == 0 ? .bold : .medium))
          if !orderService.orders.isEmpty {
            Text("\(orderService.orders.count)")
              .font(AppTheme.captionSmall)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(selectedSegment == 0 ? AppTheme.primary.opacity(0.2) : Color.white.opacity(0.1))
              .clipShape(Capsule())
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
          Group {
            if selectedSegment == 0 {
              Capsule()
                .fill(AppTheme.surfaceElevated)
                .shadow(color: AppTheme.elevation1.color, radius: AppTheme.elevation1.radius, x: 0, y: AppTheme.elevation1.y)
            } else {
              Color.clear
            }
          }
        )
        .foregroundColor(selectedSegment == 0 ? AppTheme.primary : AppTheme.mutedText)
      }
      .buttonStyle(.plain)

      Button {
        hapticManager.impact(style: .light)
        withAnimation(AppTheme.interactiveSpring) {
          selectedSegment = 1
        }
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "sparkles.rectangle.stack.fill")
            .font(.system(size: 13, weight: .semibold))
          Text(Tx.t("order.hub.tab.archive"))
            .font(AppTheme.sansFont(size: 14, weight: selectedSegment == 1 ? .bold : .medium))
          if !historyService.savedDesigns.isEmpty {
            Text("\(historyService.savedDesigns.count)")
              .font(AppTheme.captionSmall)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(selectedSegment == 1 ? AppTheme.creative.opacity(0.2) : Color.white.opacity(0.1))
              .clipShape(Capsule())
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
          Group {
            if selectedSegment == 1 {
              Capsule()
                .fill(AppTheme.surfaceElevated)
                .shadow(color: AppTheme.elevation1.color, radius: AppTheme.elevation1.radius, x: 0, y: AppTheme.elevation1.y)
            } else {
              Color.clear
            }
          }
        )
        .foregroundColor(selectedSegment == 1 ? AppTheme.primary : AppTheme.mutedText)
      }
      .buttonStyle(.plain)
    }
    .padding(3)
    .background(AppTheme.surfaceGlass)
    .clipShape(Capsule())
    .overlay(Capsule().stroke(AppTheme.hairline, lineWidth: 0.5))
  }

  // MARK: - Orders Content
  private var ordersContent: some View {
    ScrollView {
      VStack(spacing: 16) {
        // Search Bar
        WorkbenchSearchField(
          placeholder: Tx.t("general.search") + "...",
          text: $orderSearchText
        )
        .padding(.horizontal)

        // Filter Tabs
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            FilterTabButton(
              title: Tx.t("general.all"),
              isSelected: selectedOrderStatus == nil
            ) {
              selectedOrderStatus = nil
            }

            ForEach(OrderStatus.allCases) { status in
              FilterTabButton(
                title: Tx.t("order.status." + status.rawValue),
                isSelected: selectedOrderStatus == status
              ) {
                selectedOrderStatus = status
              }
            }
          }
          .padding(.horizontal)
        }

        // List or Empty
        let orders = filteredOrders
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
      .padding(.bottom, 80)
    }
    .scrollAwareTabBar()
  }

  // MARK: - Archive Content
  private var archiveContent: some View {
    ScrollView {
      VStack(spacing: 16) {
        WorkbenchSearchField(
          placeholder: Tx.t("history.search"),
          text: $historySearchText
        )
        .padding(.horizontal)

        if filteredDesigns.isEmpty {
          VStack(alignment: .center, spacing: 16) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 48))
              .foregroundStyle(
                LinearGradient(
                  colors: [AppTheme.creative.opacity(0.7), AppTheme.primary.opacity(0.5)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
            Text(historyService.savedDesigns.isEmpty ? Tx.t("history.empty") : Tx.t("history.search.empty"))
              .font(AppTheme.serifFont(size: 18, weight: .bold))
              .foregroundColor(AppTheme.foreground)
            Text(historyService.savedDesigns.isEmpty ? Tx.t("history.empty.desc") : Tx.t("history.search.empty.desc"))
              .font(AppTheme.sansFont(size: 14))
              .foregroundColor(AppTheme.mutedText)
              .multilineTextAlignment(.center)
            if historyService.savedDesigns.isEmpty, let onStartDesign {
              Button {
                onStartDesign()
              } label: {
                Label(Tx.t("history.empty.action"), systemImage: "sparkles")
              }
              .buttonStyle(PrimaryButtonStyle())
              .padding(.top, 4)
            }
          }
          .frame(maxWidth: .infinity)
          .padding(24)
          .padding(.top, 24)
          .glassmorphic()
          .padding(.horizontal)
        } else {
          LazyVStack(spacing: 14) {
            ForEach(Array(filteredDesigns.enumerated()), id: \.element.id) { _, design in
              NavigationLink(destination: DesignDetailView(design: design)) {
                HistoryRow(design: design)
              }
              .buttonStyle(PlainButtonStyle())
            }
          }
          .padding(.horizontal)
        }
      }
      .padding(.vertical)
      .padding(.bottom, 80)
    }
    .scrollAwareTabBar()
  }
}
