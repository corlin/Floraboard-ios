import SwiftUI

struct ResultView: View {
  let result: DesignResult
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var historyService: HistoryService
  @EnvironmentObject var inventoryService: InventoryService
  @Environment(\.imagePersistence) var imagePersistence

  @State private var designImage: UIImage? = nil
  @State private var isShowingFullScreen = false
  @State private var showStockWarning = false
  @State private var shortages: [InventoryService.StockShortage] = []
  @State private var executed = false
  @State private var showExecutionSheet = false

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.premiumGradient.ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            // Main Image
            if let img = designImage {
              Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                .shadow(color: AppTheme.elevation3.color, radius: AppTheme.elevation3.radius, x: 0, y: AppTheme.elevation3.y)
                .padding(.horizontal)
                .padding(.top, 20)
                .onTapGesture {
                  isShowingFullScreen = true
                }
                .fullScreenCover(isPresented: $isShowingFullScreen) {
                  FullScreenImageView(image: img)
                }
            } else {
              // Placeholder or missing
              if let imageError = result.imageError, !imageError.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                  Label(Tx.t("result.imageError.title"), systemImage: "photo.badge.exclamationmark")
                    .font(AppTheme.sansFont(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.primary)
                  Text(imageError)
                    .font(AppTheme.sansFont(size: 13))
                    .foregroundColor(AppTheme.mutedText)
                }
                .padding()
                .glassmorphic()
                .padding(.horizontal)
                .padding(.top, 20)
              } else {
                Rectangle()
                  .fill(Color.clear)
                  .frame(height: 20)
              }
            }

            // Header Card
            VStack(alignment: .leading, spacing: 12) {
              Text(result.title)
                .font(AppTheme.serifFont(size: 32, weight: .bold))
                .foregroundColor(AppTheme.foreground)

              Text(result.description)
                .font(AppTheme.sansFont(size: 16))
                .foregroundColor(AppTheme.foreground.opacity(0.8))
                .lineSpacing(4)
            }
            .padding(.horizontal)

            // Meaning Card
            VStack(alignment: .leading, spacing: 10) {
              Label(Tx.t("result.meaning.title"), systemImage: "heart.text.square.fill")
                .font(AppTheme.sansFont(size: 14, weight: .bold))
                .foregroundColor(AppTheme.primary)

              Text(result.meaningText)
                .font(AppTheme.serifFont(size: 18).italic())
                .foregroundColor(AppTheme.foreground)
            }
            .padding()
            .glassmorphic()
            .padding(.horizontal)

            // Flower BOM Card
            VStack(alignment: .leading, spacing: 16) {
              Label(Tx.t("result.bom.title"), systemImage: "leaf.fill")
                .font(AppTheme.sansFont(size: 18, weight: .bold))
                .foregroundColor(AppTheme.primary)

              ForEach(result.flowerList) { item in
                HStack {
                  Text(item.flowerName)
                    .font(AppTheme.serifFont(size: 16))
                    .foregroundColor(AppTheme.foreground)
                  Spacer()
                  Text("x\(item.count)")
                    .font(AppTheme.sansFont(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.foreground)
                }
                Divider()
              }

              HStack {
                Text(Tx.t("result.cost.title"))
                  .font(AppTheme.sansFont(size: 16, weight: .medium))
                  .foregroundColor(AppTheme.mutedText)
                Spacer()
                Text(CurrencyFormat.compact(result.totalCost))
                  .font(AppTheme.sansFont(size: 20, weight: .bold))
                  .foregroundColor(AppTheme.primary)
              }
            }
            .padding()
            .glassmorphic()
            .padding(.horizontal)

            // Steps Card
            if !result.steps.isEmpty {
              VStack(alignment: .leading, spacing: 16) {
                Label(Tx.t("result.steps.title"), systemImage: "list.number")
                  .font(AppTheme.sansFont(size: 18, weight: .bold))
                  .foregroundColor(AppTheme.primary)

                ForEach(Array(result.steps.enumerated()), id: \.offset) { index, step in
                  HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                      .font(AppTheme.sansFont(size: 14, weight: .bold))
                      .foregroundColor(AppTheme.iconOnAccent)
                      .frame(width: 24, height: 24)
                      .background(Circle().fill(AppTheme.primary.opacity(0.8)))

                    Text(step)
                      .font(AppTheme.sansFont(size: 16))
                      .foregroundColor(AppTheme.foreground)
                      .fixedSize(horizontal: false, vertical: true)
                  }
                }
              }
              .padding()
              .glassmorphic()
              .padding(.horizontal)
            }

            // Execute Button
            if !executed && result.status == .draft {
              Button(action: { showExecutionSheet = true }) {
                HStack {
                  Image(systemName: "checkmark.circle.fill")
                  Text(Tx.t("design.action.execute"))
                }
                .font(.headline)
                .foregroundColor(AppTheme.iconOnAccent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
              }
              .padding(.horizontal)
              .sheet(isPresented: $showExecutionSheet) {
                DesignExecutionSheet(design: result) { mappedItems in
                  commitExecution(mappedItems: mappedItems)
                }
              }
            } else if executed || result.status == .completed {
              HStack {
                Image(systemName: "checkmark.seal.fill")
                  .foregroundColor(AppTheme.success)
                Text(Tx.t("design.action.executed"))
                  .font(AppTheme.serifFont(size: 18, weight: .bold))
                  .foregroundColor(AppTheme.success)
              }
              .frame(maxWidth: .infinity)
              .padding()
              .background(AppTheme.success.opacity(0.12))
              .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
              .padding(.horizontal)
            }
          }
          .padding(.bottom, 40)
        }
      }
      .navigationTitle(Tx.t("result.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(Tx.t("general.done")) {
            dismiss()
          }
          .font(AppTheme.sansFont(size: 16, weight: .bold))
        }
      }
      .task {
        await loadDetailImageAsync()
      }
    }
  }

  private func executeDesign() {
    showExecutionSheet = true
  }

  private func commitExecution(mappedItems: [InventoryService.DeductionItem]?) {
    historyService.executeDesign(result, mappedItems: mappedItems)
    executed = true
    HapticManager.shared.notification(type: .success)
  }

  private func loadDetailImageAsync() async {
    if let path = result.imageUrl, !path.hasPrefix("http") {
      self.designImage = imagePersistence.loadImage(named: path)
    }
  }
}
