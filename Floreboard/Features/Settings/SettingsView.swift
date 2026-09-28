import SwiftUI

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
                  Text(auth.currentTenant?.name ?? "花店空间")
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
              SectionHeader(title: "会员与点数中心", icon: "sparkles")

              VStack(spacing: 16) {
                HStack(alignment: .center) {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("当前剩余点数")
                      .font(AppTheme.labelMedium)
                      .foregroundColor(AppTheme.mutedText)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                      Text("\(currentCredits)")
                        .font(AppTheme.sansFont(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.foreground)
                      Text("点")
                        .font(AppTheme.sansFont(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.mutedText)
                    }
                  }

                  Spacer()

                  VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                      Image(systemName: isProTier ? "crown.fill" : "person.fill")
                        .font(.system(size: 11))
                      Text(isProTier ? "PRO 专业版" : "免费体验")
                        .font(AppTheme.sansFont(size: 13, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundColor(isProTier ? .white : AppTheme.mutedText)
                    .background(isProTier ? AppTheme.creative : AppTheme.surfaceElevated)
                    .clipShape(Capsule())

                    if let exp = viewModel.creditsData?.subscriptionExpiresAt {
                      Text("到期: \(formatExpirationDate(exp))")
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
                    Text("充值点数 / 升级会员")
                      .font(AppTheme.sansFont(size: 15, weight: .semibold))
                  }
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                }
                .buttonStyle(PrimaryButtonStyle())

                // Recent Transactions List
                if let txs = viewModel.creditsData?.transactions, !txs.isEmpty {
                  VStack(alignment: .leading, spacing: 10) {
                    Text("近期账单明细")
                      .font(AppTheme.sansFont(size: 13, weight: .semibold))
                      .foregroundColor(AppTheme.mutedText)
                      .padding(.top, 4)

                    ForEach(txs.prefix(5)) { tx in
                      HStack {
                        VStack(alignment: .leading, spacing: 2) {
                          Text(tx.description ?? (tx.amount > 0 ? "充值到账" : "点数消耗"))
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
