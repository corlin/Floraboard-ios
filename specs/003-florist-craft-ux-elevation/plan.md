# Implementation Plan: Florist Craft & UI/UX Elevation

**Feature Directory**: [specs/003-florist-craft-ux-elevation](file:///Users/corlin/2026/Floraboard-ios/specs/003-florist-craft-ux-elevation)  
**Spec**: [spec.md](file:///Users/corlin/2026/Floraboard-ios/specs/003-florist-craft-ux-elevation/spec.md)  
**Status**: APPROVED  

---

## Architecture & Component Design

```
Floreboard/
├── App/
│   ├── ContentView.swift                // Embeds OrderHubView for Tab 3; scroll offset binding
│   └── Localization.swift               // Key definitions for Order Hub, Workbench, Proposal Modes
├── Core/
│   └── Utils/
│       └── FloatingTabBar.swift         // Elastic gliding pill indicator + hide translation offset
├── Features/
│   ├── Home/
│   │   └── HomeView.swift               // "Today's Orders" pulse card + 3-action bar
│   ├── Orders/
│   │   ├── OrderHubView.swift           // NEW: Segmented Hub for [Orders] and [Archive]
│   │   ├── OrderListView.swift          // Filterable orders list with quick tap actions
│   │   ├── OrderDetailView.swift        // Order details with "Launch Workbench" trigger
│   │   └── FloristWorkbenchView.swift   // NEW: Immersive full-screen production focus view
│   ├── Inventory/
│   │   └── InventoryRowView.swift       // Quick inline stepper (+10 / -1) with numericText transition
│   └── Design/
│       └── SharePosterView.swift        // Client Proposal vs Florist BOM dual-mode export
```

---

## Technical Specifications

1. **Order Hub Segmented Control**:
   - `OrderHubView.swift`: hosts `@State private var selectedTab: Int = 0` (0: Orders, 1: History Archive).
   - Glassmorphic segmented capsule selector matching `AppTheme.surfaceGlass`.
2. **Florist Workbench Mode**:
   - `FloristWorkbenchView.swift`: Presented `.fullScreenCover(isPresented: $showWorkbench)`.
   - Recipe checklist backed by `@State private var checkedItems: Set<UUID> = []`.
   - Tactile feedback via `HapticManager.shared.impact(style: .rigid)`.
3. **Scroll-Aware Tab Bar**:
   - CoordinateSpace scroll offset tracker or directional delta publisher in list views.
   - Smooth `offset(y: isTabBarHidden ? 100 : 0)` with `AppTheme.interactiveSpring`.
   - Matched geometry gliding capsule behind active tab icon and label.
4. **Quick Wastage & Dual Proposal**:
   - `FlowerRow.swift`: Add compact step buttons or swipe action for rapid -1 wastage, triggering `.contentTransition(.numericText())`.
   - `SharePosterView.swift`: Add proposal view state (`isClientMode: Bool`), toggling prices to show only total retail price while omitting internal steps.
