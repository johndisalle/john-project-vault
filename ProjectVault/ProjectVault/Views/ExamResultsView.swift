import SwiftUI
import Charts

struct ExamResultsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let viewModel: QuizViewModel
    @State private var saved = false
    @State private var animateScore = false
    @State private var selectedReviewFilter: ReviewFilter = .all

    private let service = DataService.shared

    enum ReviewFilter: String, CaseIterable {
        case all = "All"
        case incorrect = "Incorrect"
        case correct = "Correct"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerBadge
                scoreRing
                verdictBanner
                statsRow
                domainBarChart
                difficultyChart
                scoreTrendChart
                domainBreakdownCards
                questionReviewSection

                Button { dismiss() } label: { Text("Done") }
                    .buttonStyle(GoldButtonStyle())
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            saveResult()
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                animateScore = true
            }
        }
    }

    // MARK: - Header

    private var headerBadge: some View {
        VStack(spacing: 4) {
            Text("MOCK EXAM RESULTS")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(VaultTheme.gold)
            Text("CompTIA Project+ PK0-005")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Score Ring

    private var scoreRing: some View {
        ZStack {
            // Outer track
            Circle()
                .stroke(.white.opacity(0.06), lineWidth: 14)
                .frame(width: 180, height: 180)

            // Score arc
            Circle()
                .trim(from: 0, to: animateScore ? viewModel.scorePercentage / 100 : 0)
                .stroke(
                    AngularGradient(
                        colors: [scoreColor.opacity(0.6), scoreColor],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))

            // Passing threshold marker at 65%
            Circle()
                .fill(.white.opacity(0.4))
                .frame(width: 6, height: 6)
                .offset(y: -90)
                .rotationEffect(.degrees(360 * 0.65))

            VStack(spacing: 2) {
                Text(String(format: "%.1f%%", viewModel.scorePercentage))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text("\(viewModel.correctCount) of \(viewModel.questions.count)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))

                Text("Passing: 65%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Verdict Banner

    private var verdictBanner: some View {
        let passed = viewModel.scorePercentage >= 65

        return HStack(spacing: 12) {
            Image(systemName: passed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(passed ? VaultTheme.correctGreen : VaultTheme.warningAmber)

            VStack(alignment: .leading, spacing: 2) {
                Text(passed ? "Congratulations!" : "Keep Studying")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(passed ? VaultTheme.correctGreen : VaultTheme.warningAmber)

                Text(passed
                     ? "You passed the mock exam. Great work!"
                     : "You need 65% to pass. Review weak domains.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill((passed ? VaultTheme.correctGreen : VaultTheme.warningAmber).opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke((passed ? VaultTheme.correctGreen : VaultTheme.warningAmber).opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            ResultStatBox(label: "Correct", value: "\(viewModel.correctCount)", color: VaultTheme.correctGreen)
            ResultStatBox(label: "Incorrect", value: "\(viewModel.questions.count - viewModel.correctCount)", color: VaultTheme.incorrectRed)
            ResultStatBox(label: "Time", value: formatTime(Date().timeIntervalSince(viewModel.sessionStartTime)), color: .cyan)
            ResultStatBox(label: "Avg/Q", value: formatAvgTime, color: .purple)
        }
    }

    private var formatAvgTime: String {
        let total = Date().timeIntervalSince(viewModel.sessionStartTime)
        let avg = viewModel.questions.isEmpty ? 0 : total / Double(viewModel.questions.count)
        return String(format: "%.0fs", avg)
    }

    // MARK: - Domain Bar Chart

    private var domainBarChart: some View {
        let breakdown = service.domainBreakdown(from: viewModel.questionResults)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(VaultTheme.gold)
                Text("Domain Performance")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Chart {
                ForEach(ExamDomain.allCases) { domain in
                    let data = breakdown[domain] ?? (0, 0)
                    let pct = data.total > 0 ? Double(data.correct) / Double(data.total) * 100 : 0

                    BarMark(
                        x: .value("Domain", domain.shortTitle),
                        y: .value("Score", pct)
                    )
                    .foregroundStyle(domain.color.gradient)
                    .cornerRadius(6)
                    .annotation(position: .top, spacing: 4) {
                        Text(String(format: "%.0f%%", pct))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                // Passing threshold line
                RuleMark(y: .value("Pass", 65))
                    .foregroundStyle(.white.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .trailing, alignment: .trailing) {
                        Text("65%")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)%")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    AxisGridLine().foregroundStyle(.white.opacity(0.05))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(height: 200)
        }
        .vaultCard()
    }

    // MARK: - Difficulty Donut Chart

    private var difficultyChart: some View {
        let breakdown = service.difficultyBreakdown(from: viewModel.questionResults)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(.purple)
                Text("Difficulty Breakdown")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 16) {
                Chart {
                    ForEach(Question.Difficulty.allCases, id: \.self) { diff in
                        let data = breakdown[diff] ?? (0, 0)
                        SectorMark(
                            angle: .value("Count", data.total),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(difficultyColor(diff).gradient)
                        .cornerRadius(4)
                    }
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Question.Difficulty.allCases, id: \.self) { diff in
                        let data = breakdown[diff] ?? (0, 0)
                        let pct = data.total > 0 ? Double(data.correct) / Double(data.total) * 100 : 0

                        HStack(spacing: 8) {
                            Circle()
                                .fill(difficultyColor(diff))
                                .frame(width: 8, height: 8)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(diff.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("\(data.correct)/\(data.total) correct (\(String(format: "%.0f%%", pct)))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                    }
                }
            }
        }
        .vaultCard()
    }

    // MARK: - Score Trend (Historical Mock Exams)

    private var scoreTrendChart: some View {
        let mockResults = appState.progress.quizHistory
            .filter { $0.mode == "Mock Exam" || $0.mode == "Timed Exam" }
            .sorted { $0.date < $1.date }

        return Group {
            if mockResults.count >= 2 {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundStyle(.cyan)
                        Text("Score Trend")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Chart {
                        ForEach(Array(mockResults.enumerated()), id: \.offset) { index, result in
                            LineMark(
                                x: .value("Exam", index + 1),
                                y: .value("Score", result.scorePercentage)
                            )
                            .foregroundStyle(.cyan.gradient)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))

                            PointMark(
                                x: .value("Exam", index + 1),
                                y: .value("Score", result.scorePercentage)
                            )
                            .foregroundStyle(result.passed ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
                            .symbolSize(40)

                            AreaMark(
                                x: .value("Exam", index + 1),
                                y: .value("Score", result.scorePercentage)
                            )
                            .foregroundStyle(.cyan.opacity(0.08).gradient)
                        }

                        RuleMark(y: .value("Pass", 65))
                            .foregroundStyle(.white.opacity(0.2))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                            AxisValueLabel {
                                Text("\(value.as(Int.self) ?? 0)%")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            AxisGridLine().foregroundStyle(.white.opacity(0.05))
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                Text("Exam \(value.as(Int.self) ?? 0)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                    }
                    .frame(height: 180)
                }
                .vaultCard()
            }
        }
    }

    // MARK: - Domain Breakdown Cards

    private var domainBreakdownCards: some View {
        let breakdown = service.domainBreakdown(from: viewModel.questionResults)

        return VStack(alignment: .leading, spacing: 10) {
            Text("Domain Details")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            ForEach(ExamDomain.allCases) { domain in
                let data = breakdown[domain] ?? (0, 0)
                let pct = data.total > 0 ? Double(data.correct) / Double(data.total) * 100 : 0
                let passed = pct >= 65

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(domain.color.opacity(0.2), lineWidth: 3)
                            .frame(width: 44, height: 44)
                        Circle()
                            .trim(from: 0, to: pct / 100)
                            .stroke(domain.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                        Text(String(format: "%.0f%%", pct))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(domain.color)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(domain.shortTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)

                            Text("\(domain.examWeight)%")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(domain.color.opacity(0.6))
                        }

                        Text("\(data.correct)/\(data.total) correct")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()

                    Image(systemName: passed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(passed ? VaultTheme.correctGreen : VaultTheme.warningAmber)
                }
                .padding(12)
                .vaultCard()
            }
        }
    }

    // MARK: - Question Review

    private var questionReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Question Review")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Picker("Filter", selection: $selectedReviewFilter) {
                    ForEach(ReviewFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            let filtered = filteredReviewItems

            if filtered.isEmpty {
                Text("No questions match this filter.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                ForEach(Array(filtered.enumerated()), id: \.element.result.id) { _, item in
                    ExamReviewRow(
                        index: item.originalIndex,
                        question: item.question,
                        result: item.result
                    )
                }
            }
        }
        .vaultCard()
    }

    private struct ReviewItem {
        let originalIndex: Int
        let question: Question
        let result: QuestionResult
    }

    private var filteredReviewItems: [ReviewItem] {
        let items = viewModel.questionResults.enumerated().compactMap { index, result -> ReviewItem? in
            guard index < viewModel.questions.count else { return nil }
            return ReviewItem(originalIndex: index + 1, question: viewModel.questions[index], result: result)
        }

        switch selectedReviewFilter {
        case .all: return items
        case .incorrect: return items.filter { !$0.result.isCorrect }
        case .correct: return items.filter { $0.result.isCorrect }
        }
    }

    // MARK: - Helpers

    private var scoreColor: Color {
        if viewModel.scorePercentage >= 80 { return VaultTheme.correctGreen }
        if viewModel.scorePercentage >= 65 { return VaultTheme.warningAmber }
        return VaultTheme.incorrectRed
    }

    private func difficultyColor(_ diff: Question.Difficulty) -> Color {
        switch diff {
        case .Easy: return VaultTheme.correctGreen
        case .Medium: return VaultTheme.warningAmber
        case .Hard: return VaultTheme.incorrectRed
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func saveResult() {
        guard !saved else { return }
        saved = true
        let result = viewModel.buildResult()
        DataService.shared.saveQuizResult(result, to: &appState.progress)
    }
}

// MARK: - Exam Review Row

struct ExamReviewRow: View {
    let index: Int
    let question: Question
    let result: QuestionResult
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text("\(index)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: 28)

                    Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(result.isCorrect ? VaultTheme.correctGreen : VaultTheme.incorrectRed)

                    Text(question.question)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(isExpanded ? nil : 2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.2))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(question.options, id: \.self) { option in
                        let letter = String(option.prefix(1))
                        let isCorrect = question.correctAnswers.contains(letter)
                        let wasSelected = result.selectedAnswers.contains(letter)

                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: optionIcon(isCorrect: isCorrect, wasSelected: wasSelected))
                                .font(.system(size: 11))
                                .foregroundStyle(optionColor(isCorrect: isCorrect, wasSelected: wasSelected))

                            Text(option)
                                .font(.system(size: 12))
                                .foregroundStyle(isCorrect ? VaultTheme.correctGreen : (wasSelected ? VaultTheme.incorrectRed : .white.opacity(0.4)))
                        }
                    }

                    Text(question.explanation)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineSpacing(2)
                        .padding(8)
                        .background(.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.leading, 38)
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 6)
    }

    private func optionIcon(isCorrect: Bool, wasSelected: Bool) -> String {
        if isCorrect && wasSelected { return "checkmark.circle.fill" }
        if isCorrect { return "checkmark.circle" }
        if wasSelected { return "xmark.circle.fill" }
        return "circle"
    }

    private func optionColor(isCorrect: Bool, wasSelected: Bool) -> Color {
        if isCorrect { return VaultTheme.correctGreen }
        if wasSelected { return VaultTheme.incorrectRed }
        return .white.opacity(0.2)
    }
}
