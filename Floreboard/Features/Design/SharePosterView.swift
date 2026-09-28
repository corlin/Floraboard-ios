import SwiftUI

struct SharePosterView: View {
  let design: DesignResult
  let image: UIImage?
  var isClientMode: Bool = true

  var body: some View {
    VStack(spacing: 0) {
      // Top header
      HStack {
        Image(systemName: "leaf.fill")
          .foregroundColor(AppTheme.primary)
          .font(.system(size: 24))
        Text(isClientMode ? "Petal & Bloom Atelier" : "Floraboard BOM")
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
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 6) {
            Text(design.title)
              .font(AppTheme.serifFont(size: 26, weight: .bold))
              .foregroundColor(AppTheme.foreground)

            if !design.meaningText.isEmpty {
              Text(design.meaningText)
                .font(AppTheme.serifFont(size: 15).italic())
                .foregroundColor(AppTheme.primary)
            }
          }

          Spacer()

          // Client Presentation Badge
          if isClientMode {
            VStack(alignment: .trailing, spacing: 2) {
              Text(Tx.t("poster.client.retail_price"))
                .font(AppTheme.captionSmall)
                .foregroundColor(AppTheme.mutedText)
              Text("¥\(String(format: "%.2f", design.totalCost))")
                .font(AppTheme.serifFont(size: 20, weight: .bold))
                .foregroundColor(AppTheme.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
          }
        }

        Text(design.description)
          .font(AppTheme.sansFont(size: 14))
          .foregroundColor(AppTheme.mutedText)
          .lineSpacing(4)
          .fixedSize(horizontal: false, vertical: true)

        Divider()
          .padding(.vertical, 4)

        if isClientMode {
          // Client Floral Palette Highlights
          VStack(alignment: .leading, spacing: 8) {
            Label(Tx.t("poster.client.aesthetic"), systemImage: "sparkles")
              .font(AppTheme.sansFont(size: 14, weight: .bold))
              .foregroundColor(AppTheme.primary)

            HStack(spacing: 8) {
              ForEach(design.flowerList.prefix(4)) { item in
                Text(item.flowerName)
                  .font(AppTheme.sansFont(size: 12, weight: .medium))
                  .foregroundColor(AppTheme.foreground)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(AppTheme.surfaceGlass, in: Capsule())
              }
            }
          }
        } else {
          // Full BOM for Florist
          VStack(alignment: .leading, spacing: 10) {
            Label(Tx.t("result.bom.title"), systemImage: "leaf.fill")
              .font(AppTheme.sansFont(size: 15, weight: .bold))
              .foregroundColor(AppTheme.foreground)

            ForEach(design.flowerList.prefix(6)) { item in
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
          }

          if !design.steps.isEmpty {
            Divider()
              .padding(.vertical, 4)

            // Steps
            VStack(alignment: .leading, spacing: 10) {
              Label(Tx.t("result.steps.title"), systemImage: "list.number")
                .font(AppTheme.sansFont(size: 15, weight: .bold))
                .foregroundColor(AppTheme.foreground)

              ForEach(Array(design.steps.prefix(4).enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                  Text("\(index + 1)")
                    .font(AppTheme.sansFont(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.iconOnAccent)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(AppTheme.primary.opacity(0.8)))

                  Text(step)
                    .font(AppTheme.sansFont(size: 13))
                    .foregroundColor(AppTheme.foreground)
                    .fixedSize(horizontal: false, vertical: true)
                }
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

      Spacer(minLength: 28)

      // Footer Slogan
      Text(isClientMode ? "Petal & Bloom · Bespoke Floral Concept" : "Floraboard Production Specification")
        .font(AppTheme.sansFont(size: 12, weight: .medium))
        .foregroundColor(AppTheme.mutedText)
        .padding(.bottom, 28)
    }
    .frame(width: 380)
    .background(AppTheme.premiumGradient)
  }
}
