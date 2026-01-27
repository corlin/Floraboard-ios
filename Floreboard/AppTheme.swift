//
//  AppTheme.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import SwiftUI
import UIKit

struct AppTheme {
  // MARK: - Core Palette (Oklch adapted to SRGB for iOS)

  // Web: --background: oklch(0.97 0.02 95); -> Soft Cream
  static let background = Color(hue: 0.26, saturation: 0.1, brightness: 0.98)

  // Web: --foreground: oklch(0.35 0.05 340); -> Deep Warm Grey
  static let foreground = Color(hue: 0.94, saturation: 0.1, brightness: 0.25)

  // Web: --card: oklch(0.985 0.01 95);
  static let card = Color(hue: 0.26, saturation: 0.05, brightness: 0.99)

  // Web: --primary: oklch(0.65 0.18 20); -> Muted Rose
  static let primary = Color(hue: 0.95, saturation: 0.65, brightness: 0.75)
  // static let primary = Color(red: 220/255, green: 110/255, blue: 130/255) // Approximate

  // Web: --secondary: oklch(0.90 0.08 140); -> Sage Green
  static let secondary = Color(hue: 0.35, saturation: 0.25, brightness: 0.88)

  // Web: --accent: oklch(0.90 0.10 85); -> Soft Gold
  static let accent = Color(hue: 0.12, saturation: 0.35, brightness: 0.92)

  // MARK: - Gradients & Textures

  static var premiumGradient: LinearGradient {
    LinearGradient(
      gradient: Gradient(colors: [
        background,
        Color(hue: 0.95, saturation: 0.05, brightness: 0.96),  // faint rose tint
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
}

// MARK: - View Modifiers

struct GlassmorphicCard: ViewModifier {
  func body(content: Content) -> some View {
    content
      .background(.ultraThinMaterial)
      .background(AppTheme.card.opacity(0.6))
      .cornerRadius(20)
      .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
      .overlay(
        RoundedRectangle(cornerRadius: 20)
          .stroke(
            LinearGradient(
              colors: [.white.opacity(0.6), .white.opacity(0.1)],
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
      .foregroundColor(.white)
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
