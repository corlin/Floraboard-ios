import PhotosUI
import SwiftUI

struct VisualMuseView: View {
  @ObservedObject var viewModel: DesignViewModel
  @Binding var pickerItem: PhotosPickerItem?

  var body: some View {
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
              .cornerRadius(AppTheme.controlRadius)
              .overlay(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius)
                  .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
              )
          } else {
            VStack(spacing: 12) {
              Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.aiDesign)
              Text(Tx.t("design.scene.uploadBtn"))
                .font(AppTheme.sansFont(size: 16, weight: .medium))
                .foregroundColor(AppTheme.foreground.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(AppTheme.surfaceGlass)
            .cornerRadius(AppTheme.controlRadius)
            .overlay(
              RoundedRectangle(cornerRadius: AppTheme.controlRadius)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(AppTheme.aiDesign.opacity(0.35))
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
            .foregroundColor(AppTheme.danger)
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
