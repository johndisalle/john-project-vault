import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false

    var body: some View {
        @Bindable var state = appState
        TabView(selection: $state.selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            settingsButton
                        }
                    }
            }

            Tab("Study", systemImage: "books.vertical.fill", value: .study) {
                StudyView()
            }

            Tab("Quiz", systemImage: "bolt.fill", value: .quiz) {
                QuickQuizView()
            }

            Tab("Mock Exam", systemImage: "clock.badge.checkmark.fill", value: .mockExam) {
                MockExamView()
            }

            Tab("Vault", systemImage: "lock.shield.fill", value: .vault) {
                VaultView()
            }
        }
        .tint(VaultTheme.gold)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showSettings = false
                            } label: {
                                Text("Done")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(VaultTheme.gold)
                            }
                        }
                    }
            }
        }
    }

    private var settingsButton: some View {
        Button {
            Haptics.light()
            showSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
