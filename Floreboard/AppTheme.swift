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
  // Positioning: a calm floristry workbench, not a decorative bouquet catalog.
  // Neutral surfaces keep repeated operational screens readable; botanical, iris, brass, and slate
  // accents separate core actions from AI, finance, and informational states.

  static let background = dynamic(
    light: UIColor(red: 0.96, green: 0.97, blue: 0.95, alpha: 1),
    dark: UIColor(red: 0.06, green: 0.08, blue: 0.08, alpha: 1)
  )

  static let backgroundAccent = dynamic(
    light: UIColor(red: 0.91, green: 0.95, blue: 0.91, alpha: 1),
    dark: UIColor(red: 0.09, green: 0.12, blue: 0.11, alpha: 1)
  )

  static let foreground = dynamic(
    light: UIColor(red: 0.11, green: 0.13, blue: 0.12, alpha: 1),
    dark: UIColor(red: 0.91, green: 0.93, blue: 0.90, alpha: 1)
  )

  static let mutedText = dynamic(
    light: UIColor(red: 0.39, green: 0.43, blue: 0.40, alpha: 1),
    dark: UIColor(red: 0.66, green: 0.71, blue: 0.67, alpha: 1)
  )

  static let card = dynamic(
    light: UIColor(red: 0.99, green: 1.00, blue: 0.98, alpha: 0.98),
    dark: UIColor(red: 0.11, green: 0.14, blue: 0.13, alpha: 0.98)
  )

  static let surfaceGlass = dynamic(
    light: UIColor(red: 0.98, green: 0.99, blue: 0.97, alpha: 0.80),
    dark: UIColor(red: 0.14, green: 0.17, blue: 0.16, alpha: 0.82)
  )

  static let surfaceElevated = dynamic(
    light: UIColor(red: 1.00, green: 1.00, blue: 0.99, alpha: 0.94),
    dark: UIColor(red: 0.16, green: 0.19, blue: 0.18, alpha: 0.94)
  )

  static let surfaceStrong = dynamic(
    light: UIColor(red: 1.00, green: 1.00, blue: 0.99, alpha: 0.98),
    dark: UIColor(red: 0.22, green: 0.25, blue: 0.24, alpha: 0.98)
  )

  static let hairline = dynamic(
    light: UIColor(red: 0.75, green: 0.81, blue: 0.76, alpha: 0.74),
    dark: UIColor(red: 0.43, green: 0.52, blue: 0.47, alpha: 0.30)
  )

  static let primary = dynamic(
    light: UIColor(red: 0.10, green: 0.36, blue: 0.27, alpha: 1),
    dark: UIColor(red: 0.43, green: 0.77, blue: 0.58, alpha: 1)
  )

  static let secondary = dynamic(
    light: UIColor(red: 0.34, green: 0.48, blue: 0.35, alpha: 1),
    dark: UIColor(red: 0.58, green: 0.73, blue: 0.56, alpha: 1)
  )

  static let accent = dynamic(
    light: UIColor(red: 0.68, green: 0.43, blue: 0.19, alpha: 1),
    dark: UIColor(red: 0.92, green: 0.68, blue: 0.34, alpha: 1)
  )

  static let info = dynamic(
    light: UIColor(red: 0.22, green: 0.37, blue: 0.52, alpha: 1),
    dark: UIColor(red: 0.48, green: 0.65, blue: 0.80, alpha: 1)
  )

  static let creative = dynamic(
    light: UIColor(red: 0.49, green: 0.34, blue: 0.58, alpha: 1),
    dark: UIColor(red: 0.74, green: 0.60, blue: 0.84, alpha: 1)
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

  // MARK: - Product Semantic Colors

  static let inventory = secondary
  static let aiDesign = creative
  static let revenue = accent
  static let operationalInfo = info
  static let stockRisk = warning

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

struct WorkbenchSearchField: View {
  let placeholder: String
  @Binding var text: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(AppTheme.mutedText)
        .frame(width: 18)

      TextField(placeholder, text: $text)
        .font(AppTheme.sansFont(size: 15))
        .foregroundColor(AppTheme.foreground)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .submitLabel(.search)

      if !text.isEmpty {
        Button {
          text = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(AppTheme.mutedText.opacity(0.7))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(AppTheme.surfaceElevated)
    .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius))
    .overlay(
      RoundedRectangle(cornerRadius: AppTheme.controlRadius)
        .stroke(AppTheme.hairline, lineWidth: 1)
    )
  }
}

struct WorkbenchBottomActionBar: View {
  let title: String
  let systemImage: String
  var isLoading = false
  var isEnabled = true
  let action: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      WorkbenchPrimaryActionBar(
        title: title,
        systemImage: systemImage,
        isLoading: isLoading,
        isEnabled: isEnabled,
        action: action
      )
    }
  }
}

struct WorkbenchPrimaryActionBar: View {
  let title: String
  let systemImage: String
  var isLoading = false
  var isEnabled = true
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if isLoading {
          ProgressView()
            .tint(AppTheme.iconOnAccent)
        } else {
          Image(systemName: systemImage)
            .font(.system(size: 15, weight: .semibold))
        }

        Text(title)
          .font(AppTheme.sansFont(size: 16, weight: .semibold))
      }
      .foregroundColor(AppTheme.iconOnAccent)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .background((isEnabled && !isLoading) ? AppTheme.primary : AppTheme.mutedText.opacity(0.45))
      .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius))
      .shadow(
        color: (isEnabled && !isLoading) ? AppTheme.primary.opacity(0.22) : Color.clear,
        radius: 8,
        x: 0,
        y: 4
      )
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled || isLoading)
    .padding(.horizontal)
    .padding(.top, 18)
    .padding(.bottom, 10)
    .background(
      LinearGradient(
        colors: [
          AppTheme.background.opacity(0.0),
          AppTheme.background.opacity(0.92)
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .allowsHitTesting(false)
    )
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
