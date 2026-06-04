import SwiftUI

struct FlowerRow: View {
  let flower: FlowerType
  var onEdit: () -> Void
  var onDelete: () -> Void

  private var stockLevel: StockLevel {
    if flower.quantity == 0 { return .out }
    if flower.quantity < 10 { return .low }
    return .normal
  }

  var body: some View {
    HStack(spacing: 14) {
      // Flower color indicator
      ZStack {
        Circle()
          .fill(Color(string: flower.color))
          .frame(width: 44, height: 44)
          .overlay(
            Circle()
              .stroke(AppTheme.hairline.opacity(0.5), lineWidth: 1)
          )

        // Low stock badge
        if stockLevel != .normal {
          Circle()
            .fill(stockLevel == .out ? AppTheme.danger : AppTheme.warning)
            .frame(width: 12, height: 12)
            .overlay(
              Circle().stroke(AppTheme.card, lineWidth: 2)
            )
            .offset(x: 15, y: -15)
        }
      }

      // Name + category
      VStack(alignment: .leading, spacing: 4) {
        Text(flower.name)
          .font(AppTheme.sansFont(size: 16, weight: .semibold))
          .foregroundColor(AppTheme.foreground)
          .lineLimit(1)

        HStack(spacing: 6) {
          Text(flower.category.displayName)
            .font(AppTheme.sansFont(size: 12, weight: .medium))
            .foregroundColor(AppTheme.primary.opacity(0.8))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppTheme.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

          if let meaning = flower.meaning, !meaning.isEmpty {
            Text(meaning)
              .font(AppTheme.sansFont(size: 12))
              .foregroundColor(AppTheme.mutedText)
              .lineLimit(1)
          }
        }
      }

      Spacer()

      // Stock + price (primary data)
      VStack(alignment: .trailing, spacing: 4) {
        Text("\(flower.quantity)")
          .font(AppTheme.sansFont(size: 20, weight: .bold))
          .foregroundColor(stockLevel.color)
          .contentTransition(.numericText())

        Text(CurrencyFormat.compact(flower.retailPrice))
          .font(AppTheme.sansFont(size: 13, weight: .medium))
          .foregroundColor(AppTheme.mutedText)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .glassmorphic()
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(flower.name), \(Tx.t("inventory.row.stock")) \(flower.quantity), \(CurrencyFormat.compact(flower.retailPrice))")
  }
}

private enum StockLevel {
  case normal, low, out

  var color: Color {
    switch self {
    case .normal: return AppTheme.foreground
    case .low: return AppTheme.warning
    case .out: return AppTheme.danger
    }
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
