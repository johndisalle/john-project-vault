import SwiftUI

struct StudyView: View {
    @Environment(AppState.self) private var appState
    private let service = DataService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        examOverviewCard
                        domainCards
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Study")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.clear, for: .navigationBar)
        }
    }

    // MARK: - Exam Overview

    private var examOverviewCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PK0-005 Exam Domains")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(service.totalCount) questions across 4 domains")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "graduationcap.fill")
                    .font(.title2)
                    .foregroundStyle(VaultTheme.gold)
            }

            // Overall mastery bar
            let totalAttempted = appState.progress.totalQuestionsAnswered
            let totalAvailable = max(service.totalCount, 1)
            let coverage = min(Double(totalAttempted) / Double(totalAvailable), 1.0)

            VStack(spacing: 4) {
                HStack {
                    Text("Coverage")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    Text("\(totalAttempted)/\(totalAvailable) attempted")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.08)).frame(height: 6)
                        Capsule()
                            .fill(VaultTheme.goldGradient)
                            .frame(width: geo.size.width * coverage, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .vaultCard()
    }

    // MARK: - Domain Cards

    private var domainCards: some View {
        ForEach(ExamDomain.allCases) { domain in
            NavigationLink(destination: DomainDetailView(domain: domain)) {
                StudyDomainCard(
                    domain: domain,
                    questionCount: service.count(for: domain),
                    score: appState.progress.domainScores[domain.rawValue]
                )
            }
        }
    }
}

// MARK: - Study Domain Card

struct StudyDomainCard: View {
    let domain: ExamDomain
    let questionCount: Int
    let score: DomainScore?

    private var accuracy: Double { score?.accuracy ?? 0 }
    private var attempted: Int { score?.attempted ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(domain.color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: domain.icon)
                        .font(.title3)
                        .foregroundStyle(domain.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Domain \(domain.rawValue)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(domain.color.opacity(0.8))

                        Text("\(domain.examWeight)% of exam")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.06))
                            .clipShape(Capsule())
                    }

                    Text(domain.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.2))
            }

            // Stats row
            HStack(spacing: 0) {
                StatPill(label: "Questions", value: "\(questionCount)", color: .white.opacity(0.5))
                Spacer()
                StatPill(label: "Attempted", value: "\(attempted)", color: .cyan)
                Spacer()
                StatPill(
                    label: "Accuracy",
                    value: attempted > 0 ? String(format: "%.0f%%", accuracy) : "--",
                    color: attempted > 0 ? (accuracy >= 65 ? VaultTheme.correctGreen : VaultTheme.warningAmber) : .white.opacity(0.3)
                )
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.06))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [domain.color.opacity(0.7), domain.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(accuracy / 100, 1.0), height: 6)
                        .animation(.easeOut(duration: 0.6), value: accuracy)
                }
            }
            .frame(height: 6)

            // Mastery label
            if attempted > 0 {
                HStack {
                    Spacer()
                    Text(masteryLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(masteryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(masteryColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .vaultCard()
    }

    private var masteryLabel: String {
        if accuracy >= 90 { return "Mastered" }
        if accuracy >= 75 { return "Proficient" }
        if accuracy >= 65 { return "On Track" }
        if accuracy >= 40 { return "Needs Work" }
        return "Getting Started"
    }

    private var masteryColor: Color {
        if accuracy >= 90 { return VaultTheme.correctGreen }
        if accuracy >= 75 { return .cyan }
        if accuracy >= 65 { return VaultTheme.warningAmber }
        return VaultTheme.incorrectRed
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
        }
    }
}

// MARK: - Domain Detail (kept from previous, updated)

struct DomainDetailView: View {
    let domain: ExamDomain
    @Environment(AppState.self) private var appState
    @State private var navigateToQuiz = false
    @State private var selectedCount = 10
    @State private var quizQuestions: [Question] = []

    private let service = DataService.shared
    private let countOptions = [10, 15, 25, 50]

    var body: some View {
        ZStack {
            VaultTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Domain header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(domain.color.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: domain.icon)
                                .font(.system(size: 36))
                                .foregroundStyle(domain.color)
                        }

                        Text(domain.title)
                            .font(VaultTheme.headlineFont)
                            .foregroundStyle(.white)

                        HStack(spacing: 12) {
                            Label("Domain \(domain.rawValue)", systemImage: "number")
                            Label("\(domain.examWeight)% of exam", systemImage: "chart.pie")
                            Label("\(service.count(for: domain)) Qs", systemImage: "list.bullet")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.top, 12)

                    // Question count picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Number of Questions")
                            .font(VaultTheme.captionFont)
                            .foregroundStyle(.white.opacity(0.6))

                        HStack(spacing: 10) {
                            ForEach(countOptions, id: \.self) { count in
                                Button {
                                    selectedCount = count
                                } label: {
                                    Text("\(count)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(selectedCount == count ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedCount == count
                                            ? AnyShapeStyle(VaultTheme.goldGradient)
                                            : AnyShapeStyle(.white.opacity(0.1))
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .disabled(count > service.count(for: domain))
                            }
                        }
                    }
                    .vaultCard()

                    Button {
                        quizQuestions = service.randomQuestions(
                            count: min(selectedCount, service.count(for: domain)),
                            from: domain
                        )
                        navigateToQuiz = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Practice")
                        }
                    }
                    .buttonStyle(GoldButtonStyle())

                    // Domain score
                    if let score = appState.progress.domainScores[domain.rawValue], score.attempted > 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Progress")
                                .font(VaultTheme.headlineFont)
                                .foregroundStyle(.white)

                            HStack {
                                ScoreColumn(value: "\(score.attempted)", label: "Attempted", color: .white)
                                ScoreColumn(value: "\(score.correct)", label: "Correct", color: VaultTheme.correctGreen)
                                ScoreColumn(
                                    value: String(format: "%.0f%%", score.accuracy),
                                    label: "Accuracy",
                                    color: score.accuracy >= 65 ? VaultTheme.correctGreen : VaultTheme.warningAmber
                                )
                            }
                        }
                        .vaultCard()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(domain.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToQuiz) {
            QuizView(questions: quizQuestions, mode: .practice, domain: domain)
        }
    }
}

private struct ScoreColumn: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(VaultTheme.captionFont)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}
