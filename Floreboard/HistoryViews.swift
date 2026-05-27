//
//  HistoryViews.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import SwiftUI

struct HistoryView: View {
  @StateObject private var historyService = HistoryService.shared
  @State private var searchText = ""
  var onStartDesign: (() -> Void)? = nil

  var filteredDesigns: [DesignResult] {
    if searchText.isEmpty {
      return historyService.savedDesigns
    } else {
      return historyService.savedDesigns.filter { design in
        design.title.localizedCaseInsensitiveContains(searchText)
          || design.description.localizedCaseInsensitiveContains(searchText)
          || design.meaningText.localizedCaseInsensitiveContains(searchText)
      }
    }
  }

  var body: some View {
    NavigationView {
      ZStack {
        AppTheme.premiumGradient.ignoresSafeArea()

        ScrollView {
          VStack(spacing: 20) {
            WorkbenchSearchField(
              placeholder: Tx.t("history.search"),
              text: $searchText
            )
            .padding(.horizontal)

            if filteredDesigns.isEmpty {
              VStack(alignment: .center, spacing: 16) {
                Image(systemName: historyService.savedDesigns.isEmpty ? "sparkles" : "magnifyingglass")
                  .font(.system(size: 60))
                  .foregroundColor(AppTheme.primary.opacity(0.3))

                Text(historyService.savedDesigns.isEmpty ? Tx.t("history.empty") : Tx.t("history.search.empty"))
                  .font(AppTheme.serifFont(size: 20, weight: .bold))
                  .foregroundColor(AppTheme.foreground)

                Text(
                  historyService.savedDesigns.isEmpty
                    ? Tx.t("history.empty.desc")
                    : Tx.t("history.search.empty.desc")
                )
                  .font(AppTheme.sansFont(size: 14))
                  .foregroundColor(AppTheme.mutedText)
                  .multilineTextAlignment(.center)

                if historyService.savedDesigns.isEmpty, let onStartDesign {
                  Button {
                    onStartDesign()
                  } label: {
                    Label(Tx.t("history.empty.action"), systemImage: "sparkles")
                  }
                  .buttonStyle(PrimaryButtonStyle())
                  .padding(.top, 4)
                } else if !searchText.isEmpty {
                  Button {
                    HapticManager.shared.impact(style: .light)
                    searchText = ""
                  } label: {
                    Label(Tx.t("history.search.clear"), systemImage: "xmark.circle")
                      .font(AppTheme.sansFont(size: 14, weight: .semibold))
                  }
                  .buttonStyle(.plain)
                  .foregroundColor(AppTheme.primary)
                  .padding(.top, 4)
                }
              }
              .frame(maxWidth: .infinity)
              .padding(24)
              .padding(.top, 36)
              .glassmorphic()
              .padding(.horizontal)
            } else {
              LazyVStack(spacing: 16) {
                ForEach(filteredDesigns) { design in
                  NavigationLink(destination: DesignDetailView(design: design)) {
                    HistoryRow(design: design)
                  }
                  .buttonStyle(PlainButtonStyle())  // Important for custom rows in ScrollView
                }
              }
              .padding(.horizontal)
              .padding(.bottom, 20)
            }
          }
          .padding(.top)
        }
      }
      .navigationTitle(Tx.t("history.title"))
    }
  }
}

struct HistoryRow: View {
  let design: DesignResult
  @State private var thumbnail: UIImage?

  var body: some View {
    HStack(spacing: 16) {
      // Icon / Thumbnail
      ZStack {
        if let image = thumbnail {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius))
            .overlay(
              RoundedRectangle(cornerRadius: AppTheme.controlRadius).stroke(AppTheme.hairline, lineWidth: 1))
        } else {
          RoundedRectangle(cornerRadius: AppTheme.controlRadius)
            .fill(AppTheme.primary.opacity(0.1))
            .frame(width: 60, height: 60)
          Image(systemName: "leaf")  // Replaced flower
            .font(.title2)
            .foregroundColor(AppTheme.primary)
        }
      }
      .onAppear {
        loadImage()
      }

      VStack(alignment: .leading, spacing: 6) {
        Text(design.title)
          .font(AppTheme.serifFont(size: 18, weight: .bold))
          .foregroundColor(AppTheme.foreground)
          .lineLimit(1)

        Text(design.meaningText)
          .font(AppTheme.sansFont(size: 14))
          .foregroundColor(AppTheme.mutedText)
          .lineLimit(2)

        HStack {
          Label("\(Int(design.totalCost))", systemImage: "yensign.circle.fill")  // Replaced yen.circle.fill
            .font(.caption.bold())
            .foregroundColor(AppTheme.primary)

          Text("•")
            .font(.caption)
            .foregroundColor(AppTheme.mutedText)

          Text(
            Date(timeIntervalSince1970: design.createdAt).formatted(
              date: .abbreviated, time: .shortened)
          )
          .font(.caption)
          .foregroundColor(AppTheme.mutedText)
        }
      }
      Spacer()
      Image(systemName: "chevron.right")
        .foregroundColor(AppTheme.foreground.opacity(0.3))
        .font(.caption)
    }
    .padding()
    .glassmorphic()
    .contextMenu {
      Button(role: .destructive) {
        HistoryService.shared.deleteDesign(id: design.id)
      } label: {
        Label(Tx.t("general.delete"), systemImage: "trash")
      }
    }
  }

  func loadImage() {
    if let path = design.imageUrl {
      // If it looks like a web URL (http), we skip for now (or use AsyncImage), but our current logic saves local filenames
      if !path.hasPrefix("http") {
        if let img = ImagePersistence.shared.loadImage(named: path) {
          self.thumbnail = img
        }
      }
    }
  }
}

struct DesignDetailView: View {
  let design: DesignResult
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
              Text("¥\(Int(design.totalCost))")
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
    .onAppear {
      loadDetailImage()
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
    let currentShortages = InventoryService.shared.stockShortages(for: design.flowerList)
    guard currentShortages.isEmpty else {
      shortages = currentShortages
      showStockWarning = true
      return
    }

    commitExecution()
  }

  private func commitExecution() {
    HistoryService.shared.executeDesign(design)
    displayedStatus = .completed
  }

  private func loadDetailImage() {
    if let path = design.imageUrl {
      if !path.hasPrefix("http") {
        if let img = ImagePersistence.shared.loadImage(named: path) {
          self.designImage = img
        }
      }
    }
  }
}
