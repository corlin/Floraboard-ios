import SwiftUI

struct HomeView: View {
  @Binding var selection: Int
  @EnvironmentObject var auth: AuthService
  @EnvironmentObject var loc: LocalizationManager
  @EnvironmentObject var inventoryService: InventoryService
  @EnvironmentObject var historyService: HistoryService
  @Environment(\.hapticManager) var hapticManager

  // Computed Stats
  var totalStock: Int {
    inventoryService.flowers.reduce(0) { $0 + $1.quantity }
  }

  var lowStockCount: Int {
    inventoryService.flowers.filter { $0.quantity < 10 }.count
  }

  var totalRevenue: Double {
    historyService.savedDesigns.reduce(0) { $0 + $1.totalCost }  // Using totalCost as proxy for revenue, or profit logic if available
  }

  var recentDesigns: [DesignResult] {
    Array(historyService.savedDesigns.prefix(5))
  }

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.premiumGradient.ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            // Welcome Header
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(loc.t("home.greeting", ["name": auth.currentTenant?.name ?? "Florist"]))
                  .font(AppTheme.sansFont(size: 16, weight: .medium))
                  .foregroundColor(AppTheme.foreground.opacity(0.7))
                Text(auth.currentTenant?.name ?? "Floreboard")
                  .font(AppTheme.serifFont(size: 32, weight: .bold))
                  .foregroundColor(AppTheme.foreground)
                Text(
                  loc.t(
                    "home.subtitle", ["date": Date().formatted(date: .abbreviated, time: .omitted)])
                )
                .font(AppTheme.sansFont(size: 14))
                .foregroundColor(AppTheme.mutedText)
              }
              Spacer()

              Button {
                hapticManager.impact(style: .light)
                selection = 3
              } label: {
                Image(systemName: "wand.and.stars")
                  .font(.system(size: 20))
                  .foregroundColor(AppTheme.iconOnAccent)
                  .padding(12)
                  .background(Circle().fill(AppTheme.primary))
                  .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
              }
              .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 20)

            // Quick Stats Grid
            LazyVGrid(
              columns: [GridItem(.adaptive(minimum: 108), spacing: 12)],
              spacing: 12
            ) {
              StatCard(
                title: loc.t("home.stats.inventoryOverview"),
                value: "\(inventoryService.flowers.count)",
                subValue: "\(totalStock) " + loc.t("home.stats.itemCount"),
                icon: "leaf.fill",
                color: AppTheme.inventory
              )

              StatCard(
                title: loc.t("home.stats.stockAlert"),
                value: "\(lowStockCount)",
                subValue: loc.t("home.stats.card.lowStock"),
                icon: "exclamationmark.triangle.fill",
                color: lowStockCount > 0 ? AppTheme.danger : AppTheme.success
              )

              StatCard(
                title: loc.t("home.stats.revenue"),
                value: CurrencyFormat.compact(totalRevenue),
                subValue: "\(recentDesigns.count) "
                  + loc.t("home.stats.designCount", ["count": ""]),  // Need to handle plurals or just append text? For now just append generic
                icon: "yensign.circle.fill",
                color: AppTheme.revenue
              )
            }
            .padding(.horizontal)

            // Quick Actions & Inspiration
            VStack(alignment: .leading, spacing: 16) {
              Text(loc.t("home.quickActions.title"))
                .font(AppTheme.serifFont(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.foreground)
                .padding(.horizontal)

              HStack(spacing: 12) {
                Button {
                  hapticManager.impact(style: .light)
                  selection = 1
                } label: {
                  QuickActionCard(
                    title: loc.t("home.quickActions.addInventory"),
                    icon: "plus.circle.fill",
                    color: AppTheme.inventory
                  )
                }
                .buttonStyle(.plain)

                Button {
                  hapticManager.impact(style: .light)
                  selection = 3
                } label: {
                  QuickActionCard(
                    title: loc.t("home.quickActions.smartDesign"),
                    icon: "sparkles",
                    color: AppTheme.aiDesign
                  )
                }
                .buttonStyle(.plain)
              }
              .padding(.horizontal)

              // Inspiration Box
              HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.max.fill")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundColor(AppTheme.accent)
                  .frame(width: 30, height: 30)
                  .background(AppTheme.accent.opacity(0.12))
                  .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                  Text(loc.t("home.quickActions.inspirationTitle"))
                    .font(AppTheme.sansFont(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.primary)
                  Text(loc.t("home.quickActions.inspirationText"))
                    .font(AppTheme.sansFont(size: 12))
                    .foregroundColor(AppTheme.mutedText)
                    .lineLimit(nil)
                }
              }
              .padding()
              .glassmorphic()
              .padding(.horizontal)
            }

            // Recent Activity
            VStack(alignment: .leading, spacing: 16) {
              HStack {
                Text(loc.t("home.recentDesigns.title"))
                  .font(AppTheme.serifFont(size: 20, weight: .semibold))
                  .foregroundColor(AppTheme.foreground)
                Spacer()
                Button {
                  hapticManager.impact(style: .light)
                  selection = 2
                } label: {
                  Text(loc.t("home.recentDesigns.viewAll"))
                    .font(AppTheme.sansFont(size: 14))
                    .foregroundColor(AppTheme.primary)
                }
                .buttonStyle(.plain)
              }
              .padding(.horizontal)

              if recentDesigns.isEmpty {
                VStack(spacing: 12) {
                  Image(systemName: "photo.on.rectangle")
                    .font(.largeTitle)
                    .foregroundColor(AppTheme.mutedText.opacity(0.45))
                  Text(loc.t("home.recentDesigns.empty"))
                    .font(AppTheme.sansFont(size: 14))
                    .foregroundColor(AppTheme.mutedText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .glassmorphic()
                .padding(.horizontal)
              } else {
                VStack(spacing: 12) {
                  ForEach(recentDesigns) { design in
                    NavigationLink(destination: DesignDetailView(design: design)) {
                      // Compact Row
                      HStack(spacing: 12) {
                        // Thumbnail
                        CompactThumbnail(path: design.imageUrl)

                        VStack(alignment: .leading, spacing: 4) {
                          Text(design.title)
                            .font(AppTheme.sansFont(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.foreground)
                            .lineLimit(1)
                          Text(
                            Date(timeIntervalSince1970: design.createdAt).formatted(
                              date: .numeric, time: .omitted)
                          )
                          .font(AppTheme.sansFont(size: 12))
                          .foregroundColor(AppTheme.mutedText)
                        }

                        Spacer()

                        Text(CurrencyFormat.compact(design.totalCost))
                          .font(AppTheme.sansFont(size: 14, weight: .bold))
                          .foregroundColor(AppTheme.primary)

                        Image(systemName: "chevron.right")
                          .font(.caption)
                          .foregroundColor(AppTheme.mutedText.opacity(0.5))
                      }
                      .padding(12)
                      .glassmorphic()
                    }
                    .buttonStyle(PlainButtonStyle())
                  }
                }
                .padding(.horizontal)
              }
            }
          }
          .padding(.bottom, 40)
        }
      }
      .toolbar(.hidden, for: .navigationBar)
    }
  }
}

