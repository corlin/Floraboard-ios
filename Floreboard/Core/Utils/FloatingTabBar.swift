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
    var isHidden: Bool = false
    @EnvironmentObject var loc: LocalizationManager
    @Namespace private var indicatorNamespace

    var items: [TabBarItem] = [
        TabBarItem(id: 0, iconDefault: "square.grid.2x2", iconSelected: "square.grid.2x2.fill", localizationKey: "app.nav.dashboard"),
        TabBarItem(id: 1, iconDefault: "leaf", iconSelected: "leaf.fill", localizationKey: "app.nav.inventory"),
        TabBarItem(id: 2, iconDefault: "wand.and.stars", iconSelected: "wand.and.stars", localizationKey: "app.nav.design"),
        TabBarItem(id: 3, iconDefault: "shippingbox", iconSelected: "shippingbox.fill", localizationKey: "app.nav.orders_hub"),
        TabBarItem(id: 4, iconDefault: "gearshape", iconSelected: "gearshape.fill", localizationKey: "app.nav.settings"),
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                tabItemView(item)
            }
        }
        .frame(height: 62)
        .padding(.horizontal, 6)
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
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .offset(y: isHidden ? 100 : 0)
        .opacity(isHidden ? 0 : 1)
        .animation(AppTheme.interactiveSpring, value: isHidden)
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
            ZStack {
                // Elastic gliding pill background for selected tab
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(AppTheme.primary.opacity(0.12))
                        .matchedGeometryEffect(id: "tab_pill", in: indicatorNamespace)
                }

                VStack(spacing: 3) {
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .medium))
                        .scaleEffect(isSelected ? 1.10 : 1.0)
                        .animation(AppTheme.interactiveSpring, value: selection)

                    Text(loc.t(item.localizationKey))
                        .font(AppTheme.captionSmall)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .lineLimit(1)

                    // Indicator dot
                    if isSelected {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 4, height: 4)
                            .matchedGeometryEffect(id: "tab_indicator", in: indicatorNamespace)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.vertical, 6)
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
