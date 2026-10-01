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

// MARK: - Action Tile Button (3-Column Vertical Layout)

struct ActionTileButton: View {
  let title: String
  let subtitle: String
  let icon: String
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        ZStack {
          Circle()
            .fill(color.opacity(0.14))
            .frame(width: 44, height: 44)
          Image(systemName: icon)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(color)
        }

        Text(title)
          .font(AppTheme.sansFont(size: 14, weight: .bold))
          .foregroundColor(AppTheme.foreground)
          .lineLimit(1)

        Text(subtitle)
          .font(AppTheme.sansFont(size: 11, weight: .medium))
          .foregroundColor(AppTheme.mutedText)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .padding(.horizontal, 4)
      .glassmorphic()
    }
    .buttonStyle(TilePressButtonStyle())
  }
}

// MARK: - Tile Press Button Style

struct TilePressButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

// MARK: - Editorial Lookbook Card

struct EditorialLookbookCard: View {
  let design: DesignResult
  @Environment(\.imagePersistence) var imagePersistence

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // High-res visual banner with badge
      ZStack(alignment: .topTrailing) {
        GalleryThumbnail(path: design.imageUrl)
          .frame(width: 250, height: 165)
          .clipped()

        // Stems count pill
        let totalStems = design.flowerList.reduce(0) { $0 + $1.count }
        HStack(spacing: 4) {
          Image(systemName: "leaf.fill")
            .font(.system(size: 9))
          Text(Tx.t("home.stats.stemsSelected", ["count": "\(totalStems > 0 ? totalStems : design.flowerList.count)"]))
            .font(AppTheme.captionSmall)
            .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .foregroundColor(Color.white)
        .padding(8)
      }
      .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))

      // Editorial Details
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline) {
          Text(design.title)
            .font(AppTheme.serifFont(size: 16, weight: .bold))
            .foregroundColor(AppTheme.foreground)
            .lineLimit(1)

          Spacer()

          Text(CurrencyFormat.compact(design.totalCost))
            .font(AppTheme.serifFont(size: 16, weight: .bold))
            .foregroundColor(AppTheme.primary)
        }

        if !design.meaningText.isEmpty {
          Text(design.meaningText)
            .font(AppTheme.serifFont(size: 12).italic())
            .foregroundColor(AppTheme.mutedText)
            .lineLimit(1)
        }
      }
      .padding(14)
    }
    .frame(width: 250)
    .glassmorphic()
  }
}

// MARK: - Gallery Thumbnail

struct GalleryThumbnail: View {
  let path: String?
  @Environment(\.imagePersistence) var imagePersistence
  @State private var image: UIImage?

  var body: some View {
    Group {
      if let img = image {
        Image(uiImage: img)
          .resizable()
          .scaledToFill()
      } else {
        Rectangle()
          .fill(AppTheme.primary.opacity(0.08))
          .overlay(
            Image(systemName: "photo.on.rectangle")
              .font(.system(size: 28))
              .foregroundColor(AppTheme.primary.opacity(0.3))
          )
      }
    }
    .task {
      // 支持本地文件名和远程 URL（带磁盘缓存）
      if let p = path, !p.isEmpty {
        self.image = await imagePersistence.loadImageAsync(namedOrURL: p)
      }
    }
  }
}

// MARK: - Notifications

struct NotificationSheetView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var loc: LocalizationManager
  let lowStockItems: [FlowerType]
  let onGoToInventory: (String?) -> Void

  var body: some View {
    NavigationStack {
      ZStack {
        PremiumBackgroundView()

        ScrollView {
          VStack(spacing: 16) {
            if lowStockItems.isEmpty {
              VStack(spacing: 16) {
                Image(systemName: "bell.badge.slash")
                  .font(.system(size: 48))
                  .foregroundColor(AppTheme.success)
                Text(loc.t("home.notifications.empty"))
                  .font(AppTheme.serifFont(size: 20, weight: .bold))
                  .foregroundColor(AppTheme.foreground)
                Text(loc.t("home.notifications.emptyDesc"))
                  .font(AppTheme.sansFont(size: 14))
                  .foregroundColor(AppTheme.mutedText)
                  .multilineTextAlignment(.center)
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 60)
              .glassmorphic()
            } else {
              VStack(alignment: .leading, spacing: 16) {
                HStack {
                  Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.danger)
                  Text(loc.t("home.notifications.alert"))
                    .font(AppTheme.sansFont(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.foreground)
                }

                Text(loc.t("home.notifications.lowStock", ["count": "\(lowStockItems.count)"]))
                  .font(AppTheme.sansFont(size: 14))
                  .foregroundColor(AppTheme.mutedText)
                  .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                  ForEach(lowStockItems) { item in
                    Button {
                      onGoToInventory(item.name)
                    } label: {
                      HStack {
                        Text(item.name)
                          .font(AppTheme.sansFont(size: 16, weight: .medium))
                          .foregroundColor(AppTheme.foreground)
                        Spacer()
                        Text(loc.t("home.notifications.only_left", ["count": "\(item.quantity)"]))
                          .font(AppTheme.sansFont(size: 14, weight: .bold))
                          .foregroundColor(AppTheme.danger)
                      }
                      .padding()
                      .background(AppTheme.surfaceGlass)
                      .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                  }
                }

                Button {
                  onGoToInventory(nil)
                } label: {
                  Text(loc.t("home.notifications.replenish"))
                    .font(AppTheme.sansFont(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                }
                .padding(.top, 8)
              }
              .padding(20)
              .glassmorphic()
            }
          }
          .padding(24)
        }
      }
      .navigationTitle(loc.t("home.notifications.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(loc.t("general.close")) {
            dismiss()
          }
          .foregroundColor(AppTheme.primary)
        }
      }
    }
  }
}
