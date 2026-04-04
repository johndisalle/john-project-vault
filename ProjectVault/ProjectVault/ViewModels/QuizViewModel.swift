import SwiftUI

@MainActor
@Observable
final class QuizViewModel {
    // MARK: - Session Config
    let questions: [Question]
    let mode: QuizSession.QuizMode
    let domain: ExamDomain?

    // MARK: - State
    var currentIndex = 0
    var selectedAnswers: Set<String> = []
    var hasSubmitted = false
    var questionResults: [QuestionResult] = []
    var isQuizComplete = false
    var questionStartTime = Date()
    var sessionStartTime = Date()

    // Timer for timed mode
    var remainingSeconds: Int = 0
    var timerActive = false

    init(questions: [Question], mode: QuizSession.QuizMode, domain: ExamDomain?) {
        self.questions = questions
        self.mode = mode
        self.domain = domain

        if mode == .timed {
            // ~90 seconds per question
            self.remainingSeconds = questions.count * 90
        } else if mode == .mockExam {
            // Real PK0-005 format: 90 minutes
            self.remainingSeconds = 90 * 60
        }
    }

    // MARK: - Computed

    var currentQuestion: Question {
        questions[currentIndex]
    }

    var progressFraction: Double {
        Double(currentIndex + 1) / Double(questions.count)
    }

    var progressText: String {
        "\(currentIndex + 1) of \(questions.count)"
    }

    var isMultiSelect: Bool {
        currentQuestion.type == .multipleSelect
    }

    var requiredSelections: Int {
        currentQuestion.correctAnswers.count
    }

    var isCorrect: Bool {
        selectedAnswers == currentQuestion.correctLetters
    }

    var correctCount: Int {
        questionResults.filter(\.isCorrect).count
    }

    var scorePercentage: Double {
        guard !questionResults.isEmpty else { return 0 }
        return Double(correctCount) / Double(questionResults.count) * 100
    }

    var timerString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Actions

    func toggleAnswer(_ letter: String) {
        guard !hasSubmitted else { return }

        if isMultiSelect {
            if selectedAnswers.contains(letter) {
                selectedAnswers.remove(letter)
            } else {
                selectedAnswers.insert(letter)
            }
        } else {
            selectedAnswers = [letter]
        }
    }

    func submitAnswer() {
        guard !hasSubmitted else { return }
        hasSubmitted = true

        let timeSpent = Date().timeIntervalSince(questionStartTime)
        let result = QuestionResult(
            id: UUID().uuidString,
            questionId: currentQuestion.id,
            selectedAnswers: Array(selectedAnswers).sorted(),
            isCorrect: isCorrect,
            timeSpent: timeSpent
        )
        questionResults.append(result)
    }

    func nextQuestion() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
            selectedAnswers = []
            hasSubmitted = false
            questionStartTime = Date()
        } else {
            isQuizComplete = true
        }
    }

    func buildResult() -> QuizResult {
        QuizResult(
            id: UUID(),
            date: Date(),
            domainId: domain?.rawValue,
            mode: mode.rawValue,
            totalQuestions: questions.count,
            correctCount: correctCount,
            timeSpent: Date().timeIntervalSince(sessionStartTime),
            questionResults: questionResults
        )
    }

    func tickTimer() {
        guard timerActive, remainingSeconds > 0 else { return }
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            isQuizComplete = true
            timerActive = false
        }
    }

    func letterForOption(_ option: String) -> String {
        String(option.prefix(1))
    }
}
