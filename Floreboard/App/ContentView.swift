import SwiftUI

struct ContentView: View {
  @StateObject private var authService = AuthService.shared
  @StateObject private var localizationManager = LocalizationManager.shared
  @State private var selection = 0

  var body: some View {
    Group {
      if authService.isAuthenticated {
        TabView(selection: $selection) {
          HomeView(selection: $selection)
            .tabItem {
              Label(localizationManager.t("app.nav.dashboard"), systemImage: "square.grid.2x2")
            }
            .tag(0)

          InventoryView()
            .tabItem {
              Label(localizationManager.t("app.nav.inventory"), systemImage: "leaf.fill")
            }
            .tag(1)

          HistoryView(onStartDesign: {
            HapticManager.shared.impact(style: .light)
            selection = 3
          })
            .tabItem {
              Label(localizationManager.t("app.nav.history"), systemImage: "clock.arrow.circlepath")
            }
            .tag(2)

          DesignMainView()
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
    .tint(AppTheme.primary)
  }
}
