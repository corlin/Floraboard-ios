import SwiftUI
import Combine

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

// MARK: - TabBarVisibility Environment Key

class TabBarVisibilityManager: ObservableObject {
    static let shared = TabBarVisibilityManager()
    @Published var isHidden: Bool = false
}

private struct TabBarVisibilityKey: EnvironmentKey {
    static let defaultValue = TabBarVisibilityManager.shared
}

extension EnvironmentValues {
    var tabBarVisibility: TabBarVisibilityManager {
        get { self[TabBarVisibilityKey.self] }
        set { self[TabBarVisibilityKey.self] = newValue }
    }
}

// MARK: - Scroll Aware TabBar Modifier

struct ScrollAwareTabBarModifier: ViewModifier {
    @Environment(\.tabBarVisibility) var tabBarVisibility

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 25)
                    .onChanged { value in
                        if value.translation.height < -20 {
                            if !tabBarVisibility.isHidden {
                                withAnimation(AppTheme.interactiveSpring) {
                                    tabBarVisibility.isHidden = true
                                }
                            }
                        } else if value.translation.height > 20 {
                            if tabBarVisibility.isHidden {
                                withAnimation(AppTheme.interactiveSpring) {
                                    tabBarVisibility.isHidden = false
                                }
                            }
                        }
                    }
            )
    }
}

extension View {
    func scrollAwareTabBar() -> some View {
        modifier(ScrollAwareTabBarModifier())
    }
}
