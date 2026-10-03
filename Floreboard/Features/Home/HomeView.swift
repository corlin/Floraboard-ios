import SwiftUI

struct HomeView: View {
  @Binding var selection: Int
  @Binding var inventorySearchText: String
  @EnvironmentObject var auth: AuthService
  @EnvironmentObject var loc: LocalizationManager
  @EnvironmentObject var inventoryService: InventoryService
  @EnvironmentObject var historyService: HistoryService
  @EnvironmentObject var orderService: OrderService
  @Environment(\.hapticManager) var hapticManager
  @State private var showNotifications = false
  @State private var showInventoryAnalytics = false
  @State private var showRevenueAnalytics = false

  init(selection: Binding<Int>, inventorySearchText: Binding<String> = .constant("")) {
    self._selection = selection
    self._inventorySearchText = inventorySearchText
  }

  // Computed Stats
  var inProductionOrders: [OrderRecord] {
    orderService.orders.filter { $0.status == .inProduction }
  }

  var confirmedOrders: [OrderRecord] {
    orderService.orders.filter { $0.status == .confirmed }
  }

  var todayPendingOrders: [OrderRecord] {
    orderService.orders.filter { $0.status == .confirmed || $0.status == .inProduction }
  }

  var todayOrdersCount: Int {
    todayPendingOrders.count
  }

  var totalStock: Int {
    inventoryService.flowers.reduce(0) { $0 + $1.quantity }
  }

  var lowStockItems: [FlowerType] {
    inventoryService.flowers.filter { $0.quantity < 10 }
  }

  var lowStockCount: Int {
    lowStockItems.count
  }

  var totalRevenue: Double {
    historyService.savedDesigns.reduce(0) { $0 + $1.totalCost }
  }

  var recentDesigns: [DesignResult] {
    Array(historyService.savedDesigns.prefix(8))
  }

  var body: some View {
    NavigationStack {
      ZStack {
        PremiumBackgroundView()

        ScrollView(showsIndicators: false) {
          VStack(alignment: .leading, spacing: 26) {
            // MARK: - Hero Welcome Header
            welcomeHeader
              .padding(.horizontal, 24)
              .padding(.top, 16)

            // MARK: - Studio Focus Hero Card (今日工坊态势主卡)
            studioFocusHeroCard
              .padding(.horizontal, 24)

            // MARK: - Quick Action Vertical Tiles (三联等宽纵向触控磁贴)
            quickActionTilesSection
              .padding(.horizontal, 24)

            // MARK: - Studio Health KPI Row (经营简报微胶囊)
            studioHealthPillsRow

            // MARK: - Editorial Floral Lookbook (近期花艺画卷)
            recentLookbookSection
          }
          .padding(.bottom, 100)
        }
        .scrollAwareTabBar()
      }
      .toolbar(.hidden, for: .navigationBar)
      .sheet(isPresented: $showNotifications) {
        NotificationSheetView(
          lowStockItems: lowStockItems,
          onGoToInventory: { flowerName in
            inventorySearchText = flowerName ?? ""
            showNotifications = false
            selection = 1
          }
        )
      }
      .sheet(isPresented: $showInventoryAnalytics) {
        InventoryAnalyticsSheetView(inventory: inventoryService.flowers)
      }
      .sheet(isPresented: $showRevenueAnalytics) {
        RevenueAnalyticsSheetView(designs: historyService.savedDesigns)
      }
    }
  }

  // MARK: - Welcome Header
  private var welcomeHeader: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        HStack(spacing: 6) {
          Image(systemName: "leaf.fill")
            .foregroundColor(AppTheme.primary)
            .font(.system(size: 14))
          Text("Petal & Bloom Atelier")
            .font(AppTheme.sansFont(size: 14, weight: .semibold))
            .foregroundColor(AppTheme.primary)
        }

        Spacer()

