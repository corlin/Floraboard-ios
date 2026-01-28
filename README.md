# 🌺 Floraboard iOS (Native)

This is the native iOS client for **Floraboard**, built completely with **SwiftUI** for maximum performance and platform integration. It complements the web application by providing a robust, on-the-go experience for florists on iPhone and iPad.

## ✨ Key Features

*   **Native Performance**: 100% SwiftUI interface with smooth animations and transitions.
*   **AI-Powered Design**: Integrated `AIService` for generating floral arrangements and "Image to Flower" analysis directly on device.
*   **Inventory Management**: dedicated `InventoryViews` for managing stock with haptic feedback.
*   **History & Portfolio**: Browse past designs in `HistoryViews` with zoomable image support (`ZoomableImageView`).
*   **Secure Storage**: Uses `KeychainManager` for secure API key and credential storage.
*   **Theme Aware**: centralized `AppTheme` managing colors and typography to match the brand identity.
*   **Localization**: Built-in support for multiple languages via `Localization.swift`.

## 🏗 Architecture

The app follows a modern **MVVM (Model-View-ViewModel)** architecture:

*   **Models**: `Models.swift`, `DesignModels.swift`, `Item.swift` - define core data structures.
*   **Views**: `ContentView`, `DesignViews`, `InventoryViews`, `SettingsViews` - SwiftUI declarative UI.
*   **ViewModels**: `ViewModels.swift` - manages state and business logic, separating UI from data.
*   **Services**:
    *   `AIService.swift`: Handles communication with LLM/GenAI providers (Aliyun/OpenAI).
    *   `Services.swift`: Core business logic services.
    *   `ImagePersistence.swift`: Handles local caching and storage of design images.

## 🛠 Requirements

*   **Xcode**: 15.0+
*   **iOS**: 17.0+
*   **Swift**: 5.9+

## 🚀 Getting Started

1.  **Open Project**:
    Double-click `Floreboard.xcodeproj` to open the project in Xcode.

2.  **Configuration**:
    *   Select your development team in **Signing & Capabilities**.
    *   Ensure the Bundle Identifier matches your provisioning profile.

3.  **Build & Run**:
    *   Select a simulator (e.g., iPhone 15 Pro) or a connected real device.
    *   Press `Cmd + R` to build and run.

4.  **API Keys**:
    User API keys (for AI services) are stored securely in the Keychain. You can configure them inside the app's **Settings** tab.

## 🔧 Development Scripts

The project includes helper scripts in the `scripts/` directory to automate common tasks.

### App Icon Generation
To generate standard iOS icon sizes from the master 1024pt icon:
```bash
python3 scripts/generate_icons.py
```
This will populate `misc/icons/` with resized assets (e.g., for marketing or legacy support). The app itself uses the single-size `AppIcon.png` in `Assets.xcassets`.
## 📂 Project Structure

```
Floreboard/
├── AppTheme.swift         # Design system (Colors, Fonts)
├── Models/
│   ├── Models.swift       # Shared models
│   ├── Item.swift         # Inventory item model
│   └── DesignModels.swift # Design request/result models
├── Views/
│   ├── ContentView.swift  # App Entry & TabView
│   ├── DesignViews.swift  # Design generation flow
│   ├── InventoryViews.swift # Stock management
│   └── SettingsViews.swift # App configuration
├── ViewModels/
│   └── ViewModels.swift   # Logic controllers
├── Services/
│   ├── AIService.swift    # AI Integration
│   ├── Services.swift     # General backend services
│   └── KeychainManager.swift # Security
└── Resources/
    └── Assets.xcassets    # Images and Colors
```
