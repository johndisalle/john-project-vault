import SwiftUI

struct BadgesView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                VaultTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        earnedBadgesSection
                        lockedBadgesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.clear, for: .navigationBar)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(VaultTheme.gold.opacity(0.06))
                    .frame(width: 88, height: 88)
                Circle()
                    .stroke(VaultTheme.goldGradient, lineWidth: 2.5)
                    .frame(width: 88, height: 88)
                Image(systemName: "medal.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(VaultTheme.goldGradient)
            }

            Text("Your Achievements")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(appState.earnedBadges.count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(VaultTheme.gold)
                    Text("Earned")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(Badge.allBadges.count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Total")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var earnedBadgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earned Badges")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(.white)

            if appState.earnedBadges.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("No badges yet")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                    Text("Complete quizzes and reach milestones to earn badges")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.2))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .vaultCard()
            } else {
                let earnedBadgeObjects = Badge.allBadges.filter { appState.earnedBadges.contains($0.id) }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(earnedBadgeObjects) { badge in
                        BadgeCard(badge: badge, isEarned: true)
                    }
                }
            }
        }
    }

    private var lockedBadgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Locked Badges")
                .font(VaultTheme.headlineFont)
                .foregroundStyle(.white)

            let lockedBadges = Badge.allBadges.filter { !appState.earnedBadges.contains($0.id) }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(lockedBadges) { badge in
                    BadgeCard(badge: badge, isEarned: false)
                }
            }
        }
    }
}

struct BadgeCard: View {
    let badge: Badge
    let isEarned: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEarned ? badge.color.opacity(0.15) : .white.opacity(0.04))

                Image(systemName: badge.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(isEarned ? badge.color : .white.opacity(0.2))

                if !isEarned {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                        .offset(x: 18, y: -18)
                }
            }
            .frame(height: 80)

            VStack(spacing: 2) {
                Text(badge.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(isEarned ? .white : .white.opacity(0.4))
                    .multilineTextAlignment(.center)

                Text(badge.description)
                    .font(.system(size: 9))
                    .foregroundStyle(isEarned ? .white.opacity(0.6) : .white.opacity(0.2))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .vaultCard()
    }
}

#Preview {
    BadgesView()
        .environment(AppState())
}
