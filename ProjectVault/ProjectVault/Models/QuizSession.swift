import Foundation

struct QuizSession: Identifiable {
    let id = UUID()
    let questions: [Question]
    let domain: ExamDomain?
    let mode: QuizMode
    let startTime: Date

    var totalQuestions: Int { questions.count }

    enum QuizMode: String, Sendable {
        case practice = "Practice"
        case timed = "Timed Exam"
        case review = "Review Missed"
    }
}

struct QuizResult: Codable, Identifiable, Sendable {
    let id: UUID
    let date: Date
    let domainId: String?
    let mode: String
    let totalQuestions: Int
    let correctCount: Int
    let timeSpent: TimeInterval
    let questionResults: [QuestionResult]

    var scorePercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctCount) / Double(totalQuestions) * 100
    }

    var passed: Bool {
        scorePercentage >= 65.0
    }
}

struct QuestionResult: Codable, Identifiable, Sendable {
    let id: String
    let questionId: String
    let selectedAnswers: [String]
    let isCorrect: Bool
    let timeSpent: TimeInterval
}

struct UserProgress: Codable, Sendable {
    var totalQuestionsAnswered: Int = 0
    var totalCorrect: Int = 0
    var quizHistory: [QuizResult] = []
    var bookmarkedQuestionIds: Set<String> = []
    var missedQuestionIds: Set<String> = []
    var domainScores: [String: DomainScore] = [:]

    var overallAccuracy: Double {
        guard totalQuestionsAnswered > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalQuestionsAnswered) * 100
    }

    /// Consecutive calendar days with at least one quiz completed, ending today.
    var streak: Int {
        guard !quizHistory.isEmpty else { return 0 }

        let calendar = Calendar.current
        // Unique days that have quiz activity, sorted descending
        let uniqueDays = Set(quizHistory.map { calendar.startOfDay(for: $0.date) })
            .sorted(by: >)

        guard let mostRecent = uniqueDays.first,
              calendar.isDateInToday(mostRecent) || calendar.isDateInYesterday(mostRecent) else {
            return 0
        }

        var count = 1
        for i in 1..<uniqueDays.count {
            let expected = calendar.date(byAdding: .day, value: -1, to: uniqueDays[i - 1])!
            if calendar.isDate(uniqueDays[i], inSameDayAs: expected) {
                count += 1
            } else {
                break
            }
        }
        return count
    }
}

struct DomainScore: Codable, Sendable {
    var attempted: Int = 0
    var correct: Int = 0

    var accuracy: Double {
        guard attempted > 0 else { return 0 }
        return Double(correct) / Double(attempted) * 100
    }
}
