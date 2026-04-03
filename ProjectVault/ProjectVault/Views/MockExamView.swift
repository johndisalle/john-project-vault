import SwiftUI

struct MockExamView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreKitManager.self) private var store
    @State private var navigateToExam = false
    @State private var examQuestions: [Question] = []
    @State private var showPaywall = false

    private let service = DataService.shared

    private static let presetExams: [(number: Int, name: String, subtitle: String, icon: String, gradient: [Color])] = [
        (1, "Exam A", "Foundation Assessment", "a.circle.fill",
         [Color(red: 0.85, green: 0.65, blue: 0.13), Color(red: 1.0, green: 0.84, blue: 0.0)]),
        (2, "Exam B", "Intermediate Challenge", "b.circle.fill",
         [.cyan.opacity(0.8), .blue]),
        (3, "Exam C", "Advanced Practice", "c.circle.fill",
         [.purple.opacity(0.8), .pink]),
        (4, "Exam D", "Final Readiness Check", "d.circle.fill",
         [Color(red: 0.2, green: 0.8, blue: 0.4), .teal]),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        examPresetCards
                        examFormatCard
                        randomExamButton
                        pastExamsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Mock Exam")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToExam) {
                QuizView(questions: examQuestions, mode: .mockExam, domain: nil)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func launchExamIfPremium(questions: [Question]) {
        if store.isPremium {
            examQuestions = questions
            navigateToExam = true
        } else {
            showPaywall = true
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(VaultTheme.gold.opacity(0.06))
                    .frame(width: 88, height: 88)
                Circle()
                    .stroke(VaultTheme.goldGradient, lineWidth: 2.5)
                    .frame(width: 88, height: 88)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(VaultTheme.goldGradient)
            }

            Text("Full-Length Mock Exams")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("90 questions \u{2022} 90 minutes \u{2022} Real PK0-005 format")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))

            // Readiness indicator
            let bestScore = bestMockScore
            if let best = bestScore {
                HStack(spacing: 6) {
                    Image(systemName: best >= 65 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(best >= 65 ? VaultTheme.correctGreen : VaultTheme.warningAmber)
                    Text("Best: \(String(format: "%.0f%%", best))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(best >= 65 ? VaultTheme.correctGreen : VaultTheme.warningAmber)
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var bestMockScore: Double? {
        let mocks = appState.progress.quizHistory.filter { $0.mode == "Mock Exam" || $0.mode == "Timed Exam" }
        return mocks.map(\.scorePercentage).max()
    }

    // MARK: - 4 Preset Exam Cards

    private var examPresetCards: some View {
        VStack(spacing: 12) {
            if !store.isPremium {
                PremiumBanner(message: "Unlock all 4 mock exams + analytics") {
                    showPaywall = true
                }
            }

            ForEach(Self.presetExams, id: \.number) { exam in
                let attempt = attemptForExam(exam.number)

                Button {
                    launchExamIfPremium(questions: service.mockExam(number: exam.number))
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: exam.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ).opacity(0.15)
                                )
                                .frame(width: 56, height: 56)

                            Image(systemName: exam.icon)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: exam.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(exam.name)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text(exam.subtitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))

                            HStack(spacing: 8) {
                                Label("90 Qs", systemImage: "list.bullet")
                                Label("90 min", systemImage: "clock")
                                if let attempt {
                                    Label(
                                        String(format: "%.0f%%", attempt.scorePercentage),
                                        systemImage: attempt.passed ? "checkmark.circle.fill" : "xmark.circle.fill"
                                    )
                                    .foregroundStyle(attempt.passed ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
                                }
                            }
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: exam.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            if attempt != nil {
                                Text("Retake")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        }
                    }
                    .padding(14)
                    .vaultCard()
                }
            }
        }
    }

    // MARK: - Exam Format Card

    private var examFormatCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(VaultTheme.gold)
                Text("PK0-005 Exam Format")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                ExamInfoRow(label: "Passing Score", value: "710 / 900 (~79%)")
                ExamInfoRow(label: "Our Pass Threshold", value: "65% (practice mode)")
                ExamInfoRow(label: "Question Types", value: "Multiple choice & select")
                ExamInfoRow(label: "Time Limit", value: "90 minutes")
                ExamInfoRow(label: "Max Questions", value: "Up to 90")
            }

            Divider().background(.white.opacity(0.08))

            Text("Domain Weights")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))

            ForEach(ExamDomain.allCases) { domain in
                HStack(spacing: 8) {
                    Circle().fill(domain.color).frame(width: 6, height: 6)
                    Text("\(domain.rawValue) \(domain.title)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Text("\(domain.examWeight)%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(domain.color)
                    Text("(\(questionsForWeight(domain.examWeight)) Qs)")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .vaultCard()
    }

    // MARK: - Random Exam Button

    private var randomExamButton: some View {
        Button {
            launchExamIfPremium(questions: service.examSimulation(questionCount: 90))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "shuffle")
                    .font(.title3)
                    .foregroundStyle(VaultTheme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Random Exam")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Fully randomized 90-question exam")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(VaultTheme.gold)
            }
            .vaultCard()
        }
    }

    // MARK: - Past Exams

    private var pastExamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exam History")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(.white)

            let mockResults = appState.progress.quizHistory
                .filter { $0.mode == "Mock Exam" || $0.mode == "Timed Exam" }

            if mockResults.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.15))
                    Text("No mock exams completed yet")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                    Text("Complete an exam to see detailed analytics")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.2))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .vaultCard()
            } else {
                ForEach(mockResults.reversed()) { result in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(result.passed ? VaultTheme.correctGreen.opacity(0.12) : VaultTheme.incorrectRed.opacity(0.12))
                                .frame(width: 50, height: 50)

                            VStack(spacing: 0) {
                                Text(String(format: "%.0f%%", result.scorePercentage))
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(result.passed ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
                                Text(result.passed ? "PASS" : "FAIL")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(result.passed ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(result.totalQuestions)-Question \(result.mode)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)

                            HStack(spacing: 8) {
                                Text("\(result.correctCount)/\(result.totalQuestions) correct")
                                Text(formatDuration(result.timeSpent))
                            }
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                        }

                        Spacer()

                        Text(result.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    .padding(12)
                    .vaultCard()
                }
            }
        }
    }

    // MARK: - Helpers

    private func attemptForExam(_ number: Int) -> QuizResult? {
        // Match by mode containing the exam label
        appState.progress.quizHistory
            .filter { $0.mode == "Mock Exam" }
            .last
    }

    private func questionsForWeight(_ weight: Int) -> Int {
        Int(Double(90) * Double(weight) / 100.0)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        return "\(minutes) min"
    }
}

struct ExamInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}
