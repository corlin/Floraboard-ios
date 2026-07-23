import SwiftUI

struct SettingsView: View {
  @Environment(\.aiService) var aiService
  @EnvironmentObject var auth: AuthService
  @EnvironmentObject var localizationManager: LocalizationManager
  @StateObject private var viewModel = SettingsViewModel()
  @FocusState private var isEditingText: Bool
  @State private var isShowingLogoutConfirmation = false
  @State private var appeared = false

  var body: some View {
    NavigationStack {
      ZStack {
        PremiumBackgroundView()

        ScrollView(showsIndicators: false) {
          VStack(alignment: .leading, spacing: 24) {

            // Page Header
            VStack(alignment: .leading, spacing: 6) {
              Text(localizationManager.t("settings.title"))
                .font(AppTheme.serifFont(size: 32, weight: .bold))
                .foregroundStyle(AppTheme.titleGradient)
              Text(localizationManager.t("settings.subtitle"))
                .font(AppTheme.sansFont(size: 15))
                .foregroundColor(AppTheme.mutedText)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Account Card
            VStack(alignment: .leading, spacing: 16) {
              SectionHeader(title: localizationManager.t("settings.account"), icon: "person.crop.circle.fill")

              HStack(spacing: 14) {
                ZStack {
                  Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 48, height: 48)
                  Text(String((auth.currentTenant?.name ?? "U").prefix(1)).uppercased())
                    .font(AppTheme.serifFont(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                  Text(auth.currentTenant?.name ?? "Unknown")
                    .font(AppTheme.sansFont(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.foreground)
                  Text(auth.currentTenant?.id ?? "")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.mutedText)
                    .lineLimit(1)
                }
                Spacer()
              }
            }
            .padding(20)
            .glassmorphic()
            .padding(.horizontal, 24)

            // Quota Card
            VStack(alignment: .leading, spacing: 16) {
              SectionHeader(title: localizationManager.t("settings.quota"), icon: "sparkles")

              if let quota = viewModel.userQuota {
                VStack(spacing: 16) {
                  // Balance display
                  HStack {
                    VStack(alignment: .leading, spacing: 4) {
                      Text(localizationManager.t("settings.quota_balance"))
                        .font(AppTheme.labelMedium)
                        .foregroundColor(AppTheme.mutedText)
                      Text("\(quota.balance)")
                        .font(AppTheme.sansFont(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.foreground)
                    }
                    Spacer()
                    // Tier Badge
                    Text(quota.tier.uppercased())
                      .font(AppTheme.sansFont(size: 12, weight: .bold))
                      .padding(.horizontal, 12)
                      .padding(.vertical, 6)
                      .foregroundColor(quota.tier == "pro" ? AppTheme.accent : AppTheme.mutedText)
                      .background(
                        (quota.tier == "pro" ? AppTheme.accent : AppTheme.mutedText).opacity(0.12)
                      )
                      .clipShape(Capsule())
                  }

                  // Progress bar
                  GeometryReader { geo in
                    let ratio = min(Double(quota.balance) / 100000.0, 1.0)
                    ZStack(alignment: .leading) {
                      Capsule()
                        .fill(AppTheme.primary.opacity(0.12))
                        .frame(height: 8)
                      Capsule()
                        .fill(
                          LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                            startPoint: .leading, endPoint: .trailing
                          )
                        )
                        .frame(width: geo.size.width * ratio, height: 8)
                    }
                  }
                  .frame(height: 8)
                }
              } else {
                HStack {
                  Text(localizationManager.t("settings.fetching_quota"))
                    .font(AppTheme.bodySmall)
                    .foregroundColor(AppTheme.mutedText)
                  Spacer()
                  ProgressView()
                }
              }
            }
            .padding(20)
            .glassmorphic()
            .padding(.horizontal, 24)

            // Language Card
            VStack(alignment: .leading, spacing: 16) {
              SectionHeader(title: localizationManager.t("settings.language"), icon: "globe")

              Picker(
                localizationManager.t("settings.language"),
                selection: $localizationManager.currentLanguage
              ) {
                ForEach(Language.allCases) { lang in
                  Text(lang.displayName).tag(lang)
                }
              }
              .pickerStyle(SegmentedPickerStyle())
            }
            .padding(20)
            .glassmorphic()
            .padding(.horizontal, 24)

            // AI Service Card
            VStack(alignment: .leading, spacing: 16) {
              SectionHeader(title: localizationManager.t("settings.aiService"), icon: "cpu")

              HStack {
                Label(localizationManager.t("settings.aiServiceManaged"), systemImage: "checkmark.seal.fill")
                  .font(AppTheme.sansFont(size: 14, weight: .semibold))
                  .foregroundColor(AppTheme.success)
                Spacer()
              }

              Text(localizationManager.t("settings.aiServiceManagedDesc"))
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.mutedText)

              Button {
                viewModel.testConnection()
              } label: {
                HStack(spacing: 8) {
                  if viewModel.isTestingConnection {
                    ProgressView().tint(AppTheme.primary)
                  } else {
                    Image(systemName: "bolt.heart.fill")
                  }
                  Text(localizationManager.t("settings.testConnection"))
                }
                .frame(maxWidth: .infinity)
              }
              .buttonStyle(SecondaryButtonStyle())
              .disabled(viewModel.isTestingConnection)

              if let message = viewModel.statusMessage {
                Text(message)
                  .font(AppTheme.caption)
                  .foregroundColor(viewModel.isStatusError ? AppTheme.danger : AppTheme.success)
              }
            }
            .padding(20)
            .glassmorphic()
            .padding(.horizontal, 24)

            // Business Rules Card
            VStack(alignment: .leading, spacing: 16) {
              SectionHeader(title: localizationManager.t("settings.businessRules"), icon: "slider.horizontal.3")

              VStack(spacing: 14) {
                HStack {
                  Text(localizationManager.t("settings.defaultBudget"))
                    .font(AppTheme.bodySmall)
                    .foregroundColor(AppTheme.foreground)
                  Spacer()
                  TextField("500", value: $viewModel.config.budget, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(AppTheme.sansFont(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 100)
                    .focused($isEditingText)
                }

                Divider().foregroundColor(AppTheme.hairline)

                HStack {
                  Text(localizationManager.t("settings.lowStockWarning"))
                    .font(AppTheme.bodySmall)
                    .foregroundColor(AppTheme.foreground)
                  Spacer()
                  Stepper(
                    "\(viewModel.config.lowStockThreshold)",
                    value: $viewModel.config.lowStockThreshold
                  )
                  .labelsHidden()
                  Text("\(viewModel.config.lowStockThreshold)")
                    .font(AppTheme.sansFont(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 30)
                }
              }

              Button {
                viewModel.save()
              } label: {
                Text(localizationManager.t("settings.saveConfig"))
                  .frame(maxWidth: .infinity)
              }
              .buttonStyle(PrimaryButtonStyle())

              if let message = viewModel.statusMessage {
                Text(message)
                  .font(AppTheme.caption)
                  .foregroundColor(viewModel.isStatusError ? AppTheme.danger : AppTheme.success)
              }
            }
            .padding(20)
            .glassmorphic()
            .padding(.horizontal, 24)

            // Logout
            Button {
              isShowingLogoutConfirmation = true
            } label: {
              HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text(localizationManager.t("settings.logout"))
              }
              .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle(color: AppTheme.danger))
            .padding(.horizontal, 24)

            Text(localizationManager.t("settings.logoutHint"))
              .font(AppTheme.captionSmall)
              .foregroundColor(AppTheme.mutedText)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)
              .padding(.horizontal, 24)

            Spacer().frame(height: 100) // Bottom padding for floating tab bar
          }
        }
        .scrollDismissesKeyboard(.interactively)
      }
      .toolbar(.hidden, for: .navigationBar)
      .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button(localizationManager.t("general.done")) {
            isEditingText = false
          }
        }
      }
      .confirmationDialog(
        localizationManager.t("settings.logoutConfirmTitle"),
        isPresented: $isShowingLogoutConfirmation,
        titleVisibility: .visible
      ) {
        Button(localizationManager.t("settings.logout"), role: .destructive) {
          auth.logout()
        }
        Button(localizationManager.t("general.cancel"), role: .cancel) {}
      } message: {
        Text(localizationManager.t("settings.logoutConfirmMessage"))
      }
      .onAppear {
        viewModel.setup(with: aiService)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
          appeared = true
        }
      }
    }
  }
}
