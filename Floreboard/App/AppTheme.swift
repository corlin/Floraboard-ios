import SwiftUI
import UIKit

struct AppTheme {
  // MARK: - Core Palette
  // A clean, bright, premium glassmorphism iOS app for florists.
  // Soft green and white palette, highly polished, beautiful modern UI.

  static let background = dynamic(
    light: UIColor(red: 0.96, green: 0.98, blue: 0.97, alpha: 1.0),
    dark: UIColor(red: 0.05, green: 0.07, blue: 0.06, alpha: 1.0)
  )

  static let backgroundAccent = dynamic(
    light: UIColor(red: 0.91, green: 0.95, blue: 0.93, alpha: 1.0),
    dark: UIColor(red: 0.08, green: 0.11, blue: 0.09, alpha: 1.0)
  )

  static let foreground = dynamic(
    light: UIColor(red: 0.10, green: 0.14, blue: 0.12, alpha: 1.0),
    dark: UIColor(red: 0.94, green: 0.96, blue: 0.95, alpha: 1.0)
  )

  static let mutedText = dynamic(
    light: UIColor(red: 0.45, green: 0.50, blue: 0.47, alpha: 1.0),
    dark: UIColor(red: 0.60, green: 0.65, blue: 0.62, alpha: 1.0)
  )

  static let card = dynamic(
    light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6),
    dark: UIColor(red: 0.12, green: 0.15, blue: 0.13, alpha: 0.6)
  )

  static let hairline = dynamic(
    light: UIColor(red: 0.85, green: 0.88, blue: 0.86, alpha: 0.5),
    dark: UIColor(red: 0.35, green: 0.40, blue: 0.38, alpha: 0.3)
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

  static let primary = dynamic(
    light: UIColor(red: 0.18, green: 0.49, blue: 0.36, alpha: 1.0), // Elegant deep green
    dark: UIColor(red: 0.35, green: 0.70, blue: 0.53, alpha: 1.0)
  )

  static let secondary = dynamic(
    light: UIColor(red: 0.45, green: 0.60, blue: 0.50, alpha: 1.0),
    dark: UIColor(red: 0.65, green: 0.80, blue: 0.70, alpha: 1.0)
  )

  static let accent = dynamic(
    light: UIColor(red: 0.85, green: 0.58, blue: 0.45, alpha: 1.0), // Soft peach/gold
    dark: UIColor(red: 0.92, green: 0.68, blue: 0.55, alpha: 1.0)
  )

  static let info = dynamic(
    light: UIColor(red: 0.35, green: 0.55, blue: 0.75, alpha: 1.0),
    dark: UIColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1.0)
  )

  static let creative = dynamic(
    light: UIColor(red: 0.65, green: 0.45, blue: 0.75, alpha: 1.0),
    dark: UIColor(red: 0.80, green: 0.65, blue: 0.90, alpha: 1.0)
  )

  static let success = dynamic(
    light: UIColor(red: 0.28, green: 0.65, blue: 0.40, alpha: 1.0),
    dark: UIColor(red: 0.45, green: 0.85, blue: 0.60, alpha: 1.0)
  )

  static let warning = dynamic(
    light: UIColor(red: 0.85, green: 0.65, blue: 0.25, alpha: 1.0),
    dark: UIColor(red: 0.95, green: 0.80, blue: 0.45, alpha: 1.0)
  )

  static let danger = dynamic(
    light: UIColor(red: 0.85, green: 0.35, blue: 0.35, alpha: 1.0),
    dark: UIColor(red: 0.95, green: 0.55, blue: 0.55, alpha: 1.0)
  )

  static let iconOnAccent = Color.white
  static let scrim = Color.black.opacity(0.3)

  static let shadow = Color.black.opacity(0.10)

  // MARK: - Elevation System
  static let elevation1 = (color: Color.black.opacity(0.04), radius: CGFloat(8), y: CGFloat(4))
  static let elevation2 = (color: Color.black.opacity(0.08), radius: CGFloat(16), y: CGFloat(8))
  static let elevation3 = (color: Color.black.opacity(0.12), radius: CGFloat(24), y: CGFloat(12))

  // MARK: - Radius System
  static let containerRadius: CGFloat = 24
  static let cardRadius: CGFloat = 20
  static let controlRadius: CGFloat = 16
  static let chipRadius: CGFloat = 10
  static let imageRadius: CGFloat = 16

  // MARK: - Spacing System (4pt grid)
  struct Spacing {
      static let xxs: CGFloat = 4
      static let xs: CGFloat = 8
      static let sm: CGFloat = 12
      static let md: CGFloat = 16
      static let lg: CGFloat = 24
      static let xl: CGFloat = 32
      static let xxl: CGFloat = 48
  }

  // MARK: - Product Semantic Colors
  static let inventory = primary
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
  static func serifFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
    return .system(size: size, weight: weight, design: .serif)
  }

  static func sansFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
    return .system(size: size, weight: weight, design: .default)
  }

  // MARK: - Typography Tokens
  static let displayLarge = serifFont(size: 34, weight: .bold)
  static let displayMedium = serifFont(size: 28, weight: .bold)
  static let headlineLarge = serifFont(size: 24, weight: .semibold)
  static let headlineMedium = serifFont(size: 20, weight: .semibold)
  static let headlineSmall = serifFont(size: 18, weight: .semibold)
  static let titleLarge = sansFont(size: 18, weight: .semibold)
  static let titleMedium = sansFont(size: 16, weight: .semibold)
  static let titleSmall = sansFont(size: 14, weight: .semibold)
  static let bodyLarge = sansFont(size: 16, weight: .regular)
  static let bodyMedium = sansFont(size: 15, weight: .regular)
  static let bodySmall = sansFont(size: 14, weight: .regular)
  static let labelLarge = sansFont(size: 14, weight: .medium)
  static let labelMedium = sansFont(size: 13, weight: .medium)
  static let labelSmall = sansFont(size: 12, weight: .medium)
  static let caption = sansFont(size: 12, weight: .regular)
  static let captionSmall = sansFont(size: 11, weight: .regular)

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
      .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
      .shadow(color: AppTheme.elevation2.color, radius: AppTheme.elevation2.radius, x: 0, y: AppTheme.elevation2.y)
      .overlay(
        RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
          .stroke(AppTheme.hairline, lineWidth: 0.5)
      )
  }
}

