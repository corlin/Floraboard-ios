import SwiftUI

extension AppTheme {
  static let springDefault = Animation.spring(response: 0.35, dampingFraction: 0.8)
}

struct SettingsView: View {
  @Environment(\.aiService) var aiService
  @EnvironmentObject var auth: AuthService
  @EnvironmentObject var localizationManager: LocalizationManager
  @StateObject private var viewModel = SettingsViewModel()
  @FocusState private var isEditingText: Bool
  @State private var isShowingLogoutConfirmation = false
  @State private var isShowingPaywall = false
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
                    .frame(width: 52, height: 52)
                  Text(String((auth.currentTenant?.name ?? "U").prefix(1)).uppercased())
                    .font(AppTheme.serifFont(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                  Text(auth.currentTenant?.name ?? localizationManager.t("settings.storeName"))
                    .font(AppTheme.sansFont(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.foreground)

                  if let email = auth.currentUser?.email, !email.isEmpty {
                    Text(email)
                      .font(AppTheme.sansFont(size: 13))
                      .foregroundColor(AppTheme.mutedText)
                  }

                  Text("ID: \(auth.currentTenant?.id ?? "")")
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

            // Member Tier & Credits Center
            VStack(alignment: .leading, spacing: 16) {
              SectionHeader(title: localizationManager.t("settings.credits.title"), icon: "sparkles")

              VStack(spacing: 16) {
                HStack(alignment: .center) {
                  VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.t("settings.credits.remaining"))
                      .font(AppTheme.labelMedium)
                      .foregroundColor(AppTheme.mutedText)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                      Text("\(currentCredits)")
                        .font(AppTheme.sansFont(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.foreground)
                      Text(localizationManager.t("settings.credits.unit"))
                        .font(AppTheme.sansFont(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.mutedText)
                    }
                  }

                  Spacer()

                  VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                      Image(systemName: isProTier ? "crown.fill" : "person.fill")
                        .font(.system(size: 11))
                      Text(isProTier ? proBadgeTitle : freeBadgeTitle)
                        .font(AppTheme.sansFont(size: 13, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundColor(isProTier ? .white : AppTheme.mutedText)
                    .background(isProTier ? AppTheme.creative : AppTheme.surfaceElevated)
                    .clipShape(Capsule())

                    if let exp = viewModel.creditsData?.subscriptionExpiresAt {
                      Text(expirationText(exp))
                        .font(AppTheme.captionSmall)
                        .foregroundColor(AppTheme.mutedText)
                    }
                  }
                }

                Button {
                  isShowingPaywall = true
                } label: {
                  HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(rechargeButtonTitle)
                      .font(AppTheme.sansFont(size: 15, weight: .semibold))
                  }
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                }
                .buttonStyle(PrimaryButtonStyle())

                // Recent Transactions List
                if let txs = viewModel.creditsData?.transactions, !txs.isEmpty {
                  VStack(alignment: .leading, spacing: 10) {
                    Text(historyTitle)
                      .font(AppTheme.sansFont(size: 13, weight: .semibold))
                      .foregroundColor(AppTheme.mutedText)
                      .padding(.top, 4)

                    ForEach(txs.prefix(5)) { tx in
                      HStack {
                        VStack(alignment: .leading, spacing: 2) {
                          Text(tx.description ?? (tx.amount > 0 ? localizationManager.t("settings.credits.top_up") : localizationManager.t("settings.credits.consume")))
                            .font(AppTheme.sansFont(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.foreground)

                          Text(formatTxDate(tx.createdAt))
                            .font(AppTheme.captionSmall)
                            .foregroundColor(AppTheme.mutedText)
                        }

                        Spacer()

                        Text(tx.amount > 0 ? "+\(tx.amount)" : "\(tx.amount)")
                          .font(AppTheme.sansFont(size: 14, weight: .bold))
                          .foregroundColor(tx.amount > 0 ? AppTheme.success : AppTheme.foreground)
                      }
                      .padding(.vertical, 4)

                      if tx.id != txs.prefix(5).last?.id {
                        Divider().foregroundColor(AppTheme.hairline)
                      }
                    }
                  }
                } else if viewModel.creditsData != nil {
                  Text(noHistoryTitle)
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.mutedText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
              }
            }
            .padding(20)
            .glassmorphic()
            .padding(.horizontal, 24)

            // Language Card
            VStack(alignment: .leading, spacing: 16) {
              SectionHeader(title: localizationManager.t("settings.language"), icon: "globe")

              HStack {
                Text(localizationManager.t("settings.currentLanguage"))
                  .font(AppTheme.bodySmall)
                  .foregroundColor(AppTheme.foreground)

                Spacer()

                Menu {
                  ForEach(Language.allCases) { lang in
                    Button {
                      withAnimation(AppTheme.springDefault) {
                        localizationManager.currentLanguage = lang
                      }
                    } label: {
                      HStack {
                        Text(lang.displayName)
                        if localizationManager.currentLanguage == lang {
                          Image(systemName: "checkmark")
                        }
                      }
                    }
                  }
                } label: {
                  HStack(spacing: 6) {
                    Text(localizationManager.currentLanguage.displayName)
                      .font(AppTheme.sansFont(size: 14, weight: .medium))
                      .foregroundColor(AppTheme.foreground)

                    Image(systemName: "chevron.up.chevron.down")
                      .font(.system(size: 11, weight: .medium))
                      .foregroundColor(AppTheme.mutedText)
                  }
                  .padding(.horizontal, 12)
                  .padding(.vertical, 8)
                  .background(AppTheme.surfaceElevated)
                  .clipShape(Capsule())
                  .overlay(
                    Capsule()
                      .stroke(AppTheme.hairline, lineWidth: 1)
                  )
                }
              }
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
      .sheet(isPresented: $isShowingPaywall) {
        PaywallView(onPurchaseSuccess: {
          viewModel.fetchCredits()
        })
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

  private var currentCredits: Int {
    viewModel.creditsData?.credits ?? auth.currentTenant?.credits ?? 30
  }

  private var isProTier: Bool {
    let tier = viewModel.creditsData?.tier ?? auth.currentTenant?.tier ?? "free"
    return tier.lowercased() == "pro"
  }

  private var proBadgeTitle: String {
    let t = localizationManager.t("settings.credits.proBadge")
    return t != "settings.credits.proBadge" ? t : localizationManager.t("settings.credits.tier_pro")
  }

  private var freeBadgeTitle: String {
    let t = localizationManager.t("settings.credits.freeBadge")
    return t != "settings.credits.freeBadge" ? t : localizationManager.t("settings.credits.tier_free")
  }

  private func expirationText(_ dateString: String) -> String {
    let formatted = formatExpirationDate(dateString)
    let t = localizationManager.t("settings.credits.expires", ["date": formatted])
    if t != "settings.credits.expires" {
      return t
    }
    return localizationManager.t("settings.credits.expires_at", ["date": formatted])
  }

  private var rechargeButtonTitle: String {
    let t = localizationManager.t("settings.credits.recharge")
    return t != "settings.credits.recharge" ? t : localizationManager.t("settings.credits.upgrade_button")
  }

  private var historyTitle: String {
    let t = localizationManager.t("settings.credits.history")
    return t != "settings.credits.history" ? t : localizationManager.t("settings.credits.recent_title")
  }

  private var noHistoryTitle: String {
    let t = localizationManager.t("settings.credits.noHistory")
    return t != "settings.credits.noHistory" ? t : localizationManager.t("settings.credits.empty")
  }

  private func formatExpirationDate(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: dateString) {
      let df = DateFormatter()
      df.dateFormat = "yyyy-MM-dd"
      return df.string(from: date)
    }
    return String(dateString.prefix(10))
  }

  private func formatTxDate(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: dateString) {
      let df = DateFormatter()
      df.dateFormat = "MM-dd HH:mm"
      return df.string(from: date)
    }
    return String(dateString.prefix(16))
  }
}
