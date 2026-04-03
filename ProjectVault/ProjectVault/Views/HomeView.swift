import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var quoteIndex: Int = 0

    private let service = DataService.shared

    private static let quotes: [(String, String)] = [
        ("The secret of getting ahead is getting started.", "Mark Twain"),
        ("Success is the sum of small efforts, repeated day in and day out.", "Robert Collier"),
        ("Don't watch the clock; do what it does. Keep going.", "Sam Levenson"),
        ("The expert in anything was once a beginner.", "Helen Hayes"),
        ("Believe you can and you're halfway there.", "Theodore Roosevelt"),
        ("It always seems impossible until it's done.", "Nelson Mandela"),
        ("You don't have to be great to start, but you have to start to be great.", "Zig Ziglar"),
        ("The only way to do great work is to love what you do.", "Steve Jobs"),
        ("Education is the passport to the future.", "Malcolm X"),
        ("A project is complete when it starts working for you, rather than you working for it.", "Scott Allen"),
        ("Quality is never an accident; it is always the result of intelligent effort.", "John Ruskin"),
        ("Plan your work and work your plan.", "Napoleon Hill"),
        ("Risk comes from not knowing what you're doing.", "Warren Buffett"),
        ("The best preparation for tomorrow is doing your best today.", "H. Jackson Brown Jr."),
        ("Discipline is the bridge between goals and accomplishment.", "Jim Rohn"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        streakAndGoalRow
                        overallProgressCard
                        viewAllStatsLink
                        domainSnapshotSection
                        motivationalQuote
                        recentActivitySection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            quoteIndex = Int.random(in: 0..<Self.quotes.count)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Text("Project+ Vault")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(VaultTheme.goldGradient)

            Text("Your Personal Project+ Treasure Trove")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    // MARK: - Streak & Daily Goal

    private var streakAndGoalRow: some View {
        HStack(spacing: 12) {
            // Streak
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(appState.progress.streak)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Day Streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()
            }
            .padding(14)
            .vaultCard()

            // Daily Goal
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 3)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: appState.dailyGoalProgress)
                        .stroke(VaultTheme.correctGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                    Image(systemName: appState.dailyGoalProgress >= 1.0 ? "checkmark" : "target")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(appState.dailyGoalProgress >= 1.0 ? VaultTheme.correctGreen : .white.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(appState.questionsAnsweredToday)/\(appState.dailyGoal)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Daily Goal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()
            }
            .padding(14)
            .vaultCard()
        }
    }

    // MARK: - Overall Progress Ring

    private var overallProgressCard: some View {
        HStack(spacing: 20) {
            // Accuracy ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 10)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: appState.progress.overallAccuracy / 100)
                    .stroke(
                        accuracyColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text(String(format: "%.0f%%", appState.progress.overallAccuracy))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("accuracy")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                ProgressStatRow(
                    icon: "checkmark.circle.fill",
                    color: .cyan,
                    label: "Answered",
                    value: "\(appState.progress.totalQuestionsAnswered)"
                )
                ProgressStatRow(
                    icon: "star.fill",
                    color: VaultTheme.gold,
                    label: "Correct",
                    value: "\(appState.progress.totalCorrect)"
                )
                ProgressStatRow(
                    icon: "list.clipboard.fill",
                    color: .purple,
                    label: "Quizzes",
                    value: "\(appState.progress.quizHistory.count)"
                )
                ProgressStatRow(
                    icon: "crown.fill",
                    color: VaultTheme.gold,
                    label: "Mastered",
                    value: "\(appState.progress.masteredQuestionIds.count)"
                )
                ProgressStatRow(
                    icon: "bookmark.fill",
                    color: .orange,
                    label: "Bookmarked",
                    value: "\(appState.progress.bookmarkedQuestionIds.count)"
                )
            }

            Spacer()
        }
        .vaultCard()
    }

    private var accuracyColor: Color {
        let acc = appState.progress.overallAccuracy
        if acc >= 80 { return VaultTheme.correctGreen }
        if acc >= 65 { return VaultTheme.warningAmber }
        return VaultTheme.incorrectRed
    }

    // MARK: - Stats Link

    private var viewAllStatsLink: some View {
        NavigationLink(destination: StatsDashboardView()) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.cyan.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "chart.bar.xaxis.ascending")
                        .font(.system(size: 18))
                        .foregroundStyle(.cyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Statistics & Analytics")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Charts, trends, weak areas, streaks")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .vaultCard()
        }
    }

    // MARK: - Domain Snapshot

    private var domainSnapshotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Domain Readiness")
                    .font(VaultTheme.headlineFont)
                    .foregroundStyle(.white)
                Spacer()
                Text("PK0-005")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(VaultTheme.gold.opacity(0.5))
            }

            ForEach(ExamDomain.allCases) { domain in
                let score = appState.progress.domainScores[domain.rawValue]
                let mastered = service.masteredCount(for: domain, in: appState.progress)
                let total = service.count(for: domain)
                DomainSnapshotRow(domain: domain, score: score, masteredCount: mastered, totalCount: total)
            }
        }
        .vaultCard()
    }

    // MARK: - Motivational Quote

    private var motivationalQuote: some View {
        let quote = Self.quotes[quoteIndex]
        return VStack(spacing: 10) {
            Image(systemName: "quote.opening")
                .font(.title3)
                .foregroundStyle(VaultTheme.gold.opacity(0.4))

            Text(quote.0)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("- \(quote.1)")
                .font(.system(size: 12, weight: .regular, design: .serif))
                .foregroundStyle(VaultTheme.gold.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .vaultCard()
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(.white)

            if appState.progress.quizHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundStyle(VaultTheme.gold.opacity(0.3))
                    Text("Your journey begins now!")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Take your first quiz to start tracking progress.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .vaultCard()
            } else {
                ForEach(appState.progress.quizHistory.suffix(5).reversed()) { result in
                    RecentResultRow(result: result)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ProgressStatRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
                .frame(width: 18)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

struct DomainSnapshotRow: View {
    let domain: ExamDomain
    let score: DomainScore?
    let masteredCount: Int
    let totalCount: Int

    private var accuracy: Double { score?.accuracy ?? 0 }
    private var attempted: Bool { (score?.attempted ?? 0) > 0 }
    private var masteryFraction: Double { totalCount > 0 ? Double(masteredCount) / Double(totalCount) : 0 }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: domain.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(domain.color)
                    .frame(width: 16)

                Text(domain.shortTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                Text("\(domain.examWeight)%")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(domain.color.opacity(0.5))

                Spacer()

                if masteredCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(VaultTheme.gold)
                        Text("\(masteredCount)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(VaultTheme.gold.opacity(0.7))
                    }
                }

                if attempted {
                    Text(String(format: "%.0f%%", accuracy))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(accuracy >= 65 ? VaultTheme.correctGreen : VaultTheme.warningAmber)
                } else {
                    Text("--")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }

            // Dual bars: accuracy + mastery
            GeometryReader { geo in
                VStack(spacing: 2) {
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.06)).frame(height: 3)
                        Capsule()
                            .fill(domain.color.opacity(attempted ? 1.0 : 0.2))
                            .frame(width: geo.size.width * min(accuracy / 100, 1.0), height: 3)
                    }
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.04)).frame(height: 3)
                        Capsule()
                            .fill(VaultTheme.gold.opacity(masteredCount > 0 ? 0.8 : 0.1))
                            .frame(width: geo.size.width * min(masteryFraction, 1.0), height: 3)
                    }
                }
            }
            .frame(height: 8)
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
