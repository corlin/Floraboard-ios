//
//  DesignViews.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import PhotosUI
import SwiftUI

struct DesignView: View {
  @StateObject private var viewModel = DesignViewModel()
  @ObservedObject private var loc = LocalizationManager.shared
  @State private var pickerItem: PhotosPickerItem? = nil

  var body: some View {
    NavigationView {
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
            }
            .padding()
            .glassmorphic()

            // Section: Visual Muse
            VStack(alignment: .leading, spacing: 16) {
              Text(Tx.t("design.scene.muse"))
                .font(AppTheme.serifFont(size: 22, weight: .bold))
                .foregroundColor(AppTheme.foreground)

              PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack {
                  if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                      .resizable()
                      .scaledToFill()
                      .frame(height: 200)
                      .clipped()
                      .cornerRadius(12)
                      .overlay(
                        RoundedRectangle(cornerRadius: 12)
                          .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
                      )
                  } else {
                    VStack(spacing: 12) {
                      Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.primary)
                      Text(Tx.t("design.scene.uploadBtn"))
                        .font(AppTheme.sansFont(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.foreground.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(12)
                    .overlay(
                      RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(AppTheme.primary.opacity(0.3))
                    )
                  }
                }
              }
              .onChange(of: pickerItem) { _, newItem in
                Task {
                  if let data = try? await newItem?.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                  {
                    viewModel.selectedImage = image
                  }
                }
              }

              if viewModel.selectedImage != nil {
                Button(action: {
                  viewModel.selectedImage = nil
                  pickerItem = nil
                }) {
                  Label(Tx.t("design.scene.clearImage"), systemImage: "trash")
                    .font(AppTheme.sansFont(size: 14))
                    .foregroundColor(AppTheme.primary)
                }
                .padding(.leading, 4)

                Divider()

                // Advanced Muse Options
                VStack(alignment: .leading, spacing: 12) {
                  Text(Tx.t("design.vm.options.title"))
                    .font(AppTheme.serifFont(size: 18, weight: .semibold))

                  musePicker(
                    title: Tx.t("design.vm.scale"),
                    selection: Binding(
                      get: { viewModel.request.scalePreference ?? "auto" },
                      set: { viewModel.request.scalePreference = $0 }),
                    options: [
                      ("auto", Tx.t("design.vm.options.scale.auto")),
                      ("micro", Tx.t("design.vm.options.scale.micro")),
                      ("small", Tx.t("design.vm.options.scale.small")),
                      ("large", Tx.t("design.vm.options.scale.large")),
                    ])

                  musePicker(
                    title: Tx.t("design.vm.mood"),
                    selection: Binding(
                      get: { viewModel.request.moodPreference ?? "auto" },
                      set: { viewModel.request.moodPreference = $0 }),
                    options: [
                      ("auto", Tx.t("design.vm.options.mood.auto")),
                      ("romantic", Tx.t("design.vm.options.mood.romantic")),
                      ("serene", Tx.t("design.vm.options.mood.serene")),
                      ("dramatic", Tx.t("design.vm.options.mood.dramatic")),
                    ])

                  musePicker(
                    title: Tx.t("design.vm.form"),
                    selection: Binding(
                      get: { viewModel.request.formPreference ?? "auto" },
                      set: { viewModel.request.formPreference = $0 }),
                    options: [
                      ("auto", Tx.t("design.vm.options.form.auto")),
                      ("vertical", Tx.t("design.vm.options.form.vertical")),
                      ("cascade", Tx.t("design.vm.options.form.cascade")),
                      ("organic", Tx.t("design.vm.options.form.organic")),
                    ])

                  musePicker(
                    title: Tx.t("design.vm.bg"),
                    selection: Binding(
                      get: { viewModel.request.backgroundStyle ?? "auto" },
                      set: { viewModel.request.backgroundStyle = $0 }),
                    options: [
                      ("auto", Tx.t("design.vm.options.bg.auto")),
                      ("minimal", Tx.t("design.vm.options.bg.minimal")),
                      ("luxe", Tx.t("design.vm.options.bg.luxe")),
                    ])
                }
              }
            }
            .padding()
            .glassmorphic()

            // Section: Preferences
            VStack(alignment: .leading, spacing: 16) {
              Text(Tx.t("design.step.scene"))
                .font(AppTheme.serifFont(size: 22, weight: .bold))
                .foregroundColor(AppTheme.foreground)

              HStack {
                Text(Tx.t("design.step.scene"))
                Spacer()
                Picker("", selection: $viewModel.request.occasion) {
                  ForEach(OccasionType.allCases) { type in Text(type.displayName).tag(type) }
                }.pickerStyle(.menu).tint(AppTheme.primary)
              }
              Divider()
              HStack {
                Text(Tx.t("design.style.title"))
                Spacer()
                Picker("", selection: $viewModel.request.style) {
                  ForEach(StyleType.allCases) { type in Text(type.displayName).tag(type) }
                }.pickerStyle(.menu).tint(AppTheme.primary)
              }
              Divider()
              HStack {
                Text(Tx.t("design.budget.title"))
                Spacer()
                TextField("500", value: $viewModel.request.budget, format: .number)
                  .keyboardType(.decimalPad)
                  .multilineTextAlignment(.trailing)
                  .foregroundColor(AppTheme.primary)
                  .font(.system(size: 18, weight: .bold))
                  .onTapGesture {}  // Prevent propagation only on the field itself if needed, but actually we want tap OUTSIDE.

              }
            }
            .padding()
            .glassmorphic()

            // Section: Professional Details
            if viewModel.isProfessionalMode {
              VStack(alignment: .leading, spacing: 16) {
                Text(Tx.t("app.nav.design") + " (Pro)")
                  .font(AppTheme.serifFont(size: 22, weight: .bold))
                  .foregroundColor(AppTheme.foreground)

                // Culture Filter
                Picker("Filter", selection: $viewModel.cultureFilter) {
                  Text(Tx.t("filter.culture.all")).tag(DesignViewModel.CultureFilter.all)
                  Text(Tx.t("filter.culture.japanese")).tag(DesignViewModel.CultureFilter.japanese)
                  Text(Tx.t("filter.culture.chinese")).tag(DesignViewModel.CultureFilter.chinese)
                  Text(Tx.t("filter.culture.western")).tag(DesignViewModel.CultureFilter.western)
                }
                .pickerStyle(.segmented)

                // School
                HStack {
                  Text(Tx.t("design.pro.school.title"))
                  Spacer()
                  Picker(
                    "",
                    selection: Binding(
                      get: { viewModel.request.school ?? "" },
                      set: { viewModel.request.school = $0 })
                  ) {
                    Text(Tx.t("design.pro.school.select")).tag("")
                    ForEach(viewModel.filteredSchools, id: \.self) { id in
                      Text(Tx.t("pro.school.\(id).name")).tag(id)
                    }
                  }.tint(AppTheme.primary)
                }
                Divider()

                // Technique
                HStack {
                  Text(Tx.t("design.pro.technique.title"))
                  Spacer()
                  Picker(
                    "",
                    selection: Binding(
                      get: { viewModel.request.technique ?? "" },
                      set: { viewModel.request.technique = $0 })
                  ) {
                    Text(Tx.t("design.pro.technique.select")).tag("")
                    ForEach(viewModel.filteredTechniques, id: \.self) { id in
                      Text(Tx.t("pro.tech.\(id).name")).tag(id)
                    }
                  }.tint(AppTheme.primary)
                }

                Divider()

                // Context Input
                Text(Tx.t("design.pro.context.title"))
                  .font(AppTheme.sansFont(size: 14, weight: .medium))
                  .foregroundColor(.secondary)

                TextField(
                  Tx.t("design.pro.context.placeholder"),
                  text: Binding(
                    get: { viewModel.request.culturalContext ?? "" },
                    set: { viewModel.request.culturalContext = $0 })
                )
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(8)
              }
              .padding()
              .glassmorphic()
            }

            // Button
            Button(action: viewModel.generateDesign) {
              if viewModel.isLoading {
                ProgressView().tint(.white)
              } else {
                Text(Tx.t("design.generate.button"))
              }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 10)
            .disabled(viewModel.isLoading)
            .padding(.bottom, 40)

          }
          .padding()
        }
      }
      .scrollDismissesKeyboard(.interactively)

      .navigationTitle(Tx.t("app.nav.design"))
      // Loading Overlay
      .overlay {
        if viewModel.isLoading {
          ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 24) {
              ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.primary)
                .padding()
                .background(Circle().fill(Color.white.opacity(0.8)))

              Text(viewModel.loadingStatus)
                .font(AppTheme.serifFont(size: 20, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(radius: 20)
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

  // Helper for consistent muse pickers
  func musePicker(title: String, selection: Binding<String>, options: [(String, String)])
    -> some View
  {
    HStack {
      Text(title).font(AppTheme.sansFont(size: 14))
      Spacer()
      Picker(title, selection: selection) {
        ForEach(options, id: \.0) { opt in
          Text(opt.1).tag(opt.0)
        }
      }
      .pickerStyle(.menu)
      .tint(AppTheme.primary)
      .scaleEffect(0.9)
    }
  }
}

struct AlertItem: Identifiable {
  var id = UUID()
  var message: String
}

struct ResultView: View {
  let result: DesignResult
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Header
          VStack(alignment: .leading, spacing: 8) {
            Text(result.title)
              .font(.title)
              .fontWeight(.bold)
            Text(result.description)
              .font(.body)
              .foregroundColor(.secondary)
          }
          .padding()

          // Flower BOM
          GroupBox(label: Label(Tx.t("result.bom.title"), systemImage: "list.bullet")) {
            VStack(alignment: .leading, spacing: 8) {
              ForEach(result.flowerList) { item in
                HStack {
                  Text(item.flowerName)
                  Spacer()
                  Text("x\(item.count)")
                    .fontWeight(.bold)
                }
                Divider()
              }
              HStack {
                Text(Tx.t("result.cost.title"))
                  .fontWeight(.bold)
                Spacer()
                Text("¥\(Int(result.totalCost))")
                  .fontWeight(.bold)
                  .foregroundColor(.pink)
              }
            }
            .padding(.vertical, 8)
          }
          .padding(.horizontal)

          // Steps
          GroupBox(label: Label(Tx.t("result.steps.title"), systemImage: "text.book.closed")) {
            VStack(alignment: .leading, spacing: 10) {
              ForEach(Array(result.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top) {
                  Text("\(index + 1).")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                  Text(step)
                }
              }
            }
            .padding(.vertical, 8)
          }
          .padding(.horizontal)

          // Meaning
          GroupBox(label: Label(Tx.t("result.meaning.title"), systemImage: "heart.text.square")) {
            Text(result.meaningText)
              .italic()
              .padding(.vertical, 8)
          }
          .padding(.horizontal)
        }
      }
      .navigationTitle(Tx.t("result.title"))
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(Tx.t("general.done")) {
            presentationMode.wrappedValue.dismiss()
          }
        }
      }
    }
  }
}
