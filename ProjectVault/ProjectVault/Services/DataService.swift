import Foundation

/// Unified data layer — offline-first design.
///
/// All questions are bundled in the app binary and loaded from
/// `ProjectVaultQuestions.json` at launch. All user progress is
/// persisted locally via UserDefaults. No network required.
///
/// Provides indexed filtering by domain / difficulty / tag / sub-objective.
final class DataService: @unchecked Sendable {
    static let shared = DataService()

    // MARK: - Question Storage

    private(set) var allQuestions: [Question] = []

    /// O(1) lookup by question ID
    private var questionsById: [String: Question] = [:]
    /// Pre-grouped by ExamDomain
    private var questionsByDomain: [ExamDomain: [Question]] = [:]
    /// Pre-grouped by Difficulty
    private var questionsByDifficulty: [Question.Difficulty: [Question]] = [:]
    /// Pre-grouped by sub-objective (e.g. "1.4")
    private var questionsBySubObjective: [String: [Question]] = [:]
    /// Inverted index: tag → [Question]
    private var questionsByTag: [String: [Question]] = [:]

    /// Error state for UI display
    private(set) var loadError: String?

    // MARK: - Persistence

    private let defaults = UserDefaults.standard
    private let progressKey = "pv_user_progress"

    // MARK: - Init

    private init() {
        loadQuestions()
    }

    // MARK: - JSON Loading (offline-first: bundled in app binary)

    private func loadQuestions() {
        guard let url = Bundle.main.url(forResource: "ProjectVaultQuestions", withExtension: "json") else {
            loadError = "Question bank not found in app bundle."
            print("[DataService] ProjectVaultQuestions.json not found in bundle.")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let bank = try JSONDecoder().decode(QuestionBank.self, from: data)
            allQuestions = bank.questions
            buildIndices()
            loadError = nil
            print("[DataService] Loaded \(allQuestions.count) questions, \(allTags.count) unique tags.")
        } catch let decodingError as DecodingError {
            loadError = "Failed to parse question data."
            print("[DataService] Decode error: \(decodingError)")
        } catch {
            loadError = "Failed to load questions: \(error.localizedDescription)"
            print("[DataService] Load error: \(error)")
        }
    }

    private func buildIndices() {
        questionsById = Dictionary(uniqueKeysWithValues: allQuestions.map { ($0.id, $0) })

        // Domain index
        var domainMap: [ExamDomain: [Question]] = [:]
        for q in allQuestions {
            if let domain = ExamDomain.from(domainString: q.domain) {
                domainMap[domain, default: []].append(q)
            }
        }
        questionsByDomain = domainMap

        // Difficulty index
        questionsByDifficulty = Dictionary(grouping: allQuestions, by: \.difficulty)

        // Sub-objective index
        questionsBySubObjective = Dictionary(grouping: allQuestions, by: \.subObjective)

        // Tag inverted index
        var tagMap: [String: [Question]] = [:]
        for q in allQuestions {
            for tag in q.tags {
                tagMap[tag, default: []].append(q)
            }
        }
        questionsByTag = tagMap
    }

    // MARK: - Question Lookup

    func question(byId id: String) -> Question? {
        questionsById[id]
    }

    // MARK: - Filtering (all indexed, no linear scans)

    func questions(for domain: ExamDomain) -> [Question] {
        questionsByDomain[domain] ?? []
    }

    func questions(for difficulty: Question.Difficulty) -> [Question] {
        questionsByDifficulty[difficulty] ?? []
    }

    func questions(forSubObjective sub: String) -> [Question] {
        questionsBySubObjective[sub] ?? []
    }

    func questions(withTag tag: String) -> [Question] {
        questionsByTag[tag] ?? []
    }

    func questions(withIds ids: Set<String>) -> [Question] {
        ids.compactMap { questionsById[$0] }
    }

