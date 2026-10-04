import SwiftUI

struct DesignDetailView: View {
  let design: DesignResult
  @EnvironmentObject var historyService: HistoryService
  @EnvironmentObject var inventoryService: InventoryService
  @Environment(\.imagePersistence) var imagePersistence
  @State private var currentDesign: DesignResult
  @State private var designImage: UIImage?
  @State private var posterImage: UIImage?
  @State private var isShowingFullScreen = false
  @State private var displayedStatus: DesignStatus?
  @State private var showStockWarning = false
  @State private var shortages: [InventoryService.StockShortage] = []
  @State private var showExecutionSheet = false
  @State private var isRetryingImage = false

  init(design: DesignResult) {
    self.design = design
    self._currentDesign = State(initialValue: design)
  }

  var body: some View {
    ZStack {
      PremiumBackgroundView()

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          // 客户反馈 + 发给客户（分享链接）
          ShareProposalSection(design: currentDesign)

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
            if let imageError = currentDesign.imageError, !imageError.isEmpty {
              VStack(alignment: .leading, spacing: 12) {
                HStack {
                  Label(Tx.t("result.imageError.title"), systemImage: "photo.badge.exclamationmark")
                    .font(AppTheme.sansFont(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.primary)
                  Spacer()
                }
                Text(imageError)
                  .font(AppTheme.sansFont(size: 13))
                  .foregroundColor(AppTheme.mutedText)

                HStack(spacing: 10) {
                  Button(action: retryImageGeneration) {
                    HStack(spacing: 4) {
                      if isRetryingImage {
                        ProgressView()
                          .scaleEffect(0.75)
                      } else {
                        Image(systemName: "arrow.clockwise")
                      }
                      Text(isRetryingImage ? Tx.t("design.loading.dreaming") : Tx.t("general.retry"))
                        .font(AppTheme.sansFont(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.primary.opacity(0.12))
                    .foregroundColor(AppTheme.primary)
                    .clipShape(Capsule())
                  }
                  .disabled(isRetryingImage)

                  if currentDesign.referenceImageUrl != nil {
                    Button(action: useReferenceImageAsFinal) {
                      HStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text(Tx.t("design.image.useReference"))
                          .font(AppTheme.sansFont(size: 12, weight: .semibold))
                      }
                      .padding(.horizontal, 12)
                      .padding(.vertical, 6)
                      .background(AppTheme.accent.opacity(0.12))
                      .foregroundColor(AppTheme.accent)
                      .clipShape(Capsule())
                    }
                    .disabled(isRetryingImage)
                  }
                }
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

          // 制作稿：配方表 + 制作前校验 + 工艺要点
          ProductionSheetView(design: currentDesign)

          // 评分与心得：保存后同步到云端
          DesignEvaluationView(rating: currentDesign.rating, feedback: currentDesign.feedback) { rating, feedback in
            currentDesign.rating = rating > 0 ? rating : nil
            currentDesign.feedback = feedback.isEmpty ? nil : feedback
            historyService.saveDesign(currentDesign)
            HapticManager.shared.notification(type: .success)
          }

          // Action Buttons
          if currentStatus == .draft {
            Button {
              showExecutionSheet = true
            } label: {
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
            .sheet(isPresented: $showExecutionSheet) {
              DesignExecutionSheet(design: design) { mappedItems in
                commitExecution(mappedItems: mappedItems)
              }
            }
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
    .onReceive(historyService.$savedDesigns) { designs in
      // 服务端会重算校验结果、原子执行会写入执行状态：把这些“以云端为准”的字段同步进本页副本
      guard let latest = designs.first(where: { $0.id == currentDesign.id }) else { return }
      if latest.findings != currentDesign.findings { currentDesign.findings = latest.findings }
      if latest.share != currentDesign.share { currentDesign.share = latest.share }
      if latest.clientResponse != currentDesign.clientResponse { currentDesign.clientResponse = latest.clientResponse }
      if latest.status == .completed && currentDesign.status != .completed {
        currentDesign.status = .completed
        currentDesign.executedAt = latest.executedAt
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        if let poster = posterImage {
          ShareLink(
            item: Image(uiImage: poster),
            subject: Text(design.title),
            message: Text(design.description),
            preview: SharePreview(design.title, image: Image(uiImage: poster))
          ) {
            Image(systemName: "square.and.arrow.up")
              .font(.system(size: 16, weight: .bold))
          }
        } else if let img = designImage {
          ShareLink(
            item: Image(uiImage: img),
            subject: Text(design.title),
            message: Text(design.description),
            preview: SharePreview(design.title, image: Image(uiImage: img))
          ) {
            Image(systemName: "square.and.arrow.up")
              .font(.system(size: 16, weight: .bold))
          }
        } else {
          ShareLink(
            item: "\(design.title)\n\(design.description)"
          ) {
            Image(systemName: "square.and.arrow.up")
              .font(.system(size: 16, weight: .bold))
          }
        }
      }
    }
    .task {
      await loadDetailImageAsync()
    }
  }

  private var currentStatus: DesignStatus {
    displayedStatus ?? design.status
  }

  private func executeDesign() {
    // Replaced by showExecutionSheet flow.
    showExecutionSheet = true
  }

  private func commitExecution(mappedItems: [InventoryService.DeductionItem]?) {
    historyService.executeDesign(design, mappedItems: mappedItems)
    // 本页持有的是方案副本：同步已执行状态，避免之后保存评分/出图结果时把状态写回草稿
    currentDesign.status = .completed
    currentDesign.executedAt = currentDesign.executedAt ?? Date().timeIntervalSince1970
    displayedStatus = .completed
    HapticManager.shared.notification(type: .success)
  }

  private func retryImageGeneration() {
    guard let prompt = currentDesign.imagePrompt, !prompt.isEmpty, !isRetryingImage else { return }
    isRetryingImage = true
    currentDesign.imageError = nil
    currentDesign.imageStatus = .generating

    Task {
      do {
        let imageUrlString = try await AIService.shared.generateImage(
          prompt: prompt,
          requestId: currentDesign.syncId ?? currentDesign.requestId
        )
        let image = try await resolveGeneratedImage(from: imageUrlString)

        if let validImage = image {
          let designId = await MainActor.run { currentDesign.id }
          if let stored = await ImageSyncService.shared.storedImageValue(
            image: validImage,
            remoteURL: DesignMerge.isRemoteImage(imageUrlString) ? imageUrlString : nil,
            designId: designId, persistence: imagePersistence) {
            await MainActor.run {
              currentDesign.imageUrl = stored
              currentDesign.imageError = nil
              currentDesign.imageStatus = .succeeded
              self.designImage = validImage
              generatePoster()
            }
          } else {
            await MainActor.run {
              currentDesign.imageError = Tx.t("error.saveImage")
              currentDesign.imageStatus = .failed
            }
          }
        } else {
          await MainActor.run {
            currentDesign.imageError = Tx.t("error.invalidImageData")
            currentDesign.imageStatus = .failed
          }
        }
      } catch {
        await MainActor.run {
          currentDesign.imageError = AppError(from: error).localizedDescription
          currentDesign.imageStatus = .failed
        }
      }

      let updated = currentDesign
      await MainActor.run {
        isRetryingImage = false
        historyService.saveDesign(updated)
      }
    }
  }

  private func useReferenceImageAsFinal() {
    guard let refPath = currentDesign.referenceImageUrl else { return }
    if let refImage = imagePersistence.loadImage(named: refPath) {
      let designId = currentDesign.id
      Task {
        if let stored = await ImageSyncService.shared.storedImageValue(
          image: refImage, remoteURL: nil, designId: designId, persistence: imagePersistence) {
          await MainActor.run {
            currentDesign.imageUrl = stored
            currentDesign.imageError = nil
            currentDesign.imageStatus = .succeeded
            self.designImage = refImage
            historyService.saveDesign(currentDesign)
            generatePoster()
          }
        }
      }
    }
  }

  private func resolveGeneratedImage(from imageString: String) async throws -> UIImage? {
    if imageString.hasPrefix("data:image") {
      let base64String = imageString.components(separatedBy: ",").last ?? imageString
      if let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) {
        return UIImage(data: data)
      }
      return nil
    }

    if let url = URL(string: imageString),
      let scheme = url.scheme?.lowercased(),
      scheme == "http" || scheme == "https" {
      return try await AIProxyClient.downloadImageWithRetry(from: url, maxRetries: 2)
    }

    if let data = Data(base64Encoded: imageString, options: .ignoreUnknownCharacters) {
      return UIImage(data: data)
    }

    return nil
  }

  private func loadDetailImageAsync() async {
    if let path = currentDesign.imageUrl {
      let img = await imagePersistence.loadImageAsync(namedOrURL: path)
      await MainActor.run {
        self.designImage = img
        generatePoster()
      }
    } else {
      await MainActor.run {
        self.designImage = nil
        generatePoster()
      }
    }
  }

  @MainActor
  private func generatePoster() {
    let renderer = ImageRenderer(content: SharePosterView(design: currentDesign, image: designImage))
    renderer.scale = UIScreen.main.scale
    if let uiImage = renderer.uiImage {
      self.posterImage = uiImage
    }
  }
}
