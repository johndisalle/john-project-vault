import SwiftUI

struct SplashScreenView: View {
    @Environment(AppState.self) private var appState
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            VaultTheme.backgroundGradient
                .ignoresSafeArea()

            // Ambient glow behind logo
            Circle()
                .fill(VaultTheme.gold.opacity(0.06))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .opacity(glowOpacity)

            VStack(spacing: 28) {
                Spacer()

                // Vault Icon with rotating ring
                ZStack {
                    // Outer rotating ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [VaultTheme.gold.opacity(0.0), VaultTheme.gold.opacity(0.4), VaultTheme.gold.opacity(0.0)],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 156, height: 156)
                        .rotationEffect(.degrees(ringRotation))

                    Circle()
                        .fill(VaultTheme.gold.opacity(0.1))
                        .frame(width: 140, height: 140)

                    Circle()
                        .stroke(VaultTheme.goldGradient, lineWidth: 3)
                        .frame(width: 140, height: 140)

                    Text("PV")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(VaultTheme.goldGradient)
                        .shimmer()
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App Title
                VStack(spacing: 10) {
                    Text("Project+ Vault")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(VaultTheme.goldGradient)

                    Text("Your Personal Project+ Treasure Trove")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))

                    Text("Ace the PK0-005 Exam")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(VaultTheme.gold.opacity(0.5))
                }
                .opacity(taglineOpacity)

                Spacer()

                // Loading dots
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        LoadingDot(delay: Double(i) * 0.2)
                    }
                }
                .opacity(taglineOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            Haptics.medium()

            withAnimation(.easeOut(duration: 0.9)) {
                logoScale = 1.0
                logoOpacity = 1.0
                glowOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.7).delay(0.4)) {
                taglineOpacity = 1.0
            }

            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                Haptics.light()
                withAnimation(.easeInOut(duration: 0.4)) {
                    appState.showSplash = false
                }
            }
        }
    }
}

struct LoadingDot: View {
    let delay: Double
    @State private var opacity: Double = 0.3

    var body: some View {
        Circle()
            .fill(VaultTheme.gold)
            .frame(width: 6, height: 6)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay)) {
                    opacity = 1.0
                }
            }
    }
}
