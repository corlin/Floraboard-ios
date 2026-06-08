import SwiftUI

struct SharePosterView: View {
  let design: DesignResult
  let image: UIImage?

  var body: some View {
    VStack(spacing: 0) {
      // Top header
      HStack {
        Image(systemName: "leaf.fill")
          .foregroundColor(AppTheme.primary)
          .font(.system(size: 24))
        Text("Floraboard")
          .font(AppTheme.serifFont(size: 24, weight: .bold))
          .foregroundColor(AppTheme.primary)
      }
      .padding(.top, 32)
      .padding(.bottom, 24)

      // Main Image
      if let img = image {
        Image(uiImage: img)
          .resizable()
          .scaledToFill()
          .frame(width: 320, height: 320)
          .clipShape(RoundedRectangle(cornerRadius: AppTheme.imageRadius))
          .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 5)
          .padding(.horizontal, 24)
      } else {
        Rectangle()
          .fill(AppTheme.primary.opacity(0.1))
          .frame(width: 320, height: 320)
          .clipShape(RoundedRectangle(cornerRadius: AppTheme.imageRadius))
          .overlay(
            Image(systemName: "photo")
              .font(.system(size: 40))
              .foregroundColor(AppTheme.primary.opacity(0.3))
          )
          .padding(.horizontal, 24)
      }

      // Details
      VStack(alignment: .leading, spacing: 16) {
        Text(design.title)
          .font(AppTheme.serifFont(size: 28, weight: .bold))
          .foregroundColor(AppTheme.foreground)

        if !design.meaningText.isEmpty {
          Text(design.meaningText)
            .font(AppTheme.serifFont(size: 16).italic())
            .foregroundColor(AppTheme.primary)
        }

        Text(design.description)
          .font(AppTheme.sansFont(size: 15))
          .foregroundColor(AppTheme.mutedText)
          .lineSpacing(4)
          .fixedSize(horizontal: false, vertical: true)

        Divider()
          .padding(.vertical, 8)

        // BOM
        VStack(alignment: .leading, spacing: 12) {
          Label(Tx.t("result.bom.title"), systemImage: "leaf.fill")
            .font(AppTheme.sansFont(size: 16, weight: .bold))
            .foregroundColor(AppTheme.foreground)

          ForEach(design.flowerList.prefix(5)) { item in
            HStack {
              Text(item.flowerName)
                .font(AppTheme.serifFont(size: 14))
                .foregroundColor(AppTheme.foreground)
              Spacer()
              Text("x\(item.count)")
                .font(AppTheme.sansFont(size: 14, weight: .bold))
                .foregroundColor(AppTheme.foreground)
            }
          }
          if design.flowerList.count > 5 {
            Text("...")
              .font(AppTheme.sansFont(size: 14, weight: .bold))
              .foregroundColor(AppTheme.mutedText)
          }
        }

        if !design.steps.isEmpty {
          Divider()
            .padding(.vertical, 8)

          // Steps
          VStack(alignment: .leading, spacing: 12) {
            Label(Tx.t("result.steps.title"), systemImage: "list.number")
              .font(AppTheme.sansFont(size: 16, weight: .bold))
              .foregroundColor(AppTheme.foreground)

            ForEach(Array(design.steps.enumerated()), id: \.offset) { index, step in
              HStack(alignment: .top, spacing: 12) {
                Text("\(index + 1)")
                  .font(AppTheme.sansFont(size: 12, weight: .bold))
                  .foregroundColor(AppTheme.iconOnAccent)
                  .frame(width: 20, height: 20)
                  .background(Circle().fill(AppTheme.primary.opacity(0.8)))

                Text(step)
                  .font(AppTheme.sansFont(size: 14))
                  .foregroundColor(AppTheme.foreground)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
          }
        }
      }
      .padding(24)
      .background(AppTheme.card)
      .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
      .padding(.horizontal, 24)
      .padding(.top, -20)
      .zIndex(1)

      Spacer(minLength: 32)

      // Footer Slogan
      Text("Created with Floraboard")
        .font(AppTheme.sansFont(size: 12, weight: .medium))
        .foregroundColor(AppTheme.mutedText)
        .padding(.bottom, 32)
    }
    .frame(width: 380)
    .background(AppTheme.premiumGradient)
  }
}
