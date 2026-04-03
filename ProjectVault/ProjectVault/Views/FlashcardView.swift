import SwiftUI

struct FlashcardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let domain: ExamDomain?
    @State private var cards: [Question] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var dragOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var reviewedCount = 0
    @State private var knewCount = 0
    @State private var isSessionComplete = false

    private let service = DataService.shared

    var body: some View {
        ZStack {
            VaultTheme.backgroundGradient.ignoresSafeArea()

            if isSessionComplete {
                sessionCompleteView
            } else if cards.isEmpty {
                emptyState
            } else {
                VStack(spacing: 16) {
                    header
                    cardStack
                    swipeHints
                    ratingButtons
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("\(dueCount) due")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(VaultTheme.gold.opacity(0.6))
            }
        }
        .onAppear {
            loadCards()
        }
    }

    private var dueCount: Int {
        service.flashcardsDue(in: appState.progress, domain: domain).count
    }

    private func loadCards() {
        cards = Array(service.flashcardsDue(in: appState.progress, domain: domain).prefix(20))
        currentIndex = 0
        isFlipped = false
        reviewedCount = 0
        knewCount = 0
        isSessionComplete = false
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Text(domain?.shortTitle ?? "All Domains")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Text("\(currentIndex + 1) / \(cards.count)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Progress
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.08)).frame(height: 4)
                    Capsule()
                        .fill(VaultTheme.goldGradient)
                        .frame(
                            width: geo.size.width * (cards.isEmpty ? 0 : Double(currentIndex) / Double(cards.count)),
                            height: 4
                        )
                        .animation(.easeOut(duration: 0.3), value: currentIndex)
                }
            }
            .frame(height: 4)

            HStack {
                Label("\(knewCount) knew", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(VaultTheme.correctGreen)
                Spacer()
                Label("\(reviewedCount - knewCount) learning", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(VaultTheme.warningAmber)
            }
        }
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        ZStack {
            // Background card preview
            if currentIndex + 1 < cards.count {
                cardFace(for: cards[currentIndex + 1], showingFront: true)
                    .scaleEffect(0.95)
                    .opacity(0.4)
            }

            // Active card
            if currentIndex < cards.count {
                cardFace(for: cards[currentIndex], showingFront: !isFlipped)
                    .offset(dragOffset)
                    .rotationEffect(.degrees(Double(dragOffset.width) / 20))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                handleSwipe(value.translation)
                            }
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isFlipped.toggle()
                        }
                    }
                    .animation(.spring(response: 0.3), value: dragOffset)

                // Swipe indicator overlays
                if dragOffset.width > 40 {
                    swipeOverlay(text: "KNEW IT", color: VaultTheme.correctGreen, icon: "checkmark.circle.fill")
                        .opacity(min(Double(dragOffset.width - 40) / 80, 1.0))
                }
                if dragOffset.width < -40 {
                    swipeOverlay(text: "STUDY MORE", color: VaultTheme.incorrectRed, icon: "arrow.counterclockwise")
                        .opacity(min(Double(-dragOffset.width - 40) / 80, 1.0))
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func cardFace(for question: Question, showingFront: Bool) -> some View {
        VStack(spacing: 0) {
            if showingFront {
                frontFace(question)
            } else {
                backFace(question)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 420)
        .background(VaultTheme.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    showingFront ? VaultTheme.gold.opacity(0.2) : VaultTheme.correctGreen.opacity(0.3),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
    }

    private func frontFace(_ question: Question) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text(question.reference)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(domainColor(for: question).opacity(0.7))

                Spacer()

                DifficultyBadge(difficulty: question.difficulty)
            }

            Spacer()

            Text(question.question)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            if question.isMultiSelect {
                Text("Select \(question.correctAnswers.count) answers")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(VaultTheme.warningAmber)
            }

            Text("Tap to reveal answer")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(24)
    }

    private func backFace(_ question: Question) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("ANSWER")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(VaultTheme.correctGreen)
                    Spacer()
                    if appState.progress.masteredQuestionIds.contains(question.id) {
                        Label("Mastered", systemImage: "crown.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(VaultTheme.gold)
                    }
                }

                ForEach(question.options, id: \.self) { option in
                    let letter = String(option.prefix(1))
                    let isCorrect = question.correctAnswers.contains(letter)

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(isCorrect ? VaultTheme.correctGreen : .white.opacity(0.2))

                        Text(option)
                            .font(.system(size: 14, weight: isCorrect ? .semibold : .regular))
                            .foregroundStyle(isCorrect ? .white : .white.opacity(0.5))
                            .lineSpacing(2)
                    }
                }

                Divider().background(.white.opacity(0.1))

                Text(question.explanation)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineSpacing(3)

                // Mastery toggle
                Button {
                    DataService.shared.toggleMastered(questionId: question.id, in: &appState.progress)
                } label: {
                    let isMastered = appState.progress.masteredQuestionIds.contains(question.id)
                    HStack(spacing: 6) {
                        Image(systemName: isMastered ? "crown.fill" : "crown")
                            .font(.system(size: 12))
                        Text(isMastered ? "Mastered" : "Mark as Mastered")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(isMastered ? .black : VaultTheme.gold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isMastered ? VaultTheme.goldGradient : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(VaultTheme.gold.opacity(isMastered ? 0 : 0.4), lineWidth: 1)
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding(24)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Swipe Hints

    private var swipeHints: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left")
                Text("Study More")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(VaultTheme.incorrectRed.opacity(0.5))

            Spacer()

            HStack(spacing: 4) {
                Text("Knew It")
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(VaultTheme.correctGreen.opacity(0.5))
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Rating Buttons (for precise SM-2 grading)

    private var ratingButtons: some View {
        Group {
            if isFlipped {
                VStack(spacing: 8) {
                    Text("How well did you know this?")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))

                    HStack(spacing: 8) {
                        RatingButton(label: "Again", subtitle: "1 day", color: VaultTheme.incorrectRed, quality: 1) {
                            recordAndAdvance(quality: 1)
                        }
                        RatingButton(label: "Hard", subtitle: "3 days", color: VaultTheme.warningAmber, quality: 3) {
                            recordAndAdvance(quality: 3)
                        }
                        RatingButton(label: "Good", subtitle: "6 days", color: .cyan, quality: 4) {
                            recordAndAdvance(quality: 4)
                        }
                        RatingButton(label: "Easy", subtitle: "10+ days", color: VaultTheme.correctGreen, quality: 5) {
                            recordAndAdvance(quality: 5)
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: isFlipped)
        .padding(.bottom, 8)
    }

    // MARK: - Swipe Overlay

    private func swipeOverlay(text: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 40))
            Text(text)
                .font(.system(size: 14, weight: .black, design: .rounded))
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty / Complete

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(VaultTheme.gold)
            Text("All Caught Up!")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(.white)
            Text("No flashcards due for review right now.\nCome back later or start a quiz.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Button("Go Back") { dismiss() }
                .buttonStyle(SecondaryButtonStyle())
        }
        .padding(32)
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundStyle(VaultTheme.goldGradient)

            Text("Session Complete!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(reviewedCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Reviewed")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                VStack(spacing: 4) {
                    Text("\(knewCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(VaultTheme.correctGreen)
                    Text("Knew")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                VStack(spacing: 4) {
                    Text("\(reviewedCount - knewCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(VaultTheme.warningAmber)
                    Text("Learning")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .vaultCard()

            let mastered = appState.progress.masteredQuestionIds.count
            Text("\(mastered) total questions mastered")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(VaultTheme.gold.opacity(0.6))

            VStack(spacing: 10) {
                if dueCount > 0 {
                    Button {
                        loadCards()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Continue (\(dueCount) more due)")
                        }
                    }
                    .buttonStyle(GoldButtonStyle())
                }

                Button("Done") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(32)
    }

    // MARK: - Actions

    private func handleSwipe(_ translation: CGSize) {
        if translation.width > 100 {
            // Swipe right = knew it (quality 4)
            recordAndAdvance(quality: 4)
        } else if translation.width < -100 {
            // Swipe left = didn't know (quality 1)
            recordAndAdvance(quality: 1)
        } else {
            dragOffset = .zero
        }
    }

    private func recordAndAdvance(quality: Int) {
        guard currentIndex < cards.count else { return }

        let questionId = cards[currentIndex].id
        service.recordFlashcardResult(questionId: questionId, quality: quality, in: &appState.progress)

        reviewedCount += 1
        if quality >= 3 { knewCount += 1 }

        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: quality >= 3 ? 500 : -500, height: 0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dragOffset = .zero
            isFlipped = false
            if currentIndex + 1 < cards.count {
                currentIndex += 1
            } else {
                isSessionComplete = true
            }
        }
    }

    private func domainColor(for question: Question) -> Color {
        ExamDomain.from(domainString: question.domain)?.color ?? VaultTheme.gold
    }
}

// MARK: - Rating Button

struct RatingButton: View {
    let label: String
    let subtitle: String
    let color: Color
    let quality: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
                Text(subtitle)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
