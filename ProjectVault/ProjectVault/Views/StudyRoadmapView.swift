import SwiftUI

struct StudyRoadmapView: View {
    @Environment(AppState.self) private var appState
    @State private var showDatePicker = false

    private let service = DataService.shared

    var body: some View {
        ZStack {
            VaultTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    examCountdownHeader
                    readinessGauge
                    dailyRecommendation
                    domainTimeline
                    weeklyMilestones
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Study Plan")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .sheet(isPresented: $showDatePicker) {
            examDateSheet
        }
    }

    // MARK: - Exam Countdown Header

    private var examCountdownHeader: some View {
        VStack(spacing: 14) {
            if let days = appState.daysUntilExam, let examDate = appState.examDate {
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("\(days)")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(urgencyColor(days))
                        Text("days left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Exam Date")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                        Text(examDate.formatted(date: .long, time: .omitted))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Button {
                            showDatePicker = true
                        } label: {
                            Text("Change date")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(VaultTheme.gold)
                        }
                    }

                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 36))
                        .foregroundStyle(VaultTheme.gold.opacity(0.5))

                    Text("Set Your Exam Date")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Get a personalized study plan based on your timeline")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)

                    Button {
                        showDatePicker = true
                    } label: {
                        Text("Set Exam Date")
                    }
                    .buttonStyle(GoldButtonStyle())
                }
            }
        }
        .vaultCard()
    }

    // MARK: - Readiness Gauge

    private var readinessGauge: some View {
        let readiness = calculateReadiness()

        return VStack(spacing: 12) {
            HStack {
                Text("Exam Readiness")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text(readinessLabel(readiness))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(readinessColor(readiness))
            }

            // Segmented gauge
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background segments
                    HStack(spacing: 2) {
                        ForEach(0..<20, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(segmentColor(index: i, readiness: readiness))
                                .frame(height: 12)
                        }
                    }
                }
            }
            .frame(height: 12)

            HStack {
                Text("0%")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.2))
                Spacer()
                Text("Pass: 65%")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                Spacer()
                Text("100%")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.2))
            }

            HStack(spacing: 16) {
                ReadinessMetric(label: "Accuracy", value: String(format: "%.0f%%", appState.progress.overallAccuracy), color: .cyan)
                ReadinessMetric(label: "Coverage", value: String(format: "%.0f%%", coveragePercentage()), color: .purple)
                ReadinessMetric(label: "Mastered", value: "\(appState.progress.masteredQuestionIds.count)", color: VaultTheme.gold)
                ReadinessMetric(label: "Prediction", value: "\(appState.passPredictionPercentage)%", color: predictionColor())
            }
        }
        .vaultCard()
    }

    // MARK: - Daily Recommendation

    private var dailyRecommendation: some View {
        let recommendation = generateRecommendation()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(VaultTheme.gold)
                Text("Today's Focus")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(recommendation.headline)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Text(recommendation.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineSpacing(3)

                if !recommendation.weakAreas.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Priority Sub-Objectives:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(VaultTheme.warningAmber)

                        ForEach(recommendation.weakAreas, id: \.self) { area in
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(VaultTheme.warningAmber)
                                Text(area)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(10)
                    .background(VaultTheme.warningAmber.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .vaultCard()
    }

    // MARK: - Domain Timeline

    private var domainTimeline: some View {
        let days = appState.daysUntilExam ?? 60

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(.cyan)
                Text("Domain Roadmap")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            ForEach(ExamDomain.allCases) { domain in
                let score = appState.progress.domainScores[domain.rawValue]
                let accuracy = score?.accuracy ?? 0
                let attempted = score?.attempted ?? 0
                let totalQuestions = service.count(for: domain)
                let coverage = totalQuestions > 0 ? Double(attempted) / Double(totalQuestions) : 0
                let mastered = service.masteredCount(for: domain, in: appState.progress)
                let targetDays = Int(Double(days) * Double(domain.examWeight) / 100.0)
                let isReady = accuracy >= 65 && coverage >= 0.5

                HStack(spacing: 12) {
                    // Status indicator
                    ZStack {
                        Circle()
                            .fill(isReady ? VaultTheme.correctGreen.opacity(0.15) : domain.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: isReady ? "checkmark.circle.fill" : domain.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(isReady ? VaultTheme.correctGreen : domain.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(domain.shortTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("(\(domain.examWeight)%)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(domain.color.opacity(0.6))
                        }

                        HStack(spacing: 12) {
                            Label(String(format: "%.0f%%", accuracy), systemImage: "target")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(accuracy >= 65 ? VaultTheme.correctGreen : VaultTheme.warningAmber)

                            Label("\(mastered) mastered", systemImage: "crown.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(VaultTheme.gold.opacity(0.6))
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.06)).frame(height: 4)
                                Capsule().fill(domain.color)
                                    .frame(width: geo.size.width * min(coverage, 1.0), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("~\(targetDays)d")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("budget")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                }
                .padding(.vertical, 4)

                if domain != ExamDomain.allCases.last {
                    Divider().background(.white.opacity(0.06))
                }
            }
        }
        .vaultCard()
    }

    // MARK: - Weekly Milestones

    private var weeklyMilestones: some View {
        let days = appState.daysUntilExam ?? 60
        let weeks = max(days / 7, 1)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(.purple)
                Text("Weekly Milestones")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            let questionsPerWeek = max(service.totalCount / weeks, 10)
            let currentWeek = max(1, (days > 0 ? (appState.daysUntilExam.map { max(1, (60 - $0) / 7 + 1) } ?? 1) : 1))

            ForEach(1...min(weeks, 8), id: \.self) { week in
                let isCurrentWeek = week == currentWeek
                let isPast = week < currentWeek

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isPast ? VaultTheme.correctGreen.opacity(0.15) : (isCurrentWeek ? VaultTheme.gold.opacity(0.15) : .white.opacity(0.05)))
                            .frame(width: 32, height: 32)
                        if isPast {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(VaultTheme.correctGreen)
                        } else {
                            Text("\(week)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(isCurrentWeek ? VaultTheme.gold : .white.opacity(0.4))
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(weekMilestoneTitle(week: week, totalWeeks: weeks))
                            .font(.system(size: 13, weight: isCurrentWeek ? .bold : .medium))
                            .foregroundStyle(isCurrentWeek ? .white : .white.opacity(0.6))
                        Text("~\(questionsPerWeek) questions/week")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    Spacer()

                    if isCurrentWeek {
                        Text("THIS WEEK")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(VaultTheme.gold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(VaultTheme.gold.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .vaultCard()
    }

    // MARK: - Exam Date Sheet

    private var examDateSheet: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Set Your Exam Date")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    DatePicker("Exam Date", selection: Binding(
                        get: { appState.examDate ?? Date().addingTimeInterval(86400 * 30) },
                        set: { appState.setExamDate($0) }
                    ), in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(VaultTheme.gold)

                    Button {
                        if appState.examDate == nil {
                            appState.setExamDate(Date().addingTimeInterval(86400 * 30))
                        }
                        showDatePicker = false
                    } label: {
                        Text("Save")
                    }
                    .buttonStyle(GoldButtonStyle())
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showDatePicker = false }
                        .foregroundStyle(VaultTheme.gold)
                }
            }
        }
    }

    // MARK: - Calculations

    private func calculateReadiness() -> Double {
        let accuracy = appState.progress.overallAccuracy
        let coverage = coveragePercentage()
        let masteryRatio = service.totalCount > 0 ? Double(appState.progress.masteredQuestionIds.count) / Double(service.totalCount) * 100 : 0

        return (accuracy * 0.5) + (coverage * 0.3) + (masteryRatio * 0.2)
    }

    private func coveragePercentage() -> Double {
        let total = max(service.totalCount, 1)
        return min(Double(appState.progress.totalQuestionsAnswered) / Double(total) * 100, 100)
    }

    private func generateRecommendation() -> StudyRecommendation {
        let weakAreas = appState.getWeakSubObjectives()
        let accuracy = appState.progress.overallAccuracy
        let coverage = coveragePercentage()
        let days = appState.daysUntilExam ?? 60

        // Find weakest domain
        var weakestDomain: ExamDomain = .domain1
        var worstAccuracy: Double = 100
        for domain in ExamDomain.allCases {
            let score = appState.progress.domainScores[domain.rawValue]
            let acc = score?.accuracy ?? 0
            let attempted = score?.attempted ?? 0
            if attempted > 0 && acc < worstAccuracy {
                worstAccuracy = acc
                weakestDomain = domain
            }
        }

        let headline: String
        let detail: String

        if appState.progress.totalQuestionsAnswered == 0 {
            headline = "Start with Domain 1"
            detail = "Begin your study journey with Project Integration and Management. Aim for 10-15 questions today to build momentum."
        } else if days <= 7 {
            headline = "Final Sprint: Focus on Weak Areas"
            detail = "With \(days) days left, prioritize your weakest sub-objectives. Do timed practice to build exam stamina."
        } else if accuracy < 50 {
            headline = "Build Your Foundation"
            detail = "Focus on understanding core concepts in \(weakestDomain.shortTitle). Review explanations carefully after each question."
        } else if accuracy < 65 {
            headline = "Push Past the Pass Line"
            detail = "You're at \(String(format: "%.0f%%", accuracy)) accuracy. Focus on \(weakestDomain.shortTitle) (\(String(format: "%.0f%%", worstAccuracy))) to get above 65%."
        } else if coverage < 50 {
            headline = "Expand Your Coverage"
            detail = "Good accuracy! Now cover more ground. You've seen \(String(format: "%.0f%%", coverage)) of questions. Try domains you haven't touched yet."
        } else {
            headline = "Refine and Master"
            detail = "Strong progress! Focus on mastering weak sub-objectives and use flashcards for long-term retention."
        }

        return StudyRecommendation(headline: headline, detail: detail, weakAreas: weakAreas)
    }

    private func urgencyColor(_ days: Int) -> Color {
        if days <= 7 { return VaultTheme.incorrectRed }
        if days <= 14 { return VaultTheme.warningAmber }
        return VaultTheme.correctGreen
    }

    private func readinessLabel(_ readiness: Double) -> String {
        if readiness >= 75 { return "Ready" }
        if readiness >= 55 { return "Getting There" }
        if readiness >= 30 { return "In Progress" }
        return "Just Starting"
    }

    private func readinessColor(_ readiness: Double) -> Color {
        if readiness >= 75 { return VaultTheme.correctGreen }
        if readiness >= 55 { return VaultTheme.warningAmber }
        return VaultTheme.incorrectRed
    }

    private func segmentColor(index: Int, readiness: Double) -> Color {
        let threshold = Int(readiness / 5)
        if index < threshold {
            return readinessColor(readiness)
        }
        return .white.opacity(0.06)
    }

    private func predictionColor() -> Color {
        let pred = appState.passPredictionPercentage
        if pred >= 70 { return VaultTheme.correctGreen }
        if pred >= 55 { return VaultTheme.warningAmber }
        return VaultTheme.incorrectRed
    }

    private func weekMilestoneTitle(week: Int, totalWeeks: Int) -> String {
        if week == 1 { return "Foundation: Domain 1 & 2 basics" }
        if week == totalWeeks { return "Final review & mock exams" }
        if week <= totalWeeks / 3 { return "Cover Domains 1 & 2 in depth" }
        if week <= (totalWeeks * 2) / 3 { return "Domains 3 & 4 + weak area drill" }
        return "Full mock exams + flashcard review"
    }
}

// MARK: - Supporting Types

struct StudyRecommendation {
    let headline: String
    let detail: String
    let weakAreas: [String]
}

struct ReadinessMetric: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}
