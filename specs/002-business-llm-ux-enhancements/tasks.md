# Tasks Breakdown: Order Fulfillment, LLM Streaming & UX Polish

**Feature Directory**: [specs/002-business-llm-ux-enhancements](file:///Users/corlin/2026/Floraboard-ios/specs/002-business-llm-ux-enhancements)  
**Spec**: [spec.md](file:///Users/corlin/2026/Floraboard-ios/specs/002-business-llm-ux-enhancements/spec.md)  
**Plan**: [plan.md](file:///Users/corlin/2026/Floraboard-ios/specs/002-business-llm-ux-enhancements/plan.md)  

---

## Phase 1: Foundation & Order Data Models

- [x] T001 Define `OrderStatus` enum (`draft`, `quoted`, `confirmed`, `inProduction`, `delivered`, `cancelled`) and `OrderRecord` SwiftData model in [Floreboard/Core/Models/DomainModels.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Models/DomainModels.swift)
- [x] T002 Register `OrderRecord` schema in `ModelContainer` in [Floreboard/App/FloreboardApp.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/App/FloreboardApp.swift)

---

## Phase 2: User Story 1 - Order Lifecycle Fulfillment & Stock Locking

- [x] T003 [P] [US1] Create `OrderService.swift` implementing order creation, status transitions, and automatic stock deduction in `InventoryService` in [Floreboard/Core/Services/OrderService.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Services/OrderService.swift)
- [x] T004 [P] [US1] Create `OrderViewModel.swift` managing order state and filter tabs in [Floreboard/Features/Orders/OrderViewModel.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Orders/OrderViewModel.swift)
- [x] T005 [US1] Build `OrderListView.swift` & `OrderDetailView.swift` UI with status badges and inventory deduction triggers in [Floreboard/Features/Orders/OrderListView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Orders/OrderListView.swift)
- [x] T006 [US1] Add "Convert to Order" action in AI Design detail view in [Floreboard/Features/Design/DesignExecutionSheet.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Design/DesignExecutionSheet.swift)

---

## Phase 3: User Story 2 - Restocking & Purchase Order Export

- [x] T007 [P] [US2] Implement `PurchaseOrderGenerator` creating clean restocking summaries in [Floreboard/Core/Utils/PurchaseOrderGenerator.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Utils/PurchaseOrderGenerator.swift)
- [x] T008 [P] [US2] Create SwiftUI `ActivityView` UIViewControllerRepresentable wrapper for native `UIActivityViewController` in [Floreboard/Core/Utils/ActivityView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Utils/ActivityView.swift)
- [x] T009 [US2] Add "Export Purchase Order" button and share sheet trigger in [Floreboard/Features/Inventory/InventoryListView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Inventory/InventoryListView.swift) and [Floreboard/Features/Analytics/InventoryAnalyticsSheetView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Analytics/InventoryAnalyticsSheetView.swift)

---

## Phase 4: User Story 3 - LLM SSE Streaming & Reference Image Preprocessing

- [x] T010 [P] [US3] Implement SSE EventStream token reader for design plan generation in [Floreboard/Core/Services/AIProxyClient.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Services/AIProxyClient.swift)
- [x] T011 [P] [US3] Add real-time token streaming & typing effect state in [Floreboard/Features/Design/DesignMainView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Features/Design/DesignMainView.swift)
- [x] T012 [US3] Create `ImageCompressor.swift` downscaling reference photos to max 1280px edge / 0.75 JPEG before upload in [Floreboard/Core/Utils/ImageCompressor.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Utils/ImageCompressor.swift)

---

## Phase 5: User Story 4 - Skeleton Shimmer & Fluid Motion Physics

- [x] T013 [P] [US4] Create `SkeletonShimmerView` modifier and progressive AI status badges (`[1/3] Palette...`) in [Floreboard/App/AppTheme.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/App/AppTheme.swift)
- [x] T014 [US4] Enhance `ZoomableImageView` drag physics with velocity-based inertia decay and rubber-banding spring response in [Floreboard/Core/Utils/ZoomableImageView.swift](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Core/Utils/ZoomableImageView.swift)

---

## Phase 6: Verification & Double-Language Audit

- [x] T015 Perform Xcode build verification to confirm zero compiler errors and 100% string localization in [Floreboard/Localizable.xcstrings](file:///Users/corlin/2026/Floraboard-ios/Floreboard/Localizable.xcstrings)
