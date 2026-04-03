import SwiftUI

@main
struct ProjectVaultApp: App {
    @State private var appState = AppState()
    @State private var storeKit = StoreKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(storeKit)
                .preferredColorScheme(.dark)
        }
    }
}
