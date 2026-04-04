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
                .onAppear {
                    // Sync progress from iCloud if available
                    if let cloudProgress = DataService.shared.syncFromiCloud() {
                        appState.progress = cloudProgress
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)) { _ in
                    if let cloudProgress = DataService.shared.syncFromiCloud() {
                        appState.progress = cloudProgress
                    }
                }
        }
    }
}
