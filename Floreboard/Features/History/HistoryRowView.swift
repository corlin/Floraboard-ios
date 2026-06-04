import SwiftUI

struct HistoryRow: View {
  let design: DesignResult
  @EnvironmentObject var historyService: HistoryService
  @Environment(\.imagePersistence) var imagePersistence
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
      .task {
        await loadImageAsync()
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
          Label(CurrencyFormat.compact(design.totalCost), systemImage: "yensign.circle.fill")  // Replaced yen.circle.fill
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
        historyService.deleteDesign(id: design.id)
      } label: {
        Label(Tx.t("general.delete"), systemImage: "trash")
      }
    }
  }

  func loadImageAsync() async {
    if let path = design.imageUrl, !path.hasPrefix("http") {
      self.thumbnail = imagePersistence.loadImage(named: path)
    }
  }
}
