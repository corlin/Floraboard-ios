# 🌺 Floraboard iOS (Native)

This is the native iOS client for **Floraboard**, built completely with **SwiftUI** (iOS 17.0+) following MVVM architecture and centralized design system tokens (`AppTheme.swift`). It complements the web application by providing a robust, premium on-the-go experience for florists on iPhone and iPad.

---

## ✨ Key Features

* **Native SwiftUI & Apple Design**: 100% SwiftUI interface featuring critically damped spring physics (`dampingFraction: 1.0`), haptic feedback, glassmorphic card overlays, and ProMotion velocity rubber-banding drag dynamics.
* **Order Lifecycle & Automatic Stock Locking**: Full customer order fulfillment state machine (`Draft` -> `Quoted` -> `Confirmed` -> `InProduction` -> `Delivered`). Confirming an order automatically locks and deducts flower inventory (`OrderService.swift`).
* **Smart Purchase Order Export**: One-tap generation of formatted supplier restocking orders with pre-calculated deficit costs, exportable via native iOS `UIActivityViewController` share sheet.
* **LLM Streaming & Image Preprocessing**: AI Proxy streaming response parsing (real-time typing effect) and client-side photo downscaling/JPEG compression (<500KB) prior to Visual Muse uploads (`ImageCompressor.swift`).
* **Offline Intelligent Fallback Generator**: Graceful, local intelligent AI design fallback matching real-time stock when the remote AI proxy backend is offline.
* **Skeleton Shimmer Placeholders**: Elegant glassmorphic `SkeletonShimmerView` loading placeholders with 3-stage progressive AI status badges (`[1/3] Palette...`).
* **Inventory & Stock Alert Navigation**: Instant navigation from dashboard stock alerts directly to highlighted low-stock flowers.
* **100% Dual-Language String Catalog**: Fully localized in English (`en`) and Simplified Chinese (`zh-Hans`) via Apple String Catalog (`Localizable.xcstrings`).
* **Managed AI Architecture**: Zero client API key configuration. All LLM calls pass through managed AI Proxy backend.

---

## 🏗 Architecture

The app follows a modern **MVVM (Model-View-ViewModel)** architecture:

* **App**:
  * `AppTheme.swift`: Centralized design system managing colors, typography, haptics, and spring tokens.
  * `Localization.swift`: Language switcher and `Tx.t(...)` helper wrapper over String Catalog.
  * `FloreboardApp.swift`: App entry point registering SwiftData `ModelContainer` schemas (`FlowerRecord`, `DesignRecord`, `OrderRecord`).
* **Core**:
  * **Models**: `DomainModels.swift`, `PersistentModels.swift`, `Enums.swift`, `AppError.swift`.
  * **Services**: `OrderService.swift`, `InventoryService.swift`, `HistoryService.swift`, `AIService.swift`, `AIProxyClient.swift`.
  * **Utils**: `PurchaseOrderGenerator.swift`, `ImageCompressor.swift`, `ActivityView.swift`, `ZoomableImageView.swift`, `FloatingTabBar.swift`.
* **Features**:
  * `Home/`: Hero welcome, statistics overview, quick actions, low stock alerts.
  * `Inventory/`: Inventory list, search, add/edit sheets, purchase order export.
  * `Orders/`: Customer order list, status filter tabs, order detail, status transitions.
  * `Design/`: Professional AI form, Visual Muse photo generator, design execution, share posters.
  * `Analytics/`: Revenue & inventory analytics sheets.
  * `History/`: Portfolio design history and detail views.
  * `Settings/`: Account quota, store preferences, language switcher.

---

## 🛠 Requirements

* **Xcode**: 15.0+
* **iOS**: 17.0+
* **Swift**: 5.9+

---

## 🚀 Getting Started

1. **Open Project**:
   Double-click `Floreboard.xcodeproj` to open the project in Xcode.

2. **Configuration**:
   * Select your development team in **Signing & Capabilities**.
   * Ensure the Bundle Identifier matches your provisioning profile.

3. **Build & Run**:
   * Select a simulator (e.g., iPhone 15 Pro) or a connected real device.
   * Press `Cmd + R` to build and run.

---

## 📂 Project Structure

```
Floreboard/
├── App/
│   ├── AppTheme.swift         # Design system tokens & modifiers
│   ├── Localization.swift     # Localization manager & Tx.t
│   ├── FloreboardApp.swift    # App entry & SwiftData schema init
│   └── ContentView.swift      # Main navigation & floating tab bar
├── Core/
│   ├── Models/                # SwiftData & domain models
│   ├── Services/              # Order, Inventory, History, AI services
│   └── Utils/                 # Share sheets, image compressor, physics
├── Features/
│   ├── Home/                  # Dashboard & notification alerts
│   ├── Inventory/             # Stock management & purchase export
│   ├── Orders/                # Order fulfillment & status machine
│   ├── Design/                # AI design generator & Visual Muse
│   ├── Analytics/             # Revenue & stock analytics
│   ├── History/               # Saved design portfolio
│   ├── Paywall/               # Pro membership subscription
│   ├── Settings/              # Store preferences & quota
│   └── Auth/                  # Login & registration
└── Localizable.xcstrings       # Apple dual-language String Catalog
```