struct StatCard: View {
  let title: String
  let value: String
  let subValue: String
  let icon: String
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: icon)
          .foregroundColor(color)
          .font(.system(size: 18))
        Spacer()
      }

      Text(value)
        .font(AppTheme.sansFont(size: 22, weight: .bold))
        .foregroundColor(AppTheme.foreground)
        .minimumScaleFactor(0.8)

      VStack(alignment: .leading, spacing: 2) {
        Text(subValue)
          .font(AppTheme.sansFont(size: 10))
          .foregroundColor(AppTheme.mutedText)
        Text(title)
          .font(AppTheme.sansFont(size: 10))
          .foregroundColor(AppTheme.mutedText)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(12)
    .background(AppTheme.surfaceElevated)
    .cornerRadius(AppTheme.cardRadius)
    .overlay(
      RoundedRectangle(cornerRadius: AppTheme.cardRadius)
        .stroke(AppTheme.hairline, lineWidth: 1)
    )
    .shadow(color: AppTheme.shadow.opacity(0.6), radius: 5, x: 0, y: 2)
  }
}

struct QuickActionCard: View {
  let title: String
  let icon: String
  let color: Color

  var body: some View {
    HStack {
      Image(systemName: icon)
        .font(.title3)
        .foregroundColor(color)
        .frame(width: 20, height: 20)
        .padding(10)
        .background(color.opacity(0.1))
        .clipShape(Circle())

      Text(title)
        .font(AppTheme.sansFont(size: 14, weight: .medium))
        .foregroundColor(AppTheme.foreground)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)

      Spacer()
    }
    .padding()
    .frame(maxWidth: .infinity, minHeight: 64)
    .glassmorphic()
    .contentShape(Rectangle())
  }
}

struct CompactThumbnail: View {
  let path: String?
  @Environment(\.imagePersistence) var imagePersistence
  @State private var image: UIImage?

  var body: some View {
    Group {
      if let img = image {
        Image(uiImage: img)
          .resizable()
          .scaledToFill()
          .frame(width: 40, height: 40)
          .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius))
      } else {
        RoundedRectangle(cornerRadius: AppTheme.controlRadius)
          .fill(AppTheme.primary.opacity(0.1))
          .frame(width: 40, height: 40)
          .overlay(Image(systemName: "leaf").font(.caption))  // Replaced flower
      }
    }
    .task {
      if let p = path, !p.hasPrefix("http") {
        let loaded = await Task.detached { [imagePersistence] in
          imagePersistence.loadImage(named: p)
        }.value
        self.image = loaded
      }
    }
  }
}
