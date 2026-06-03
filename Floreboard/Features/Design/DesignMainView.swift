import PhotosUI
import SwiftUI

struct AlertItem: Identifiable {
  var id = UUID()
  var message: String
}

struct DesignMainView: View {
  @StateObject private var viewModel = DesignViewModel()
  @ObservedObject private var loc = LocalizationManager.shared
  @State private var pickerItem: PhotosPickerItem? = nil

  var body: some View {
    NavigationStack {
      ZStack {
        // Global Background
        AppTheme.premiumGradient.ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {

            // Section: Mode Selection (Glass Card)
            VStack(alignment: .leading, spacing: 10) {
              Text(Tx.t("design.tabs.quick"))  // Using Quick/Pro label as title for now or "Design Mode"
                .font(AppTheme.serifFont(size: 20, weight: .bold))
                .foregroundColor(AppTheme.foreground)

              Picker(Tx.t("design.tabs.quick"), selection: $viewModel.isProfessionalMode) {
                Text(Tx.t("design.tabs.quick")).tag(false)
                Text(Tx.t("design.tabs.pro")).tag(true)
              }
              .pickerStyle(SegmentedPickerStyle())
              .onChange(of: viewModel.isProfessionalMode) { _, _ in
                HapticManager.shared.impact(style: .medium)
              }
            }
            .padding()
            .glassmorphic()

            // Section: Visual Muse
            VisualMuseView(viewModel: viewModel, pickerItem: $pickerItem)

            // Section: Preferences (Quick Mode Only)
            if !viewModel.isProfessionalMode {
              QuickFormView(viewModel: viewModel)
            }

            // Section: Professional Details
            if viewModel.isProfessionalMode {
              ProfessionalFormView(viewModel: viewModel)
            }

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
          HapticManager.shared.notification(type: .success)
          viewModel.generateDesign()
        }
      }
      .keyboardDismissToolbar()
      // Loading Overlay
      .overlay {
        if viewModel.isLoading {
          ZStack {
            AppTheme.scrim.ignoresSafeArea()

            VStack(spacing: 24) {
              ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.primary)
                .padding()
                .background(Circle().fill(AppTheme.surfaceStrong))

              Text(viewModel.loadingStatus)
                .font(AppTheme.serifFont(size: 20, weight: .medium))
                .foregroundColor(AppTheme.iconOnAccent)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            .padding(40)
            .background(AppTheme.card)
            .cornerRadius(AppTheme.cardRadius)
            .overlay(
              RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.hairline.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)
            .padding(.horizontal, 40)
          }
          .transition(.opacity.animation(.easeInOut))
        }
      }
      .sheet(isPresented: $viewModel.showResult) {
        if let result = viewModel.generatedResult {
          ResultView(result: result)
        }
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
