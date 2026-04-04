import SwiftUI

struct QuizView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: QuizViewModel
    @State private var showExitAlert = false
    @State private var timer: Timer?

    init(questions: [Question], mode: QuizSession.QuizMode, domain: ExamDomain?, examNumber: Int? = nil) {
        _viewModel = State(initialValue: QuizViewModel(
            questions: questions,
            mode: mode,
            domain: domain,
            examNumber: examNumber
        ))
    }

    var body: some View {
        ZStack {
            VaultTheme.backgroundGradient.ignoresSafeArea()

            if viewModel.questions.isEmpty {
                emptyState
            } else if viewModel.isQuizComplete {
                if viewModel.mode == .mockExam || viewModel.mode == .timed {
                    ExamResultsView(viewModel: viewModel)
                } else {
                    QuizResultsView(viewModel: viewModel)
                }
            } else {
                questionContent
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showExitAlert = true
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            if viewModel.mode == .timed || viewModel.mode == .mockExam {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text(viewModel.timerString)
                        .font(VaultTheme.monoFont)
                        .foregroundStyle(viewModel.remainingSeconds < 300 ? VaultTheme.incorrectRed : VaultTheme.gold)
                }
            }
        }
        .alert("Exit Quiz?", isPresented: $showExitAlert) {
            Button("Continue", role: .cancel) {}
            Button("Exit", role: .destructive) { dismiss() }
        } message: {
            Text("Your progress in this quiz will be lost.")
        }
        .onAppear {
            if viewModel.mode == .timed || viewModel.mode == .mockExam {
                viewModel.timerActive = true
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    Task { @MainActor in viewModel.tickTimer() }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Question Content

    private var questionContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                progressHeader
                questionCard
                optionsList
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.progressText)
                    .font(VaultTheme.captionFont)
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                if viewModel.isMultiSelect {
                    Text("Select \(viewModel.requiredSelections)")
                        .font(VaultTheme.captionFont)
                        .foregroundStyle(VaultTheme.warningAmber)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(VaultTheme.warningAmber.opacity(0.15))
                        .clipShape(Capsule())
                }

                DifficultyBadge(difficulty: viewModel.currentQuestion.difficulty)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.1))
                        .frame(height: 3)
                    Capsule()
                        .fill(VaultTheme.goldGradient)
                        .frame(width: geo.size.width * viewModel.progressFraction, height: 3)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progressFraction)
                }
            }
            .frame(height: 3)
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.currentQuestion.reference)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(VaultTheme.gold.opacity(0.6))

            Text(viewModel.currentQuestion.question)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .vaultCard()
    }

    private var optionsList: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.currentQuestion.options, id: \.self) { option in
                OptionButton(
                    option: option,
                    isSelected: viewModel.selectedAnswers.contains(viewModel.letterForOption(option)),
                    isCorrect: viewModel.hasSubmitted ? viewModel.currentQuestion.correctLetters.contains(viewModel.letterForOption(option)) : nil,
                    hasSubmitted: viewModel.hasSubmitted
                ) {
                    Haptics.selection()
                    viewModel.toggleAnswer(viewModel.letterForOption(option))
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if viewModel.hasSubmitted {
                // Explanation
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: viewModel.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(viewModel.isCorrect ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
                        Text(viewModel.isCorrect ? "Correct!" : "Incorrect")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(viewModel.isCorrect ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
                    }

                    Text(viewModel.currentQuestion.explanation)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .vaultCard()

                Button {
                    Haptics.light()
                    viewModel.nextQuestion()
                } label: {
                    HStack {
                        Text(viewModel.currentIndex + 1 < viewModel.questions.count ? "Next Question" : "View Results")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(GoldButtonStyle())
            } else {
                Button {
                    Haptics.medium()
                    viewModel.submitAnswer()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        viewModel.isCorrect ? Haptics.success() : Haptics.error()
                    }
                } label: {
                    Text("Submit Answer")
                }
                .buttonStyle(GoldButtonStyle())
                .disabled(viewModel.selectedAnswers.isEmpty)
                .opacity(viewModel.selectedAnswers.isEmpty ? 0.5 : 1.0)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
            Text("No questions available")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(.white.opacity(0.5))
            Button("Go Back") { dismiss() }
                .buttonStyle(SecondaryButtonStyle())
        }
    }
}

// MARK: - Option Button

struct OptionButton: View {
    let option: String
    let isSelected: Bool
    let isCorrect: Bool?
    let hasSubmitted: Bool
    let action: () -> Void

    private var borderColor: Color {
        if let isCorrect = isCorrect, hasSubmitted {
            return isCorrect ? VaultTheme.correctGreen : (isSelected ? VaultTheme.incorrectRed : .clear)
        }
        return isSelected ? VaultTheme.gold : .white.opacity(0.1)
    }

    private var backgroundColor: Color {
        if let isCorrect = isCorrect, hasSubmitted {
            if isCorrect { return VaultTheme.correctGreen.opacity(0.12) }
            if isSelected { return VaultTheme.incorrectRed.opacity(0.12) }
        }
        return isSelected ? VaultTheme.gold.opacity(0.08) : .white.opacity(0.04)
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Text(option)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)

                Spacer()

                if hasSubmitted {
                    if let isCorrect = isCorrect, isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(VaultTheme.correctGreen)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(VaultTheme.incorrectRed)
                    }
                }
            }
            .padding(14)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected || (hasSubmitted && isCorrect == true) ? 1.5 : 0.5)
            )
        }
        .disabled(hasSubmitted)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: Question.Difficulty

    private var color: Color {
        switch difficulty {
        case .Easy: return VaultTheme.correctGreen
        case .Medium: return VaultTheme.warningAmber
        case .Hard: return VaultTheme.incorrectRed
        }
    }

    var body: some View {
        Text(difficulty.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}
