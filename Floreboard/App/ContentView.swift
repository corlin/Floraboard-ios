import SwiftUI

struct ContentView: View {
  @EnvironmentObject var authService: AuthService
  @EnvironmentObject var localizationManager: LocalizationManager
  @Environment(\.hapticManager) var hapticManager
  @State private var selection = 0
  @State private var inventorySearchText = ""

  var body: some View {
    Group {
      if authService.isAuthenticated {
        ZStack(alignment: .bottom) {
          // Page Content
          Group {
            switch selection {
            case 0:
              HomeView(selection: $selection, inventorySearchText: $inventorySearchText)
            case 1:
              InventoryView(initialSearchText: $inventorySearchText)
            case 2:
              DesignMainView()
            case 3:
              HistoryView(onStartDesign: {
                hapticManager.impact(style: .light)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                  selection = 2
                }
              })
            case 4:
              SettingsView()
            default:
              HomeView(selection: $selection, inventorySearchText: $inventorySearchText)
            }
          }
          .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 100)
          }

          // Floating Tab Bar
          FloatingTabBar(selection: $selection)
        }
        .fullScreenCover(isPresented: $authService.isNewlyRegistered) {
            PaywallView()
        }
        .onAppear {
            HistoryService.shared.loadDesigns()
            InventoryService.shared.loadInventory()
        }
        .onChange(of: authService.currentTenant?.id) {
            HistoryService.shared.loadDesigns()
            InventoryService.shared.loadInventory()
        }
      } else {
        LoginView()
      }
    }
    .tint(AppTheme.primary)
  }
}
