import SwiftUI

@Observable
final class AppState {
    var progress: UserProgress
    var showSplash = true
    var selectedTab: AppTab = .home

    enum AppTab: Int, CaseIterable {
        case home, study, quiz, mockExam, vault
    }

    init() {
        self.progress = DataService.shared.loadProgress()
    }

    func refreshProgress() {
        progress = DataService.shared.loadProgress()
    }

    func resetAllProgress() {
        DataService.shared.resetProgress()
        progress = UserProgress()
    }

    var questionsAnsweredToday: Int {
        let calendar = Calendar.current
        return progress.quizHistory
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.totalQuestions }
    }

    var dailyGoal: Int { 20 }

    var dailyGoalProgress: Double {
        min(Double(questionsAnsweredToday) / Double(dailyGoal), 1.0)
    }
}
