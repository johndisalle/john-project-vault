import SwiftUI

struct VaultView: View {
    @Environment(AppState.self) private var appState

    @State private var searchText = ""
    @State private var selectedDomain: ExamDomain?
    @State private var selectedDifficulty: Question.Difficulty?
    @State private var showBookmarkedOnly = false
    @State private var showMissedOnly = false
    @State private var expandedQuestionId: String?

    private let service = DataService.shared

    private var filteredQuestions: [Question] {
        var pool = service.allQuestions

        if let domain = selectedDomain {
            pool = pool.filter { $0.domain.hasPrefix(domain.rawValue) }
        }
        if let diff = selectedDifficulty {
            pool = pool.filter { $0.difficulty == diff }
        }
        if showBookmarkedOnly {
            pool = pool.filter { appState.progress.bookmarkedQuestionIds.contains($0.id) }
        }
        if showMissedOnly {
            pool = pool.filter { appState.progress.missedQuestionIds.contains($0.id) }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            pool = pool.filter {
                $0.question.lowercased().contains(query) ||
                $0.explanation.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.lowercased().contains(query) }) ||
                $0.reference.lowercased().contains(query) ||
                $0.subObjective.contains(query)
            }
        }
        return pool
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    filtersSection
                    questionList
                }
            }
            .navigationTitle("Vault")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search questions, tags, objectives...")
        }
    }

    // MARK: - Filters

    private var filtersSection: some View {
        VStack(spacing: 10) {
            // Domain filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All Domains", isSelected: selectedDomain == nil) {
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
                .padding(.horizontal, 16)
            }

            // Difficulty + special filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All Levels", isSelected: selectedDifficulty == nil) {
                        selectedDifficulty = nil
                    }
                    FilterChip(
                        label: "Easy",
                        isSelected: selectedDifficulty == .Easy,
                        color: VaultTheme.correctGreen
                    ) {
                        selectedDifficulty = selectedDifficulty == .Easy ? nil : .Easy
                    }
                    FilterChip(
                        label: "Medium",
                        isSelected: selectedDifficulty == .Medium,
                        color: VaultTheme.warningAmber
                    ) {
                        selectedDifficulty = selectedDifficulty == .Medium ? nil : .Medium
                    }
                    FilterChip(
                        label: "Hard",
                        isSelected: selectedDifficulty == .Hard,
                        color: VaultTheme.incorrectRed
                    ) {
                        selectedDifficulty = selectedDifficulty == .Hard ? nil : .Hard
                    }

                    Divider()
                        .frame(height: 20)
                        .background(.white.opacity(0.15))

                    FilterChip(
                        label: "Bookmarked",
                        isSelected: showBookmarkedOnly,
                        color: .orange
                    ) {
                        showBookmarkedOnly.toggle()
                        if showBookmarkedOnly { showMissedOnly = false }
                    }
                    FilterChip(
                        label: "Missed",
                        isSelected: showMissedOnly,
                        color: VaultTheme.incorrectRed
                    ) {
                        showMissedOnly.toggle()
                        if showMissedOnly { showBookmarkedOnly = false }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Result count
            HStack {
                Text("\(filteredQuestions.count) questions")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                if selectedDomain != nil || selectedDifficulty != nil || showBookmarkedOnly || showMissedOnly {
                    Button {
                        selectedDomain = nil
                        selectedDifficulty = nil
                        showBookmarkedOnly = false
                        showMissedOnly = false
                    } label: {
                        Text("Clear Filters")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(VaultTheme.gold)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
        .padding(.top, 8)
    }

    // MARK: - Question List

    private var questionList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredQuestions) { question in
                    VaultQuestionCard(
                        question: question,
                        isExpanded: expandedQuestionId == question.id,
                        isBookmarked: appState.progress.bookmarkedQuestionIds.contains(question.id),
                        wasMissed: appState.progress.missedQuestionIds.contains(question.id),
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expandedQuestionId = expandedQuestionId == question.id ? nil : question.id
                            }
                        },
                        onBookmark: {
                            DataService.shared.toggleBookmark(questionId: question.id, in: &appState.progress)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Vault Question Card

struct VaultQuestionCard: View {
    let question: Question
    let isExpanded: Bool
    let isBookmarked: Bool
    let wasMissed: Bool
    let onTap: () -> Void
    let onBookmark: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — always visible
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(question.reference)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(domainColor.opacity(0.7))

                        DifficultyDot(difficulty: question.difficulty)

                        if question.isMultiSelect {
                            Text("MULTI")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(VaultTheme.warningAmber)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(VaultTheme.warningAmber.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }

                        if wasMissed {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(VaultTheme.incorrectRed.opacity(0.6))
                        }

                        Spacer()

                        Button(action: onBookmark) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 13))
                                .foregroundStyle(isBookmarked ? .orange : .white.opacity(0.3))
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.25))
                    }

                    Text(question.question)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(isExpanded ? nil : 2)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().background(.white.opacity(0.1))
                        .padding(.vertical, 4)

                    ForEach(question.options, id: \.self) { option in
                        let letter = String(option.prefix(1))
                        let isCorrect = question.correctAnswers.contains(letter)

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 13))
                                .foregroundStyle(isCorrect ? VaultTheme.correctGreen : .white.opacity(0.25))

                            Text(option)
                                .font(.system(size: 13))
                                .foregroundStyle(isCorrect ? VaultTheme.correctGreen : .white.opacity(0.6))
                                .lineSpacing(2)
                        }
                    }

                    // Explanation
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Explanation")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(VaultTheme.gold.opacity(0.7))

                        Text(question.explanation)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.65))
                            .lineSpacing(3)
                    }
                    .padding(10)
                    .background(.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Tags
                    if !question.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(question.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.4))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(.white.opacity(0.06))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .vaultCard()
    }

    private var domainColor: Color {
        ExamDomain.from(domainString: question.domain)?.color ?? VaultTheme.gold
    }
}

struct DifficultyDot: View {
    let difficulty: Question.Difficulty

    private var color: Color {
        switch difficulty {
        case .Easy: return VaultTheme.correctGreen
        case .Medium: return VaultTheme.warningAmber
        case .Hard: return VaultTheme.incorrectRed
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
    }
}
