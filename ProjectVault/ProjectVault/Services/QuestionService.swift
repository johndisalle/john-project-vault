import Foundation

final class QuestionService {
    static let shared = QuestionService()

    private(set) var allQuestions: [Question] = []

    private init() {
        loadQuestions()
    }

    private func loadQuestions() {
        guard let url = Bundle.main.url(forResource: "ProjectVaultQuestions", withExtension: "json") else {
            print("[QuestionService] ProjectVaultQuestions.json not found in bundle.")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let bank = try JSONDecoder().decode(QuestionBank.self, from: data)
            allQuestions = bank.questions
            print("[QuestionService] Loaded \(allQuestions.count) questions.")
        } catch {
            print("[QuestionService] Failed to decode questions: \(error)")
        }
    }

    // MARK: - Filtering

    func questions(for domain: ExamDomain) -> [Question] {
        allQuestions.filter { $0.domain.hasPrefix(domain.rawValue) }
    }

    func questions(for difficulty: Question.Difficulty) -> [Question] {
        allQuestions.filter { $0.difficulty == difficulty }
    }

    func questions(withTag tag: String) -> [Question] {
        allQuestions.filter { $0.tags.contains(tag) }
    }

    func questions(withIds ids: Set<String>) -> [Question] {
        allQuestions.filter { ids.contains($0.id) }
    }

    func randomQuestions(count: Int, from domain: ExamDomain? = nil) -> [Question] {
        let pool = domain != nil ? questions(for: domain!) : allQuestions
        return Array(pool.shuffled().prefix(count))
    }

    // MARK: - Exam Simulation

    func examSimulation(questionCount: Int = 65) -> [Question] {
        // Weighted by domain exam percentages
        let d1Count = Int(Double(questionCount) * 0.33)
        let d2Count = Int(Double(questionCount) * 0.30)
        let d3Count = Int(Double(questionCount) * 0.19)
        let d4Count = questionCount - d1Count - d2Count - d3Count

        var result: [Question] = []
        result.append(contentsOf: randomQuestions(count: d1Count, from: .domain1))
        result.append(contentsOf: randomQuestions(count: d2Count, from: .domain2))
        result.append(contentsOf: randomQuestions(count: d3Count, from: .domain3))
        result.append(contentsOf: randomQuestions(count: d4Count, from: .domain4))

        return result.shuffled()
    }

    // MARK: - Stats

    var totalCount: Int { allQuestions.count }

    func count(for domain: ExamDomain) -> Int {
        questions(for: domain).count
    }

    var allTags: [String] {
        Array(Set(allQuestions.flatMap { $0.tags })).sorted()
    }
}
