import Foundation

final class PersistenceService {
    static let shared = PersistenceService()

    private let defaults = UserDefaults.standard
    private let progressKey = "user_progress"

    private init() {}

    // MARK: - User Progress

    func loadProgress() -> UserProgress {
        guard let data = defaults.data(forKey: progressKey),
              let progress = try? JSONDecoder().decode(UserProgress.self, from: data) else {
            return UserProgress()
        }
        return progress
    }

    func saveProgress(_ progress: UserProgress) {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: progressKey)
        }
    }

    func resetProgress() {
        defaults.removeObject(forKey: progressKey)
    }

    // MARK: - Quiz Results

    func saveQuizResult(_ result: QuizResult, to progress: inout UserProgress) {
        progress.quizHistory.append(result)
        progress.totalQuestionsAnswered += result.totalQuestions
        progress.totalCorrect += result.correctCount

        // Update missed questions
        for qr in result.questionResults {
            if qr.isCorrect {
                progress.missedQuestionIds.remove(qr.questionId)
            } else {
                progress.missedQuestionIds.insert(qr.questionId)
            }
        }

        // Update domain scores
        if let domainId = result.domainId {
            var score = progress.domainScores[domainId] ?? DomainScore()
            score.attempted += result.totalQuestions
            score.correct += result.correctCount
            progress.domainScores[domainId] = score
        } else {
            // Exam mode — attribute per question
            for qr in result.questionResults {
                if let question = QuestionService.shared.allQuestions.first(where: { $0.id == qr.questionId }),
                   let domain = ExamDomain.from(domainString: question.domain) {
                    var score = progress.domainScores[domain.rawValue] ?? DomainScore()
                    score.attempted += 1
                    if qr.isCorrect { score.correct += 1 }
                    progress.domainScores[domain.rawValue] = score
                }
            }
        }

        saveProgress(progress)
    }

    // MARK: - Bookmarks

    func toggleBookmark(questionId: String, in progress: inout UserProgress) {
        if progress.bookmarkedQuestionIds.contains(questionId) {
            progress.bookmarkedQuestionIds.remove(questionId)
        } else {
            progress.bookmarkedQuestionIds.insert(questionId)
        }
        saveProgress(progress)
    }
}
