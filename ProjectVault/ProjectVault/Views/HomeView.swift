import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var navigateToQuiz = false
    @State private var quizQuestions: [Question] = []
    @State private var quizMode: QuizSession.QuizMode = .practice

    private let service = DataService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        statsCards
                        quickStartSection
                        recentActivitySection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToQuiz) {
                QuizView(
                    questions: quizQuestions,
                    mode: quizMode,
                    domain: nil
                )
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Project+ Vault")
                    .font(VaultTheme.titleFont)
                    .foregroundStyle(VaultTheme.goldGradient)

                Text("PK0-005 Exam Prep")
                    .font(VaultTheme.captionFont)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            // Streak Badge
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("\(appState.progress.streak)")
                    .font(VaultTheme.captionFont)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(12)
            .background(
                Circle()
                    .fill(Color.orange.opacity(0.15))
            )
        }
        .padding(.top, 8)
    }

    // MARK: - Stats

    private var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Answered",
                value: "\(appState.progress.totalQuestionsAnswered)",
                icon: "checkmark.circle.fill",
                color: .cyan
            )
            StatCard(
                title: "Accuracy",
                value: String(format: "%.0f%%", appState.progress.overallAccuracy),
                icon: "target",
                color: VaultTheme.gold
            )
            StatCard(
                title: "Today",
                value: "\(appState.questionsAnsweredToday)",
                icon: "calendar",
                color: .mint
            )
        }
    }

    // MARK: - Quick Start

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                QuickStartButton(
                    title: "Quick 10",
                    subtitle: "10 random questions",
                    icon: "bolt.fill",
                    color: .cyan
                ) {
                    startQuiz(count: 10, mode: .practice)
                }

                QuickStartButton(
                    title: "Practice 25",
                    subtitle: "25 mixed questions",
                    icon: "book.fill",
                    color: VaultTheme.gold
                ) {
                    startQuiz(count: 25, mode: .practice)
                }

                QuickStartButton(
                    title: "Exam Simulation",
                    subtitle: "65 questions, timed (90 min)",
                    icon: "clock.badge.checkmark.fill",
                    color: .purple
                ) {
                    quizQuestions = service.examSimulation()
                    quizMode = .timed
                    navigateToQuiz = true
                }

                if !appState.progress.missedQuestionIds.isEmpty {
                    QuickStartButton(
                        title: "Review Missed",
                        subtitle: "\(appState.progress.missedQuestionIds.count) questions to review",
                        icon: "arrow.counterclockwise",
                        color: VaultTheme.incorrectRed
                    ) {
                        quizQuestions = service.questions(withIds: appState.progress.missedQuestionIds).shuffled()
                        quizMode = .review
                        navigateToQuiz = true
                    }
                }
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(.white)

            if appState.progress.quizHistory.isEmpty {
                HStack {
                    Image(systemName: "tray")
                        .foregroundStyle(.white.opacity(0.4))
                    Text("No quizzes taken yet. Start practicing!")
                        .font(VaultTheme.bodyFont)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .vaultCard()
            } else {
                ForEach(appState.progress.quizHistory.suffix(5).reversed()) { result in
                    RecentResultRow(result: result)
                }
            }
        }
    }

    // MARK: - Helpers

    private func startQuiz(count: Int, mode: QuizSession.QuizMode) {
        quizQuestions = service.randomQuestions(count: min(count, service.totalCount))
        quizMode = mode
        navigateToQuiz = true
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(VaultTheme.captionFont)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .vaultCard()
    }
}

struct QuickStartButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(VaultTheme.captionFont)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(14)
            .vaultCard()
        }
    }
}

struct RecentResultRow: View {
    let result: QuizResult

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(result.passed ? VaultTheme.correctGreen.opacity(0.2) : VaultTheme.incorrectRed.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(format: "%.0f%%", result.scorePercentage))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(result.passed ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("\(result.mode) - \(result.totalQuestions) questions")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                    .font(VaultTheme.captionFont)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Text("\(result.correctCount)/\(result.totalQuestions)")
                .font(VaultTheme.monoFont)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(12)
        .vaultCard()
    }
}
