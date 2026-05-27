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
    light: UIColor(red: 0.95, green: 0.97, blue: 0.95, alpha: 1),
    dark: UIColor(red: 0.07, green: 0.09, blue: 0.09, alpha: 1)
  )

  static let backgroundAccent = dynamic(
    light: UIColor(red: 0.90, green: 0.95, blue: 0.92, alpha: 1),
    dark: UIColor(red: 0.10, green: 0.13, blue: 0.12, alpha: 1)
  )

  static let foreground = dynamic(
    light: UIColor(red: 0.12, green: 0.15, blue: 0.14, alpha: 1),
    dark: UIColor(red: 0.92, green: 0.95, blue: 0.92, alpha: 1)
  )

  static let mutedText = dynamic(
    light: UIColor(red: 0.40, green: 0.45, blue: 0.42, alpha: 1),
    dark: UIColor(red: 0.68, green: 0.73, blue: 0.69, alpha: 1)
  )

  static let card = dynamic(
    light: UIColor(red: 0.99, green: 1.00, blue: 0.98, alpha: 0.96),
    dark: UIColor(red: 0.12, green: 0.15, blue: 0.14, alpha: 0.96)
  )

  static let surfaceGlass = dynamic(
    light: UIColor(red: 0.98, green: 1.00, blue: 0.98, alpha: 0.76),
    dark: UIColor(red: 0.15, green: 0.18, blue: 0.17, alpha: 0.78)
  )

  static let surfaceElevated = dynamic(
    light: UIColor(red: 1.00, green: 1.00, blue: 0.99, alpha: 0.90),
    dark: UIColor(red: 0.17, green: 0.20, blue: 0.19, alpha: 0.90)
  )

  static let surfaceStrong = dynamic(
    light: UIColor(red: 1.00, green: 1.00, blue: 0.99, alpha: 0.98),
    dark: UIColor(red: 0.22, green: 0.25, blue: 0.24, alpha: 0.98)
  )

  static let hairline = dynamic(
    light: UIColor(red: 0.78, green: 0.84, blue: 0.79, alpha: 0.72),
    dark: UIColor(red: 0.48, green: 0.56, blue: 0.51, alpha: 0.28)
  )

  static let primary = dynamic(
    light: UIColor(red: 0.16, green: 0.42, blue: 0.30, alpha: 1),
    dark: UIColor(red: 0.44, green: 0.78, blue: 0.59, alpha: 1)
  )

  static let secondary = dynamic(
    light: UIColor(red: 0.46, green: 0.36, blue: 0.52, alpha: 1),
    dark: UIColor(red: 0.72, green: 0.63, blue: 0.80, alpha: 1)
  )

  static let accent = dynamic(
    light: UIColor(red: 0.72, green: 0.48, blue: 0.22, alpha: 1),
    dark: UIColor(red: 0.94, green: 0.72, blue: 0.38, alpha: 1)
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
  static let shadow = Color.black.opacity(0.10)
  static let cardRadius: CGFloat = 8
  static let controlRadius: CGFloat = 8
  static let imageRadius: CGFloat = 10

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
      .background(AppTheme.card)
      .cornerRadius(AppTheme.cardRadius)
      .shadow(color: AppTheme.shadow, radius: 8, x: 0, y: 3)
      .overlay(
        RoundedRectangle(cornerRadius: AppTheme.cardRadius)
          .stroke(AppTheme.hairline, lineWidth: 1)
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
      .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius))
      .shadow(color: AppTheme.primary.opacity(0.25), radius: 6, x: 0, y: 3)
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
