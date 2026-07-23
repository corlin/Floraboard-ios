import SwiftUI

struct HomeView: View {
  @Binding var selection: Int
  @Binding var inventorySearchText: String
  @EnvironmentObject var auth: AuthService
  @EnvironmentObject var loc: LocalizationManager
  @EnvironmentObject var inventoryService: InventoryService
  @EnvironmentObject var historyService: HistoryService
  @Environment(\.hapticManager) var hapticManager
  @State private var showNotifications = false
  @State private var showInventoryAnalytics = false
  @State private var showRevenueAnalytics = false

  init(selection: Binding<Int>, inventorySearchText: Binding<String> = .constant("")) {
    self._selection = selection
    self._inventorySearchText = inventorySearchText
  }

  // Computed Stats
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
          VStack(alignment: .leading, spacing: 32) {
            // Hero Welcome
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "leaf.fill")
                  .foregroundColor(AppTheme.primary)
                Text("Petal & Bloom")
                  .font(AppTheme.sansFont(size: 15, weight: .semibold))
                  .foregroundColor(AppTheme.primary)
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
              .padding(.bottom, 16)

              HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                  Text(loc.t("home.greeting", ["name": auth.currentTenant?.name ?? "Sarah"]))
                    .font(AppTheme.serifFont(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.titleGradient)
                }
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                  .font(AppTheme.sansFont(size: 14, weight: .medium))
                  .foregroundColor(AppTheme.mutedText)
              }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Quick Stats Row (Overview)
            VStack(alignment: .leading, spacing: 16) {
              Text(loc.t("home.section.overview"))
                .font(AppTheme.serifFont(size: 22, weight: .semibold))
                .foregroundColor(AppTheme.foreground)
                .padding(.horizontal, 24)

              ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                  Spacer().frame(width: 8)
                  Button {
                    hapticManager.impact(style: .light)
                    showInventoryAnalytics = true
                  } label: {
                    StatCard(
                      title: loc.t("home.stats.inventoryOverview"),
                      value: "\(inventoryService.flowers.count)",
                      subValue: "Total: \(totalStock)",
                      icon: "cart",
                      color: AppTheme.inventory,
                      trend: nil
                    )
                  }
                  .buttonStyle(.plain)

                  Button {
                    hapticManager.impact(style: .light)
                    showNotifications = true
                  } label: {
                    StatCard(
                      title: loc.t("home.stats.stockAlert"),
                      value: "\(lowStockCount)",
                      subValue: loc.t("home.stats.card.lowStock"),
                      icon: "clock",
                      color: lowStockCount > 0 ? AppTheme.danger : AppTheme.success,
                      trend: nil
                    )
                  }
                  .buttonStyle(.plain)

                  Button {
                    hapticManager.impact(style: .light)
                    showRevenueAnalytics = true
                  } label: {
                    StatCard(
                      title: loc.t("home.stats.revenue"),
                      value: CurrencyFormat.compact(totalRevenue),
                      subValue: loc.t("home.stats.total_revenue"),
                      icon: "dollarsign.circle",
                      color: AppTheme.revenue,
                      trend: nil
                    )
                  }
                  .buttonStyle(.plain)
                  Spacer().frame(width: 8)
                }
              }
            }

            // Quick Actions (Modernized)
            VStack(alignment: .leading, spacing: 16) {
              Text(loc.t("home.section.actions"))
                .font(AppTheme.serifFont(size: 22, weight: .semibold))
                .foregroundColor(AppTheme.foreground)
                .padding(.horizontal, 24)

              HStack(spacing: 16) {
                Button {
                  hapticManager.impact(style: .light)
                  selection = 1
                } label: {
                  QuickActionCard(
                    title: loc.t("home.quickActions.addInventory"),
                    icon: "plus",
                    color: AppTheme.inventory
                  )
                }
                .buttonStyle(.plain)

                Button {
                  hapticManager.impact(style: .light)
                  selection = 2
                } label: {
                  QuickActionCard(
                    title: loc.t("home.quickActions.smartDesign"),
                    icon: "wand.and.stars",
                    color: AppTheme.aiDesign
                  )
                }
                .buttonStyle(.plain)
              }
              .padding(.horizontal, 24)
            }

            // Recent Activity Gallery
            VStack(alignment: .leading, spacing: 16) {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.t("home.section.recent_designs"))
                      .font(AppTheme.serifFont(size: 22, weight: .semibold))
                      .foregroundColor(AppTheme.foreground)
                    Text(loc.t("home.section.gallery_subtitle"))
                        .font(AppTheme.sansFont(size: 14))
                        .foregroundColor(AppTheme.mutedText)
                }
                Spacer()
                Button {
                  hapticManager.impact(style: .light)
                  selection = 3
                } label: {
                  Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
              }
              .padding(.horizontal, 24)

              if recentDesigns.isEmpty {
                VStack(spacing: 16) {
                  Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.accent)
                  Text(loc.t("home.recentDesigns.empty"))
                    .font(AppTheme.sansFont(size: 15))
                    .foregroundColor(AppTheme.mutedText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .glassmorphic()
                .padding(.horizontal, 24)
              } else {
                ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: 20) {
                    Spacer().frame(width: 4)
                    ForEach(recentDesigns) { design in
                      NavigationLink(destination: DesignDetailView(design: design)) {
                        DesignGalleryCard(design: design)
                      }
                      .buttonStyle(PlainButtonStyle())
                    }
                    Spacer().frame(width: 4)
                  }
                }
              }
            }
          }
          .padding(.bottom, 100)
        }
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
}

// MARK: - Components

