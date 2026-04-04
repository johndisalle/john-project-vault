import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreKitManager.self) private var store
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            VaultTheme.backgroundGradient.ignoresSafeArea()

            VStack {
                TabView(selection: $currentPage) {
                    // Page 1: Value Proposition
                    valueScreen
                        .tag(0)

                    // Page 2: Exam Date
                    examDateScreen
                        .tag(1)

                    // Page 3: Sample Question
                    sampleQuestionScreen
                        .tag(2)

                    // Page 4: Upsell
                    upsellScreen
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()

                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? VaultTheme.gold : .white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Screen 1: Value Proposition

    private var valueScreen: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(VaultTheme.gold.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: "book.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(VaultTheme.goldGradient)
                }

                Text("Master the CompTIA Project+ Exam")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("525+ practice questions, mock exams, and intelligent spaced repetition — everything you need to ace PK0-005")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                FeatureRow(icon: "book.fill", title: "525+ Questions", subtitle: "Full PK0-005 coverage")
                FeatureRow(icon: "doc.text.fill", title: "Mock Exams", subtitle: "Real exam format")
                FeatureRow(icon: "repeat.circle.fill", title: "Spaced Repetition", subtitle: "Learn to remember")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Analytics", subtitle: "Track your progress")
            }
            .padding(.horizontal, 20)

            Spacer()

            Button {
                currentPage = 1
            } label: {
                HStack {
                    Text("Get Started")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(GoldButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Screen 2: Exam Date

    private var examDateScreen: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(VaultTheme.gold.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(VaultTheme.goldGradient)
                }

                Text("When is Your Exam?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Set your exam date to get a personalized study plan and daily focus areas")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                DatePicker("Exam Date", selection: Binding(
                    get: { appState.examDate ?? Date().addingTimeInterval(86400 * 30) },
                    set: { appState.setExamDate($0) }
                ), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(VaultTheme.gold)

                if let examDate = appState.examDate {
                    let days = appState.daysUntilExam ?? 0
                    HStack {
                        Image(systemName: "hourglass")
                            .foregroundStyle(VaultTheme.gold)
                        Text("\(days) days of focused study ahead")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(VaultTheme.gold.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    currentPage = 1
                } label: {
                    Text("Back")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    currentPage = 2
                } label: {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(GoldButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Screen 3: Sample Question

    private var sampleQuestionScreen: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 16) {
                Text("Try a Sample Question")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Experience the quality of our questions")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)

            // Sample Question Card
            VStack(alignment: .leading, spacing: 12) {
                Text("What is the primary purpose of the Monitor and Control Phase Group?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                VStack(spacing: 10) {
                    OptionView(letter: "A", text: "Define project scope and objectives")
                    OptionView(letter: "B", text: "Execute project work and produce deliverables")
                    OptionView(letter: "C", text: "Track and regulate the ongoing project activities")
                    OptionView(letter: "D", text: "Close the project and document lessons learned")
                }

                Text("C")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(VaultTheme.correctGreen)
                    .padding(.top, 8)
            }
            .padding(16)
            .vaultCard()
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("Did you know?")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(VaultTheme.gold)

                Text("Each question includes detailed explanations to help you understand not just the answer, but the underlying concepts.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    currentPage = 1
                } label: {
                    Text("Back")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    currentPage = 3
                } label: {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(GoldButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Screen 4: Upsell

    private var upsellScreen: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(VaultTheme.gold.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(VaultTheme.gold)
                }

                Text("Unlimited Access Awaits")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                if store.isPremium {
                    Text("You're all set with Premium! Start studying now.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                } else {
                    Text("Upgrade to Premium for unlimited questions, mock exams, and full analytics")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                if !store.isPremium {
                    Text("From $4.99/month")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(VaultTheme.gold)

                    VStack(spacing: 8) {
                        PremiumFeatureRow(icon: "infinity", title: "Unlimited Questions")
                        PremiumFeatureRow(icon: "doc.text.fill", title: "All 4 Mock Exams")
                        PremiumFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics")
                        PremiumFeatureRow(icon: "bolt.fill", title: "Adaptive Learning")
                    }
                    .padding(.horizontal, 20)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                if !store.isPremium {
                    Button {
                        Haptics.light()
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Upgrade to Premium")
                        }
                    }
                    .buttonStyle(GoldButtonStyle())
                }

                Button {
                    Haptics.light()
                    appState.completeOnboarding()
                } label: {
                    Text(store.isPremium ? "Start Learning" : "Use Free Version")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(VaultTheme.gold)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(12)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct OptionView: View {
    let letter: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(letter)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(VaultTheme.gold)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(2)

            Spacer()
        }
        .padding(10)
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(VaultTheme.gold)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(VaultTheme.correctGreen)
        }
        .padding(.horizontal, 0)
    }
}
