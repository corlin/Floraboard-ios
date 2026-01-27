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
              .foregroundColor(.secondary)
          }

          Button(localizationManager.t("settings.logout")) {
            auth.logout()
          }
          .foregroundColor(.red)
        }

        Section(header: Text(localizationManager.t("settings.apiProvider"))) {
          Picker(
            localizationManager.t("settings.provider"), selection: $viewModel.selectedProviderID
          ) {
            ForEach(AIProvider.all) { provider in
              Text(provider.name).tag(provider.id)
            }
          }

          .onChange(of: viewModel.selectedProviderID) { _, newValue in
            viewModel.updateProvider(newValue)
          }

          SecureField(localizationManager.t("settings.apiKey"), text: $viewModel.config.apiKey)
            .textContentType(.password)

          if viewModel.selectedProviderID == "custom" {
            TextField(localizationManager.t("settings.endpoint"), text: $viewModel.config.endpoint)
              .autocapitalization(.none)
              .disableAutocorrection(true)
          }
        }

        Section(header: Text(localizationManager.t("settings.textModel"))) {
          if let provider = AIProvider.all.first(where: { $0.id == viewModel.selectedProviderID }),
            !provider.models.isEmpty
          {
            Picker(
              localizationManager.t("settings.api.model"), selection: $viewModel.config.textModel
            ) {
              ForEach(provider.models, id: \.self) { model in
                Text(model).tag(model)
              }
            }
            // Allow manual override if needed (optional UX, sticking to picker for now for simplicity of port)
          } else {
            TextField(
              localizationManager.t("settings.modelName"), text: $viewModel.config.textModel)
          }
        }

        Section(header: Text(localizationManager.t("settings.visionModel"))) {
          if let provider = AIProvider.all.first(where: { $0.id == viewModel.selectedProviderID }),
            !provider.visionModels.isEmpty
          {
            Picker(
              localizationManager.t("settings.api.model"), selection: $viewModel.config.visionModel
            ) {
              ForEach(provider.visionModels, id: \.self) { model in
                Text(model).tag(model)
              }
            }
          } else {
            TextField(
              localizationManager.t("settings.modelName"), text: $viewModel.config.visionModel)
          }
        }

        Section(header: Text(localizationManager.t("settings.imageModel"))) {
          if let provider = AIProvider.all.first(where: { $0.id == viewModel.selectedProviderID }),
            !provider.imageModels.isEmpty
          {
            Picker(
              localizationManager.t("settings.api.model"),
              selection: Binding(
                get: { viewModel.config.imageModel },
                set: { viewModel.config.imageModel = $0 })
            ) {
              ForEach(provider.imageModels, id: \.self) { model in
                Text(model).tag(model)
              }
            }
          } else {
            TextField(
              localizationManager.t("settings.modelName"),
              text: Binding(
                get: { viewModel.config.imageModel },
                set: { viewModel.config.imageModel = $0 }))
          }

          if viewModel.selectedProviderID == "custom" {
            TextField(
              localizationManager.t("settings.imageEndpoint"),
              text: Binding(
                get: { viewModel.config.imageEndpoint ?? "" },
                set: { viewModel.config.imageEndpoint = $0 }))
          }
        }

        Section(header: Text(localizationManager.t("settings.businessRules"))) {
          HStack {
            Text(localizationManager.t("settings.defaultBudget"))
            Spacer()
            TextField("500", value: $viewModel.config.budget, format: .number)
              .keyboardType(.numberPad)
              .multilineTextAlignment(.trailing)
          }

          Stepper(
            "\(localizationManager.t("settings.lowStockWarning")): < \(viewModel.config.lowStockThreshold)",
            value: $viewModel.config.lowStockThreshold)
        }

        Section {
          Button(localizationManager.t("settings.saveConfig")) {
            viewModel.save()
          }
        }
      }
      .scrollContentBackground(.hidden)
      .background(AppTheme.premiumGradient.ignoresSafeArea())
      .background(AppTheme.premiumGradient.ignoresSafeArea())
      .scrollDismissesKeyboard(.interactively)  // iOS 16+ friendly replacement if available, or just remove gesture.
      // If scrollDismissesKeyboard is not available in the project's target, simple removal is best.
      // Assuming iOS 16+.

      .navigationTitle(localizationManager.t("settings.title"))
    }
  }
}