struct PrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(AppTheme.titleMedium)
      .padding(.vertical, 16)
      .padding(.horizontal, 24)
      .background(
        LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.opacity(0.8)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .foregroundColor(AppTheme.iconOnAccent)
      .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
      .shadow(color: AppTheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
      .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
      .opacity(configuration.isPressed ? 0.9 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

struct WorkbenchSearchField: View {
  let placeholder: String
  @Binding var text: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(AppTheme.mutedText)
        .frame(width: 20)

      TextField(placeholder, text: $text)
        .font(AppTheme.sansFont(size: 16))
        .foregroundColor(AppTheme.foreground)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .submitLabel(.search)

      if !text.isEmpty {
        Button {
          text = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(AppTheme.mutedText.opacity(0.7))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(.ultraThinMaterial)
    .background(AppTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
        .stroke(AppTheme.hairline, lineWidth: 0.5)
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
            .font(.system(size: 16, weight: .semibold))
        }
        Text(title)
          .font(AppTheme.sansFont(size: 16, weight: .semibold))
      }
      .foregroundColor(AppTheme.iconOnAccent)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(
        (isEnabled && !isLoading) ?
        AnyView(LinearGradient(colors: [AppTheme.primary, AppTheme.primary.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)) :
        AnyView(AppTheme.mutedText.opacity(0.45))
      )
      .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
      .shadow(
        color: (isEnabled && !isLoading) ? AppTheme.primary.opacity(0.3) : Color.clear,
        radius: AppTheme.elevation3.radius,
        x: 0,
        y: AppTheme.elevation3.y
      )
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled || isLoading)
    .padding(.horizontal, 20)
    .padding(.top, 24)
    .padding(.bottom, 16)
    .background(
      LinearGradient(
        colors: [
          AppTheme.background.opacity(0.0),
          AppTheme.background.opacity(0.95)
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

  func keyboardDismissToolbar() -> some View {
    self.toolbar {
      ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") {
          UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
      }
    }
  }
}
