import SwiftUI

struct FlowerRow: View {
  let flower: FlowerType
  var onEdit: () -> Void
  var onDelete: () -> Void

  // Computed Margin
  var marginPercent: Int {
    guard flower.retailPrice > 0 else { return 0 }
    return Int(((flower.retailPrice - flower.unitCost) / flower.retailPrice) * 100)
  }

  var marginColor: Color {
    if marginPercent >= 60 {
      return AppTheme.success
    } else if marginPercent >= 40 {
      return AppTheme.stockRisk
    } else {
      return AppTheme.danger
    }
  }

  var body: some View {
    HStack(spacing: 16) {
      // Color Circle with Low Stock Indicator
      ZStack {
        Circle()
          .fill(Color(string: flower.color))
          .frame(width: 48, height: 48)
          .overlay(Circle().stroke(AppTheme.hairline, lineWidth: 2))
          .shadow(radius: 2)

        if flower.quantity < 10 {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(AppTheme.danger)
            .background(Circle().fill(AppTheme.surfaceStrong))
            .offset(x: 16, y: -16)
        }
      }

      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text(flower.name)
            .font(AppTheme.serifFont(size: 18, weight: .semibold))
            .foregroundColor(AppTheme.foreground)

          // Category Badge
          Text(flower.category.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppTheme.primary.opacity(0.1))
            .foregroundColor(AppTheme.primary)
            .cornerRadius(4)
        }

        // Stats Row
        HStack(spacing: 12) {
          Text("\(Tx.t("inventory.row.stock")): \(flower.quantity)")
            .font(AppTheme.sansFont(size: 12))
            .foregroundColor(flower.quantity < 10 ? AppTheme.danger : AppTheme.mutedText)

          Text("\(Tx.t("inventory.row.used")): \(flower.totalUsed ?? 0)")
            .font(AppTheme.sansFont(size: 12))
            .foregroundColor(AppTheme.operationalInfo)
        }

        // Tags
        if let tags = flower.cultureTags, !tags.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              ForEach(tags, id: \.self) { tag in
                Text(Tx.t("inventory.form.cultureOptions.\(tag.lowercased())"))
                  .font(.caption2)
                  .padding(.horizontal, 4)
                  .padding(.vertical, 2)
                  .overlay(
                    RoundedRectangle(cornerRadius: 4).stroke(
                      AppTheme.hairline, lineWidth: 1)
                  )
                  .foregroundColor(AppTheme.mutedText)
              }
            }
          }
        }
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 4) {
        // Price & Cost
        HStack(spacing: 4) {
          Text(CurrencyFormat.compact(flower.retailPrice))
            .font(AppTheme.sansFont(size: 16, weight: .bold))
            .foregroundColor(AppTheme.primary)
          Text("(\(CurrencyFormat.compact(flower.unitCost)))")
            .font(AppTheme.sansFont(size: 12))
            .foregroundColor(AppTheme.mutedText)
        }

        // Margin
        Text("\(Tx.t("inventory.row.margin")): \(marginPercent)%")
          .font(.caption.bold())
          .foregroundColor(marginColor)

        HStack {
          Button(action: onEdit) {
            Image(systemName: "pencil.circle.fill")
              .foregroundColor(AppTheme.foreground.opacity(0.6))
              .font(.title2)
          }

          Button(action: onDelete) {
            Image(systemName: "trash.circle.fill")
              .foregroundColor(AppTheme.danger.opacity(0.7))
              .font(.title2)
          }
        }
        .padding(.top, 4)
      }
    }
    .padding()
    .glassmorphic()
  }
}

extension Color {
  // Helper to convert string color to Color
  init(string: String) {
    let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines)

    if normalized.hasPrefix("#") {
      let hex = String(normalized.dropFirst())
      var value: UInt64 = 0

      if Scanner(string: hex).scanHexInt64(&value) {
        switch hex.count {
        case 6:
          let red = Double((value & 0xFF0000) >> 16) / 255
          let green = Double((value & 0x00FF00) >> 8) / 255
          let blue = Double(value & 0x0000FF) / 255
          self = Color(red: red, green: green, blue: blue)
          return
        case 8:
          let alpha = Double((value & 0xFF000000) >> 24) / 255
          let red = Double((value & 0x00FF0000) >> 16) / 255
          let green = Double((value & 0x0000FF00) >> 8) / 255
          let blue = Double(value & 0x000000FF) / 255
          self = Color(red: red, green: green, blue: blue, opacity: alpha)
          return
        default:
          break
        }
      }
    }

    switch normalized.lowercased() {
    case "red": self = .red
    case "white": self = .white
    case "pink": self = .pink
    case "yellow": self = .yellow
    case "blue": self = .blue
    case "green": self = .green
    case "purple": self = .purple
    case "orange": self = .orange
    default: self = .gray
    }
  }
}
