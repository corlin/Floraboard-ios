# Tasks Breakdown: UI Design Audit & Optimization Strategy

**Feature Directory**: [specs/001-ui-design-audit](file:///Users/corlin/2026/Floraboard-ios/specs/001-ui-design-audit)  
**Spec**: [spec.md](file:///Users/corlin/2026/Floraboard-ios/specs/001-ui-design-audit/spec.md)  
**Plan**: [plan.md](file:///Users/corlin/2026/Floraboard-ios/specs/001-ui-design-audit/plan.md)  

---

## Phase 1: Core Motion & Design Tokens Setup

- [x] T001 Define standardized motion spring tokens (`buttonSpring`, `interactiveSpring`, `sheetSpring`) and letter tracking in [Floreboard/App/AppTheme.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/App/AppTheme.swift)
- [x] T002 Add `UIImpactFeedbackGenerator` haptic trigger helper for pointer-down feedback in [Floreboard/App/AppTheme.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/App/AppTheme.swift)

---

## Phase 2: User Story 1 - Button Styles & Haptics Polish

- [x] T003 [P] [US1] Refactor `PrimaryButtonStyle` and `SecondaryButtonStyle` to use critically damped `AppTheme.buttonSpring` (`dampingFraction: 1.0`) and instant touch-down haptics in [Floreboard/App/AppTheme.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/App/AppTheme.swift)
- [x] T004 [P] [US1] Update `WorkbenchPrimaryActionBar` press animations to use `AppTheme.buttonSpring` in [Floreboard/App/AppTheme.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/App/AppTheme.swift)

---

## Phase 3: User Story 2 - Floating Tab Bar Refactoring

- [x] T005 [US2] Remove `asyncAfter` artificial timer from `FloatingTabBar` bounce logic and drive selection state using `AppTheme.interactiveSpring` in [Floreboard/Core/Utils/FloatingTabBar.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Utils/FloatingTabBar.swift)

---

## Phase 4: User Story 3 - Glassmorphic Depth & Typography

- [x] T006 [P] [US3] Refactor `GlassmorphicCard` modifier to use a single unified `.ultraThinMaterial` pass, eliminating multi-layer translucency turbidity in [Floreboard/App/AppTheme.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/App/AppTheme.swift)
- [x] T007 [P] [US3] Apply negative tracking (`-0.5pt`) to `displayLarge` and `displayMedium` typography tokens in [Floreboard/App/AppTheme.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/App/AppTheme.swift)

---

## Phase 5: User Story 4 - Complete Localization Overhaul & Mixed Language Remediation

- [x] T009 [US4] Extract hardcoded strings in [Floreboard/Features/Home/HomeView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Home/HomeView.swift) to `Localizable.xcstrings` via `loc.t("key")`
- [x] T010 [US4] Extract hardcoded strings in [Floreboard/Features/Paywall/PaywallView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Paywall/PaywallView.swift) and [Floreboard/Features/Settings/SettingsView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Settings/SettingsView.swift) to `Localizable.xcstrings`
- [x] T011 [US4] Extract hardcoded strings in [Floreboard/Features/Design/VisualMuseView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Design/VisualMuseView.swift) and [Floreboard/Features/Design/DesignExecutionSheet.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Design/DesignExecutionSheet.swift)
- [x] T012 [US4] Populate `Localizable.xcstrings` with complete English and Simplified Chinese (`zh-Hans`) translations

---

## Phase 6: Build Verification & Quality Check

- [x] T013 Perform Xcode build check to confirm clean compilation and zero syntax regressions
