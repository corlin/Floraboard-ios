import SwiftUI

struct InventoryView: View {
  @EnvironmentObject var inventoryService: InventoryService
  @StateObject private var viewModel = InventoryViewModel()
  @State private var showingAddSheet = false
  @State private var editingFlower: FlowerType? = nil

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.premiumGradient.ignoresSafeArea()

        ScrollView {
          VStack(spacing: 16) {
            WorkbenchSearchField(
              placeholder: Tx.t("general.search") + "...",
              text: $viewModel.searchText
            )
            .padding(.horizontal)

            LazyVStack(spacing: 16) {
              if viewModel.filteredFlowers.isEmpty {
                VStack(spacing: 14) {
                  Image(systemName: viewModel.flowers.isEmpty ? "leaf.circle" : "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.primary.opacity(0.32))

                  Text(
                    viewModel.flowers.isEmpty
                      ? Tx.t("inventory.list.empty.title")
                      : Tx.t("inventory.search.empty")
                  )
                  .font(AppTheme.serifFont(size: 20, weight: .bold))
                  .foregroundColor(AppTheme.foreground)

                  Text(
                    viewModel.flowers.isEmpty
                      ? Tx.t("inventory.list.empty.desc")
                      : Tx.t("inventory.search.empty.desc")
                  )
                  .font(AppTheme.sansFont(size: 14))
                  .foregroundColor(AppTheme.mutedText)
                  .multilineTextAlignment(.center)

                  if viewModel.flowers.isEmpty {
                    Button {
                      HapticManager.shared.impact(style: .medium)
                      showingAddSheet = true
                    } label: {
                      Label(Tx.t("inventory.add"), systemImage: "plus")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 4)
                  } else if !viewModel.searchText.isEmpty {
                    Button {
                      HapticManager.shared.impact(style: .light)
                      viewModel.searchText = ""
                    } label: {
                      Label(Tx.t("inventory.search.clear"), systemImage: "xmark.circle")
                        .font(AppTheme.sansFont(size: 14, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(AppTheme.primary)
                    .padding(.top, 4)
                  }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .padding(.top, 24)
                .glassmorphic()
              } else {
                ForEach(viewModel.filteredFlowers) { flower in
                  FlowerRow(
                    flower: flower,
                    onEdit: {
                      HapticManager.shared.impact(style: .light)
                      editingFlower = flower
                    },
                    onDelete: {
                      HapticManager.shared.notification(type: .warning)
                      viewModel.delete(flower)
                    })
                }
              }
            }
            .padding(.horizontal)
            .padding(.bottom, 96)
          }
          .padding(.top)
        }
      }
      .scrollDismissesKeyboard(.interactively)
      .navigationTitle(Tx.t("inventory.title"))
      .overlay {
        WorkbenchBottomActionBar(
          title: Tx.t("inventory.add"),
          systemImage: "plus"
        ) {
          HapticManager.shared.impact(style: .medium)
          showingAddSheet = true
        }
      }
      // Add Sheet
      .sheet(isPresented: $showingAddSheet) {
        EditFlowerSheet(viewModel: viewModel, flowerToEdit: nil)
      }
      // Edit Sheet
      .sheet(item: $editingFlower) { flower in
        EditFlowerSheet(viewModel: viewModel, flowerToEdit: flower)
      }
      .onAppear {
        viewModel.setup(with: inventoryService)
      }
    }
  }
}
