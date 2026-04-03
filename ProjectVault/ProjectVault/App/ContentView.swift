import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            if appState.showSplash {
                SplashScreenView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appState.showSplash)
    }
}
