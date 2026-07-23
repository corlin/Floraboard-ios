# Specification: UI Design Audit & Optimization Strategy

## Executive Summary
This specification presents a comprehensive UI/UX audit and optimization strategy for **Floraboard iOS**, based on the design principles of **Apple Human Interface Guidelines (WWDC Fluid Interfaces)** and **Emil Kowalski's Design Engineering Philosophy**.

The goal is to elevate the visual craft, motion physics, tactile feedback, and spatial consistency of Floraboard iOS to match top-tier Apple native applications.

---

## Constitution Alignment Check
Compliance with [Floraboard iOS Constitution](file:///.specify/memory/constitution.md):
- [x] **Principle 1 (SwiftUI & AppTheme)**: All proposed design tokens and motion parameters will be centralized in `AppTheme.swift`.
- [x] **Principle 2 (Strict MVVM)**: Motion, haptics, and visual states are strictly encapsulated within View/ViewModifier layers.
- [x] **Principle 3 (Zero Client Secrets)**: No changes to backend/AI proxy boundaries.
- [x] **Principle 4 (Localization & Motion)**: Maintains full `Localization.swift` compatibility and enhances haptics/fluid motion.

---

## Comprehensive Design Audit & Optimization Table

As required by Emil's Design Engineering review guidelines, the table below documents the current state, proposed optimization, and rationale:

| Before (Current Codebase) | After (Proposed Optimization) | Why (Design Engineering & Apple Design Rationale) |
| --- | --- | --- |
| `PrimaryButtonStyle` / `SecondaryButtonStyle` uses `.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)` | Change to `.animation(.spring(response: 0.25, dampingFraction: 1.0), value: isPressed)` with instant touch-down scale `0.97` | Standard UI buttons should be critically damped (`damping = 1.0`). Overshoot (`damping < 1.0`) on a simple press release feels wobbly and distracting. |
| Button styles lack built-in haptic feedback on touch-down | Integrate `UIImpactFeedbackGenerator(style: .light).impactOccurred()` on press state activation | Apple Multimodal Feedback Rule: Visual feedback + haptic feedback must fire on the exact same frame on pointer-down. |
| `FloatingTabBar.swift` uses `DispatchQueue.main.asyncAfter(deadline: .now() + 0.35)` to reset bounce state | Replace artificial timer with direct spring state binding `.spring(response: 0.35, dampingFraction: 0.75)` | Apple Latency Rule #1: Eliminate artificial timers and debounces on input paths. Motion should settle naturally via spring physics. |
| `GlassmorphicCard` stacks `.background(.ultraThinMaterial)` directly over `AppTheme.card` (`alpha: 0.6`) | Refactor `AppTheme.card` glass token to a single unified material layer with crisp 0.5pt light-catching border (`stroke(hairline)`) | Emil Material Rule: Never stack multiple translucent layers over each other; visual legibility collapses and background blur becomes murky. |
| Large display titles (`displayLarge`: 34pt) use default letter spacing | Apply size-specific negative tracking (`tracking(-0.5)` / `-0.02em`) for titles and positive tracking (`tracking(0.2)` / `+0.01em`) for captions | Apple Typography Rule #15: Large display text requires negative letter spacing to look tight and authoritative; small text needs positive spacing for legibility. |
| Sheet entrances (`DesignExecutionSheet`, `InventoryAnalyticsSheet`) use standard slide transitions without velocity handoff | Apply custom spring `response: 0.35, dampingFraction: 0.82` with velocity-aware dismiss gestures | Apple Fluid Motion Rule #5: Sheet dismissals must inherit drag release velocity to eliminate motion discontinuity. |
| Modal cards / empty states fade in from `scale(0)` or raw opacity | Animate from `scale(0.95)` + `opacity(0)` | Emil Principle: "Nothing in the real world appears from nothing." Animating from `scale(0.95)` creates a natural, physical entrance. |
| Icon buttons in `FloatingTabBar` have static hit areas without drag cancel padding | Expand touch target hit area with `contentShape(Rectangle())` + ~10px drag cancel hysteresis boundary | Apple Touch & Drag Rule #10: Allow cancel-by-dragging-away while maintaining instant press feedback on touch-down. |

## Clarifications

### Session 2026-07-23
- Q: 多语言中英文混排治理策略？ → A: 全量抽离与严格国际化重构（Option A）。全量扫描并抽离所有 Feature 视图中的硬编码文本（如 HomeView、PaywallView、SettingsView 等中的硬编码文本）至 `Localizable.xcstrings`，通过 `loc.t("key")` 进行多语言绑定，杜绝混排。

---

## User Stories & Acceptance Criteria

### User Story 1: Fluid & Tactile Button Feedback
- **As a** florist using Floraboard on iOS,
- **I want** buttons and interactive controls to respond instantly to my touch with subtle scaling and light haptic feedback,
- **So that** the application feels ultra-responsive, continuous, and tactile.

#### Acceptance Criteria
- [ ] Tapping any primary or secondary button triggers light haptic feedback on touch-down (`UIImpactFeedbackGenerator`).
- [ ] Pressed state scales to `0.97` instantly with critically damped spring (`dampingFraction: 1.0`, `response: 0.25`) without post-release oscillation.

### User Story 2: Natural Floating Tab Bar Navigation
- **As a** user switching tabs,
- **I want** tab selection indicators to slide smoothly without delay or lag,
- **So that** navigating between Dashboard, Inventory, Design, History, and Settings feels seamless.

#### Acceptance Criteria
- [ ] `FloatingTabBar` indicator dot uses `matchedGeometryEffect` driven by an interruptible spring animation (`response: 0.3, dampingFraction: 0.8`).
- [ ] All artificial `asyncAfter` timers are removed.

### User Story 3: Refined Typography & Glassmorphism Depth
- **As a** user viewing floral design portfolios and inventory metrics,
- **I want** headers, card backgrounds, and blurred overlays to maintain sharp legibility and premium Apple aesthetic,
- **So that** the UI looks sophisticated under both light and dark mode.

#### Acceptance Criteria
- [ ] Display titles (34pt/28pt) display tight negative letter spacing (`-0.5pt`).
- [ ] Glassmorphic cards use single-pass translucent materials with a 0.5pt light-catching highlight border.

### User Story 4: Complete Localization & Zero Mixed Language UI
- **As a** user selecting English or Simplified Chinese language in settings,
- **I want** 100% of text elements across Home, Paywall, Settings, Design, and Inventory to render in the selected language,
- **So that** there is zero mixed language UI (e.g. no English headers appearing alongside Chinese labels).

#### Acceptance Criteria
- [ ] All hardcoded strings (e.g. `Overview`, `Recent Floral Designs`, `Unlock Floreboard Pro`, `只剩 \(item.quantity)`) are extracted to `Localizable.xcstrings`.
- [ ] All SwiftUI views reference strings via `loc.t("key")` or `String(localized: "key")`.

---

## Functional Requirements

1. **Centralized Motion Tokens in `AppTheme`**:
   - `AppTheme.swift` MUST define standardized SwiftUI animation tokens:
     - `AppTheme.buttonSpring = Animation.spring(response: 0.25, dampingFraction: 1.0)`
     - `AppTheme.interactiveSpring = Animation.spring(response: 0.35, dampingFraction: 0.8)`
     - `AppTheme.sheetSpring = Animation.spring(response: 0.4, dampingFraction: 0.82)`

2. **Haptic Feedback Modifier**:
   - Create a reusable `ViewModifier` or `ButtonStyle` enhancement in `AppTheme.swift` to trigger `.light` haptics on press events.

3. **Typography Tracking Tokens**:
   - Extend `AppTheme` typography helpers to include size-appropriate letter tracking.

4. **Component Polishing**:
   - Update `PrimaryButtonStyle`, `SecondaryButtonStyle`, `FloatingTabBar`, `GlassmorphicCard`, and `WorkbenchPrimaryActionBar` across `Floreboard/App` and `Floreboard/Core/Utils`.

---

## Non-Functional Requirements

- **Frame Rate**: All transitions and spring animations MUST maintain 60fps / 120fps (ProMotion) without main thread drops.
- **Latency**: Pointer-down touch response latency MUST be under 16ms (instant visual scaling on touch).
- **Accessibility**: Honor `prefers-reduced-motion` by gracefully falling back to cross-fades (`opacity` only) without spring scale/translation.

---

## Success Criteria

1. **Touch Responsiveness**: 100% of interactive buttons provide instant visual scaling (`scale 0.97`) and haptic feedback on touch-down.
2. **Visual Consistency**: Zero stacked translucent background artifacts across all glassmorphic cards.
3. **Motion Fidelity**: Zero wobbly/oscillating button releases (`dampingFraction` set to `1.0` for button styles).
4. **Typography Quality**: Large titles have negative tracking (`-0.5pt`) consistently applied across all feature headers.
