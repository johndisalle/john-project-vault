import SwiftUI

struct QuizResultsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let viewModel: QuizViewModel
    @State private var saved = false
    @State private var animateScore = false
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                scoreSection
                breakdownSection
                questionReviewSection

                HStack(spacing: 12) {
                    Button {
                        showShareSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Share Results")

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                    .buttonStyle(GoldButtonStyle())
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .onAppear {
            saveResult()
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateScore = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
    }

    // MARK: - Score

    private var scoreSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 150, height: 150)

                Circle()
                    .trim(from: 0, to: animateScore ? viewModel.scorePercentage / 100 : 0)
                    .stroke(
                        viewModel.scorePercentage >= 65 ? VaultTheme.correctGreen : VaultTheme.incorrectRed,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", viewModel.scorePercentage))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(viewModel.correctCount)/\(viewModel.questions.count)")
                        .font(VaultTheme.captionFont)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Text(viewModel.scorePercentage >= 65 ? "Passed!" : "Keep Practicing")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(viewModel.scorePercentage >= 65 ? VaultTheme.correctGreen : VaultTheme.warningAmber)

            Text("Passing score: 65%")
                .font(VaultTheme.captionFont)
                .foregroundStyle(.white.opacity(0.4))
        }
        .vaultCard()
    }

    // MARK: - Breakdown

    private var breakdownSection: some View {
        HStack(spacing: 12) {
            ResultStatBox(
                label: "Correct",
                value: "\(viewModel.correctCount)",
                color: VaultTheme.correctGreen
            )
            ResultStatBox(
                label: "Incorrect",
                value: "\(viewModel.questions.count - viewModel.correctCount)",
                color: VaultTheme.incorrectRed
            )
            ResultStatBox(
                label: "Time",
                value: formatTime(Date().timeIntervalSince(viewModel.sessionStartTime)),
                color: .cyan
            )
        }
    }

    // MARK: - Question Review

    private var questionReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Question Review")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(.white)

            ForEach(Array(viewModel.questionResults.enumerated()), id: \.element.id) { index, result in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(VaultTheme.monoFont)
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 28)

                    Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.isCorrect ? VaultTheme.correctGreen : VaultTheme.incorrectRed)

                    Text(index < viewModel.questions.count ? viewModel.questions[index].question : "Question \(index + 1)")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)

                    Spacer()
                }
                .padding(.vertical, 6)

                if index < viewModel.questionResults.count - 1 {
                    Divider().background(.white.opacity(0.1))
                }
            }
        }
        .vaultCard()
    }

    // MARK: - Helpers

    private func saveResult() {
        guard !saved else { return }
        saved = true
        let result = viewModel.buildResult()
        DataService.shared.saveQuizResult(result, to: &appState.progress)
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var shareText: String {
        let score = String(format: "%.0f%%", viewModel.scorePercentage)
        let status = viewModel.scorePercentage >= 65 ? "PASSED" : "Keep studying"
        let mode = viewModel.mode.rawValue
        return """
        \(status)! I scored \(score) on a \(mode) quiz in Project+ Vault!

        \(viewModel.correctCount)/\(viewModel.questions.count) correct
        Time: \(formatTime(Date().timeIntervalSince(viewModel.sessionStartTime)))

        Studying for CompTIA Project+ (PK0-005) with Project+ Vault
        #ProjectPlus #CompTIA #PK0005
        """
    }
}

struct ResultStatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(VaultTheme.captionFont)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .vaultCard()
    }
}
