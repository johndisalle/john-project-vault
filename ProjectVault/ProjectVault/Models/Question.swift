import Foundation

struct Question: Codable, Identifiable, Hashable {
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

    enum QuestionType: String, Codable {
        case multipleChoice
        case multipleSelect
    }

    enum Difficulty: String, Codable {
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
}

struct QuestionBank: Codable {
    let questions: [Question]
}
