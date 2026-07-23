# Feature Specification: Order Fulfillment, LLM Streaming & UX Polish

**Feature Directory**: [specs/002-business-llm-ux-enhancements](file:///Users/corlin/2026/Floraboard-ios/specs/002-business-llm-ux-enhancements)  
**Status**: DRAFT  
**Created**: 2026-07-23  

---

## 📌 Executive Summary

This specification defines the second major feature release (`002-business-llm-ux-enhancements`) for Floraboard iOS. Based on the comprehensive project analysis (`/speckit-analyze`), this release delivers end-to-end enhancements across three core domains:
1. **Business Workflows**: Order fulfillment lifecycle state machine (`Draft` -> `Quoted` -> `Confirmed` -> `InProduction` -> `Delivered`), automatic inventory locking upon order confirmation, and one-tap purchase order text/data export for florist suppliers.
2. **LLM Architecture**: AI Proxy streaming response parsing (SSE typing effect for design inspiration descriptions) and client-side reference image preprocessing (1280px max edge, 0.75 JPEG compression, <500KB footprint).
3. **UX & Design Craft**: Skeleton Shimmer placeholder animations during AI generation and Apple fluid motion physical rubber-banding drag dynamics for modal sheets and image previewers.

---

## 🏛️ Constitution & Governance Alignment

This specification strictly adheres to the project constitution ([constitution.md](file:///Users/corlin/2026/Floraboard-ios/.specify/memory/constitution.md)):
- **Principle 1 (100% SwiftUI & AppTheme Tokens)**: All new UI views (Skeleton Shimmer, Order Cards, Export Sheets) MUST reference `AppTheme.swift` tokens and styles.
- **Principle 2 (Strict MVVM)**: Business logic, order state mutations, and streaming token assembly MUST reside in ViewModels or Services (`OrderService.swift`, `AIProxyClient.swift`).
- **Principle 3 (Zero Client Secrets)**: Streaming AI requests MUST go through the managed AI Proxy backend without exposing API keys.
- **Principle 4 (Localization & Seamless Motion)**: All user-visible strings MUST use `LocalizationManager` (`loc.t(...)` / `Tx.t(...)`) with full `en` and `zh-Hans` coverage. Motion springs MUST use `AppTheme` spring tokens.

---

## 📖 User Stories & Requirements

### User Story 1: Order Lifecycle Fulfillment & Inventory Locking (Priority: HIGH)
**As a** florist owner,  
**I want** to track customer orders across explicit fulfillment states (`Draft` -> `Quoted` -> `Confirmed` -> `InProduction` -> `Delivered`),  
**So that** inventory items mapped to a confirmed order are automatically locked and deducted, preventing over-selling across multiple draft proposals.

#### Requirements:
- **FR-101**: Define `OrderRecord` model with `OrderStatus` enum (`draft`, `quoted`, `confirmed`, `inProduction`, `delivered`, `cancelled`).
- **FR-102**: When an order transitions to `confirmed`, automatically deduct/lock the mapped flower quantities in `InventoryService`.
- **FR-103**: Allow converting an AI-generated design directly into a new Customer Order.

---

### User Story 2: Smart Purchase Order Export (Priority: MEDIUM)
**As a** florist shop manager,  
**I want** to generate a formatted purchase order when inventory items drop below safety thresholds,  
**So that** I can share the restocking request with flower suppliers via WeChat, Message, or Email in one tap.

#### Requirements:
- **FR-201**: Add "Export Purchase Order" button in Inventory & Analytics sheets.
- **FR-202**: Format restocking items into a clean text/table summary (Flower Name, Deficit Count, Unit Cost, Suggested Supplier Note).
- **FR-203**: Present native iOS `UIActivityViewController` share sheet for instant copying/sharing.

---

### User Story 3: LLM Streaming & Image Compression (Priority: HIGH)
**As a** florist designer using Visual Muse and AI Plan generation,  
**I want** to see AI design descriptions stream in real-time with a typing effect and have reference images compressed before upload,  
**So that** initial response perception is fast (<1s) and image uploads consume minimal bandwidth.

#### Requirements:
- **FR-301**: Implement SSE / Stream Token parsing in `AIProxyClient` for AI design generation, emitting incremental text tokens to `DesignViewModel`.
- **FR-302**: Automatically downscale and compress Visual Muse reference images on background thread (max 1280px edge, JPEG 0.75 quality, target <500KB) prior to pre-signed URL upload.

---

### User Story 4: Skeleton Shimmer & Fluid Motion Physics (Priority: MEDIUM)
**As an** iOS app user,  
**I want** elegant Skeleton Shimmer animations during AI generation and smooth rubber-banding physics when dragging image previews,  
**So that** the app feels ultra-premium, fluid, and responsive according to Apple Design guidelines.

#### Requirements:
- **FR-401**: Create `SkeletonShimmerView` view modifier using `AppTheme.surfaceGlass` with progressive status text badges (`[1/3] Analyzing Palette...`, `[2/3] Matching Stock...`, `[3/3] Assembling Recipe`).
- **FR-402**: Enhance `ZoomableImageView` and modal sheet drag gestures with velocity-based inertia decay and rubber-banding spring physics.

---

## 💬 Clarifications & Decision Log (Session 2026-07-23)

- **Decision 1**: Consolidated all 3 domains into a single unified release (`002-business-llm-ux-enhancements`).
- **Decision 2**: Approved 5 order fulfillment statuses (`draft`, `quoted`, `confirmed`, `inProduction`, `delivered`) and `UIActivityViewController` purchase order text export.
- **Decision 3**: Approved EventStream typing effect for LLM responses and client-side 1280px / JPEG 0.75 image compression.
- **Decision 4**: Approved Skeleton Shimmer placeholders with progressive status badges and Apple Design velocity rubber-banding.
