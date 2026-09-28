//
//  FloristWorkbenchView.swift
//  Floreboard
//
//  Full-screen immersive florist workbench mode for bouquet preparation.
//

import SwiftUI

struct FloristWorkbenchView: View {
  let order: OrderRecord
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var orderService: OrderService
  @EnvironmentObject var historyService: HistoryService
  @Environment(\.hapticManager) private var hapticManager
  @Environment(\.imagePersistence) private var imagePersistence

  @State private var checkedItemIds: Set<String> = []
  @State private var showFullImage = false
  @State private var workbenchImage: UIImage? = nil

  var associatedDesign: DesignResult? {
    guard let designId = order.designId else { return nil }
    return historyService.savedDesigns.first { $0.id == designId }
  }

  var allChecked: Bool {
    !order.items.isEmpty && checkedItemIds.count == order.items.count
  }

  var body: some View {
    ZStack {
      // Dark luxurious workbench canvas
      AppTheme.background.ignoresSafeArea()

      VStack(spacing: 0) {
        // Top Floating Control Bar
        headerBar
          .padding(.horizontal, 20)
          .padding(.top, 16)
          .padding(.bottom, 12)

        ScrollView(showsIndicators: false) {
          VStack(spacing: 20) {
            // Reference Visual Card
            referenceVisualCard
              .padding(.horizontal, 20)

            // Recipe Checklist Section
            checklistSection
              .padding(.horizontal, 20)
          }
          .padding(.bottom, 120)
        }
      }

      // Bottom Fixed Completion Bar
      VStack {
        Spacer()
        bottomCompletionBar
          .padding(.horizontal, 20)
          .padding(.bottom, 24)
      }
    }
    .onAppear {
      loadImage()
    }
  }

