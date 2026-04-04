import XCTest
@testable import ProjectVault

final class QuizSessionTests: XCTestCase {

    // MARK: - QuizResult

    func testScorePercentage() {
        let result = QuizResult(
            id: UUID(),
            date: Date(),
            domainId: "domain_1",
            mode: "Practice",
            totalQuestions: 10,
            correctCount: 7,
            timeSpent: 120,
            questionResults: []
        )
        XCTAssertEqual(result.scorePercentage, 70.0, accuracy: 0.01)
    }

    func testScorePercentageZeroQuestions() {
        let result = QuizResult(
            id: UUID(),
            date: Date(),
            domainId: nil,
            mode: "Practice",
            totalQuestions: 0,
            correctCount: 0,
            timeSpent: 0,
            questionResults: []
        )
        XCTAssertEqual(result.scorePercentage, 0)
    }

    func testPassedAt65Percent() {
        let passing = QuizResult(id: UUID(), date: Date(), domainId: nil, mode: "Practice", totalQuestions: 100, correctCount: 65, timeSpent: 0, questionResults: [])
        XCTAssertTrue(passing.passed)

        let failing = QuizResult(id: UUID(), date: Date(), domainId: nil, mode: "Practice", totalQuestions: 100, correctCount: 64, timeSpent: 0, questionResults: [])
        XCTAssertFalse(failing.passed)
    }

    // MARK: - DomainScore

    func testDomainScoreAccuracy() {
        var score = DomainScore()
        XCTAssertEqual(score.accuracy, 0)

        score.attempted = 10
        score.correct = 8
        XCTAssertEqual(score.accuracy, 80.0, accuracy: 0.01)
    }

    // MARK: - FlashcardState SM-2

    func testFlashcardStateInitialValues() {
        let state = FlashcardState()
        XCTAssertEqual(state.easeFactor, 2.5)
        XCTAssertEqual(state.interval, 1)
        XCTAssertEqual(state.repetitions, 0)
        XCTAssertTrue(state.isDueForReview)
    }

    func testFlashcardStateFailResets() {
        var state = FlashcardState()
        state.update(quality: 4) // pass
        state.update(quality: 4) // pass again
        XCTAssertTrue(state.repetitions > 0)

        state.update(quality: 1) // fail
        XCTAssertEqual(state.repetitions, 0)
        XCTAssertEqual(state.interval, 1)
    }

    func testFlashcardStatePassIncrementsRepetitions() {
        var state = FlashcardState()
        state.update(quality: 4)
        XCTAssertEqual(state.repetitions, 1)
        XCTAssertEqual(state.interval, 1)

        state.update(quality: 4)
        XCTAssertEqual(state.repetitions, 2)
        XCTAssertEqual(state.interval, 6)
    }

    func testFlashcardEaseFactorNeverBelowMinimum() {
        var state = FlashcardState()
        // Repeatedly fail to drive ease factor down
        for _ in 0..<20 {
            state.update(quality: 0)
        }
        XCTAssertGreaterThanOrEqual(state.easeFactor, 1.3)
    }

    // MARK: - UserProgress

    func testOverallAccuracy() {
        var progress = UserProgress()
        XCTAssertEqual(progress.overallAccuracy, 0)

        progress.totalQuestionsAnswered = 20
        progress.totalCorrect = 15
        XCTAssertEqual(progress.overallAccuracy, 75.0, accuracy: 0.01)
    }

    func testStreakWithNoHistory() {
        let progress = UserProgress()
        XCTAssertEqual(progress.streak, 0)
    }

    func testStreakWithTodayOnly() {
        var progress = UserProgress()
        progress.quizHistory = [
            QuizResult(id: UUID(), date: Date(), domainId: nil, mode: "Practice", totalQuestions: 5, correctCount: 3, timeSpent: 60, questionResults: [])
        ]
        XCTAssertEqual(progress.streak, 1)
    }

    func testStreakWithConsecutiveDays() {
        var progress = UserProgress()
        let calendar = Calendar.current
        progress.quizHistory = [
            QuizResult(id: UUID(), date: Date(), domainId: nil, mode: "Practice", totalQuestions: 5, correctCount: 3, timeSpent: 60, questionResults: []),
            QuizResult(id: UUID(), date: calendar.date(byAdding: .day, value: -1, to: Date())!, domainId: nil, mode: "Practice", totalQuestions: 5, correctCount: 3, timeSpent: 60, questionResults: []),
            QuizResult(id: UUID(), date: calendar.date(byAdding: .day, value: -2, to: Date())!, domainId: nil, mode: "Practice", totalQuestions: 5, correctCount: 3, timeSpent: 60, questionResults: [])
        ]
        XCTAssertEqual(progress.streak, 3)
    }

    func testStreakBrokenByGap() {
        var progress = UserProgress()
        let calendar = Calendar.current
        progress.quizHistory = [
            QuizResult(id: UUID(), date: Date(), domainId: nil, mode: "Practice", totalQuestions: 5, correctCount: 3, timeSpent: 60, questionResults: []),
            // Gap: skip yesterday
            QuizResult(id: UUID(), date: calendar.date(byAdding: .day, value: -2, to: Date())!, domainId: nil, mode: "Practice", totalQuestions: 5, correctCount: 3, timeSpent: 60, questionResults: [])
        ]
        XCTAssertEqual(progress.streak, 1)
    }
}
