import SwiftUI

struct QuizView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    /// Strips the leading letter prefix (e.g. "B. ") from an option string.
    static func stripLetterPrefix(_ option: String) -> String {
        // Handles "A. text", "B. text", etc.
        if option.count > 2, option[option.index(option.startIndex, offsetBy: 1)] == "." {
            return String(option.dropFirst(3))
        }
        return option
    }
    @State private var viewModel: QuizViewModel
    @State private var showExitAlert = false
    @State private var showReportSheet = false
    @State private var reportReason = ""
    @State private var reportSubmitted = false
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
            ForEach(Array(viewModel.shuffledOptions.enumerated()), id: \.element) { index, option in
                let displayLetter = viewModel.letterForOption(option)
                let displayText = "\(displayLetter). \(Self.stripLetterPrefix(option))"
                let isCorrectOption = viewModel.hasSubmitted ? viewModel.displayCorrectAnswers.contains(displayLetter) : nil
                OptionButton(
                    option: displayText,
                    isSelected: viewModel.selectedAnswers.contains(displayLetter),
                    isCorrect: isCorrectOption,
                    hasSubmitted: viewModel.hasSubmitted
                ) {
                    Haptics.selection()
                    viewModel.toggleAnswer(displayLetter)
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if viewModel.hasSubmitted {
                // Explanation
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: viewModel.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(viewModel.isCorrect ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
                        Text(viewModel.isCorrect ? "Correct!" : "Incorrect")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(viewModel.isCorrect ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
                        Spacer()
                        Button {
                            showReportSheet = true
                        } label: {
                            Image(systemName: "flag")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .accessibilityLabel("Report Question")
                        .accessibilityHint("Report an issue with this question")
                    }

                    // Show correct answer if wrong
                    if !viewModel.isCorrect {
                        HStack(spacing: 6) {
                            Text("Correct answer:")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(VaultTheme.correctGreen.opacity(0.7))
                            Text(viewModel.displayCorrectAnswers.joined(separator: ", "))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(VaultTheme.correctGreen)
                        }
                    }

                    Divider().background(.white.opacity(0.1))

                    // Explanation
                    Text(viewModel.currentQuestion.explanation)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineSpacing(3)

                    // Objective reference
                    HStack(spacing: 8) {
                        Text(viewModel.currentQuestion.subObjective)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(VaultTheme.gold.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(VaultTheme.gold.opacity(0.1))
                            .clipShape(Capsule())

                        Text(viewModel.currentQuestion.reference)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .vaultCard()
                .sheet(isPresented: $showReportSheet) {
                    reportQuestionSheet
                }

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
                .accessibilityLabel(viewModel.currentIndex + 1 < viewModel.questions.count ? "Next Question" : "View Results")
                .accessibilityHint("Move to the next question or view your results")
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
                .accessibilityLabel("Submit Answer")
                .accessibilityHint("Submit your selected answer and receive feedback")
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

    // MARK: - Report Question Sheet

    private var reportQuestionSheet: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Report Question")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("ID: \(viewModel.currentQuestion.id)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))

                    Text(viewModel.currentQuestion.question)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(3)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's wrong?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)

                        ForEach(["Incorrect answer", "Unclear question", "Typo/grammar", "Wrong explanation", "Duplicate question", "Other"], id: \.self) { reason in
                            Button {
                                reportReason = reason
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: reportReason == reason ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(reportReason == reason ? VaultTheme.gold : .white.opacity(0.3))
                                    Text(reason)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.8))
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }

                    if reportSubmitted {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(VaultTheme.correctGreen)
                            Text("Report saved. Thank you!")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(VaultTheme.correctGreen)
                        }
                        .padding(12)
                        .background(VaultTheme.correctGreen.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Spacer()

                    Button {
                        guard !reportReason.isEmpty else { return }
                        DataService.shared.saveQuestionReport(
                            questionId: viewModel.currentQuestion.id,
                            reason: reportReason
                        )
                        reportSubmitted = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showReportSheet = false
                            reportReason = ""
                            reportSubmitted = false
                        }
                    } label: {
                        Text("Submit Report")
                    }
                    .buttonStyle(GoldButtonStyle())
                    .disabled(reportReason.isEmpty)
                    .opacity(reportReason.isEmpty ? 0.5 : 1.0)
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showReportSheet = false
                        reportReason = ""
                    }
                    .foregroundStyle(VaultTheme.gold)
                }
            }
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
        .accessibilityLabel("Option: \(option)")
        .accessibilityHint(hasSubmitted ? (isCorrect == true ? "Correct answer" : (isSelected ? "Your incorrect answer" : "Incorrect option")) : (isSelected ? "Selected" : "Not selected"))
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