  // MARK: - Header Bar
  private var headerBar: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Circle()
            .fill(AppTheme.secondary)
            .frame(width: 8, height: 8)
          Text(Tx.t("workbench.title"))
            .font(AppTheme.serifFont(size: 20, weight: .bold))
            .foregroundColor(AppTheme.foreground)
        }

        HStack(spacing: 8) {
          Text(order.customerName)
            .font(AppTheme.sansFont(size: 14, weight: .semibold))
            .foregroundColor(AppTheme.primary)

          if !order.customerPhone.isEmpty {
            Text("·")
              .foregroundColor(AppTheme.mutedText)
            Text(order.customerPhone)
              .font(AppTheme.sansFont(size: 13))
              .foregroundColor(AppTheme.mutedText)
          }
        }
      }

      Spacer()

      Button {
        hapticManager.impact(style: .light)
        dismiss()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 28))
          .foregroundColor(AppTheme.mutedText.opacity(0.8))
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 8)
  }

  // MARK: - Reference Visual Card
  private var referenceVisualCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let img = workbenchImage {
        ZStack(alignment: .bottomTrailing) {
          Image(uiImage: img)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .onTapGesture {
              showFullImage = true
            }

          Button {
            showFullImage = true
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 12, weight: .bold))
              Text("原图")
                .font(AppTheme.captionSmall)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundColor(Color.white)
          }
          .padding(12)
        }
        .fullScreenCover(isPresented: $showFullImage) {
          FullScreenImageView(image: img)
        }
      } else {
        HStack(spacing: 12) {
          Image(systemName: "leaf.fill")
            .font(.system(size: 32))
            .foregroundColor(AppTheme.primary.opacity(0.6))
          VStack(alignment: .leading, spacing: 4) {
            Text(associatedDesign?.title ?? order.customerName + " · 定制花艺")
              .font(AppTheme.serifFont(size: 16, weight: .bold))
              .foregroundColor(AppTheme.foreground)
            if let meaning = associatedDesign?.meaningText, !meaning.isEmpty {
              Text(meaning)
                .font(AppTheme.sansFont(size: 13))
                .foregroundColor(AppTheme.mutedText)
            }
          }
        }
        .padding(.vertical, 12)
      }

      if let title = associatedDesign?.title, !title.isEmpty, workbenchImage != nil {
        Text(title)
          .font(AppTheme.serifFont(size: 17, weight: .bold))
          .foregroundColor(AppTheme.foreground)
      }
    }
    .padding(14)
    .glassmorphic()
  }

  // MARK: - Checklist Section
  private var checklistSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(Tx.t("workbench.checklist_title"))
            .font(AppTheme.serifFont(size: 17, weight: .bold))
            .foregroundColor(AppTheme.foreground)

          Text(Tx.t("workbench.checklist_hint"))
            .font(AppTheme.sansFont(size: 12))
            .foregroundColor(AppTheme.mutedText)
        }

        Spacer()

        Text("\(checkedItemIds.count) / \(order.items.count)")
          .font(AppTheme.sansFont(size: 14, weight: .bold))
          .foregroundColor(allChecked ? AppTheme.success : AppTheme.primary)
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(
            (allChecked ? AppTheme.success : AppTheme.primary).opacity(0.12),
            in: Capsule()
          )
      }

      VStack(spacing: 10) {
        ForEach(order.items) { item in
          let isChecked = checkedItemIds.contains(item.id)
          Button {
            toggleItem(item.id)
          } label: {
            HStack(spacing: 14) {
              // Big tactile checkbox
              ZStack {
                Circle()
                  .stroke(isChecked ? AppTheme.success : AppTheme.hairline, lineWidth: 2)
                  .frame(width: 28, height: 28)

                if isChecked {
                  Circle()
                    .fill(AppTheme.success)
                    .frame(width: 28, height: 28)
                  Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.white)
                }
              }

              // Flower Name with strike-through when completed
              Text(item.flowerName)
                .font(AppTheme.sansFont(size: 17, weight: isChecked ? .regular : .semibold))
                .foregroundColor(isChecked ? AppTheme.mutedText : AppTheme.foreground)
                .strikethrough(isChecked, color: AppTheme.mutedText)

              Spacer()

              // Big Stem Quantity Badge
              Text("x\(item.count)")
                .font(AppTheme.sansFont(size: 18, weight: .bold))
                .foregroundColor(isChecked ? AppTheme.mutedText : AppTheme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                  RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isChecked ? Color.clear : AppTheme.primary.opacity(0.1))
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
              RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(isChecked ? AppTheme.surfaceGlass.opacity(0.5) : AppTheme.surfaceElevated)
            )
            .overlay(
              RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(isChecked ? AppTheme.success.opacity(0.3) : AppTheme.hairline, lineWidth: 1)
            )
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  // MARK: - Bottom Completion Bar
  private var bottomCompletionBar: some View {
    Button {
      completeBouquet()
    } label: {
      HStack(spacing: 10) {
        Image(systemName: allChecked ? "checkmark.circle.fill" : "sparkles")
          .font(.system(size: 20, weight: .bold))

        Text(Tx.t("workbench.mark_delivered"))
          .font(AppTheme.sansFont(size: 17, weight: .bold))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 18)
      .background(
        allChecked
          ? LinearGradient(colors: [AppTheme.success, AppTheme.primary], startPoint: .leading, endPoint: .trailing)
          : LinearGradient(colors: [AppTheme.primary, AppTheme.secondary], startPoint: .leading, endPoint: .trailing)
      )
      .foregroundColor(Color.white)
      .clipShape(Capsule())
      .shadow(color: AppTheme.primary.opacity(0.3), radius: 12, x: 0, y: 6)
    }
    .buttonStyle(.plain)
  }

  // MARK: - Actions
  private func toggleItem(_ id: String) {
    hapticManager.impact(style: .medium)
    withAnimation(AppTheme.interactiveSpring) {
      if checkedItemIds.contains(id) {
        checkedItemIds.remove(id)
      } else {
        checkedItemIds.insert(id)
      }
    }
  }

  private func completeBouquet() {
    hapticManager.notification(type: .success)
    orderService.updateOrderStatus(order, newStatus: .delivered)
    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
      dismiss()
    }
  }

  private func loadImage() {
    if let design = associatedDesign, let path = design.imageUrl, !path.hasPrefix("http") {
      workbenchImage = imagePersistence.loadImage(named: path)
    }
  }
}
