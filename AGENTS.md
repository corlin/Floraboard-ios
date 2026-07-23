# Agent Context & Workflow Guidelines

## Project Overview
**Floraboard iOS** is a native SwiftUI app for florists built on iOS 17.0+ / Swift 5.9+ following MVVM architecture and centralized design tokens (`AppTheme.swift`).

<!-- SPECKIT START -->
## Active Feature Context

- **Active Spec**: [spec.md](file:///Users/corlin/2026/Floraboard-ios/specs/002-business-llm-ux-enhancements/spec.md)
- **Active Implementation Plan**: [plan.md](file:///Users/corlin/2026/Floraboard-ios/specs/002-business-llm-ux-enhancements/plan.md)
- **Tasks Breakdown**: [tasks.md](file:///Users/corlin/2026/Floraboard-ios/specs/002-business-llm-ux-enhancements/tasks.md)
- **Constitution**: [constitution.md](file:///Users/corlin/2026/Floraboard-ios/.specify/memory/constitution.md)
<!-- SPECKIT END -->

## Governance & Guidelines
- Maintain 100% SwiftUI MVVM architecture.
- All colors, fonts, and motion springs MUST reference `AppTheme.swift`.
- All user strings MUST use `LocalizationManager` (`loc.t(...)` / `Tx.t(...)`).
