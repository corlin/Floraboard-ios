//
//  SettingsViews.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import SwiftUI

struct SettingsView: View {
  @StateObject private var viewModel = SettingsViewModel()
  @StateObject private var auth = AuthService.shared
  @StateObject private var localizationManager = LocalizationManager.shared  // Added for localization
  @FocusState private var isEditingText: Bool
  @State private var isShowingLogoutConfirmation = false

  var body: some View {
    NavigationView {
      Form {
        // Added Language Picker Section
        Section(header: Text(localizationManager.t("settings.language"))) {
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

        Section(header: Text(localizationManager.t("settings.account"))) {
          HStack {
            Text(localizationManager.t("settings.storeName"))
            Spacer()
            Text(auth.currentTenant?.name ?? "Unknown")
              .foregroundColor(AppTheme.mutedText)
          }
        }

        Section(header: Text(localizationManager.t("settings.aiService"))) {
          HStack {
            Text(localizationManager.t("settings.aiServiceMode"))
            Spacer()
            Label(localizationManager.t("settings.aiServiceManaged"), systemImage: "checkmark.seal.fill")
              .font(AppTheme.sansFont(size: 13, weight: .semibold))
              .foregroundColor(AppTheme.success)
          }

          Text(localizationManager.t("settings.aiServiceManagedDesc"))
            .font(.footnote)
            .foregroundColor(AppTheme.mutedText)
        }

        Section(header: Text(localizationManager.t("settings.businessRules"))) {
          HStack {
            Text(localizationManager.t("settings.defaultBudget"))
            Spacer()
            TextField("500", value: $viewModel.config.budget, format: .number)
              .keyboardType(.numberPad)
              .multilineTextAlignment(.trailing)
              .focused($isEditingText)
          }

          Stepper(
            "\(localizationManager.t("settings.lowStockWarning")): < \(viewModel.config.lowStockThreshold)",
            value: $viewModel.config.lowStockThreshold)
        }

        Section {
          Button(localizationManager.t("settings.saveConfig")) {
            viewModel.save()
          }

          if let message = viewModel.statusMessage {
            Text(message)
              .font(.footnote)
              .foregroundColor(viewModel.isStatusError ? AppTheme.danger : AppTheme.success)
          }
        }

        Section {
          Button(role: .destructive) {
            isShowingLogoutConfirmation = true
          } label: {
            HStack {
              Spacer()
              Text(localizationManager.t("settings.logout"))
              Spacer()
            }
          }
        } footer: {
          Text(localizationManager.t("settings.logoutHint"))
        }
      }
      .scrollContentBackground(.hidden)
      .background(AppTheme.premiumGradient.ignoresSafeArea())
      .scrollDismissesKeyboard(.interactively)
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
      .navigationTitle(localizationManager.t("settings.title"))
    }
  }
}
