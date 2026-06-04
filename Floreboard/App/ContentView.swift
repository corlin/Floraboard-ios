import SwiftUI

struct ContentView: View {
  @EnvironmentObject var authService: AuthService
  @EnvironmentObject var localizationManager: LocalizationManager
  @Environment(\.hapticManager) var hapticManager
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

          DesignMainView()
            .tabItem {
              Label(localizationManager.t("app.nav.design"), systemImage: "wand.and.stars")
            }
            .tag(2)

          HistoryView(onStartDesign: {
            hapticManager.impact(style: .light)
            selection = 2
          })
            .tabItem {
              Label(localizationManager.t("app.nav.history"), systemImage: "clock.arrow.circlepath")
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
