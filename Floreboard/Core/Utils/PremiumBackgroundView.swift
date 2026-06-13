import SwiftUI

struct PremiumBackgroundView: View {
    @State private var animateOrbs = false

    var body: some View {
        ZStack {
            // Base layer: solid background color
            AppTheme.background
                .ignoresSafeArea()

            // Gradient overlay: subtle diagonal gradient
            LinearGradient(
                colors: [AppTheme.background, AppTheme.backgroundAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative orbs
            GeometryReader { geometry in
                // Orb 1: primary, top-right area
                Circle()
                    .fill(AppTheme.primary.opacity(0.07))
                    .frame(width: 320, height: 320)
                    .blur(radius: 100)
                    .offset(
                        x: animateOrbs ? 20 : -20,
                        y: animateOrbs ? -15 : 15
                    )
                    .position(
                        x: geometry.size.width * 0.8,
                        y: geometry.size.height * 0.15
                    )

                // Orb 2: accent, bottom-left area
                Circle()
                    .fill(AppTheme.accent.opacity(0.05))
                    .frame(width: 280, height: 280)
                    .blur(radius: 90)
                    .offset(
                        x: animateOrbs ? -15 : 15,
                        y: animateOrbs ? 20 : -20
                    )
                    .position(
                        x: geometry.size.width * 0.2,
                        y: geometry.size.height * 0.8
                    )

                // Orb 3: creative, center-bottom area
                Circle()
                    .fill(AppTheme.creative.opacity(0.04))
                    .frame(width: 240, height: 240)
                    .blur(radius: 80)
                    .offset(
                        x: animateOrbs ? 10 : -10,
                        y: animateOrbs ? -25 : 25
                    )
                    .position(
                        x: geometry.size.width * 0.5,
                        y: geometry.size.height * 0.75
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animateOrbs = true
            }
        }
    }
}

#Preview {
    PremiumBackgroundView()
}
