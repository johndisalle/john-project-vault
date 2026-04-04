import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        TabView(selection: $state.selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView()
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
    }
}
