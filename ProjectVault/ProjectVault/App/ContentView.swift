import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    private let service = DataService.shared

    var body: some View {
        ZStack {
            if appState.showSplash {
                SplashScreenView()
            } else if let error = service.loadError {
                errorView(error)
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appState.showSplash)
    }

    private func errorView(_ message: String) -> some View {
        ZStack {
            VaultTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(VaultTheme.warningAmber)

                Text("Unable to Load Questions")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("Please reinstall the app or contact support@ellasid.com")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }
}
