import SwiftUI

struct StudyView: View {
    @Environment(AppState.self) private var appState
    @State private var navigateToFlashcards = false
    @State private var flashcardDomain: ExamDomain?
    private let service = DataService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        examOverviewCard
                        flashcardBanner
                        masteryOverviewCard
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
            .navigationDestination(isPresented: $navigateToFlashcards) {
                FlashcardView(domain: flashcardDomain)
            }
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

    // MARK: - Flashcard Banner

    private var flashcardBanner: some View {
        let dueCount = service.flashcardsDue(in: appState.progress).count

        return Button {
            flashcardDomain = nil
            navigateToFlashcards = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 48, height: 48)
                    Image(systemName: "rectangle.on.rectangle.angled")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Spaced Repetition Flashcards")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(dueCount > 0
                         ? "\(dueCount) cards due for review"
                         : "All caught up! Check back later.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                if dueCount > 0 {
                    ZStack {
                        Circle()
                            .fill(.purple.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.purple)
                    }
                }
            }
            .vaultCard()
        }
    }

    // MARK: - Mastery Overview

    private var masteryOverviewCard: some View {
        let totalMastered = appState.progress.masteredQuestionIds.count
        let total = max(service.totalCount, 1)

        return VStack(spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(VaultTheme.gold)
                    Text("Mastery Progress")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("\(totalMastered)/\(total)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(VaultTheme.gold)
            }

            // Stacked domain mastery bars with exam weight labels
            ForEach(ExamDomain.allCases) { domain in
                let domainTotal = service.count(for: domain)
                let mastered = service.masteredCount(for: domain, in: appState.progress)
                let fraction = domainTotal > 0 ? Double(mastered) / Double(domainTotal) : 0

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(domain.color)
                            .frame(width: 8, height: 8)

                        Text(domain.shortTitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))

                        Text("\(domain.examWeight)%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(domain.color.opacity(0.6))

                        Spacer()

                        Text("\(mastered)/\(domainTotal)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))

                        if fraction >= 1.0 {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(VaultTheme.gold)
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background shows relative exam weight
                            Capsule().fill(.white.opacity(0.06)).frame(height: 6)

                            // Mastery fill
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [domain.color.opacity(0.6), domain.color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * min(fraction, 1.0), height: 6)
                                .animation(.easeOut(duration: 0.5), value: fraction)
                        }
                    }
                    .frame(height: 6)
                }
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
                    score: appState.progress.domainScores[domain.rawValue],
                    masteredCount: service.masteredCount(for: domain, in: appState.progress),
                    dueCount: service.flashcardsDue(in: appState.progress, domain: domain).count,
                    onFlashcards: {
                        flashcardDomain = domain
                        navigateToFlashcards = true
                    }
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
    let masteredCount: Int
    let dueCount: Int
    let onFlashcards: () -> Void

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
                Spacer()
                StatPill(
                    label: "Mastered",
                    value: "\(masteredCount)",
                    color: masteredCount > 0 ? VaultTheme.gold : .white.opacity(0.3)
                )
            }

            // Dual progress bars: Accuracy + Mastery
            VStack(spacing: 6) {
                // Accuracy bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.06)).frame(height: 5)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [domain.color.opacity(0.7), domain.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * min(accuracy / 100, 1.0), height: 5)
                            .animation(.easeOut(duration: 0.6), value: accuracy)
                    }
                }
                .frame(height: 5)

                // Mastery bar
                let masteryFraction = questionCount > 0 ? Double(masteredCount) / Double(questionCount) : 0
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.06)).frame(height: 5)
                        Capsule()
                            .fill(VaultTheme.goldGradient)
                            .frame(width: geo.size.width * min(masteryFraction, 1.0), height: 5)
                            .animation(.easeOut(duration: 0.6), value: masteryFraction)
                    }
                }
                .frame(height: 5)

                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(domain.color).frame(width: 6, height: 6)
                        Text("Accuracy")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(VaultTheme.gold).frame(width: 6, height: 6)
                        Text("Mastery")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }

            // Bottom row: mastery label + flashcard button
            HStack {
                if attempted > 0 {
                    Text(masteryLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(masteryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(masteryColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer()

                if dueCount > 0 {
                    Button {
                        onFlashcards()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.on.rectangle.angled")
                                .font(.system(size: 10))
                            Text("\(dueCount) due")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.purple.opacity(0.12))
                        .clipShape(Capsule())
                    }
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

// MARK: - Domain Detail

struct DomainDetailView: View {
    let domain: ExamDomain
    @Environment(AppState.self) private var appState
    @State private var navigateToQuiz = false
    @State private var navigateToFlashcards = false
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

                    // Mastery progress
                    let mastered = service.masteredCount(for: domain, in: appState.progress)
                    let total = service.count(for: domain)
                    let fraction = total > 0 ? Double(mastered) / Double(total) : 0

                    VStack(spacing: 8) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(VaultTheme.gold)
                                    .font(.system(size: 14))
                                Text("Mastery")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            Text("\(mastered)/\(total) mastered")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(VaultTheme.gold)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.08)).frame(height: 8)
                                Capsule()
                                    .fill(VaultTheme.goldGradient)
                                    .frame(width: geo.size.width * min(fraction, 1.0), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .vaultCard()

                    // Flashcard launch
                    let dueCount = service.flashcardsDue(in: appState.progress, domain: domain).count
                    if dueCount > 0 {
                        Button {
                            navigateToFlashcards = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.on.rectangle.angled")
                                    .foregroundStyle(.purple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Flashcards")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text("\(dueCount) cards due for review")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.purple)
                            }
                            .vaultCard()
                        }
                    }

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
        .navigationDestination(isPresented: $navigateToFlashcards) {
            FlashcardView(domain: domain)
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