    /// Compound filter: intersects results across non-nil criteria.
    func questions(
        domain: ExamDomain? = nil,
        difficulty: Question.Difficulty? = nil,
        tag: String? = nil,
        subObjective: String? = nil
    ) -> [Question] {
        var pool = allQuestions

        if let domain {
            let indexed = Set(questions(for: domain).map(\.id))
            pool = pool.filter { indexed.contains($0.id) }
        }
        if let difficulty {
            let indexed = Set(questions(for: difficulty).map(\.id))
            pool = pool.filter { indexed.contains($0.id) }
        }
        if let tag {
            let indexed = Set(questions(withTag: tag).map(\.id))
            pool = pool.filter { indexed.contains($0.id) }
        }
        if let subObjective {
            let indexed = Set(questions(forSubObjective: subObjective).map(\.id))
            pool = pool.filter { indexed.contains($0.id) }
        }

        return pool
    }

    // MARK: - Random Selection

    func randomQuestions(count: Int, from domain: ExamDomain? = nil) -> [Question] {
        let pool: [Question] = if let domain { questions(for: domain) } else { allQuestions }
        return Array(pool.shuffled().prefix(count))
    }

    /// Weighted exam simulation matching PK0-005 domain percentages.
    func examSimulation(questionCount: Int = 65) -> [Question] {
        let d1 = Int(Double(questionCount) * 0.33)
        let d2 = Int(Double(questionCount) * 0.30)
        let d3 = Int(Double(questionCount) * 0.19)
        let d4 = questionCount - d1 - d2 - d3

        var result: [Question] = []
        result.append(contentsOf: randomQuestions(count: d1, from: .domain1))
        result.append(contentsOf: randomQuestions(count: d2, from: .domain2))
        result.append(contentsOf: randomQuestions(count: d3, from: .domain3))
        result.append(contentsOf: randomQuestions(count: d4, from: .domain4))
        return result.shuffled()
    }

    /// Seeded 90-question exam matching real PK0-005 format.
    /// Each examNumber (1-4) produces a deterministic but different question set.
    func mockExam(number: Int) -> [Question] {
        let questionCount = 90
        // Domain weights: 33% / 30% / 19% / 18%
        let d1Count = Int(Double(questionCount) * 0.33) // 29
        let d2Count = Int(Double(questionCount) * 0.30) // 27
        let d3Count = Int(Double(questionCount) * 0.19) // 17
        let d4Count = questionCount - d1Count - d2Count - d3Count // 17

        func seededShuffle(_ questions: [Question], seed: Int) -> [Question] {
            var rng = SeededRandomNumberGenerator(seed: UInt64(seed))
            return questions.shuffled(using: &rng)
        }

        let seed = number * 7919 // distinct prime-based seeds
        var result: [Question] = []
        result.append(contentsOf: Array(seededShuffle(questions(for: .domain1), seed: seed + 1).prefix(d1Count)))
        result.append(contentsOf: Array(seededShuffle(questions(for: .domain2), seed: seed + 2).prefix(d2Count)))
        result.append(contentsOf: Array(seededShuffle(questions(for: .domain3), seed: seed + 3).prefix(d3Count)))
        result.append(contentsOf: Array(seededShuffle(questions(for: .domain4), seed: seed + 4).prefix(d4Count)))

        return seededShuffle(result, seed: seed)
    }

    /// Compute per-domain breakdown from a set of question results.
    func domainBreakdown(from questionResults: [QuestionResult]) -> [ExamDomain: (total: Int, correct: Int)] {
        var breakdown: [ExamDomain: (total: Int, correct: Int)] = [:]
        for domain in ExamDomain.allCases {
            breakdown[domain] = (0, 0)
        }
        for qr in questionResults {
            if let q = questionsById[qr.questionId],
               let domain = ExamDomain.from(domainString: q.domain) {
                let current = breakdown[domain] ?? (0, 0)
                breakdown[domain] = (current.total + 1, current.correct + (qr.isCorrect ? 1 : 0))
            }
        }
        return breakdown
    }

    /// Compute per-difficulty breakdown from a set of question results.
    func difficultyBreakdown(from questionResults: [QuestionResult]) -> [Question.Difficulty: (total: Int, correct: Int)] {
        var breakdown: [Question.Difficulty: (total: Int, correct: Int)] = [:]
        for diff in Question.Difficulty.allCases {
            breakdown[diff] = (0, 0)
        }
        for qr in questionResults {
            if let q = questionsById[qr.questionId] {
                let current = breakdown[q.difficulty] ?? (0, 0)
                breakdown[q.difficulty] = (current.total + 1, current.correct + (qr.isCorrect ? 1 : 0))
            }
        }
        return breakdown
    }

