import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showResetAlert = false

    private let service = QuestionService.shared

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
            .alert("Reset Progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    appState.resetAllProgress()
                }
            } message: {
                Text("This will permanently delete all quiz history, scores, and bookmarks. This cannot be undone.")
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
