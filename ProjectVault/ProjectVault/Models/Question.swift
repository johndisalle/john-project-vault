import Foundation

struct Question: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let domain: String
    let subObjective: String
    let type: QuestionType
    let question: String
    let options: [String]
    let correctAnswers: [String]
    let explanation: String
    let difficulty: Difficulty
    let tags: [String]
    let reference: String

    enum QuestionType: String, Codable, Sendable {
        case multipleChoice
        case multipleSelect
    }

    enum Difficulty: String, Codable, CaseIterable, Sendable {
        case Easy
        case Medium
        case Hard
    }

    var correctLetters: Set<String> {
        Set(correctAnswers)
    }

    var domainNumber: String {
        String(domain.prefix(3))
    }

    var subObjectiveNumber: String {
        subObjective
    }

    var isMultiSelect: Bool {
        type == .multipleSelect
    }
}

struct QuestionBank: Codable, Sendable {
    let questions: [Question]
}
