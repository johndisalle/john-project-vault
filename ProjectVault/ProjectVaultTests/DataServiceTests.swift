import XCTest
@testable import ProjectVault

final class DataServiceTests: XCTestCase {

    let service = DataService.shared

    // MARK: - Loading

    func testQuestionsLoaded() {
        XCTAssertTrue(service.isLoaded, "Question bank should be loaded")
        XCTAssertGreaterThan(service.totalCount, 0, "Should have questions")
    }

    func testNoLoadError() {
        XCTAssertNil(service.loadError, "Should have no load error")
    }

    func testQuestionCountMatchesExpected() {
        // We expect 525+ questions
        XCTAssertGreaterThanOrEqual(service.totalCount, 500, "Should have at least 500 questions")
    }

    // MARK: - Domain Coverage

    func testAllDomainsHaveQuestions() {
        for domain in ExamDomain.allCases {
            let count = service.count(for: domain)
            XCTAssertGreaterThan(count, 0, "Domain \(domain.rawValue) should have questions")
        }
    }

    func testDomainCountsSumToTotal() {
        let domainTotal = ExamDomain.allCases.reduce(0) { $0 + service.count(for: $1) }
        XCTAssertEqual(domainTotal, service.totalCount, "Domain counts should sum to total")
    }

    // MARK: - Lookup

    func testQuestionByIdReturnsCorrectQuestion() {
        guard let first = service.allQuestions.first else {
            XCTFail("No questions available")
            return
        }
        let found = service.question(byId: first.id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, first.id)
        XCTAssertEqual(found?.question, first.question)
    }

    func testQuestionByIdReturnsNilForInvalidId() {
        let result = service.question(byId: "nonexistent-id-12345")
        XCTAssertNil(result)
    }

    // MARK: - Filtering

    func testFilterByDomain() {
        let domain1Questions = service.questions(for: .domain1)
        XCTAssertTrue(domain1Questions.allSatisfy { $0.domain.hasPrefix("1") || $0.domain.lowercased().contains("integration") || $0.domain.lowercased().contains("project") })
    }

    func testFilterByDifficulty() {
        let easyQuestions = service.questions(for: .Easy)
        XCTAssertTrue(easyQuestions.allSatisfy { $0.difficulty == .Easy })
    }

    func testFilterBySubObjective() {
        guard let subObj = service.allSubObjectives.first else {
            XCTFail("No sub-objectives")
            return
        }
        let questions = service.questions(forSubObjective: subObj)
        XCTAssertTrue(questions.allSatisfy { $0.subObjective == subObj })
    }

    // MARK: - Random Selection

    func testRandomQuestionsReturnsRequestedCount() {
        let questions = service.randomQuestions(count: 10)
        XCTAssertEqual(questions.count, 10)
    }

    func testRandomQuestionsFromDomain() {
        let questions = service.randomQuestions(count: 5, from: .domain2)
        XCTAssertEqual(questions.count, 5)
    }

    // MARK: - Mock Exam

    func testMockExamReturns90Questions() {
        let exam = service.mockExam(number: 1)
        XCTAssertEqual(exam.count, 90)
    }

    func testDifferentMockExamsAreDifferent() {
        let exam1 = service.mockExam(number: 1)
        let exam2 = service.mockExam(number: 2)
        let ids1 = Set(exam1.map(\.id))
        let ids2 = Set(exam2.map(\.id))
        // They should share some questions but not be identical
        XCTAssertNotEqual(ids1, ids2, "Different exam numbers should produce different sets")
    }

    func testMockExamIsDeterministic() {
        let exam1a = service.mockExam(number: 1)
        let exam1b = service.mockExam(number: 1)
        let ids1a = exam1a.map(\.id)
        let ids1b = exam1b.map(\.id)
        XCTAssertEqual(ids1a, ids1b, "Same exam number should produce same questions")
    }

    // MARK: - Question Validation

    func testAllQuestionsHaveRequiredFields() {
        for q in service.allQuestions {
            XCTAssertFalse(q.id.isEmpty, "Question should have an ID")
            XCTAssertFalse(q.question.isEmpty, "Question \(q.id) should have text")
            XCTAssertFalse(q.options.isEmpty, "Question \(q.id) should have options")
            XCTAssertFalse(q.correctAnswers.isEmpty, "Question \(q.id) should have correct answers")
            XCTAssertFalse(q.explanation.isEmpty, "Question \(q.id) should have an explanation")
            XCTAssertFalse(q.subObjective.isEmpty, "Question \(q.id) should have a sub-objective")
        }
    }

    func testAllQuestionsHaveUniqueIds() {
        let ids = service.allQuestions.map(\.id)
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All question IDs should be unique")
    }

    func testCorrectAnswersAreValidOptions() {
        for q in service.allQuestions {
            let optionLetters = q.options.compactMap { $0.first.map(String.init) }
            for answer in q.correctAnswers {
                let answerLetter = String(answer.prefix(1))
                // The correct answer letter should appear in the options
                let found = optionLetters.contains(where: { $0 == answerLetter }) || q.options.contains(where: { $0.contains(answer) })
                XCTAssertTrue(found, "Question \(q.id): correct answer '\(answer)' should match an option")
            }
        }
    }
}
