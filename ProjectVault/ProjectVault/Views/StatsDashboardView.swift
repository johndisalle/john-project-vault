import SwiftUI
import Charts

// MARK: - Chart Data Types

struct DailyAccuracyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let accuracy: Double
    let count: Int
}

struct DomainMasteryData: Identifiable {
    let id = UUID()
    let domain: ExamDomain
    let mastered: Int
    let total: Int
    var fraction: Double { total > 0 ? Double(mastered) / Double(total) : 0 }
}

struct WeakAreaData: Identifiable {
    let id = UUID()
    let subObjective: String
    let label: String
    let attempted: Int
    let accuracy: Double
}

struct StreakDay: Identifiable {
    let id = UUID()
    let date: Date
    let questions: Int
    let hasActivity: Bool
}

struct DomainAccuracyData: Identifiable {
    let id = UUID()
    let domain: ExamDomain
    let accuracy: Double
    let attempted: Int
}

// MARK: - Stats Dashboard

struct StatsDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreKitManager.self) private var store
    @State private var showPaywall = false

    private let service = DataService.shared

    var body: some View {
        ZStack {
            VaultTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    streakHeatmap
                    overallStatsRow
                    accuracyTrendChart
                    domainMasteryChart
                    domainAccuracyRadar
                    weakAreasSection
                    difficultyBreakdownChart
                    studyActivityChart
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Streak Heatmap

    private var streakHeatmap: some View {
        let days = buildStreakDays(weeks: 12)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Study Streak")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()

                HStack(spacing: 4) {
                    Text("\(appState.progress.streak)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("day")
                            .font(.system(size: 10, weight: .bold))
                        Text("streak")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.orange.opacity(0.6))
                }
            }

            // Heatmap grid (12 weeks)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)

            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(days) { day in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(heatmapColor(for: day))
                        .frame(height: 14)
                }
            }

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.3))
                    ForEach([0, 5, 15, 30], id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(heatmapColorForCount(level))
                            .frame(width: 10, height: 10)
                    }
                    Text("More")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.3))
                }
                Spacer()
                Text("Last 12 weeks")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.25))
            }
        }
        .vaultCard()
    }

    // MARK: - Overall Stats Row

    private var overallStatsRow: some View {
        let p = appState.progress
        return HStack(spacing: 10) {
            MiniStatCard(value: "\(p.totalQuestionsAnswered)", label: "Answered", icon: "checkmark.circle.fill", color: .cyan)
            MiniStatCard(value: String(format: "%.0f%%", p.overallAccuracy), label: "Accuracy", icon: "target", color: VaultTheme.gold)
            MiniStatCard(value: "\(p.masteredQuestionIds.count)", label: "Mastered", icon: "crown.fill", color: VaultTheme.gold)
            MiniStatCard(value: "\(p.quizHistory.count)", label: "Quizzes", icon: "list.clipboard", color: .purple)
        }
    }

    // MARK: - Accuracy Trend Line Chart

    private var accuracyTrendChart: some View {
        let points = buildDailyAccuracy(days: 30)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(.cyan)
                Text("Accuracy Trend")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("30 days")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
            }

            if points.isEmpty {
                emptyChartPlaceholder("Complete quizzes to see your accuracy trend")
            } else {
                Chart {
                    ForEach(points) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Accuracy", point.accuracy)
                        )
                        .foregroundStyle(.cyan.gradient)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Accuracy", point.accuracy)
                        )
                        .foregroundStyle(.cyan.opacity(0.08).gradient)

                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Accuracy", point.accuracy)
                        )
                        .foregroundStyle(point.accuracy >= 65 ? VaultTheme.correctGreen : VaultTheme.incorrectRed)
                        .symbolSize(30)
                    }

                    RuleMark(y: .value("Pass", 65))
                        .foregroundStyle(.white.opacity(0.2))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .annotation(position: .trailing, alignment: .trailing) {
                            Text("65%")
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.25))
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
                        AxisGridLine().foregroundStyle(.white.opacity(0.04))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .frame(height: 200)
            }
        }
        .vaultCard()
    }

    // MARK: - Domain Mastery Bar Chart

    private var domainMasteryChart: some View {
        let data = ExamDomain.allCases.map { domain in
            DomainMasteryData(
                domain: domain,
                mastered: service.masteredCount(for: domain, in: appState.progress),
                total: service.count(for: domain)
            )
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(VaultTheme.gold)
                Text("Domain Mastery")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(appState.progress.masteredQuestionIds.count)/\(service.totalCount)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(VaultTheme.gold.opacity(0.6))
            }

            Chart(data) { item in
                BarMark(
                    x: .value("Domain", item.domain.shortTitle),
                    y: .value("Mastered", item.fraction * 100)
                )
                .foregroundStyle(item.domain.color.gradient)
                .cornerRadius(6)
                .annotation(position: .top, spacing: 4) {
                    VStack(spacing: 0) {
                        Text("\(item.mastered)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(String(format: "%.0f%%", item.fraction * 100))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
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
                    AxisGridLine().foregroundStyle(.white.opacity(0.04))
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

            // Exam weight labels beneath
            HStack(spacing: 0) {
                ForEach(ExamDomain.allCases) { domain in
                    VStack(spacing: 2) {
                        Text("\(domain.examWeight)%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(domain.color.opacity(0.5))
                        Text("of exam")
                            .font(.system(size: 7))
                            .foregroundStyle(.white.opacity(0.2))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .vaultCard()
    }

    // MARK: - Domain Accuracy Comparison

    private var domainAccuracyRadar: some View {
        let data = ExamDomain.allCases.map { domain -> DomainAccuracyData in
            let score = appState.progress.domainScores[domain.rawValue]
            return DomainAccuracyData(
                domain: domain,
                accuracy: score?.accuracy ?? 0,
                attempted: score?.attempted ?? 0
            )
        }

        let hasData = data.contains { $0.attempted > 0 }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.mint)
                Text("Domain Accuracy")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            if !hasData {
                emptyChartPlaceholder("Answer questions to see domain accuracy")
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Accuracy", item.accuracy),
                        y: .value("Domain", item.domain.shortTitle)
                    )
                    .foregroundStyle(item.domain.color.gradient)
                    .cornerRadius(6)
                    .annotation(position: .trailing, spacing: 6) {
                        if item.attempted > 0 {
                            Text(String(format: "%.0f%%", item.accuracy))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }

                    RuleMark(x: .value("Pass", 65))
                        .foregroundStyle(.white.opacity(0.15))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
                .chartXScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisValueLabel {
                            Text("\(value.as(Int.self) ?? 0)%")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        AxisGridLine().foregroundStyle(.white.opacity(0.04))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .frame(height: 160)
            }
        }
        .vaultCard()
    }

    // MARK: - Weak Areas

    private var weakAreasSection: some View {
        let weakAreas = buildWeakAreas()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(VaultTheme.warningAmber)
                Text("Weak Areas")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if !store.isPremium {
                    PremiumLockBadge()
                }
            }

            if !store.isPremium {
                PremiumBanner(message: "Unlock detailed weak area analysis") {
                    showPaywall = true
                }
            } else if weakAreas.isEmpty {
                emptyChartPlaceholder("Not enough data yet — keep practicing!")
            } else {
                ForEach(weakAreas.prefix(5)) { area in
                    HStack(spacing: 12) {
                        // Accuracy ring
                        ZStack {
                            Circle()
                                .stroke(.white.opacity(0.08), lineWidth: 3)
                                .frame(width: 40, height: 40)
                            Circle()
                                .trim(from: 0, to: area.accuracy / 100)
                                .stroke(
                                    area.accuracy < 50 ? VaultTheme.incorrectRed : VaultTheme.warningAmber,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(-90))
                            Text(String(format: "%.0f%%", area.accuracy))
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(area.accuracy < 50 ? VaultTheme.incorrectRed : VaultTheme.warningAmber)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Objective \(area.subObjective)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("\(area.attempted) attempted")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.4))
                        }

                        Spacer()

                        Image(systemName: "arrow.right.circle")
                            .foregroundStyle(.white.opacity(0.2))
                    }
                    .padding(.vertical, 4)

                    if area.id != weakAreas.prefix(5).last?.id {
                        Divider().background(.white.opacity(0.06))
                    }
                }
            }
        }
        .vaultCard()
    }

    // MARK: - Difficulty Breakdown Donut

    private var difficultyBreakdownChart: some View {
        let allResults = appState.progress.quizHistory.flatMap(\.questionResults)
        let breakdown = service.difficultyBreakdown(from: allResults)

        let hasData = breakdown.values.contains { $0.total > 0 }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(.purple)
                Text("Difficulty Performance")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            if !hasData {
                emptyChartPlaceholder("Complete quizzes to see difficulty breakdown")
            } else {
                HStack(spacing: 20) {
                    Chart {
                        ForEach(Question.Difficulty.allCases, id: \.self) { diff in
                            let data = breakdown[diff] ?? (0, 0)
                            SectorMark(
                                angle: .value("Count", data.total),
                                innerRadius: .ratio(0.55),
                                angularInset: 2.5
                            )
                            .foregroundStyle(difficultyColor(diff).gradient)
                            .cornerRadius(4)
                        }
                    }
                    .frame(width: 130, height: 130)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Question.Difficulty.allCases, id: \.self) { diff in
                            let data = breakdown[diff] ?? (0, 0)
                            let pct = data.total > 0 ? Double(data.correct) / Double(data.total) * 100 : 0

                            HStack(spacing: 8) {
                                Circle().fill(difficultyColor(diff)).frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(diff.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text("\(data.correct)/\(data.total) (\(String(format: "%.0f%%", pct)))")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }
                        }
                    }

                    Spacer()
                }
            }
        }
        .vaultCard()
    }

    // MARK: - Study Activity (Questions per day)

    private var studyActivityChart: some View {
        let days = buildActivityDays(count: 14)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundStyle(.green)
                Text("Study Activity")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("14 days")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
            }

            if days.allSatisfy({ $0.questions == 0 }) {
                emptyChartPlaceholder("Start studying to see your activity")
            } else {
                Chart(days) { day in
                    BarMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Questions", day.questions)
                    )
                    .foregroundStyle(
                        day.questions > 0
                        ? Color.green.opacity(0.7).gradient
                        : Color.white.opacity(0.05).gradient
                    )
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.day())
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            Text("\(value.as(Int.self) ?? 0)")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        AxisGridLine().foregroundStyle(.white.opacity(0.04))
                    }
                }
                .frame(height: 140)
            }
        }
        .vaultCard()
    }

    // MARK: - Empty Chart Placeholder

    private func emptyChartPlaceholder(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.12))
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Data Builders

    private func buildDailyAccuracy(days: Int) -> [DailyAccuracyPoint] {
        let calendar = Calendar.current
        let history = appState.progress.quizHistory

        var points: [DailyAccuracyPoint] = []
        for dayOffset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: date)

            let dayResults = history.filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
            guard !dayResults.isEmpty else { continue }

            let total = dayResults.reduce(0) { $0 + $1.totalQuestions }
            let correct = dayResults.reduce(0) { $0 + $1.correctCount }
            let accuracy = total > 0 ? Double(correct) / Double(total) * 100 : 0

            points.append(DailyAccuracyPoint(date: dayStart, accuracy: accuracy, count: total))
        }
        return points
    }

    private func buildStreakDays(weeks: Int) -> [StreakDay] {
        let calendar = Calendar.current
        let totalDays = weeks * 7
        let history = appState.progress.quizHistory

        // Build a map of date → question count
        var dayMap: [Date: Int] = [:]
        for result in history {
            let day = calendar.startOfDay(for: result.date)
            dayMap[day, default: 0] += result.totalQuestions
        }

        var days: [StreakDay] = []
        for offset in (0..<totalDays).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let count = dayMap[dayStart] ?? 0
            days.append(StreakDay(date: dayStart, questions: count, hasActivity: count > 0))
        }
        return days
    }

    private func buildWeakAreas() -> [WeakAreaData] {
        let allResults = appState.progress.quizHistory.flatMap(\.questionResults)

        // Group by sub-objective
        var objMap: [String: (total: Int, correct: Int)] = [:]
        for qr in allResults {
            if let q = service.question(byId: qr.questionId) {
                let key = q.subObjective
                let current = objMap[key] ?? (0, 0)
                objMap[key] = (current.total + 1, current.correct + (qr.isCorrect ? 1 : 0))
            }
        }

        return objMap
            .filter { $0.value.total >= 3 } // Need minimum attempts
            .map { key, value in
                let accuracy = Double(value.correct) / Double(value.total) * 100
                return WeakAreaData(subObjective: key, label: key, attempted: value.total, accuracy: accuracy)
            }
            .sorted { $0.accuracy < $1.accuracy }
    }

    private func buildActivityDays(count: Int) -> [StreakDay] {
        let calendar = Calendar.current
        let history = appState.progress.quizHistory

        var dayMap: [Date: Int] = [:]
        for result in history {
            let day = calendar.startOfDay(for: result.date)
            dayMap[day, default: 0] += result.totalQuestions
        }

        var days: [StreakDay] = []
        for offset in (0..<count).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let count = dayMap[dayStart] ?? 0
            days.append(StreakDay(date: dayStart, questions: count, hasActivity: count > 0))
        }
        return days
    }

    // MARK: - Helpers

    private func heatmapColor(for day: StreakDay) -> Color {
        heatmapColorForCount(day.questions)
    }

    private func heatmapColorForCount(_ count: Int) -> Color {
        switch count {
        case 0:     return .white.opacity(0.04)
        case 1...5: return .green.opacity(0.25)
        case 6...15: return .green.opacity(0.5)
        case 16...30: return .green.opacity(0.75)
        default:    return .green
        }
    }

    private func difficultyColor(_ diff: Question.Difficulty) -> Color {
        switch diff {
        case .Easy: return VaultTheme.correctGreen
        case .Medium: return VaultTheme.warningAmber
        case .Hard: return VaultTheme.incorrectRed
        }
    }
}

// MARK: - Mini Stat Card

struct MiniStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .vaultCard()
    }
}
