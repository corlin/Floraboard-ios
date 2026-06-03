import SwiftUI

struct DesignDetailView: View {
  let design: DesignResult
  @EnvironmentObject var historyService: HistoryService
  @EnvironmentObject var inventoryService: InventoryService
  @Environment(\.imagePersistence) var imagePersistence
  @State private var designImage: UIImage? = nil
  @State private var isShowingFullScreen = false
  @State private var displayedStatus: DesignStatus?
  @State private var showStockWarning = false
  @State private var shortages: [InventoryService.StockShortage] = []

  var body: some View {
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
              .shadow(color: AppTheme.shadow, radius: 8, x: 0, y: 4)
              .padding(.horizontal)
              .padding(.top, 20)
              .onTapGesture {
                isShowingFullScreen = true
              }
              .fullScreenCover(isPresented: $isShowingFullScreen) {
                if let img = designImage {
                  FullScreenImageView(image: img)
                }
              }
          } else {
            // Placeholder or missing
            if let imageError = design.imageError, !imageError.isEmpty {
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
            Text(design.title)
              .font(AppTheme.serifFont(size: 32, weight: .bold))
              .foregroundColor(AppTheme.foreground)

            Text(design.description)
              .font(AppTheme.sansFont(size: 16))
              .foregroundColor(AppTheme.foreground.opacity(0.8))
              .lineSpacing(4)

            HStack {
              Label(
                Date(timeIntervalSince1970: design.createdAt).formatted(
                  date: .long, time: .omitted), systemImage: "calendar"
              )
              .font(AppTheme.sansFont(size: 14))
              .foregroundColor(AppTheme.mutedText)
            }
          }
          .padding()

          // Meaning Card
          VStack(alignment: .leading, spacing: 10) {
            Label(Tx.t("result.meaning.title"), systemImage: "heart.text.square.fill")
              .font(AppTheme.sansFont(size: 14, weight: .bold))
              .foregroundColor(AppTheme.primary)

            Text(design.meaningText)
              .font(AppTheme.serifFont(size: 18).italic())
              .foregroundColor(AppTheme.foreground)
          }
          .padding()
          .glassmorphic()
          .padding(.horizontal)

          // Flower Recipe Card
          VStack(alignment: .leading, spacing: 16) {
            Label(Tx.t("result.bom.title"), systemImage: "leaf.fill")
              .font(AppTheme.sansFont(size: 18, weight: .bold))
              .foregroundColor(AppTheme.primary)

            ForEach(design.flowerList) { item in
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
              Text(CurrencyFormat.compact(design.totalCost))
                .font(AppTheme.sansFont(size: 20, weight: .bold))
                .foregroundColor(AppTheme.primary)
            }
          }
          .padding()
          .glassmorphic()
          .padding(.horizontal)

          // Instructions Card
          if !design.steps.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
              Label(Tx.t("result.steps.title"), systemImage: "list.number")
                .font(AppTheme.sansFont(size: 18, weight: .bold))
                .foregroundColor(AppTheme.primary)

              ForEach(Array(design.steps.enumerated()), id: \.offset) { index, step in
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

          // Action Buttons
          if currentStatus == .draft {
            Button(action: executeDesign) {
              HStack {
                Image(systemName: "checkmark.circle.fill")
                Text(Tx.t("design.action.execute"))
              }
              .font(.headline)
              .foregroundColor(AppTheme.iconOnAccent)
              .frame(maxWidth: .infinity)
              .padding()
              .background(AppTheme.primary)
              .cornerRadius(AppTheme.controlRadius)
              .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
          } else {
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
            .cornerRadius(AppTheme.controlRadius)
            .padding(.horizontal)
          }
        }
        .padding(.bottom, 40)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await loadDetailImageAsync()
    }
    .alert(Tx.t("inventory.shortage.title"), isPresented: $showStockWarning) {
      Button(Tx.t("general.cancel"), role: .cancel) {}
      Button(Tx.t("inventory.shortage.continue"), role: .destructive) {
        commitExecution()
      }
    } message: {
      Text(shortageMessage)
    }
  }

  private var shortageMessage: String {
    let rows = shortages.map {
      Tx.t(
        "inventory.shortage.item",
        ["name": $0.flowerName, "requested": "\($0.requested)", "available": "\($0.available)"]
      )
    }
    return rows.joined(separator: "\n")
  }

  private var currentStatus: DesignStatus {
    displayedStatus ?? design.status
  }

  private func executeDesign() {
    let currentShortages = inventoryService.stockShortages(for: design.flowerList)
    guard currentShortages.isEmpty else {
      shortages = currentShortages
      showStockWarning = true
      return
    }

    commitExecution()
  }

  private func commitExecution() {
    historyService.executeDesign(design)
    displayedStatus = .completed
  }

  private func loadDetailImageAsync() async {
    if let path = design.imageUrl, !path.hasPrefix("http") {
      let loaded = await Task.detached { [imagePersistence] in
        imagePersistence.loadImage(named: path)
      }.value
      self.designImage = loaded
    }
  }
}
