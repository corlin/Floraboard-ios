//
//  ContentView.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var authService = AuthService.shared
  @StateObject private var localizationManager = LocalizationManager.shared
  @State private var selection = 0

  var body: some View {
    Group {
      if authService.isAuthenticated {
        TabView(selection: $selection) {
          HomeView()
            .tabItem {
              Label(localizationManager.t("app.nav.dashboard"), systemImage: "square.grid.2x2")
            }
            .tag(0)

          InventoryView()
            .tabItem {
              Label(localizationManager.t("app.nav.inventory"), systemImage: "leaf.fill")
            }
            .tag(1)

          HistoryView()
            .tabItem {
              Label(localizationManager.t("app.nav.history"), systemImage: "clock.arrow.circlepath")
            }
            .tag(2)

          DesignView()
            .tabItem {
              Label(localizationManager.t("app.nav.design"), systemImage: "wand.and.stars")
            }
            .tag(3)

          SettingsView()
            .tabItem {
              Label(localizationManager.t("app.nav.settings"), systemImage: "gear")
            }
            .tag(4)
        }
      } else {
        LoginView()
      }
    }
  }
}

struct LoginView: View {
  @State private var storeName = ""
  @State private var isLoading = false

  var body: some View {
    ZStack {
      AppTheme.premiumGradient.ignoresSafeArea()

      VStack(spacing: 30) {
        Image(systemName: "leaf.fill")  // Replaced flower.fill
          .resizable()
          .scaledToFit()
          .frame(width: 80, height: 80)
          .foregroundStyle(AppTheme.primary)
          .padding()
          .background(Color.white.opacity(0.5))
          .clipShape(Circle())
          .shadow(color: AppTheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)

        Text("Floreboard")
          .font(AppTheme.serifFont(size: 40, weight: .bold))
          .foregroundColor(AppTheme.foreground)

        VStack(spacing: 16) {
          TextField(Tx.t("login.storeName"), text: $storeName)
            .padding()
            .background(Color.white.opacity(0.6))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 1))

          Button(action: login) {
            if isLoading {
              ProgressView().tint(.white)
            } else {
              Text(Tx.t("login.enter"))
                .font(AppTheme.sansFont(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding()
            }
          }
          .buttonStyle(PrimaryButtonStyle())
          .disabled(storeName.isEmpty || isLoading)
        }
        .padding(30)
        .glassmorphic()
        .padding(.horizontal)
      }
    }
    .onTapGesture {
      hideKeyboard()
    }
  }

  func login() {
    isLoading = true
    Task {
      _ = await AuthService.shared.login(storeName: storeName)
      isLoading = false
    }
  }
}

// MARK: - Home View

struct HomeView: View {
  @StateObject private var auth = AuthService.shared
  @StateObject private var loc = LocalizationManager.shared
  @StateObject private var inventoryService = InventoryService.shared
  @StateObject private var historyService = HistoryService.shared

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
    NavigationView {
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
                .foregroundColor(AppTheme.secondary)
              }
              Spacer()

              NavigationLink(destination: DesignView()) {
                Image(systemName: "wand.and.stars")
                  .font(.system(size: 20))
                  .foregroundColor(.white)
                  .padding(12)
                  .background(Circle().fill(AppTheme.primary))
                  .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
              }
            }
            .padding(.horizontal)
            .padding(.top, 20)

            // Quick Stats Grid
            LazyVGrid(
              columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
              spacing: 12
            ) {
              StatCard(
                title: loc.t("home.stats.inventoryOverview"),
                value: "\(inventoryService.flowers.count)",
                subValue: "\(totalStock) " + loc.t("home.stats.itemCount"),
                icon: "leaf.fill",
                color: AppTheme.secondary
              )

              StatCard(
                title: loc.t("home.stats.stockAlert"),
                value: "\(lowStockCount)",
                subValue: loc.t("home.stats.card.lowStock"),
                icon: "exclamationmark.triangle.fill",
                color: lowStockCount > 0 ? .red : .green
              )

              StatCard(
                title: loc.t("home.stats.revenue"),
                value: "¥\(Int(totalRevenue))",
                subValue: "\(recentDesigns.count) "
                  + loc.t("home.stats.designCount", ["count": ""]),  // Need to handle plurals or just append text? For now just append generic
                icon: "yensign.circle.fill",
                color: Color.orange
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
                NavigationLink(destination: InventoryView()) {
                  QuickActionCard(
                    title: loc.t("home.quickActions.addInventory"),
                    icon: "plus.circle.fill",
                    color: .blue
                  )
                }

                NavigationLink(destination: DesignView()) {
                  QuickActionCard(
                    title: loc.t("home.quickActions.smartDesign"),
                    icon: "sparkles",
                    color: .purple
                  )
                }
              }
              .padding(.horizontal)

              // Inspiration Box
              HStack(alignment: .top, spacing: 12) {
                Text("💡")
                  .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                  Text(loc.t("home.quickActions.inspirationTitle"))
                    .font(AppTheme.sansFont(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.primary)
                  Text(loc.t("home.quickActions.inspirationText"))
                    .font(AppTheme.sansFont(size: 12))
                    .foregroundColor(AppTheme.secondary)
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
                NavigationLink(destination: HistoryView()) {
                  Text(loc.t("home.recentDesigns.viewAll"))
                    .font(AppTheme.sansFont(size: 14))
                    .foregroundColor(AppTheme.primary)
                }
              }
              .padding(.horizontal)

              if recentDesigns.isEmpty {
                VStack(spacing: 12) {
                  Image(systemName: "photo.on.rectangle")
                    .font(.largeTitle)
                    .foregroundColor(.secondary.opacity(0.5))
                  Text(loc.t("home.recentDesigns.empty"))
                    .font(AppTheme.sansFont(size: 14))
                    .foregroundColor(.secondary)
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
                          .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("¥\(Int(design.totalCost))")
                          .font(AppTheme.sansFont(size: 14, weight: .bold))
                          .foregroundColor(AppTheme.primary)

                        Image(systemName: "chevron.right")
                          .font(.caption)
                          .foregroundColor(.secondary.opacity(0.5))
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
      .navigationBarHidden(true)
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
          .foregroundColor(AppTheme.secondary)
        Text(title)
          .font(AppTheme.sansFont(size: 10))
          .foregroundColor(AppTheme.foreground.opacity(0.5))
          .lineLimit(1)
      }
    }
    .padding(12)
    .background(Color.white.opacity(0.6))
    .cornerRadius(16)
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color.white.opacity(0.5), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
        .padding(10)
        .background(color.opacity(0.1))
        .clipShape(Circle())

      Text(title)
        .font(AppTheme.sansFont(size: 14, weight: .medium))
        .foregroundColor(AppTheme.foreground)

      Spacer()
    }
    .padding()
    .glassmorphic()
  }
}

struct CompactThumbnail: View {
  let path: String?
  @State private var image: UIImage?

  var body: some View {
    Group {
      if let img = image {
        Image(uiImage: img)
          .resizable()
          .scaledToFill()
          .frame(width: 40, height: 40)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      } else {
        RoundedRectangle(cornerRadius: 8)
          .fill(AppTheme.primary.opacity(0.1))
          .frame(width: 40, height: 40)
          .overlay(Image(systemName: "leaf").font(.caption))  // Replaced flower
      }
    }
    .onAppear {
      if let p = path, !p.hasPrefix("http") {
        image = ImagePersistence.shared.loadImage(named: p)
      }
    }
  }
}
