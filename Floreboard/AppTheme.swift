//
//  AppTheme.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import SwiftUI
import UIKit

struct AppTheme {
  // MARK: - Core Palette

  static let background = dynamic(
    light: UIColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1),
    dark: UIColor(red: 0.08, green: 0.10, blue: 0.09, alpha: 1)
  )

  static let backgroundAccent = dynamic(
    light: UIColor(red: 0.97, green: 0.90, blue: 0.88, alpha: 1),
    dark: UIColor(red: 0.15, green: 0.10, blue: 0.12, alpha: 1)
  )

  static let foreground = dynamic(
    light: UIColor(red: 0.20, green: 0.16, blue: 0.18, alpha: 1),
    dark: UIColor(red: 0.94, green: 0.90, blue: 0.86, alpha: 1)
  )

  static let mutedText = dynamic(
    light: UIColor(red: 0.45, green: 0.39, blue: 0.39, alpha: 1),
    dark: UIColor(red: 0.68, green: 0.63, blue: 0.60, alpha: 1)
  )

  static let card = dynamic(
    light: UIColor(red: 1.00, green: 0.98, blue: 0.94, alpha: 0.88),
    dark: UIColor(red: 0.14, green: 0.16, blue: 0.14, alpha: 0.88)
  )

  static let surfaceGlass = dynamic(
    light: UIColor(red: 1.00, green: 0.98, blue: 0.94, alpha: 0.58),
    dark: UIColor(red: 0.18, green: 0.20, blue: 0.18, alpha: 0.62)
  )

  static let surfaceElevated = dynamic(
    light: UIColor(red: 1.00, green: 0.98, blue: 0.95, alpha: 0.72),
    dark: UIColor(red: 0.20, green: 0.22, blue: 0.20, alpha: 0.72)
  )

  static let surfaceStrong = dynamic(
    light: UIColor(red: 1.00, green: 0.99, blue: 0.96, alpha: 0.88),
    dark: UIColor(red: 0.24, green: 0.26, blue: 0.24, alpha: 0.88)
  )

  static let hairline = dynamic(
    light: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.58),
    dark: UIColor(red: 0.63, green: 0.69, blue: 0.62, alpha: 0.22)
  )

  static let primary = dynamic(
    light: UIColor(red: 0.73, green: 0.27, blue: 0.38, alpha: 1),
    dark: UIColor(red: 0.95, green: 0.49, blue: 0.58, alpha: 1)
  )

  static let secondary = dynamic(
    light: UIColor(red: 0.35, green: 0.50, blue: 0.32, alpha: 1),
    dark: UIColor(red: 0.58, green: 0.75, blue: 0.50, alpha: 1)
  )

  static let accent = dynamic(
    light: UIColor(red: 0.78, green: 0.58, blue: 0.21, alpha: 1),
    dark: UIColor(red: 0.96, green: 0.76, blue: 0.36, alpha: 1)
  )

  static let info = dynamic(
    light: UIColor(red: 0.22, green: 0.43, blue: 0.66, alpha: 1),
    dark: UIColor(red: 0.46, green: 0.68, blue: 0.90, alpha: 1)
  )

  static let creative = dynamic(
    light: UIColor(red: 0.50, green: 0.34, blue: 0.63, alpha: 1),
    dark: UIColor(red: 0.74, green: 0.59, blue: 0.88, alpha: 1)
  )

  static let success = dynamic(
    light: UIColor(red: 0.22, green: 0.52, blue: 0.28, alpha: 1),
    dark: UIColor(red: 0.43, green: 0.78, blue: 0.49, alpha: 1)
  )

  static let warning = dynamic(
    light: UIColor(red: 0.76, green: 0.46, blue: 0.12, alpha: 1),
    dark: UIColor(red: 0.95, green: 0.65, blue: 0.24, alpha: 1)
  )

  static let danger = dynamic(
    light: UIColor(red: 0.72, green: 0.20, blue: 0.22, alpha: 1),
    dark: UIColor(red: 0.95, green: 0.45, blue: 0.45, alpha: 1)
  )

  static let iconOnAccent = Color.white
  static let scrim = Color.black.opacity(0.36)
  static let shadow = Color.black.opacity(0.12)

  // MARK: - Gradients & Textures

  static var premiumGradient: LinearGradient {
    LinearGradient(
      gradient: Gradient(colors: [
        background,
        backgroundAccent,
      ]),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  // MARK: - Typography
  // In a real app, you'd load custom fonts. For now, we map to system fonts with traits.

  static func serifFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
    // Fallback to system serif (New York)
    return .system(size: size, weight: weight, design: .serif)
  }

  static func sansFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
    return .system(size: size, weight: weight, design: .default)
  }

  private static func dynamic(light: UIColor, dark: UIColor) -> Color {
    Color(
      UIColor { traits in
        traits.userInterfaceStyle == .dark ? dark : light
      }
    )
  }
}

// MARK: - View Modifiers

struct GlassmorphicCard: ViewModifier {
  func body(content: Content) -> some View {
    content
      .background(.ultraThinMaterial)
      .background(AppTheme.card)
      .cornerRadius(20)
      .shadow(color: AppTheme.shadow, radius: 15, x: 0, y: 5)
      .overlay(
        RoundedRectangle(cornerRadius: 20)
          .stroke(
            LinearGradient(
              colors: [AppTheme.hairline, AppTheme.hairline.opacity(0.35)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ), lineWidth: 1)
      )
  }
}

struct PrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(AppTheme.sansFont(size: 16, weight: .semibold))
      .padding(.vertical, 14)
      .padding(.horizontal, 24)
      .background(AppTheme.primary)
      .foregroundColor(AppTheme.iconOnAccent)
      .clipShape(Capsule())
      .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .animation(.spring(response: 0.3), value: configuration.isPressed)
  }
}

extension View {
  func glassmorphic() -> some View {
    self.modifier(GlassmorphicCard())
  }

  func hideKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
