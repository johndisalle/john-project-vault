import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreKitManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: PlanType = .lifetime
    @State private var showRestoreAlert = false

    enum PlanType {
        case monthly, lifetime
    }

    var body: some View {
        ZStack {
            VaultTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    dismissBar
                    heroSection
                    featureComparison
                    planSelector
                    purchaseButton
                    restoreLink
                    legalText
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Dismiss

    private var dismissBar: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(VaultTheme.gold.opacity(0.08))
                    .frame(width: 100, height: 100)
                Circle()
                    .stroke(VaultTheme.goldGradient, lineWidth: 2.5)
                    .frame(width: 100, height: 100)

                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(VaultTheme.goldGradient)
            }

            Text("Unlock Project+ Vault")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Get unlimited access to everything")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Feature Comparison

    private var featureComparison: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Features")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Free")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 50)

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(VaultTheme.gold.opacity(0.15))
                        .frame(width: 60, height: 22)
                    Text("Premium")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(VaultTheme.gold)
                }
                .frame(width: 64)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider().background(.white.opacity(0.08))

            FeatureRow(feature: "Daily Questions", free: "50/day", premium: "Unlimited")
            FeatureRow(feature: "Practice Quizzes", free: "Basic", premium: "All modes")
            FeatureRow(feature: "4 Full Mock Exams", free: nil, premium: true)
            FeatureRow(feature: "Spaced Repetition", free: nil, premium: true)
            FeatureRow(feature: "Swift Charts Analytics", free: nil, premium: true)
            FeatureRow(feature: "Domain Deep-Dive", free: nil, premium: true)
            FeatureRow(feature: "Export Reports", free: nil, premium: true)
            FeatureRow(feature: "Full Question Vault", free: "Preview", premium: "Full access")
            FeatureRow(feature: "Ad-Free Experience", free: nil, premium: true)
        }
        .background(VaultTheme.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(VaultTheme.gold.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        VStack(spacing: 10) {
            // Monthly
            PlanCard(
                isSelected: selectedPlan == .monthly,
                badge: nil,
                title: "Monthly",
                price: store.monthlyProduct?.displayPrice ?? "$4.99",
                subtitle: "per month, cancel anytime",
                action: { selectedPlan = .monthly }
            )

            // Lifetime
            PlanCard(
                isSelected: selectedPlan == .lifetime,
                badge: "BEST VALUE",
                title: "Lifetime",
                price: store.lifetimeProduct?.displayPrice ?? "$19.99",
                subtitle: "one-time purchase, forever",
                action: { selectedPlan = .lifetime }
            )
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        VStack(spacing: 8) {
            Button {
                Haptics.medium()
                Task { await purchaseSelected() }
            } label: {
                HStack(spacing: 8) {
                    if store.purchaseInProgress {
                        ProgressView()
                            .tint(.black)
                    }
                    Image(systemName: "lock.open.fill")
                    Text("Unlock Premium")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.black)
                .background(VaultTheme.goldGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(store.purchaseInProgress)

            if let error = store.errorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(VaultTheme.incorrectRed)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Restore

    private var restoreLink: some View {
        Button {
            Task { await store.restorePurchases() }
        } label: {
            Text("Restore Purchases")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(VaultTheme.gold.opacity(0.7))
        }
    }

    // MARK: - Legal

    private var legalText: some View {
        VStack(spacing: 4) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions in your App Store account settings.")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.2))
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            HStack(spacing: 16) {
                Text("Privacy Policy")
                Text("Terms of Use")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white.opacity(0.25))
        }
    }

    // MARK: - Actions

    private func purchaseSelected() async {
        let product: Product?
        switch selectedPlan {
        case .monthly:  product = store.monthlyProduct
        case .lifetime: product = store.lifetimeProduct
        }
        guard let product else { return }
        await store.purchase(product)
        if store.isPremium {
            dismiss()
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: String
    var free: String? = nil
    var premium: Any // String or Bool

    var body: some View {
        HStack {
            Text(feature)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Free column
            Group {
                if let freeText = free {
                    Text(freeText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                } else {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.15))
                }
            }
            .frame(width: 50)

            // Premium column
            Group {
                if let text = premium as? String {
                    Text(text)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(VaultTheme.gold)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(VaultTheme.correctGreen)
                }
            }
            .frame(width: 64)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let isSelected: Bool
    let badge: String?
    let title: String
    let price: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Radio
                ZStack {
                    Circle()
                        .stroke(isSelected ? VaultTheme.gold : .white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(VaultTheme.gold)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(VaultTheme.goldGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Text(price)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? VaultTheme.gold : .white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? VaultTheme.gold.opacity(0.06) : .white.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? VaultTheme.gold.opacity(0.5) : .white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
        }
    }
}

// MARK: - Compact Premium Banner (reusable)

struct PremiumBanner: View {
    let message: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(VaultTheme.gold)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Premium Required")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(VaultTheme.gold)
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                Text("Upgrade")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(VaultTheme.goldGradient)
                    .clipShape(Capsule())
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(VaultTheme.gold.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(VaultTheme.gold.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

/// Small inline lock badge for gated features.
struct PremiumLockBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "lock.fill")
                .font(.system(size: 8))
            Text("PRO")
                .font(.system(size: 8, weight: .black))
        }
        .foregroundStyle(VaultTheme.gold)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(VaultTheme.gold.opacity(0.12))
        .clipShape(Capsule())
    }
}
