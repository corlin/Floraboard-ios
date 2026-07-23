# Implementation Plan: UI Design Audit & Optimization Strategy

**Feature Directory**: [specs/001-ui-design-audit](file:///Users/corlin/2026/Floraboard-ios/specs/001-ui-design-audit)  
**Spec Document**: [spec.md](file:///Users/corlin/2026/Floraboard-ios/specs/001-ui-design-audit/spec.md)  
**Created**: 2026-07-23  

---

## Technical Context & Architecture

- **Language / Framework**: Swift 5.9+, SwiftUI, UIKit (for `UIImpactFeedbackGenerator`).
- **Target Platform**: iOS 17.0+
- **Architecture Pattern**: MVVM + Centralized Design Tokens (`AppTheme.swift`).
- **Design Foundations**: Apple WWDC Fluid Interfaces (Spring Physics, Multimodal Feedback, Optical Letter Spacing) & Emil Kowalski's Design Engineering Principles (Critically Damped Buttons, Zero Artificial Timers, Non-stacking Glass Materials).

---

## Constitution Compliance Check

Compliance with [Floraboard iOS Constitution](file:///.specify/memory/constitution.md):
- [x] **Principle 1 (SwiftUI & AppTheme)**: All spring presets, typography tracking, and material tokens are defined in `AppTheme.swift`.
- [x] **Principle 2 (Strict MVVM)**: UI animations, gestures, and haptic feedback modifiers are isolated in View/ViewModifier layers without polluting ViewModel business logic.
- [x] **Principle 3 (Zero Client Secrets)**: No changes to backend proxy or security boundaries.
- [x] **Principle 4 (Localization & Motion)**: Full support for `Localization.swift` and accessible reduced-motion fallbacks.

---

## Proposed Changes by Component

### Component 1: Core Design System & Tokens
#### [MODIFY] [AppTheme.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/App/AppTheme.swift)
- **Spring Tokens**: Add standardized motion tokens:
  - `static let buttonSpring = Animation.spring(response: 0.25, dampingFraction: 1.0)` (Critically damped, no wobbly overshoot on press release)
  - `static let interactiveSpring = Animation.spring(response: 0.35, dampingFraction: 0.8)`
  - `static let sheetSpring = Animation.spring(response: 0.4, dampingFraction: 0.82)`
- **Haptics Integration**: Add `HapticFeedbackModifier` and helper methods for pointer-down light impact feedback (`UIImpactFeedbackGenerator(style: .light)`).
- **Typography Tracking**:
  - `displayLarge`: Add `.tracking(-0.5)` for tight display headings.
  - `caption` / `captionSmall`: Add `.tracking(0.15)` for legible micro-copy.
- **Glassmorphic Material Fix**: Simplify `GlassmorphicCard` modifier to use a single `.ultraThinMaterial` pass with `AppTheme.surfaceGlass` fill, preventing material stacking color turbidity.
- **Button Styles**:
  - Update `PrimaryButtonStyle` and `SecondaryButtonStyle` to use `AppTheme.buttonSpring` and trigger haptic impact on `isPressed == true`.

---

### Component 2: Core Utility Components
#### [MODIFY] [FloatingTabBar.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Utils/FloatingTabBar.swift)
- **Eliminate Artificial Timers**: Remove `DispatchQueue.main.asyncAfter(deadline: .now() + 0.35)` artificial timer for `bounceItemID`.
- **Spring Motion**: Drive selection state and scale bounce purely through `withAnimation(AppTheme.interactiveSpring)`.
- **Touch Targets**: Add proper hit target padding and touch-down feedback.

---

### Component 3: Feature Action Bars & Forms
#### [MODIFY] [AppTheme.swift - WorkbenchPrimaryActionBar](file:///Users/corlin/2026/Floraboard-ios/Floreboard/App/AppTheme.swift#L328-L381)
- Update `WorkbenchPrimaryActionBar` button press animations to use `AppTheme.buttonSpring` with haptics.

---

## Verification & Quickstart Plan

### Automated Verification
- Run Swift syntax / build validation via Xcode command line tools or Xcode IDE.

### Manual Visual & Motion Verification
1. **Button Scale & Haptics**:
   - Tap any primary or secondary button on iPhone Simulator or physical device.
   - Verify press scale is `0.97` without wobble on release. Verify light haptic tap on device.
2. **Floating Tab Bar**:
   - Tap between tabs in `FloatingTabBar`. Verify indicator dot moves continuously without timer lag.
3. **Glassmorphism & Typography**:
   - Inspect card background transparency over `PremiumBackgroundView` floating orbs. Confirm background blur remains crisp.
   - Verify header titles (`displayLarge`) display tight negative letter spacing.
