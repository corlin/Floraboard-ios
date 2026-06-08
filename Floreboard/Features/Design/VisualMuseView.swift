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
              .frame(height: 240)
              .clipped()
              .cornerRadius(AppTheme.imageRadius)
              .overlay(
                RoundedRectangle(cornerRadius: AppTheme.imageRadius)
                  .stroke(AppTheme.hairline, lineWidth: 1)
              )
              .shadow(color: AppTheme.elevation2.color, radius: AppTheme.elevation2.radius, y: AppTheme.elevation2.y)
              
            // Overlay gradient for clear button legibility
            LinearGradient(
                colors: [.black.opacity(0.4), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            .frame(maxHeight: .infinity, alignment: .top)
            .cornerRadius(AppTheme.imageRadius)
            
            Button(action: {
              viewModel.selectedImage = nil
              pickerItem = nil
            }) {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .shadow(radius: 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

          } else {
            VStack(spacing: 16) {
              ZStack {
                Circle()
                    .fill(AppTheme.aiDesign.opacity(0.1))
                    .frame(width: 64, height: 64)
                Image(systemName: "camera.viewfinder")
                  .font(.system(size: 28, weight: .light))
                  .foregroundColor(AppTheme.aiDesign)
              }
              VStack(spacing: 4) {
                Text(Tx.t("design.scene.uploadBtn"))
                  .font(AppTheme.sansFont(size: 16, weight: .semibold))
                  .foregroundColor(AppTheme.foreground)
                Text("Add a reference image to guide the AI")
                  .font(AppTheme.sansFont(size: 13))
                  .foregroundColor(AppTheme.mutedText)
              }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(AppTheme.surfaceGlass)
            .cornerRadius(AppTheme.imageRadius)
            .overlay(
              RoundedRectangle(cornerRadius: AppTheme.imageRadius)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .foregroundColor(AppTheme.aiDesign.opacity(0.4))
            )
          }
        }
      }
      .buttonStyle(.plain)
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
        Divider().padding(.vertical, 8)

        // Advanced Muse Options
        VStack(alignment: .leading, spacing: 16) {
          Label(Tx.t("design.vm.options.title"), systemImage: "slider.horizontal.3")
            .font(AppTheme.serifFont(size: 18, weight: .semibold))

          VStack(alignment: .leading, spacing: 8) {
              Label(Tx.t("design.vm.scale"), systemImage: "ruler.fill")
                .font(AppTheme.sansFont(size: 13, weight: .medium)).foregroundColor(AppTheme.mutedText)
              FlowChipSelector(
                  options: [
                      ("auto", Tx.t("design.vm.options.scale.auto")),
                      ("micro", Tx.t("design.vm.options.scale.micro")),
                      ("small", Tx.t("design.vm.options.scale.small")),
                      ("large", Tx.t("design.vm.options.scale.large")),
                  ],
                  selection: Binding(
                      get: { viewModel.request.scalePreference ?? "auto" },
                      set: { viewModel.request.scalePreference = $0 }
                  )
              )
          }

          VStack(alignment: .leading, spacing: 8) {
              Label(Tx.t("design.vm.mood"), systemImage: "sparkles")
                .font(AppTheme.sansFont(size: 13, weight: .medium)).foregroundColor(AppTheme.mutedText)
              FlowChipSelector(
                  options: [
                      ("auto", Tx.t("design.vm.options.mood.auto")),
                      ("romantic", Tx.t("design.vm.options.mood.romantic")),
                      ("serene", Tx.t("design.vm.options.mood.serene")),
                      ("dramatic", Tx.t("design.vm.options.mood.dramatic")),
                  ],
                  selection: Binding(
                      get: { viewModel.request.moodPreference ?? "auto" },
                      set: { viewModel.request.moodPreference = $0 }
                  )
              )
          }

          VStack(alignment: .leading, spacing: 8) {
              Label(Tx.t("design.vm.form"), systemImage: "leaf.fill")
                .font(AppTheme.sansFont(size: 13, weight: .medium)).foregroundColor(AppTheme.mutedText)
              FlowChipSelector(
                  options: [
                      ("auto", Tx.t("design.vm.options.form.auto")),
                      ("vertical", Tx.t("design.vm.options.form.vertical")),
                      ("cascade", Tx.t("design.vm.options.form.cascade")),
                      ("organic", Tx.t("design.vm.options.form.organic")),
                  ],
                  selection: Binding(
                      get: { viewModel.request.formPreference ?? "auto" },
                      set: { viewModel.request.formPreference = $0 }
                  )
              )
          }
          
          VStack(alignment: .leading, spacing: 8) {
              Label(Tx.t("design.vm.bg"), systemImage: "photo.fill")
                .font(AppTheme.sansFont(size: 13, weight: .medium)).foregroundColor(AppTheme.mutedText)
              FlowChipSelector(
                  options: [
                      ("auto", Tx.t("design.vm.options.bg.auto")),
                      ("minimal", Tx.t("design.vm.options.bg.minimal")),
                      ("luxe", Tx.t("design.vm.options.bg.luxe")),
                  ],
                  selection: Binding(
                      get: { viewModel.request.backgroundStyle ?? "auto" },
                      set: { viewModel.request.backgroundStyle = $0 }
                  )
              )
          }
        }
      }
    }
  }
}
