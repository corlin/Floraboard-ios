# Implementation Plan: Order Fulfillment, LLM Streaming & UX Polish

**Feature Directory**: [specs/002-business-llm-ux-enhancements](file:///Users/corlin/2026/Floraboard-ios/specs/002-business-llm-ux-enhancements)  
**Spec**: [spec.md](file:///Users/corlin/2026/Floraboard-ios/specs/002-business-llm-ux-enhancements/spec.md)  
**Status**: IN_PLANNING  
**Created**: 2026-07-23  

---

## 🏗️ Architecture & Technology Stack

- **UI Framework**: Native SwiftUI (iOS 17.0+)
- **Design Tokens**: `AppTheme.swift` (Colors, Radius, Elevation, Fonts, Spring Tokens)
- **Data Persistence**: SwiftData (`@Model OrderRecord`, `ModelContext`)
- **State Management**: SwiftUI `@EnvironmentObject` (`InventoryService`, `LocalizationManager`, `AuthService`)
- **LLM Proxy Protocol**: `AIProxyClient` with EventStream SSE parser and async background image optimizer (`UIImage` resize + JPEG compression)
- **Export System**: `UIActivityViewController` wrapped in SwiftUI `Sheet` for purchase order sharing
- **UX & Animations**: SwiftUI `SkeletonShimmerView` modifier, `withAnimation(AppTheme.interactiveSpring)`, ProMotion 120Hz gesture physics

---

## 🏛️ Constitution Check

| Principle | Status | Enforcement Plan |
|---|---|---|
| **1. 100% SwiftUI & AppTheme** | ✅ PASS | All new UI components (Order Cards, Shimmer, Export Sheets) use `AppTheme` tokens |
| **2. Strict MVVM Architecture** | ✅ PASS | Business logic in `OrderViewModel.swift` & `OrderService.swift` |
| **3. Zero Client Secrets** | ✅ PASS | All SSE streaming requests pass through managed AI Proxy backend |
| **4. Localization & Seamless Motion** | ✅ PASS | All strings extracted to `Localizable.xcstrings`, springs bound to `AppTheme` |

---

## 🗺️ Implementation Phases

### Phase 1: Business Workflows - Order State Machine & Stock Locking
- Add `OrderRecord` SwiftData model & `OrderStatus` enum (`draft`, `quoted`, `confirmed`, `inProduction`, `delivered`, `cancelled`).
- Add `OrderService.swift` managing order creation, status transitions, and automatic stock locking in `InventoryService.swift`.
- Create `OrderListView.swift` & `OrderDetailView.swift` for customer order fulfillment tracking.
- Add "Convert to Order" action in AI Design detail sheets.

### Phase 2: Restocking & Purchase Order Export
- Implement `PurchaseOrderGenerator` formatting low-stock items into structured restocking text.
- Add "Export Purchase Order" action in `InventoryView` & `InventoryAnalyticsSheetView`.
- Implement `ActivityView` wrapper around `UIActivityViewController` for instant WeChat/SMS sharing.

### Phase 3: LLM Architecture - SSE Streaming & Reference Image Preprocessing
- Implement EventStream token reader in `AIProxyClient` for `v1/designs/plan` / `v1/designs/visual`.
- Connect streaming tokens to `DesignViewModel` for real-time typing effect during AI generation.
- Add `ImageCompressor` utility scaling reference images to max 1280px edge and 0.75 JPEG quality before upload.

### Phase 4: UX & Motion Craft - Skeleton Shimmer & Fluid Physics
- Implement `SkeletonShimmerView` modifier with `AppTheme.surfaceGlass` background and animated gradient highlight.
- Connect progressive AI status badges (`[1/3] Palette`, `[2/3] Stock`, `[3/3] Recipe`) to AI design generation UI.
- Enhance `ZoomableImageView` and Modal Sheet gestures with velocity handoff and rubber-banding physics.

### Phase 5: Verification & Documentation
- Build check and zero syntax errors verification.
- Update `walkthrough.md` with complete implementation summary.
