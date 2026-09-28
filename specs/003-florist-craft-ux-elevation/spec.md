# Feature Specification: Florist Craft & UI/UX Elevation

**Feature Directory**: [specs/003-florist-craft-ux-elevation](file:///Users/corlin/2026/Floraboard-ios/specs/003-florist-craft-ux-elevation)  
**Status**: APPROVED  
**Created**: 2026-09-28  

---

## 📌 Executive Summary

Following a comprehensive critical review of the Floraboard iOS app and florist operational workflows, this release (`003-florist-craft-ux-elevation`) bridges the final gap between design intelligence and floral craft execution:
1. **Information Architecture & Order Hub**: Promote customer orders to first-class primary navigation by transforming Tab 3 into the unified **Order & Archive Hub** (`Orders` vs `Archived Designs` segmented toggle). Bring real-time urgency to `HomeView` with a "Today's Orders" pulse card and a 3-pillar quick action bar (`Restock`, `AI Design`, `New Order`).
2. **Florist Workbench Mode**: An immersive, full-screen production view for florists working at the table. Features sticky reference visuals, tactile check-off recipe cards (`Interactive Checklist`), and a prominent tap target to mark bouquets as finished.
3. **Scroll-Aware Dynamic Tab Bar**: An Apple fluid physical navigation bar that smoothly recedes downward during downward scroll exploration and springs back instantly on upward pull, paired with an elastic gliding pill selection indicator.
4. **Florist High-Frequency Polish**: Quick inline flower wastage/restocking (+10 / -1) with `.contentTransition(.numericText())` animations and haptic feedback, plus a dual-mode proposal generator (`Client Proposal` with masked wholesale costs vs `Florist BOM` production sheet).

---

## 🏛️ Constitution & Governance Alignment

- **Principle 1 (100% SwiftUI & AppTheme Tokens)**: All views must strictly use `AppTheme` colors, fonts, glassmorphism modifiers, and spring dynamics.
- **Principle 2 (Strict MVVM)**: Business logic, order mutations, and filtering reside in `OrderViewModel`, `InventoryViewModel`, or services.
- **Principle 3 (Zero Client Secrets)**: Retain proxy-based security architecture.
- **Principle 4 (Localization & Fluid Motion)**: 100% user-facing strings must use `Tx.t(...)` / `loc.t(...)` with complete `en` and `zh-Hans` localizations in `Localizable.xcstrings`.

---

## 📖 User Stories & Requirements

### User Story 1: Unified Order Hub & Dashboard Integration (Priority: HIGH)
**As a** florist shop owner,  
**I want** to access my customer orders directly from the bottom tab bar and see today's urgent fulfillment status on the dashboard,  
**So that** I have a single pane of glass for customer deliveries and proposal history.

#### Requirements:
- **FR-101**: Update `FloatingTabBar` and `ContentView` to map Tab 3 to the unified Order Hub view (`OrderHubView`).
- **FR-102**: In `OrderHubView`, provide a glassmorphic Segmented Control toggling between `[Customer Orders]` (`OrderListView`) and `[Design Archive]` (`HistoryView`).
- **FR-103**: In `HomeView`, add a "Today's Orders" stat badge highlighting orders due today or in production, and update Quick Actions to 3 buttons: Restock (`+ 花材`), Smart Design (`✨ AI设计`), Quick Order (`📋 新建订单`).

---

### User Story 2: Immersive Florist Workbench Mode (Priority: HIGH)
**As a** florist preparing bouquets at the physical table,  
**I want** an immersive, distraction-free workbench view with big touch targets and recipe checkmarks,  
**So that** I can easily cross off flower stems with wet hands without accidental navigation.

#### Requirements:
- **FR-201**: Add "Enter Workbench Mode" action in `OrderDetailView` when order is in `inProduction` status.
- **FR-202**: Display full-screen immersive view with sticky high-res bouquet thumbnail, recipe checklist with one-tap strike-through and haptic feedback.
- **FR-203**: Add persistent "Complete Bouquet" action capsule that transitions the order to `delivered` / ready and returns smoothly.

---

### User Story 3: Scroll-Aware Floating Tab Bar Dynamics (Priority: MEDIUM)
**As an** iOS user browsing long inventories and order books,  
**I want** the floating tab bar to auto-hide when scrolling down and spring back on scroll up,  
**So that** bottom screen content and buttons are never obscured.

#### Requirements:
- **FR-301**: Implement directional scroll detection in `ContentView` / list views that smoothly translates the tab bar off-screen downwards on scroll down.
- **FR-302**: Instantly spring the tab bar back when scroll direction reverses upward.
- **FR-303**: Upgrade the active tab selection indicator from a static dot to an elastic gliding pill background.

---

### User Story 4: Inline Wastage/Restock & Dual-Mode Client Proposal (Priority: MEDIUM)
**As a** florist managing daily flower loss and sending quotes to brides,  
**I want** to quickly log -1 wilted stems directly from the list and export a client-safe proposal poster without wholesale costs,  
**So that** daily inventory maintenance takes seconds and customer quotes look luxurious.

#### Requirements:
- **FR-401**: In `FlowerRow`, provide quick inline adjustments (+10 restock, -1 waste loss) with numeric transition animations and haptics.
- **FR-402**: In `SharePosterView`, add a segmented toggle between `[Client Proposal]` (hides wholesale costs and internal notes, emphasizes romance and beauty) and `[Florist BOM]` (full ingredients and steps).
