# Feature Specification: [FEATURE_NAME]

## Executive Summary
Brief description of the feature, target user value, and primary objective.

## Constitution Alignment Check
Verify compliance with [Floraboard iOS Constitution](file:///.specify/memory/constitution.md):
- [ ] **Principle 1 (SwiftUI & AppTheme)**: Uses 100% SwiftUI and `AppTheme` design tokens.
- [ ] **Principle 2 (Strict MVVM)**: UI, ViewModel, and Service boundaries clearly defined.
- [ ] **Principle 3 (Zero Client Secrets)**: Routes all AI capabilities through managed proxy (`AIService.swift`).
- [ ] **Principle 4 (Localization & Motion)**: Uses `Localization.swift` and includes smooth transitions/haptics.

## User User Stories & Acceptance Criteria
### User Story 1
- **As a** [user role]
- **I want to** [action]
- **So that** [benefit]

#### Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2

## Functional Requirements
1. Requirement 1
2. Requirement 2

## Non-Functional Requirements
- Performance: Smooth 60/120fps animations.
- Security: Zero client API keys stored.
- Localization: Support multi-language strings.
