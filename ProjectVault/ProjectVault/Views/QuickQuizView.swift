import SwiftUI

struct QuickQuizView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreKitManager.self) private var store
    @State private var navigateToQuiz = false
    @State private var quizQuestions: [Question] = []
    @State private var quizMode: QuizSession.QuizMode = .practice
    @State private var quizDomain: ExamDomain?
    @State private var showPaywall = false

    @State private var selectedDomain: ExamDomain?
    @State private var selectedDifficulty: Question.Difficulty?
    @State private var selectedCount: Int = 10
    @State private var useAdaptiveMode = false

    private let service = DataService.shared
    private let countOptions = [5, 10, 15, 25]

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if !store.isPremium {
                            dailyLimitBanner
                        }
                        headerSection
                        quickActions
                        customQuizBuilder
                        missedQuestionsCard
                        bookmarkedCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToQuiz) {
                QuizView(questions: quizQuestions, mode: quizMode, domain: quizDomain)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Daily Limit Banner

    private var dailyLimitBanner: some View {
        let remaining = store.remainingFreeQuestions(questionsAnsweredToday: appState.questionsAnsweredToday)
        let atLimit = remaining <= 0

        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: atLimit ? "lock.fill" : "hourglass")
                    .foregroundStyle(atLimit ? VaultTheme.incorrectRed : VaultTheme.warningAmber)

                VStack(alignment: .leading, spacing: 2) {
                    Text(atLimit ? "Daily Limit Reached" : "\(remaining) free questions left today")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Upgrade to Premium for unlimited access")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Button { showPaywall = true } label: {
                    Text("Upgrade")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(VaultTheme.goldGradient)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill((atLimit ? VaultTheme.incorrectRed : VaultTheme.warningAmber).opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke((atLimit ? VaultTheme.incorrectRed : VaultTheme.warningAmber).opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(VaultTheme.goldGradient)

            Text("Quick Quiz")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Test your knowledge with focused practice sessions")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                QuizOptionCard(
                    title: "Lightning 5",
                    subtitle: "Fast round",
                    icon: "bolt.fill",
                    color: .yellow
                ) {
                    launchQuiz(count: 5)
                }
                .accessibilityLabel("Lightning 5 Quiz")
                .accessibilityHint("Start a 5-question practice quiz")

                QuizOptionCard(
                    title: "Quick 10",
                    subtitle: "Warm up",
                    icon: "flame.fill",
                    color: .orange
                ) {
                    launchQuiz(count: 10)
                }
                .accessibilityLabel("Quick 10 Quiz")
                .accessibilityHint("Start a 10-question practice quiz")
            }

            HStack(spacing: 10) {
                QuizOptionCard(
                    title: "Focused 15",
                    subtitle: "Deep practice",
                    icon: "brain.head.profile.fill",
                    color: .cyan
                ) {
                    launchQuiz(count: 15)
                }
                .accessibilityLabel("Focused 15 Quiz")
                .accessibilityHint("Start a 15-question practice quiz")

                QuizOptionCard(
                    title: "Marathon 25",
                    subtitle: "Full session",
                    icon: "trophy.fill",
                    color: .purple
                ) {
                    launchQuiz(count: 25)
                }
                .accessibilityLabel("Marathon 25 Quiz")
                .accessibilityHint("Start a 25-question practice quiz")
            }
        }
    }

    // MARK: - Custom Quiz Builder

    private var customQuizBuilder: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(VaultTheme.gold)
                Text("Custom Quiz")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Domain filter
            VStack(alignment: .leading, spacing: 6) {
                Text("Domain")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: selectedDomain == nil) {
                            selectedDomain = nil
                        }
                        ForEach(ExamDomain.allCases) { domain in
                            FilterChip(
                                label: domain.shortTitle,
                                isSelected: selectedDomain == domain,
                                color: domain.color
                            ) {
                                selectedDomain = selectedDomain == domain ? nil : domain
                            }
                        }
                    }
                }
            }

            // Difficulty filter
            VStack(alignment: .leading, spacing: 6) {
                Text("Difficulty")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))

                HStack(spacing: 8) {
                    FilterChip(label: "All", isSelected: selectedDifficulty == nil) {
                        selectedDifficulty = nil
                    }
                    ForEach(Question.Difficulty.allCases, id: \.self) { diff in
                        FilterChip(
                            label: diff.rawValue,
                            isSelected: selectedDifficulty == diff,
                            color: difficultyColor(diff)
                        ) {
                            selectedDifficulty = selectedDifficulty == diff ? nil : diff
                        }
                    }
                }
            }

            // Adaptive Mode
            let weakAreas = appState.getWeakSubObjectives()
            if !weakAreas.isEmpty {
                Toggle(isOn: $useAdaptiveMode) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(VaultTheme.gold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Adaptive Mode")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("Focus on weak areas")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
                .tint(VaultTheme.gold)
            }

            // Count selector
            VStack(alignment: .leading, spacing: 6) {
                Text("Questions")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))

                HStack(spacing: 8) {
                    ForEach(countOptions, id: \.self) { count in
                        Button {
                            selectedCount = count
                        } label: {
                            Text("\(count)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(selectedCount == count ? .black : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    selectedCount == count
                                    ? AnyShapeStyle(VaultTheme.goldGradient)
                                    : AnyShapeStyle(.white.opacity(0.08))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            // Available count
            let available = filteredPool.count
            Text("\(available) questions match your filters")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.35))

            Button {
                guard store.canAnswerMoreToday(questionsAnsweredToday: appState.questionsAnsweredToday) else {
                    showPaywall = true
                    return
                }
                quizQuestions = Array(filteredPool.shuffled().prefix(selectedCount))
                quizMode = .practice
                quizDomain = selectedDomain
                navigateToQuiz = true
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Custom Quiz")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(available == 0)
            .opacity(available == 0 ? 0.5 : 1.0)
            .accessibilityLabel("Start Custom Quiz")
            .accessibilityHint("Starts a quiz with \(selectedCount) questions from your selected filters")
            .accessibilityValue("\(available) questions match your filters")
        }
        .vaultCard()
    }

    // MARK: - Missed & Bookmarked

    private var missedQuestionsCard: some View {
        Group {
            if !appState.progress.missedQuestionIds.isEmpty {
                ActionCard(
                    icon: "arrow.counterclockwise",
                    color: VaultTheme.incorrectRed,
                    title: "Review Missed",
                    subtitle: "\(appState.progress.missedQuestionIds.count) questions to revisit"
                ) {
                    guard store.canAnswerMoreToday(questionsAnsweredToday: appState.questionsAnsweredToday) else {
                        showPaywall = true
                        return
                    }
                    quizQuestions = service.questions(withIds: appState.progress.missedQuestionIds).shuffled()
                    quizMode = .review
                    quizDomain = nil
                    navigateToQuiz = true
                }
                .accessibilityLabel("Review Missed Questions")
                .accessibilityHint("Review \(appState.progress.missedQuestionIds.count) questions you missed previously")
            }
        }
    }

    private var bookmarkedCard: some View {
        Group {
            if !appState.progress.bookmarkedQuestionIds.isEmpty {
                ActionCard(
                    icon: "bookmark.fill",
                    color: .orange,
                    title: "Bookmarked Questions",
                    subtitle: "\(appState.progress.bookmarkedQuestionIds.count) saved questions"
                ) {
                    guard store.canAnswerMoreToday(questionsAnsweredToday: appState.questionsAnsweredToday) else {
                        showPaywall = true
                        return
                    }
                    quizQuestions = service.questions(withIds: appState.progress.bookmarkedQuestionIds).shuffled()
                    quizMode = .practice
                    quizDomain = nil
                    navigateToQuiz = true
                }
                .accessibilityLabel("Bookmarked Questions")
                .accessibilityHint("Practice with \(appState.progress.bookmarkedQuestionIds.count) bookmarked questions")
            }
        }
    }

    // MARK: - Helpers

    private var filteredPool: [Question] {
        if useAdaptiveMode {
            let weakAreas = appState.getWeakSubObjectives()
            var adaptiveQuestions: [Question] = []
            for subObj in weakAreas {
                adaptiveQuestions.append(contentsOf: service.questions(forSubObjective: subObj))
            }
            // If we have adaptive questions, filter by difficulty/domain if specified
            var result = adaptiveQuestions
            if let domain = selectedDomain {
                result = result.filter { service.question(byId: $0.id).flatMap { ExamDomain.from(domainString: $0.domain) } == domain }
            }
            if let difficulty = selectedDifficulty {
                result = result.filter { $0.difficulty == difficulty }
            }
            return result
        } else {
            return service.questions(domain: selectedDomain, difficulty: selectedDifficulty)
        }
    }

    private func launchQuiz(count: Int) {
        guard store.canAnswerMoreToday(questionsAnsweredToday: appState.questionsAnsweredToday) else {
            showPaywall = true
            return
        }
        quizQuestions = service.randomQuestions(count: min(count, service.totalCount))
        quizMode = .practice
        quizDomain = nil
        navigateToQuiz = true
    }

    private func difficultyColor(_ diff: Question.Difficulty) -> Color {
        switch diff {
        case .Easy: return VaultTheme.correctGreen
        case .Medium: return VaultTheme.warningAmber
        case .Hard: return VaultTheme.incorrectRed
        }
    }
}

// MARK: - Supporting Views

struct QuizOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .vaultCard()
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = VaultTheme.gold
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : .white.opacity(0.08))
                .clipShape(Capsule())
        }
    }
}

struct ActionCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
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
}
