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
    var masteredQuestionIds: Set<String> = []
    var domainScores: [String: DomainScore] = [:]
    var flashcardStates: [String: FlashcardState] = [:]

    var overallAccuracy: Double {
        guard totalQuestionsAnswered > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalQuestionsAnswered) * 100
    }

    func masteredCount(for domain: ExamDomain) -> Int {
        let domainQuestions = DataService.shared.questions(for: domain)
        return domainQuestions.filter { masteredQuestionIds.contains($0.id) }.count
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

// MARK: - Spaced Repetition

/// SM-2 inspired state tracked per question for spaced-repetition flashcards.
struct FlashcardState: Codable, Sendable {
    var easeFactor: Double = 2.5
    var interval: Int = 1          // days until next review
    var repetitions: Int = 0
    var nextReviewDate: Date
    var lastQuality: Int = 0       // 0-5 scale (0-2 = fail, 3-5 = pass)

    init() {
        self.nextReviewDate = Date()
    }

    /// Update schedule based on self-rated quality (0-5).
    mutating func update(quality: Int) {
        lastQuality = quality
        if quality < 3 {
            // Reset on fail
            repetitions = 0
            interval = 1
        } else {
            repetitions += 1
            switch repetitions {
            case 1: interval = 1
            case 2: interval = 6
            default: interval = Int(Double(interval) * easeFactor)
            }
        }

        // Adjust ease factor (minimum 1.3)
        let q = Double(quality)
        easeFactor = max(1.3, easeFactor + 0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02))

        nextReviewDate = Calendar.current.date(byAdding: .day, value: interval, to: Date()) ?? Date()
    }

    var isDueForReview: Bool {
        Date() >= nextReviewDate
    }
}
