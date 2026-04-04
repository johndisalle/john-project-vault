import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreKitManager.self) private var store
    @State private var showResetAlert = false
    @State private var showPaywall = false
    @State private var showShareSheet = false
    @State private var resetConfirmed = false

    private let service = DataService.shared

    var body: some View {
        ZStack {
            VaultTheme.backgroundGradient.ignoresSafeArea()

            List {
                appInfoSection
                subscriptionSection
                questionBankSection
                examInfoSection
                appearanceSection
                legalSection
                aboutSection
                dangerZoneSection
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbar {
                if !store.isPremium {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Haptics.light()
                            showPaywall = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                Text("PRO")
                                    .font(.system(size: 11, weight: .black))
                            }
                            .foregroundStyle(VaultTheme.gold)
                        }
                    }
                }
            }
            .alert("Reset All Progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset Everything", role: .destructive) {
                    Haptics.heavy()
                    withAnimation(.vaultSpring) {
                        appState.resetAllProgress()
                        resetConfirmed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        resetConfirmed = false
                    }
                }
            } message: {
                Text("This will permanently delete all quiz history, scores, bookmarks, mastery data, and flashcard progress. This action cannot be undone.")
            }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(VaultTheme.gold.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(VaultTheme.gold.opacity(0.3), lineWidth: 1)
                        )
                    Text("PV")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(VaultTheme.goldGradient)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Project+ Vault")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("CompTIA PK0-005 Exam Prep")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))

                    HStack(spacing: 8) {
                        Text("Version 1.0.0")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))

                        if store.isPremium {
                            HStack(spacing: 3) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 8))
                                Text("PREMIUM")
                                    .font(.system(size: 8, weight: .black))
                            }
                            .foregroundStyle(VaultTheme.gold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(VaultTheme.gold.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }

                Spacer()
            }
            .listRowBackground(Color.clear)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Section("Subscription") {
            if store.isPremium {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(VaultTheme.gold)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Premium Active")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(VaultTheme.gold)
                        Text("Unlimited access to all features")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(VaultTheme.correctGreen)
                }
            } else {
                Button {
                    Haptics.light()
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "crown")
                            .foregroundStyle(VaultTheme.gold)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Premium")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("Unlimited questions, mocks & analytics")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                        Text("From $4.99")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(VaultTheme.gold)
                    }
                }

                let remaining = store.remainingFreeQuestions(questionsAnsweredToday: appState.questionsAnsweredToday)
                SettingsRow(
                    icon: "hourglass",
                    color: remaining > 10 ? .cyan : VaultTheme.warningAmber,
                    title: "Free Questions Today",
                    detail: "\(remaining) / \(StoreKitManager.freeQuestionLimit)"
                )
            }

            Button {
                Haptics.light()
                Task { await store.restorePurchases() }
            } label: {
                SettingsRow(icon: "arrow.clockwise", color: .cyan, title: "Restore Purchases", detail: "")
            }

            if let error = store.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(VaultTheme.incorrectRed)
            }
        }
        .listRowBackground(VaultTheme.surface.opacity(0.5))
    }

    // MARK: - Question Bank

    private var questionBankSection: some View {
        Section("Question Bank") {
            SettingsRow(icon: "tray.full.fill", color: .cyan, title: "Total Questions", detail: "\(service.totalCount)")

            ForEach(ExamDomain.allCases) { domain in
                SettingsRow(icon: domain.icon, color: domain.color, title: domain.shortTitle, detail: "\(service.count(for: domain))")
            }

            SettingsRow(icon: "crown.fill", color: VaultTheme.gold, title: "Mastered", detail: "\(appState.progress.masteredQuestionIds.count)")
            SettingsRow(icon: "bookmark.fill", color: .orange, title: "Bookmarked", detail: "\(appState.progress.bookmarkedQuestionIds.count)")
            SettingsRow(icon: "xmark.circle.fill", color: VaultTheme.incorrectRed, title: "Missed", detail: "\(appState.progress.missedQuestionIds.count)")
        }
        .listRowBackground(VaultTheme.surface.opacity(0.5))
    }

    // MARK: - Exam Info

    private var examInfoSection: some View {
        Section("PK0-005 Exam Info") {
            SettingsRow(icon: "doc.text.fill", color: VaultTheme.gold, title: "Exam Code", detail: "PK0-005")
            SettingsRow(icon: "questionmark.circle.fill", color: .orange, title: "Questions", detail: "Up to 90")
            SettingsRow(icon: "clock.fill", color: .purple, title: "Duration", detail: "90 minutes")
            SettingsRow(icon: "checkmark.seal.fill", color: VaultTheme.correctGreen, title: "Passing Score", detail: "710 / 900")
            SettingsRow(icon: "chart.pie.fill", color: .cyan, title: "Domains", detail: "4 (33/30/19/18%)")
        }
        .listRowBackground(VaultTheme.surface.opacity(0.5))
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            HStack(spacing: 12) {
                Image(systemName: "moon.fill")
                    .foregroundStyle(.purple)
                    .frame(width: 24)
                Text("Dark Mode")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                Text("Always On")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(VaultTheme.correctGreen)
            }

            HStack(spacing: 12) {
                Image(systemName: "hand.tap.fill")
                    .foregroundStyle(.orange)
                    .frame(width: 24)
                Text("Haptic Feedback")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                Text("Enabled")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(VaultTheme.correctGreen)
            }
        }
        .listRowBackground(VaultTheme.surface.opacity(0.5))
    }

    // MARK: - Legal & Links

    private var legalSection: some View {
        Section("Legal & Support") {
            Link(destination: VaultTheme.privacyPolicyURL) {
                SettingsLinkRow(icon: "hand.raised.fill", color: .blue, title: "Privacy Policy")
            }

            Link(destination: VaultTheme.termsOfUseURL) {
                SettingsLinkRow(icon: "doc.plaintext.fill", color: .mint, title: "Terms of Use")
            }

            Link(destination: VaultTheme.supportURL) {
                SettingsLinkRow(icon: "questionmark.circle.fill", color: .green, title: "Help & Support")
            }

            Link(destination: URL(string: "mailto:\(VaultTheme.supportEmail)")!) {
                SettingsLinkRow(icon: "envelope.fill", color: .cyan, title: "Contact Us")
            }

            Button {
                Haptics.selection()
                showShareSheet = true
            } label: {
                SettingsLinkRow(icon: "square.and.arrow.up.fill", color: .orange, title: "Share Project+ Vault")
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [
                    "Check out Project+ Vault — the best CompTIA PK0-005 exam prep app!",
                ])
            }

            Button {
                Haptics.selection()
                requestReview()
            } label: {
                SettingsLinkRow(icon: "star.fill", color: .yellow, title: "Rate on App Store")
            }
        }
        .listRowBackground(VaultTheme.surface.opacity(0.5))
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Project+ Vault")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Your personal treasure trove for CompTIA Project+ (PK0-005) exam preparation. Featuring 200+ original practice questions, spaced repetition flashcards, mock exams, and detailed analytics — everything you need to ace the exam.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineSpacing(3)

                Divider().background(.white.opacity(0.08))

                HStack {
                    Text("Made with")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.3))
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(VaultTheme.incorrectRed)
                    Text("by Ellasid")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(VaultTheme.surface.opacity(0.5))
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        Section {
            Button {
                Haptics.warning()
                showResetAlert = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(VaultTheme.incorrectRed)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset All Progress")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(VaultTheme.incorrectRed)
                        Text("Deletes all history, scores & bookmarks")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    Spacer()
                }
            }

            if resetConfirmed {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(VaultTheme.correctGreen)
                    Text("Progress reset successfully")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(VaultTheme.correctGreen)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        } header: {
            Text("Danger Zone")
                .foregroundStyle(VaultTheme.incorrectRed.opacity(0.7))
        }
        .listRowBackground(VaultTheme.incorrectRed.opacity(0.05))
    }

    // MARK: - Helpers

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        AppStore.requestReview(in: scene)
    }
}

// MARK: - Supporting Views

struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            if !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

struct SettingsLinkRow: View {
    let icon: String
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.2))
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - AppStore Review Import

import StoreKit