        Button {
          hapticManager.impact(style: .medium)
          showNotifications = true
        } label: {
          Image(systemName: "bell")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(AppTheme.primary)
            .overlay(
              Group {
                if lowStockCount > 0 {
                  Circle()
                    .fill(AppTheme.danger)
                    .frame(width: 8, height: 8)
                    .offset(x: 6, y: -6)
                }
              }
            )
        }
        .buttonStyle(.plain)
      }
      .padding(.bottom, 6)

      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 4) {
          Text(loc.t("home.greeting", ["name": auth.currentTenant?.name ?? "Sarah"]))
            .font(AppTheme.serifFont(size: 30, weight: .bold))
            .foregroundStyle(AppTheme.titleGradient)
        }
        Spacer()
        Text(Date().formatted(date: .abbreviated, time: .omitted))
          .font(AppTheme.sansFont(size: 13, weight: .medium))
          .foregroundColor(AppTheme.mutedText)
      }
    }
  }

  // MARK: - Studio Focus Hero Card
  private var studioFocusHeroCard: some View {
    Button {
      hapticManager.impact(style: .light)
      selection = 3 // Direct jump to OrderHubView
    } label: {
      ZStack {
        if todayOrdersCount > 0 {
          // Active Fulfillment State
          VStack(alignment: .leading, spacing: 14) {
            HStack {
              HStack(spacing: 6) {
                Circle()
                  .fill(AppTheme.accent)
                  .frame(width: 8, height: 8)
                Text(loc.t("home.hero.orders_pending"))
                  .font(AppTheme.sansFont(size: 13, weight: .bold))
                  .foregroundColor(AppTheme.accent)
              }

              Spacer()

              HStack(spacing: 4) {
                Text(loc.t("home.hero.view_orders"))
                  .font(AppTheme.captionSmall)
                  .fontWeight(.semibold)
                Image(systemName: "arrow.right")
                  .font(.system(size: 11, weight: .bold))
              }
              .foregroundColor(AppTheme.primary)
            }

            HStack(alignment: .bottom) {
              VStack(alignment: .leading, spacing: 4) {
                Text(String(format: loc.t("home.hero.pending_count"), Int64(todayOrdersCount)))
                  .font(AppTheme.serifFont(size: 26, weight: .bold))
                  .foregroundColor(AppTheme.foreground)

                HStack(spacing: 8) {
                  if !inProductionOrders.isEmpty {
                    Text(String(format: loc.t("home.hero.in_production_count"), Int64(inProductionOrders.count)))
                      .font(AppTheme.captionSmall)
                      .fontWeight(.semibold)
                      .padding(.horizontal, 8)
                      .padding(.vertical, 3)
                      .background(AppTheme.secondary.opacity(0.15), in: Capsule())
                      .foregroundColor(AppTheme.secondary)
                  }

                  if !confirmedOrders.isEmpty {
                    Text(String(format: loc.t("home.hero.ready_count"), Int64(confirmedOrders.count)))
                      .font(AppTheme.captionSmall)
                      .fontWeight(.semibold)
                      .padding(.horizontal, 8)
                      .padding(.vertical, 3)
                      .background(AppTheme.primary.opacity(0.12), in: Capsule())
                      .foregroundColor(AppTheme.primary)
                  }
                }
              }

              Spacer()

              // Circular mini progress badge
              ZStack {
                Circle()
                  .stroke(AppTheme.hairline, lineWidth: 4)
                  .frame(width: 44, height: 44)
                Circle()
                  .trim(from: 0, to: 0.65)
                  .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                  .frame(width: 44, height: 44)
                  .rotationEffect(.degrees(-90))
                Image(systemName: "shippingbox.fill")
                  .font(.system(size: 18))
                  .foregroundColor(AppTheme.primary)
              }
            }
          }
        } else {
          // Studio Calm / Ready State
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              HStack(spacing: 6) {
                Image(systemName: "sparkles")
                  .font(.system(size: 13, weight: .bold))
                  .foregroundColor(AppTheme.success)
                Text(loc.t("home.hero.studio_calm_title"))
                  .font(AppTheme.sansFont(size: 13, weight: .bold))
                  .foregroundColor(AppTheme.success)
              }

              Spacer()

              Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.mutedText)
            }

            VStack(alignment: .leading, spacing: 4) {
              Text(loc.t("home.hero.studio_calm_subtitle"))
                .font(AppTheme.serifFont(size: 20, weight: .bold))
                .foregroundColor(AppTheme.foreground)

              Text(String(format: loc.t("home.hero.stock_summary"), Int64(totalStock)))
                .font(AppTheme.sansFont(size: 13))
                .foregroundColor(AppTheme.mutedText)
            }
          }
        }
      }
      .padding(20)
      .glassmorphic()
    }
    .buttonStyle(TilePressButtonStyle())
  }

  // MARK: - Quick Action 3-Column Vertical Tiles
  private var quickActionTilesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(loc.t("home.section.actions"))
        .font(AppTheme.serifFont(size: 20, weight: .semibold))
        .foregroundColor(AppTheme.foreground)

      HStack(spacing: 12) {
        // Tile 1: Restock
        ActionTileButton(
          title: loc.t("home.quickActions.restock_title"),
          subtitle: loc.t("home.quickActions.restock_sub"),
          icon: "leaf.fill",
          color: AppTheme.inventory
        ) {
          hapticManager.impact(style: .light)
          selection = 1
        }

        // Tile 2: Smart AI Design
        ActionTileButton(
          title: loc.t("home.quickActions.design_title"),
          subtitle: loc.t("home.quickActions.design_sub"),
          icon: "wand.and.stars",
          color: AppTheme.aiDesign
        ) {
          hapticManager.impact(style: .light)
          selection = 2
        }

        // Tile 3: New Order
        ActionTileButton(
          title: loc.t("home.quickActions.order_title"),
          subtitle: loc.t("home.quickActions.order_sub"),
          icon: "shippingbox.fill",
          color: AppTheme.primary
        ) {
          hapticManager.impact(style: .light)
          selection = 3
        }
      }
    }
  }

  // MARK: - Studio Health KPI Row
  private var studioHealthPillsRow: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        Spacer().frame(width: 12)

        Button {
          hapticManager.impact(style: .light)
          showInventoryAnalytics = true
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "cart.fill")
              .foregroundColor(AppTheme.inventory)
            Text("\(totalStock)")
              .font(AppTheme.sansFont(size: 15, weight: .bold))
              .foregroundColor(AppTheme.foreground)
            Text(Tx.t("home.stats.stockUnit"))
              .font(AppTheme.captionSmall)
              .foregroundColor(AppTheme.mutedText)
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .glassmorphic()
        }
        .buttonStyle(.plain)

        Button {
          hapticManager.impact(style: .light)
          showNotifications = true
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(lowStockCount > 0 ? AppTheme.danger : AppTheme.success)
            Text("\(lowStockCount)")
              .font(AppTheme.sansFont(size: 15, weight: .bold))
              .foregroundColor(lowStockCount > 0 ? AppTheme.danger : AppTheme.foreground)
            Text(Tx.t("home.stats.shortageUnit"))
              .font(AppTheme.captionSmall)
              .foregroundColor(AppTheme.mutedText)
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .glassmorphic()
        }
        .buttonStyle(.plain)

        Button {
          hapticManager.impact(style: .light)
          showRevenueAnalytics = true
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "dollarsign.circle.fill")
              .foregroundColor(AppTheme.revenue)
            Text(CurrencyFormat.compact(totalRevenue))
              .font(AppTheme.sansFont(size: 15, weight: .bold))
              .foregroundColor(AppTheme.foreground)
            Text(Tx.t("home.stats.revenueTitle"))
              .font(AppTheme.captionSmall)
              .foregroundColor(AppTheme.mutedText)
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .glassmorphic()
        }
        .buttonStyle(.plain)

        Spacer().frame(width: 12)
      }
    }
  }

  // MARK: - Editorial Floral Lookbook
  private var recentLookbookSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(loc.t("home.section.recent_designs"))
            .font(AppTheme.serifFont(size: 20, weight: .semibold))
            .foregroundColor(AppTheme.foreground)
          Text(loc.t("home.section.gallery_subtitle"))
            .font(AppTheme.sansFont(size: 13))
            .foregroundColor(AppTheme.mutedText)
        }
        Spacer()
        Button {
          hapticManager.impact(style: .light)
          selection = 3 // Jump to Archive inside Hub
        } label: {
          Image(systemName: "arrow.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(AppTheme.primary)
            .frame(width: 32, height: 32)
            .background(AppTheme.primary.opacity(0.1))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 24)

      if recentDesigns.isEmpty {
        VStack(spacing: 14) {
          Image(systemName: "sparkles")
            .font(.system(size: 36))
            .foregroundColor(AppTheme.accent)
          Text(loc.t("home.recentDesigns.empty"))
            .font(AppTheme.sansFont(size: 14))
            .foregroundColor(AppTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .glassmorphic()
        .padding(.horizontal, 24)
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 16) {
            Spacer().frame(width: 8)
            ForEach(recentDesigns) { design in
              NavigationLink(destination: DesignDetailView(design: design)) {
                EditorialLookbookCard(design: design)
              }
              .buttonStyle(PlainButtonStyle())
            }
            Spacer().frame(width: 8)
          }
        }
      }
    }
  }
}
