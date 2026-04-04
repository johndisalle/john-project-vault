import SwiftUI

@MainActor
@Observable
final class AppState {
    var progress: UserProgress
    var showSplash = true
    var selectedTab: AppTab = .home
    var showPaywall = false
    var hasCompletedOnboarding = false
    var examDate: Date?
    var earnedBadges: Set<String> = []

    enum AppTab: Int, CaseIterable {
        case home, study, quiz, mockExam, vault
    }

    init() {
        self.progress = DataService.shared.loadProgress()
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboarding_completed")
        if let savedExamDate = UserDefaults.standard.data(forKey: "exam_date"),
           let decoded = try? JSONDecoder().decode(Date.self, from: savedExamDate) {
            self.examDate = decoded
        }
        if let savedBadges = UserDefaults.standard.stringArray(forKey: "earned_badges") {
            self.earnedBadges = Set(savedBadges)
        }
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

    // MARK: - Exam Date & Countdown

    func setExamDate(_ date: Date) {
        examDate = date
        if let encoded = try? JSONEncoder().encode(date) {
            UserDefaults.standard.set(encoded, forKey: "exam_date")
        }
    }

    var daysUntilExam: Int? {
        guard let examDate = examDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: examDate))
        return components.day
    }

    var examCountdownText: String? {
        guard let days = daysUntilExam else { return nil }
        if days <= 0 {
            return "Exam today!"
        } else if days == 1 {
            return "Tomorrow!"
        } else {
            return "\(days) days"
        }
    }

    // MARK: - Pass Prediction

    var passPredictionPercentage: Int {
        guard !progress.quizHistory.isEmpty else { return 0 }
        let recentResults = progress.quizHistory.suffix(10)
        let avgScore = recentResults.map(\.scorePercentage).reduce(0, +) / Double(recentResults.count)

        // Predict based on recent average, with confidence adjustment
        let baseScore = avgScore
        let consistency = calculateConsistency(recentResults)
        let prediction = (baseScore * 0.7) + (consistency * 30)

        return max(0, min(100, Int(prediction)))
    }

    private func calculateConsistency(_ results: [QuizResult]) -> Double {
        guard results.count > 1 else { return 0.5 }
        let scores = results.map(\.scorePercentage)
        let mean = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.map { pow($0 - mean, 2) }.reduce(0, +) / Double(scores.count)
        let stdDev = sqrt(variance)
        return max(0, min(1, 1 - (stdDev / 50)))
    }

    // MARK: - Adaptive Difficulty

    func getWeakSubObjectives() -> [String] {
        var subObjectivePerformance: [String: (attempted: Int, correct: Int)] = [:]

        for result in progress.quizHistory {
            for qResult in result.questionResults {
                if let question = DataService.shared.question(withId: qResult.questionId) {
                    let subObj = question.subObjective
                    if subObjectivePerformance[subObj] == nil {
                        subObjectivePerformance[subObj] = (0, 0)
                    }
                    subObjectivePerformance[subObj]?.attempted += 1
                    if qResult.isCorrect {
                        subObjectivePerformance[subObj]?.correct += 1
                    }
                }
            }
        }

        return subObjectivePerformance
            .filter { $0.value.attempted >= 3 && ($0.value.correct / Double($0.value.attempted)) < 0.7 }
            .sorted { $0.value.correct / Double($0.value.attempted) < $1.value.correct / Double($1.value.attempted) }
            .map(\.key)
            .prefix(4)
            .map(String.init)
    }

    // MARK: - Badges

    func earnBadge(_ badgeId: String) {
        guard !earnedBadges.contains(badgeId) else { return }
        earnedBadges.insert(badgeId)
        var badges = UserDefaults.standard.stringArray(forKey: "earned_badges") ?? []
        badges.append(badgeId)
        UserDefaults.standard.set(Array(Set(badges)), forKey: "earned_badges")
        checkAndEarnBadges()
    }

    func checkAndEarnBadges() {
        let totalAnswered = progress.totalQuestionsAnswered

        if totalAnswered >= 25 && !earnedBadges.contains("first_25") {
            earnBadge("first_25")
        }
        if totalAnswered >= 100 && !earnedBadges.contains("first_100") {
            earnBadge("first_100")
        }
        if totalAnswered >= 250 && !earnedBadges.contains("first_250") {
            earnBadge("first_250")
        }
        if totalAnswered >= 500 && !earnedBadges.contains("first_500") {
            earnBadge("first_500")
        }

        if progress.streak >= 7 && !earnedBadges.contains("week_streak") {
            earnBadge("week_streak")
        }
        if progress.streak >= 30 && !earnedBadges.contains("month_streak") {
            earnBadge("month_streak")
        }

        for domain in ExamDomain.allCases {
            let masteredCount = progress.masteredCount(for: domain)
            if masteredCount >= 20 && !earnedBadges.contains("\(domain.rawValue)_master") {
                earnBadge("\(domain.rawValue)_master")
            }
        }

        if progress.overallAccuracy >= 80 && !earnedBadges.contains("accuracy_80") {
            earnBadge("accuracy_80")
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
    }
}
