import SwiftUI

@MainActor
@Observable
final class QuizViewModel {
    // MARK: - Session Config
    let questions: [Question]
    let mode: QuizSession.QuizMode
    let domain: ExamDomain?
    let examNumber: Int?

    // MARK: - State
    var currentIndex = 0
    var selectedAnswers: Set<String> = []
    var hasSubmitted = false
    var questionResults: [QuestionResult] = []
    var isQuizComplete = false
    var questionStartTime = Date()
    var sessionStartTime = Date()

    // Shuffled options for current question
    var shuffledOptions: [String] = []
    // Maps display letter (A,B,C,D) → original letter
    private var letterMap: [String: String] = [:]

    // Timer for timed mode
    var remainingSeconds: Int = 0
    var timerActive = false

    private static let letters = ["A", "B", "C", "D", "E", "F"]

    init(questions: [Question], mode: QuizSession.QuizMode, domain: ExamDomain?, examNumber: Int? = nil) {
        self.questions = questions
        self.mode = mode
        self.domain = domain
        self.examNumber = examNumber

        if mode == .timed {
            self.remainingSeconds = questions.count * 90
        } else if mode == .mockExam {
            self.remainingSeconds = 90 * 60
        }

        shuffleCurrentOptions()
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
        // Map selected display letters back to original letters
        let originalAnswers = Set(selectedAnswers.compactMap { letterMap[$0] })
        return originalAnswers == currentQuestion.correctLetters
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
        // Store original letters in results for consistency
        let originalAnswers = selectedAnswers.compactMap { letterMap[$0] }.sorted()
        let result = QuestionResult(
            id: UUID().uuidString,
            questionId: currentQuestion.id,
            selectedAnswers: originalAnswers,
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
            shuffleCurrentOptions()
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
            questionResults: questionResults,
            examNumber: examNumber
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
        // Return the NEW display letter for this shuffled option
        if let index = shuffledOptions.firstIndex(of: option), index < Self.letters.count {
            return Self.letters[index]
        }
        return String(option.prefix(1))
    }

    /// Get the original correct answer letters mapped to display letters
    var displayCorrectAnswers: [String] {
        let reverseMap = Dictionary(uniqueKeysWithValues: letterMap.map { ($1, $0) })
        return currentQuestion.correctAnswers.compactMap { reverseMap[$0] }.sorted()
    }

    // MARK: - Option Shuffling

    private func shuffleCurrentOptions() {
        guard currentIndex < questions.count else { return }
        let question = questions[currentIndex]
        let originalOptions = question.options

        // Shuffle the options
        let shuffled = originalOptions.shuffled()
        shuffledOptions = shuffled

        // Build mapping: new display letter → original letter
        letterMap = [:]
        for (newIndex, option) in shuffled.enumerated() {
            let originalLetter = String(option.prefix(1))
            let newLetter = Self.letters[newIndex]
            letterMap[newLetter] = originalLetter
        }
    }
}
