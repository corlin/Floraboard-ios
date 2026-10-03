//
//  HomeComponents.swift
//  Floreboard
//
//  Supporting views for HomeView: action tiles, lookbook cards, gallery thumbnails, notifications.
//

import SwiftUI

// MARK: - Action Tile Button (3-Column Vertical Layout)

struct ActionTileButton: View {
  let title: String
  let subtitle: String
  let icon: String
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        ZStack {
          Circle()
            .fill(color.opacity(0.14))
            .frame(width: 44, height: 44)
          Image(systemName: icon)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(color)
        }

        Text(title)
          .font(AppTheme.sansFont(size: 14, weight: .bold))
          .foregroundColor(AppTheme.foreground)
          .lineLimit(1)

        Text(subtitle)
          .font(AppTheme.sansFont(size: 11, weight: .medium))
          .foregroundColor(AppTheme.mutedText)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .padding(.horizontal, 4)
      .glassmorphic()
    }
    .buttonStyle(TilePressButtonStyle())
  }
}

// MARK: - Tile Press Button Style

struct TilePressButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

// MARK: - Editorial Lookbook Card

struct EditorialLookbookCard: View {
  let design: DesignResult
  @Environment(\.imagePersistence) var imagePersistence

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // High-res visual banner with badge
      ZStack(alignment: .topTrailing) {
        GalleryThumbnail(path: design.imageUrl)
          .frame(width: 250, height: 165)
          .clipped()

        // Stems count pill
        let totalStems = design.flowerList.reduce(0) { $0 + $1.count }
        HStack(spacing: 4) {
          Image(systemName: "leaf.fill")
            .font(.system(size: 9))
          Text(Tx.t("home.stats.stemsSelected", ["count": "\(totalStems > 0 ? totalStems : design.flowerList.count)"]))
            .font(AppTheme.captionSmall)
            .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .foregroundColor(Color.white)
        .padding(8)
      }
      .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))

      // Editorial Details
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline) {
          Text(design.title)
            .font(AppTheme.serifFont(size: 16, weight: .bold))
            .foregroundColor(AppTheme.foreground)
            .lineLimit(1)

          Spacer()

          Text(CurrencyFormat.compact(design.totalCost))
            .font(AppTheme.serifFont(size: 16, weight: .bold))
            .foregroundColor(AppTheme.primary)
        }

        if !design.meaningText.isEmpty {
          Text(design.meaningText)
            .font(AppTheme.serifFont(size: 12).italic())
            .foregroundColor(AppTheme.mutedText)
            .lineLimit(1)
        }
      }
      .padding(14)
    }
    .frame(width: 250)
    .glassmorphic()
  }
}

// MARK: - Gallery Thumbnail

struct GalleryThumbnail: View {
  let path: String?
  @Environment(\.imagePersistence) var imagePersistence
  @State private var image: UIImage?

  var body: some View {
    Group {
      if let img = image {
        Image(uiImage: img)
          .resizable()
          .scaledToFill()
      } else {
        Rectangle()
          .fill(AppTheme.primary.opacity(0.08))
          .overlay(
            Image(systemName: "photo.on.rectangle")
              .font(.system(size: 28))
              .foregroundColor(AppTheme.primary.opacity(0.3))
          )
      }
    }
    .task {
      // 支持本地文件名和远程 URL（带磁盘缓存）
      if let p = path, !p.isEmpty {
        self.image = await imagePersistence.loadImageAsync(namedOrURL: p)
      }
    }
  }
}

// MARK: - Notifications

struct NotificationSheetView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var loc: LocalizationManager
  let lowStockItems: [FlowerType]
  let onGoToInventory: (String?) -> Void

  var body: some View {
    NavigationStack {
      ZStack {
        PremiumBackgroundView()

        ScrollView {
          VStack(spacing: 16) {
            if lowStockItems.isEmpty {
              VStack(spacing: 16) {
                Image(systemName: "bell.badge.slash")
                  .font(.system(size: 48))
                  .foregroundColor(AppTheme.success)
                Text(loc.t("home.notifications.empty"))
                  .font(AppTheme.serifFont(size: 20, weight: .bold))
                  .foregroundColor(AppTheme.foreground)
                Text(loc.t("home.notifications.emptyDesc"))
                  .font(AppTheme.sansFont(size: 14))
                  .foregroundColor(AppTheme.mutedText)
                  .multilineTextAlignment(.center)
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 60)
              .glassmorphic()
            } else {
              VStack(alignment: .leading, spacing: 16) {
                HStack {
                  Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.danger)
                  Text(loc.t("home.notifications.alert"))
                    .font(AppTheme.sansFont(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.foreground)
                }

                Text(loc.t("home.notifications.lowStock", ["count": "\(lowStockItems.count)"]))
                  .font(AppTheme.sansFont(size: 14))
                  .foregroundColor(AppTheme.mutedText)
                  .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                  ForEach(lowStockItems) { item in
                    Button {
                      onGoToInventory(item.name)
                    } label: {
                      HStack {
                        Text(item.name)
                          .font(AppTheme.sansFont(size: 16, weight: .medium))
                          .foregroundColor(AppTheme.foreground)
                        Spacer()
                        Text(loc.t("home.notifications.only_left", ["count": "\(item.quantity)"]))
                          .font(AppTheme.sansFont(size: 14, weight: .bold))
                          .foregroundColor(AppTheme.danger)
                      }
                      .padding()
                      .background(AppTheme.surfaceGlass)
                      .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                  }
                }

                Button {
                  onGoToInventory(nil)
                } label: {
                  Text(loc.t("home.notifications.replenish"))
                    .font(AppTheme.sansFont(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
                }
                .padding(.top, 8)
              }
              .padding(20)
              .glassmorphic()
            }
          }
          .padding(24)
        }
      }
      .navigationTitle(loc.t("home.notifications.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(loc.t("general.close")) {
            dismiss()
          }
          .foregroundColor(AppTheme.primary)
        }
      }
    }
  }
}
