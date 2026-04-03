import SwiftUI

struct SplashScreenView: View {
    @Environment(AppState.self) private var appState
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack {
            VaultTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Vault Icon
                ZStack {
                    Circle()
                        .fill(VaultTheme.gold.opacity(0.15))
                        .frame(width: 140, height: 140)

                    Circle()
                        .stroke(VaultTheme.goldGradient, lineWidth: 3)
                        .frame(width: 140, height: 140)

                    Text("PV")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(VaultTheme.goldGradient)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App Title
                VStack(spacing: 8) {
                    Text("Project+ Vault")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(VaultTheme.goldGradient)

                    Text("Your Personal Project+ Treasure Trove")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))

                    Text("Ace the PK0-005 Exam")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(VaultTheme.gold.opacity(0.6))
                }
                .opacity(taglineOpacity)

                Spacer()

                // Loading indicator
                ProgressView()
                    .tint(VaultTheme.gold)
                    .opacity(taglineOpacity)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                taglineOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    appState.showSplash = false
                }
            }
        }
    }
}
