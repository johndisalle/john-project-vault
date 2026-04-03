import SwiftUI

struct DomainListView: View {
    @Environment(AppState.self) private var appState
    private let service = QuestionService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(ExamDomain.allCases) { domain in
                            NavigationLink(destination: DomainDetailView(domain: domain)) {
                                DomainCard(
                                    domain: domain,
                                    questionCount: service.count(for: domain),
                                    score: appState.progress.domainScores[domain.rawValue]
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Domains")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.clear, for: .navigationBar)
        }
    }
}

struct DomainCard: View {
    let domain: ExamDomain
    let questionCount: Int
    let score: DomainScore?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: domain.icon)
                    .font(.title2)
                    .foregroundStyle(domain.color)
                    .frame(width: 40, height: 40)
                    .background(domain.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(domain.rawValue)
                        .font(VaultTheme.captionFont)
                        .foregroundStyle(domain.color)
                    Text(domain.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(domain.examWeight)%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(domain.color)
                    Text("of exam")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            HStack {
                Label("\(questionCount) questions", systemImage: "list.bullet")
                    .font(VaultTheme.captionFont)
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                if let score = score, score.attempted > 0 {
                    Text(String(format: "%.0f%% accuracy", score.accuracy))
                        .font(VaultTheme.captionFont)
                        .foregroundStyle(score.accuracy >= 65 ? VaultTheme.correctGreen : VaultTheme.warningAmber)
                }
            }

            // Progress bar
            if let score = score, score.attempted > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.1))
                            .frame(height: 4)
                        Capsule()
                            .fill(domain.color)
                            .frame(width: geo.size.width * min(score.accuracy / 100, 1.0), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(16)
        .vaultCard()
    }
}

struct DomainDetailView: View {
    let domain: ExamDomain
    @Environment(AppState.self) private var appState
    @State private var navigateToQuiz = false
    @State private var selectedCount = 10
    @State private var quizQuestions: [Question] = []

    private let service = QuestionService.shared
    private let countOptions = [10, 15, 25, 50]

    var body: some View {
        ZStack {
            VaultTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Domain header
                    VStack(spacing: 8) {
                        Image(systemName: domain.icon)
                            .font(.system(size: 48))
                            .foregroundStyle(domain.color)

                        Text(domain.title)
                            .font(VaultTheme.headlineFont)
                            .foregroundStyle(.white)

                        Text("Domain \(domain.rawValue) - \(domain.examWeight)% of exam")
                            .font(VaultTheme.captionFont)
                            .foregroundStyle(.white.opacity(0.6))

                        Text("\(service.count(for: domain)) questions available")
                            .font(VaultTheme.captionFont)
                            .foregroundStyle(domain.color)
                    }
                    .padding(.top, 12)

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

                    // Start button
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
                                VStack(spacing: 4) {
                                    Text("\(score.attempted)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text("Attempted")
                                        .font(VaultTheme.captionFont)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)

                                VStack(spacing: 4) {
                                    Text("\(score.correct)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(VaultTheme.correctGreen)
                                    Text("Correct")
                                        .font(VaultTheme.captionFont)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)

                                VStack(spacing: 4) {
                                    Text(String(format: "%.0f%%", score.accuracy))
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(score.accuracy >= 65 ? VaultTheme.correctGreen : VaultTheme.warningAmber)
                                    Text("Accuracy")
                                        .font(VaultTheme.captionFont)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .vaultCard()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(domain.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToQuiz) {
            QuizView(
                questions: quizQuestions,
                mode: .practice,
                domain: domain
            )
        }
    }
}