struct StatCard: View {
  let title: String
  let value: String
  let subValue: String
  let icon: String
  let color: Color
  let trend: String?

  var body: some View {
    HStack(spacing: 0) {
      // Colored left bar
      RoundedRectangle(cornerRadius: 2)
        .fill(color)
        .frame(width: 4)
        .padding(.vertical, 8)

      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text(title)
            .font(AppTheme.sansFont(size: 14, weight: .medium))
            .foregroundColor(AppTheme.foreground.opacity(0.8))
          Spacer()
          Image(systemName: icon)
            .foregroundColor(color)
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 28, height: 28)
            .background(color.opacity(0.15))
            .clipShape(Circle())
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(value)
            .font(AppTheme.sansFont(size: 28, weight: .bold))
            .foregroundColor(AppTheme.foreground)

          HStack {
              if let trend = trend {
                  Text(trend)
                      .font(AppTheme.sansFont(size: 12, weight: .semibold))
                      .foregroundColor(color)
              } else {
                  Text(subValue)
                      .font(AppTheme.sansFont(size: 12, weight: .medium))
                      .foregroundColor(color)
              }
          }
        }
      }
      .padding(.leading, 12)
    }
    .frame(width: 150)
    .padding(16)
    .glassmorphic()
  }
}

struct QuickActionCard: View {
  let title: String
  let icon: String
  let color: Color

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.system(size: 20, weight: .semibold))
        .foregroundColor(color)
        .frame(width: 44, height: 44)
        .background(color.opacity(0.15))
        .clipShape(Circle())

      Text(title)
        .font(AppTheme.sansFont(size: 16, weight: .semibold))
        .foregroundColor(AppTheme.foreground)
        .lineLimit(2)

      Spacer()
    }
    .padding(16)
    .frame(maxWidth: .infinity)
    .glassmorphic()
  }
}

struct DesignGalleryCard: View {
  let design: DesignResult

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Thumbnail
      GalleryThumbnail(path: design.imageUrl)

      // Content
      VStack(alignment: .leading, spacing: 6) {
        HStack {
            Text(design.title)
              .font(AppTheme.sansFont(size: 16, weight: .bold))
              .foregroundColor(AppTheme.foreground)
              .lineLimit(1)
            Spacer()
            Text(CurrencyFormat.compact(design.totalCost))
              .font(AppTheme.sansFont(size: 15, weight: .bold))
              .foregroundColor(AppTheme.foreground)
        }

        Text(Tx.t("home.card.designer_role"))
            .font(AppTheme.sansFont(size: 12))
            .foregroundColor(AppTheme.mutedText)

        Divider()
            .padding(.vertical, 4)

        HStack {
            VStack(alignment: .center, spacing: 2) {
                Text("42")
                    .font(AppTheme.sansFont(size: 13, weight: .bold))
                Text(Tx.t("home.card.orders"))
                    .font(AppTheme.sansFont(size: 11))
                    .foregroundColor(AppTheme.mutedText)
            }
            Spacer()
            VStack(alignment: .center, spacing: 2) {
                Text("5 􀋙")
                    .font(AppTheme.sansFont(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.warning)
                Text(Tx.t("home.card.stars"))
                    .font(AppTheme.sansFont(size: 11))
                    .foregroundColor(AppTheme.mutedText)
            }
            Spacer()
            VStack(alignment: .center, spacing: 2) {
                Text("1.2k")
                    .font(AppTheme.sansFont(size: 13, weight: .bold))
                Text(Tx.t("home.card.likes"))
                    .font(AppTheme.sansFont(size: 11))
                    .foregroundColor(AppTheme.mutedText)
            }
        }
      }
      .padding(16)
    }
    .frame(width: 240)
    .glassmorphic()
  }
}

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
          .frame(height: 180)
          .clipped()
      } else {
        Rectangle()
          .fill(AppTheme.primary.opacity(0.08))
          .frame(height: 180)
          .overlay(
            Image(systemName: "photo.on.rectangle")
              .font(.system(size: 30))
              .foregroundColor(AppTheme.primary.opacity(0.3))
          )
      }
    }
    .overlay(alignment: .topTrailing) {
        Image(systemName: "heart")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .padding(12)
            .shadow(color: .black.opacity(0.3), radius: 3)
    }
    .task {
      if let p = path, !p.hasPrefix("http") {
        self.image = imagePersistence.loadImage(named: p)
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
                        Image(systemName: "chevron.right")
                          .font(.caption)
                          .foregroundColor(AppTheme.mutedText)
                      }
                      .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    
                    if item.id != lowStockItems.last?.id {
                      Divider().background(Color.white.opacity(0.1))
                    }
                  }
                }
                .padding(.top, 8)
                
                Button(action: { onGoToInventory(lowStockItems.first?.name) }) {
                  Text(loc.t("home.notifications.replenish"))
                    .font(AppTheme.sansFont(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary)
                    .cornerRadius(AppTheme.containerRadius)
                }
                .padding(.top, 16)
              }
              .padding(20)
              .frame(maxWidth: .infinity, alignment: .leading)
              .glassmorphic()
              .overlay(
                RoundedRectangle(cornerRadius: AppTheme.containerRadius)
                  .stroke(AppTheme.danger.opacity(0.3), lineWidth: 1)
              )
            }
          }
          .padding()
        }
      }
      .navigationTitle(loc.t("home.notifications.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(loc.t("common.done")) {
            dismiss()
          }
          .fontWeight(.semibold)
          .foregroundColor(AppTheme.primary)
        }
      }
    }
    .presentationDetents([.medium, .large])
  }
}

