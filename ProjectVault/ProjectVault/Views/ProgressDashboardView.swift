import SwiftUI

struct ProgressDashboardView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        overallStatsSection
                        domainBreakdownSection
                        historySection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.clear, for: .navigationBar)
        }
    }

    // MARK: - Overall Stats

    private var overallStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overall Performance")
                    .font(VaultTheme.headlineFont)
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack(spacing: 12) {
                ProgressStatCard(
                    title: "Total Answered",
                    value: "\(appState.progress.totalQuestionsAnswered)",
                    icon: "number",
                    color: .cyan
                )
                ProgressStatCard(
                    title: "Overall Accuracy",
                    value: String(format: "%.1f%%", appState.progress.overallAccuracy),
                    icon: "target",
                    color: appState.progress.overallAccuracy >= 65 ? VaultTheme.correctGreen : VaultTheme.warningAmber
                )
            }

            HStack(spacing: 12) {
                ProgressStatCard(
                    title: "Quizzes Taken",
                    value: "\(appState.progress.quizHistory.count)",
                    icon: "list.clipboard.fill",
                    color: .purple
                )
                ProgressStatCard(
                    title: "Bookmarked",
                    value: "\(appState.progress.bookmarkedQuestionIds.count)",
                    icon: "bookmark.fill",
                    color: VaultTheme.gold
                )
            }
        }
    }

    // MARK: - Domain Breakdown

    private var domainBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Domain Breakdown")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(.white)

            ForEach(ExamDomain.allCases) { domain in
                let score = appState.progress.domainScores[domain.rawValue]
                DomainProgressRow(domain: domain, score: score)
            }
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quiz History")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(.white)

            if appState.progress.quizHistory.isEmpty {
                Text("Complete a quiz to see your history here.")
                    .font(VaultTheme.bodyFont)
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .vaultCard()
            } else {
                ForEach(appState.progress.quizHistory.reversed()) { result in
                    HistoryRow(result: result)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .vaultCard()
    }
}

struct DomainProgressRow: View {
    let domain: ExamDomain
    let score: DomainScore?

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: domain.icon)
                    .font(.caption)
                    .foregroundStyle(domain.color)

                Text(domain.shortTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)

                Spacer()

                if let score = score, score.attempted > 0 {
                    Text(String(format: "%.0f%%", score.accuracy))
                        .font(VaultTheme.monoFont)
                        .foregroundStyle(score.accuracy >= 65 ? VaultTheme.correctGreen : VaultTheme.warningAmber)

                    Text("\(score.correct)/\(score.attempted)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                } else {
                    Text("Not started")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.08))
                        .frame(height: 4)

                    if let score = score, score.attempted > 0 {
                        Capsule()
                            .fill(domain.color)
                            .frame(width: geo.size.width * min(score.accuracy / 100, 1.0), height: 4)
                    }
                }
            }
            .frame(height: 4)
        }
        .padding(12)
        .vaultCard()
    }
}

struct HistoryRow: View {
    let result: QuizResult

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(result.passed ? VaultTheme.correctGreen.opacity(0.15) : VaultTheme.incorrectRed.opacity(0.15))
                    .frame(width: 44, height: 44)

                Text(String(format: "%.0f%%", result.scorePercentage))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(result.passed ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(result.mode)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Text("\(result.correctCount)/\(result.totalQuestions) correct")
                    if let domainId = result.domainId,
                       let domain = ExamDomain(rawValue: domainId) {
                        Text("- \(domain.shortTitle)")
                    }
                }
                .font(.system(size: 12))
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
