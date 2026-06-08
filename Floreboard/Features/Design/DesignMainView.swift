import PhotosUI
import SwiftUI

struct AlertItem: Identifiable {
  var id = UUID()
  var message: String
}

struct DesignMainView: View {
  @Environment(\.aiService) var aiService
  @Environment(\.imagePersistence) var imagePersistence
  @Environment(\.hapticManager) var hapticManager
  @EnvironmentObject var inventoryService: InventoryService
  @EnvironmentObject var historyService: HistoryService
  @EnvironmentObject var loc: LocalizationManager
  @StateObject private var viewModel = DesignViewModel()
  @State private var pickerItem: PhotosPickerItem? = nil

  var body: some View {
    NavigationStack {
      ZStack {
        // Global Background
        AppTheme.premiumGradient.ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {

            // Section: Visual Muse
            VisualMuseView(viewModel: viewModel, pickerItem: $pickerItem)

            // Section: Design Form (Unified Card)
            VStack(alignment: .leading, spacing: 24) {
              
              // Mode Toggle
              VStack(alignment: .leading, spacing: 12) {
                Label(Tx.t("design.tabs.quick"), systemImage: "wand.and.stars")
                  .font(AppTheme.serifFont(size: 20, weight: .bold))
                  .foregroundColor(AppTheme.foreground)

                Picker(Tx.t("design.tabs.quick"), selection: $viewModel.isProfessionalMode) {
                  Text(Tx.t("design.tabs.quick")).tag(false)
                  Text(Tx.t("design.tabs.pro")).tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: viewModel.isProfessionalMode) { _, _ in
                  hapticManager.impact(style: .medium)
                }
              }

              Divider()

              // Preferences
              if !viewModel.isProfessionalMode {
                QuickFormView(viewModel: viewModel)
              } else {
                ProfessionalFormView(viewModel: viewModel)
              }
            }
            .padding()
            .glassmorphic()

          }
          .padding()
          .padding(.bottom, 96)
        }
      }
      .scrollDismissesKeyboard(.interactively)

      .navigationTitle(Tx.t("app.nav.design"))
      .safeAreaInset(edge: .bottom, spacing: 0) {
        WorkbenchPrimaryActionBar(
          title: viewModel.isLoading ? Tx.t("design.generate.loading") : Tx.t("design.generate.button"),
          systemImage: "sparkles",
          isLoading: viewModel.isLoading,
          isEnabled: !viewModel.isLoading
        ) {
          hideKeyboard()
          hapticManager.notification(type: .success)
          viewModel.generateDesign()
        }
      }
      .keyboardDismissToolbar()
      .onAppear {
        viewModel.setup(
          inventoryService: inventoryService,
          aiService: aiService,
          imagePersistence: imagePersistence,
          historyService: historyService,
          localizationManager: loc
        )
      }
      // Loading Overlay
      .overlay {
        if viewModel.isLoading {
          ZStack {
            AppTheme.scrim.ignoresSafeArea()
            Rectangle()
              .fill(.ultraThinMaterial)
              .ignoresSafeArea()

            VStack(spacing: 28) {
              AnimatedSparkle()

              Text(viewModel.loadingStatus)
                .font(AppTheme.serifFont(size: 20, weight: .bold))
                .foregroundColor(AppTheme.foreground)
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: viewModel.loadingStatus)
            }
            .padding(40)
            .frame(maxWidth: 320)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous))
            .shadow(color: AppTheme.elevation3.color, radius: AppTheme.elevation3.radius, x: 0, y: AppTheme.elevation3.y)
            .overlay(
              RoundedRectangle(cornerRadius: AppTheme.containerRadius, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 0.5)
            )
          }
          .transition(.opacity.animation(.easeInOut))
        }
      }
      .sheet(isPresented: $viewModel.showResult) {
        if let result = viewModel.generatedResult {
          ResultView(result: result)
        }
      }
      .sheet(isPresented: $viewModel.showPaywall) {
        PaywallView()
      }
      .alert(
        item: Binding<AlertItem?>(
          get: { viewModel.errorMessage.map { AlertItem(message: $0) } },
          set: { _ in viewModel.errorMessage = nil }
        )
      ) { item in
        Alert(
          title: Text(Tx.t("general.error")), message: Text(item.message),
          dismissButton: .default(Text(Tx.t("general.ok"))))
      }
    }
  }
}

struct AnimatedSparkle: View {
  @State private var isAnimating = false
  
  var body: some View {
    Image(systemName: "sparkles")
      .font(.system(size: 40))
      .foregroundStyle(
        LinearGradient(
          colors: [AppTheme.primary, AppTheme.creative],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .scaleEffect(isAnimating ? 1.1 : 0.9)
      .opacity(isAnimating ? 1.0 : 0.7)
      .frame(width: 80, height: 80)
      .background(AppTheme.surfaceElevated)
      .clipShape(Circle())
      .shadow(color: AppTheme.elevation2.color, radius: AppTheme.elevation2.radius, x: 0, y: AppTheme.elevation2.y)
      .onAppear {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
          isAnimating = true
        }
      }
  }
}
