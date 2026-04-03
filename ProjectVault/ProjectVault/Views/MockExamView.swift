import SwiftUI

struct MockExamView: View {
    @Environment(AppState.self) private var appState
    @State private var navigateToQuiz = false
    @State private var quizQuestions: [Question] = []
    @State private var selectedQuestionCount = 65

    private let service = DataService.shared
    private let examOptions = [
        (count: 35, label: "Mini Exam", time: "30 min", icon: "gauge.with.dots.needle.33percent"),
        (count: 50, label: "Half Exam", time: "45 min", icon: "gauge.with.dots.needle.50percent"),
        (count: 65, label: "Full Exam", time: "90 min", icon: "gauge.with.dots.needle.67percent"),
        (count: 90, label: "Extended", time: "120 min", icon: "gauge.with.dots.needle.100percent"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        examCards
                        examInfoCard
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
            .navigationDestination(isPresented: $navigateToQuiz) {
                QuizView(questions: quizQuestions, mode: .timed, domain: nil)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(VaultTheme.gold.opacity(0.08))
                    .frame(width: 80, height: 80)
                Circle()
                    .stroke(VaultTheme.goldGradient, lineWidth: 2)
                    .frame(width: 80, height: 80)
                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(VaultTheme.goldGradient)
            }

            Text("Simulate the Real Exam")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Timed, weighted by domain, just like PK0-005")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Exam Cards

    private var examCards: some View {
        VStack(spacing: 10) {
            ForEach(examOptions, id: \.count) { option in
                let available = service.totalCount >= option.count
                Button {
                    quizQuestions = service.examSimulation(questionCount: option.count)
                    navigateToQuiz = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(VaultTheme.gold.opacity(0.1))
                                .frame(width: 48, height: 48)
                            Image(systemName: option.icon)
                                .font(.title3)
                                .foregroundStyle(VaultTheme.gold)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(option.label)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            HStack(spacing: 8) {
                                Label("\(option.count) questions", systemImage: "list.bullet")
                                Label(option.time, systemImage: "clock")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                        }

                        Spacer()

                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(available ? VaultTheme.gold : .white.opacity(0.15))
                    }
                    .padding(14)
                    .vaultCard()
                }
                .disabled(!available)
                .opacity(available ? 1.0 : 0.5)
            }
        }
    }

    // MARK: - Exam Info

    private var examInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(VaultTheme.gold)
                Text("About PK0-005")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                ExamInfoRow(label: "Passing Score", value: "710 out of 900")
                ExamInfoRow(label: "Question Types", value: "Multiple choice & multiple select")
                ExamInfoRow(label: "Time Limit", value: "90 minutes")
                ExamInfoRow(label: "Max Questions", value: "Up to 90")
            }

            Divider().background(.white.opacity(0.1))

            VStack(alignment: .leading, spacing: 4) {
                Text("Domain Weights")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))

                ForEach(ExamDomain.allCases) { domain in
                    HStack {
                        Circle()
                            .fill(domain.color)
                            .frame(width: 6, height: 6)
                        Text(domain.title)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Text("\(domain.examWeight)%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(domain.color)
                    }
                }
            }
        }
        .vaultCard()
    }

    // MARK: - Past Exams

    private var pastExamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Past Mock Exams")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(.white)

            let timedResults = appState.progress.quizHistory.filter { $0.mode == "Timed Exam" }

            if timedResults.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("No mock exams taken yet")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .vaultCard()
            } else {
                ForEach(timedResults.reversed()) { result in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(result.passed ? VaultTheme.correctGreen.opacity(0.15) : VaultTheme.incorrectRed.opacity(0.15))
                                .frame(width: 48, height: 48)

                            VStack(spacing: 0) {
                                Text(String(format: "%.0f%%", result.scorePercentage))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(result.passed ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
                                Text(result.passed ? "PASS" : "FAIL")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(result.passed ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(result.totalQuestions)-Question Exam")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)

                            HStack(spacing: 8) {
                                Text("\(result.correctCount)/\(result.totalQuestions) correct")
                                Text(formatTime(result.timeSpent))
                            }
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                        }

                        Spacer()

                        Text(result.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(12)
                    .vaultCard()
                }
            }
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
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
