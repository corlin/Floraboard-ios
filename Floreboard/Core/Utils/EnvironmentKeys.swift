import SwiftUI

// MARK: - AIService Environment Key

private struct AIServiceKey: EnvironmentKey {
    static let defaultValue = AIService.shared
}

extension EnvironmentValues {
    var aiService: AIService {
        get { self[AIServiceKey.self] }
        set { self[AIServiceKey.self] = newValue }
    }
}

// MARK: - ImagePersistence Environment Key

private struct ImagePersistenceKey: EnvironmentKey {
    static let defaultValue = ImagePersistence.shared
}

extension EnvironmentValues {
    var imagePersistence: ImagePersistence {
        get { self[ImagePersistenceKey.self] }
        set { self[ImagePersistenceKey.self] = newValue }
    }
}

// MARK: - HapticManager Environment Key

private struct HapticManagerKey: EnvironmentKey {
    static let defaultValue = HapticManager.shared
}

extension EnvironmentValues {
    var hapticManager: HapticManager {
        get { self[HapticManagerKey.self] }
        set { self[HapticManagerKey.self] = newValue }
    }
}
