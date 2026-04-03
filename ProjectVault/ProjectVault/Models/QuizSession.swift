import Foundation

struct QuizSession: Identifiable {
    let id = UUID()
    let questions: [Question]
    let domain: ExamDomain?
    let mode: QuizMode
    let startTime: Date

    var totalQuestions: Int { questions.count }

    enum QuizMode: String {
        case practice = "Practice"
        case timed = "Timed Exam"
        case review = "Review Missed"
    }
}

struct QuizResult: Codable, Identifiable {
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

struct QuestionResult: Codable, Identifiable {
    let id: String
    let questionId: String
    let selectedAnswers: [String]
    let isCorrect: Bool
    let timeSpent: TimeInterval
}

struct UserProgress: Codable {
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

    var streak: Int {
        var count = 0
        let sorted = quizHistory.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        var lastDate = Date()

        for result in sorted {
            if calendar.isDate(result.date, inSameDayAs: lastDate) ||
               calendar.isDate(result.date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: lastDate)!) {
                count += 1
                lastDate = result.date
            } else {
                break
            }
        }
        return count
    }
}

struct DomainScore: Codable {
    var attempted: Int = 0
    var correct: Int = 0

    var accuracy: Double {
        guard attempted > 0 else { return 0 }
        return Double(correct) / Double(attempted) * 100
    }
}
