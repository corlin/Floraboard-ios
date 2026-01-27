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
            // Search Bar (Custom Glass)
            HStack {
              Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
              TextField(Tx.t("history.search"), text: $searchText)
            }
            .padding()
            .background(Color.white.opacity(0.5))
            .cornerRadius(12)
            .padding(.horizontal)

            if filteredDesigns.isEmpty {
              VStack(alignment: .center, spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                  .font(.system(size: 60))
                  .foregroundColor(AppTheme.primary.opacity(0.3))
                Text(Tx.t("history.empty"))
                  .font(AppTheme.serifFont(size: 20, weight: .bold))
                  .foregroundColor(AppTheme.foreground)
                Text(Tx.t("history.empty.desc"))
                  .font(AppTheme.sansFont(size: 14))
                  .foregroundColor(AppTheme.secondary)
              }
              .frame(maxWidth: .infinity)
              .padding(.top, 60)
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
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
              RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.5), lineWidth: 1))
        } else {
          RoundedRectangle(cornerRadius: 12)
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
          .foregroundColor(AppTheme.secondary)
          .lineLimit(2)

        HStack {
          Label("\(Int(design.totalCost))", systemImage: "yensign.circle.fill")  // Replaced yen.circle.fill
            .font(.caption.bold())
            .foregroundColor(AppTheme.primary)

          Text("•")
            .font(.caption)
            .foregroundColor(.secondary)

          Text(
            Date(timeIntervalSince1970: design.createdAt).formatted(
              date: .abbreviated, time: .shortened)
          )
          .font(.caption)
          .foregroundColor(.secondary)
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
              .clipShape(RoundedRectangle(cornerRadius: 16))
              .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
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
            Rectangle()
              .fill(Color.clear)
              .frame(height: 20)
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
              .foregroundColor(AppTheme.secondary)
            }
          }
          .padding()

          // Meaning Card
          VStack(alignment: .leading, spacing: 10) {
            Label("Symbolism", systemImage: "heart.text.square.fill")
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
            Label("Flower Recipe", systemImage: "leaf.fill")
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
              Text("Total Estimated Cost")
                .font(AppTheme.sansFont(size: 16, weight: .medium))
                .foregroundColor(AppTheme.secondary)
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
              Label("Instructions", systemImage: "list.number")
                .font(AppTheme.sansFont(size: 18, weight: .bold))
                .foregroundColor(AppTheme.primary)

              ForEach(Array(design.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                  Text("\(index + 1)")
                    .font(AppTheme.sansFont(size: 14, weight: .bold))
                    .foregroundColor(.white)
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
          if design.status == .draft {
            Button(action: {
              HistoryService.shared.executeDesign(design)
            }) {
              HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Execute Plan")
              }
              .font(.headline)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(AppTheme.primary)
              .cornerRadius(12)
              .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
          } else {
            HStack {
              Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
              Text("Plan Executed")
                .font(AppTheme.serifFont(size: 18, weight: .bold))
                .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
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
