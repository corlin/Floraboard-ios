# Tasks Breakdown: Florist Craft & UI/UX Elevation

**Feature Directory**: [specs/003-florist-craft-ux-elevation](file:///Users/corlin/2026/Floraboard-ios/specs/003-florist-craft-ux-elevation)  
**Spec**: [spec.md](file:///Users/corlin/2026/Floraboard-ios/specs/003-florist-craft-ux-elevation/spec.md)  
**Plan**: [plan.md](file:///Users/corlin/2026/Floraboard-ios/specs/003-florist-craft-ux-elevation/plan.md)  

---

## Phase 1: Localization & Foundational Tokens

- [x] T001 [P] Add all localization keys for Order Hub, Workbench Mode, and Proposal Modes in [Floreboard/Localizable.xcstrings](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Localizable.xcstrings)

---

## Phase 2: User Story 1 - Order Hub & Navigation Integration

- [x] T002 [US1] Create `OrderHubView.swift` integrating `OrderListView` and `HistoryView` under a glassmorphic Segmented Control in [Floreboard/Features/Orders/OrderHubView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Orders/OrderHubView.swift)
- [x] T003 [US1] Update `ContentView.swift` and `FloatingTabBar.swift` to route Tab 3 to `OrderHubView` with appropriate tab icons and labels in [Floreboard/App/ContentView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/App/ContentView.swift) and [Floreboard/Core/Utils/FloatingTabBar.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Utils/FloatingTabBar.swift)
- [x] T004 [US1] Update `HomeView.swift` with "Today's Orders" pulse overview card and 3-action quick panel (Restock, AI Design, New Order) in [Floreboard/Features/Home/HomeView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Home/HomeView.swift)

---

## Phase 3: User Story 2 - Immersive Florist Workbench Mode

- [x] T005 [P] [US2] Implement `FloristWorkbenchView.swift` featuring sticky reference visual, recipe check-off checklist with haptics, and big complete button in [Floreboard/Features/Orders/FloristWorkbenchView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Orders/FloristWorkbenchView.swift)
- [x] T006 [US2] Connect `OrderDetailView.swift` to launch `FloristWorkbenchView` when in production state in [Floreboard/Features/Orders/OrderDetailView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Orders/OrderDetailView.swift)

---

## Phase 4: User Story 3 - Scroll-Aware Tab Bar Dynamics

- [x] T007 [US3] Implement dynamic scroll direction tracking and hide/show translation physics for `FloatingTabBar` in [Floreboard/Core/Utils/FloatingTabBar.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Utils/FloatingTabBar.swift) and [Floreboard/App/ContentView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/App/ContentView.swift)
- [x] T008 [US3] Implement elastic gliding pill selection animation for active tab in [Floreboard/Core/Utils/FloatingTabBar.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Utils/FloatingTabBar.swift)

---

## Phase 5: User Story 4 - Daily Wastage & Dual-Mode Proposal Poster

- [x] T009 [US4] Add quick inline -1 wastage / +10 restock interaction in `FlowerRow` with `.contentTransition(.numericText())` in [Floreboard/Features/Inventory/InventoryRowView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Inventory/InventoryRowView.swift)
- [x] T010 [US4] Add `Client Proposal` vs `Florist BOM` toggle in `SharePosterView` to conceal wholesale costs in [Floreboard/Features/Design/SharePosterView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Design/SharePosterView.swift)

---

## Phase 6: Build Verification & Regression Testing

- [x] T011 Run Xcode build to verify zero compile errors, test localization coverage, and test navigation flows
