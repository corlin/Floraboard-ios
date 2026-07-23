<!--
Sync Impact Report:
- Version change: N/A → v1.0.0
- Ratification Date: 2026-07-23
- Modified principles: N/A (Initial ratification)
- Added sections: Core Principles (1-4), Governance & Versioning, Compliance & Amendments
- Templates requiring updates:
  - .specify/templates/spec-template.md (✅ initialized)
  - .specify/templates/plan-template.md (✅ initialized)
  - .specify/templates/tasks-template.md (✅ initialized)
- Follow-up TODOs: None
-->

# Floraboard iOS Project Constitution

## Executive Summary
This document defines the non-negotiable architectural principles, security boundaries, UI standards, and governance procedures for the **Floraboard iOS** native codebase. All future feature specifications (`spec.md`), implementation plans (`plan.md`), and task breakdowns (`tasks.md`) MUST strictly adhere to this constitution.

---

## Core Principles

### Principle 1: 100% SwiftUI & AppTheme Discipline
- **Mandate**: All user interfaces MUST be built using 100% declarative SwiftUI on iOS 17.0+.
- **Design System Enforcement**: Color palettes, typography, spacing, and visual styling (including glassmorphic materials) MUST exclusively reference centralized design tokens defined in `AppTheme.swift`.
- **Constraint**: Hardcoded color values, arbitrary font sizes, or ad-hoc layout margins outside `AppTheme` are STRICTLY PROHIBITED.

### Principle 2: Strict MVVM Architecture Separation
- **Mandate**: The project MUST strictly adhere to the Model-View-ViewModel (MVVM) architectural pattern.
- **Views**: SwiftUI views (`Views/`) MUST be purely presentational and reactive. Views MUST NOT perform business logic, direct network requests, or direct data mutations.
- **ViewModels**: ViewModels (`ViewModels/`) MUST handle state management, user interaction events, and coordinate business logic.
- **Services**: Services (`Services/`) MUST isolate network API calls, persistence, and external system integrations.

### Principle 3: Zero Client Secrets & Managed AI Proxy
- **Mandate**: The iOS client application MUST NEVER store, accept in user settings, or hardcode third-party API keys (e.g., OpenAI, Gemini, Claude).
- **Security Boundary**: All AI features (floral design generation, "Image to Flower" analysis) MUST communicate exclusively through `AIService.swift` targeting the managed Floreboard AI backend proxy as detailed in `docs/ai-proxy-architecture.md`.
- **Constraint**: Client-side direct LLM API invocation is STRICTLY PROHIBITED.

### Principle 4: Localization & Seamless Motion
- **Mandate**: All user-facing strings MUST be routed through `Localization.swift` for multi-language support. Hardcoded user strings in View components are PROHIBITED.
- **Interaction Quality**: UI transitions MUST include fluid animations and haptic feedback to provide a polished, premium user experience.

---

## Governance & Versioning

### Versioning Policy
This constitution uses Semantic Versioning (`vX.Y.Z`):
- **MAJOR (X)**: Removal, backward-incompatible redefinition, or fundamental overhaul of existing core principles.
- **MINOR (Y)**: Addition of new core principles or significant expansion of mandatory quality bounds.
- **PATCH (Z)**: Wording clarifications, formatting corrections, or typo fixes that do not alter principle rules.

### Amendment Procedure
1. Proposed changes to this constitution MUST be documented with rationale.
2. Updating `constitution.md` requires incrementing the version number according to SemVer rules and updating the `Sync Impact Report`.
3. All dependent templates in `.specify/templates/` MUST be validated and updated in tandem to maintain complete specification alignment.

---

## Metadata
- **Current Version**: v1.0.0
- **Ratification Date**: 2026-07-23
- **Last Amended Date**: 2026-07-23
