import SwiftUI
import UIKit

// MARK: - Tab Bar Item Model

struct TabBarItem: Identifiable {
    let id: Int
    let iconDefault: String
    let iconSelected: String
    let localizationKey: String
}

// MARK: - Floating Tab Bar

struct FloatingTabBar: View {
    @Binding var selection: Int
    @EnvironmentObject var loc: LocalizationManager
    @Namespace private var indicatorNamespace

    var items: [TabBarItem] = [
        TabBarItem(id: 0, iconDefault: "square.grid.2x2", iconSelected: "square.grid.2x2.fill", localizationKey: "app.nav.dashboard"),
        TabBarItem(id: 1, iconDefault: "leaf", iconSelected: "leaf.fill", localizationKey: "app.nav.inventory"),
        TabBarItem(id: 2, iconDefault: "wand.and.stars", iconSelected: "wand.and.stars", localizationKey: "app.nav.design"),
        TabBarItem(id: 3, iconDefault: "clock.arrow.circlepath", iconSelected: "clock.arrow.circlepath", localizationKey: "app.nav.history"),
        TabBarItem(id: 4, iconDefault: "gearshape", iconSelected: "gearshape.fill", localizationKey: "app.nav.settings"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                tabItemView(item)
            }
        }
        .frame(height: 60)
        .padding(.horizontal, 4)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.card)
        )
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 0.5)
        )
        .shadow(
            color: AppTheme.elevation3.color,
            radius: AppTheme.elevation3.radius,
            x: 0,
            y: AppTheme.elevation3.y
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    // MARK: - Single Tab Item

    @ViewBuilder
    private func tabItemView(_ item: TabBarItem) -> some View {
        let isSelected = selection == item.id
        let tintColor = isSelected ? AppTheme.primary : AppTheme.mutedText
        let iconName = isSelected ? item.iconSelected : item.iconDefault

        Button {
            guard selection != item.id else { return }

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            withAnimation(AppTheme.interactiveSpring) {
                selection = item.id
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .medium))
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(AppTheme.interactiveSpring, value: selection)

                Text(loc.t(item.localizationKey))
                    .font(AppTheme.captionSmall)
                    .lineLimit(1)

                // Indicator dot
                if isSelected {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 6, height: 6)
                        .matchedGeometryEffect(id: "tab_indicator", in: indicatorNamespace)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .foregroundColor(tintColor)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()

        VStack {
            Spacer()
            FloatingTabBar(selection: .constant(0))
        }
    }
    .environmentObject(LocalizationManager.shared)
}