    // MARK: - Stats

    var totalCount: Int { allQuestions.count }

    var isLoaded: Bool { !allQuestions.isEmpty }

    func count(for domain: ExamDomain) -> Int {
        questionsByDomain[domain]?.count ?? 0
    }

    var allTags: [String] {
        questionsByTag.keys.sorted()
    }

    var allSubObjectives: [String] {
        questionsBySubObjective.keys.sorted()
    }

    // MARK: - Progress Persistence (offline-first: UserDefaults, no network)

    func loadProgress() -> UserProgress {
        guard let data = defaults.data(forKey: progressKey) else {
            return UserProgress()
        }
        do {
            return try JSONDecoder().decode(UserProgress.self, from: data)
        } catch {
            // Corrupted data — preserve a backup before returning fresh state
            defaults.set(data, forKey: progressKey + "_backup_\(Int(Date().timeIntervalSince1970))")
            print("[DataService] Progress decode failed, backed up and reset: \(error)")
            return UserProgress()
        }
    }

    func saveProgress(_ progress: UserProgress) {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: progressKey)
        }
    }

    func resetProgress() {
        defaults.removeObject(forKey: progressKey)
    }

    // MARK: - Quiz Result Recording

    func saveQuizResult(_ result: QuizResult, to progress: inout UserProgress) {
        progress.quizHistory.append(result)
        progress.totalQuestionsAnswered += result.totalQuestions
        progress.totalCorrect += result.correctCount

        for qr in result.questionResults {
            if qr.isCorrect {
                progress.missedQuestionIds.remove(qr.questionId)
            } else {
                progress.missedQuestionIds.insert(qr.questionId)
            }
        }

        if let domainId = result.domainId {
            var score = progress.domainScores[domainId] ?? DomainScore()
            score.attempted += result.totalQuestions
            score.correct += result.correctCount
            progress.domainScores[domainId] = score
        } else {
            for qr in result.questionResults {
                if let q = questionsById[qr.questionId],
                   let domain = ExamDomain.from(domainString: q.domain) {
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

    // MARK: - Mastery

    func toggleMastered(questionId: String, in progress: inout UserProgress) {
        if progress.masteredQuestionIds.contains(questionId) {
            progress.masteredQuestionIds.remove(questionId)
        } else {
            progress.masteredQuestionIds.insert(questionId)
        }
        saveProgress(progress)
    }

    func masteredCount(for domain: ExamDomain, in progress: UserProgress) -> Int {
        let domainQuestionIds = Set(questions(for: domain).map(\.id))
        return progress.masteredQuestionIds.intersection(domainQuestionIds).count
    }

    // MARK: - Spaced Repetition

    /// Returns questions due for review, prioritized by overdue amount.
    func flashcardsDue(in progress: UserProgress, domain: ExamDomain? = nil) -> [Question] {
        let pool: [Question] = if let domain { questions(for: domain) } else { allQuestions }
        let now = Date()

        // Include questions never seen + questions due for review. Exclude mastered.
        return pool.filter { q in
            guard !progress.masteredQuestionIds.contains(q.id) else { return false }
            guard let state = progress.flashcardStates[q.id] else { return true }
            return now >= state.nextReviewDate
        }
        .sorted { a, b in
            let stateA = progress.flashcardStates[a.id]
            let stateB = progress.flashcardStates[b.id]
            // Unseen questions first, then most overdue
            let dateA = stateA?.nextReviewDate ?? Date.distantPast
            let dateB = stateB?.nextReviewDate ?? Date.distantPast
            return dateA < dateB
        }
    }

    func recordFlashcardResult(questionId: String, quality: Int, in progress: inout UserProgress) {
        var state = progress.flashcardStates[questionId] ?? FlashcardState()
        state.update(quality: quality)
        progress.flashcardStates[questionId] = state

        // Auto-master if quality 5 and 3+ successful reps
        if quality >= 5 && state.repetitions >= 3 {
            progress.masteredQuestionIds.insert(questionId)
        }

        saveProgress(progress)
    }
}

// MARK: - Seeded RNG for deterministic exam generation

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
