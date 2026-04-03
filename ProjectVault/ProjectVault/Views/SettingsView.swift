import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreKitManager.self) private var store
    @State private var showResetAlert = false
    @State private var showPaywall = false

    private let service = DataService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                List {
                    // App Info
                    Section {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(VaultTheme.gold.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(VaultTheme.gold.opacity(0.3), lineWidth: 1)
                                    )
                                Text("PV")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(VaultTheme.goldGradient)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Project+ Vault")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("CompTIA PK0-005 Exam Prep")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.5))
                                Text("Version 1.0.0")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        }
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)
                    }

                    // Subscription
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
                                        Text("Unlock unlimited questions, mocks & analytics")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                    Spacer()
                                    Text("From $4.99")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(VaultTheme.gold)
                                }
                            }

                            // Daily limit status
                            let remaining = store.remainingFreeQuestions(questionsAnsweredToday: appState.questionsAnsweredToday)
                            SettingsRow(
                                icon: "hourglass",
                                color: remaining > 10 ? .cyan : VaultTheme.warningAmber,
                                title: "Free Questions Today",
                                detail: "\(remaining) of \(StoreKitManager.freeQuestionLimit)"
                            )
                        }

                        Button {
                            Task { await store.restorePurchases() }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundStyle(.cyan)
                                    .frame(width: 24)
                                Text("Restore Purchases")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                        }

                        if let error = store.errorMessage {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundStyle(VaultTheme.incorrectRed)
                        }
                    }
                    .listRowBackground(VaultTheme.surface.opacity(0.5))

                    // Question Bank
                    Section("Question Bank") {
                        SettingsRow(
                            icon: "tray.full.fill",
                            color: .cyan,
                            title: "Total Questions",
                            detail: "\(service.totalCount)"
                        )

                        ForEach(ExamDomain.allCases) { domain in
                            SettingsRow(
                                icon: domain.icon,
                                color: domain.color,
                                title: domain.shortTitle,
                                detail: "\(service.count(for: domain))"
                            )
                        }
                    }
                    .listRowBackground(VaultTheme.surface.opacity(0.5))

                    // Exam Info
                    Section("Exam Information") {
                        SettingsRow(icon: "doc.text.fill", color: VaultTheme.gold, title: "Exam Code", detail: "PK0-005")
                        SettingsRow(icon: "questionmark.circle.fill", color: .orange, title: "Questions", detail: "Up to 90")
                        SettingsRow(icon: "clock.fill", color: .purple, title: "Duration", detail: "90 minutes")
                        SettingsRow(icon: "checkmark.seal.fill", color: VaultTheme.correctGreen, title: "Passing Score", detail: "710 / 900")
                    }
                    .listRowBackground(VaultTheme.surface.opacity(0.5))

                    // Data Management
                    Section("Data") {
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "trash.fill")
                                    .foregroundStyle(VaultTheme.incorrectRed)
                                    .frame(width: 24)
                                Text("Reset All Progress")
                                    .foregroundStyle(VaultTheme.incorrectRed)
                                Spacer()
                            }
                        }
                    }
                    .listRowBackground(VaultTheme.surface.opacity(0.5))
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
                        Button { showPaywall = true } label: {
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
            .alert("Reset Progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    appState.resetAllProgress()
                }
            } message: {
                Text("This will permanently delete all quiz history, scores, and bookmarks. This cannot be undone.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

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
            Text(detail)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
