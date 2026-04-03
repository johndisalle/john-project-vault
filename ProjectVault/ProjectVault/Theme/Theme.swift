import SwiftUI

enum VaultTheme {
    // MARK: - Colors
    static let gold = Color("VaultGold")
    static let background = Color("VaultBackground")
    static let surface = Color("VaultSurface")
    static let accent = Color("VaultAccent")

    static let correctGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let incorrectRed = Color(red: 0.9, green: 0.3, blue: 0.3)
    static let warningAmber = Color(red: 1.0, green: 0.75, blue: 0.0)

    // MARK: - Gradients
    static let goldGradient = LinearGradient(
        colors: [Color(red: 0.85, green: 0.65, blue: 0.13), Color(red: 1.0, green: 0.84, blue: 0.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [Color(red: 0.07, green: 0.07, blue: 0.12), Color(red: 0.12, green: 0.10, blue: 0.18)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [Color(red: 0.15, green: 0.14, blue: 0.22), Color(red: 0.11, green: 0.11, blue: 0.17)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Card Style
    static func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(cardGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(gold.opacity(0.15), lineWidth: 1)
            )
    }

    // MARK: - Fonts
    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 13, weight: .medium, design: .default)
    static let monoFont = Font.system(size: 14, weight: .medium, design: .monospaced)

    // MARK: - URLs
    static let privacyPolicyURL = URL(string: "https://johndisalle.github.io/john-project-vault/privacy-policy.html")!
    static let termsOfUseURL = URL(string: "https://johndisalle.github.io/john-project-vault/terms-of-use.html")!
    static let supportURL = URL(string: "https://johndisalle.github.io/john-project-vault/support.html")!
    static let supportEmail = "support@ellasid.com"
}

// MARK: - View Modifiers

struct VaultCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(VaultTheme.cardGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(VaultTheme.gold.opacity(0.15), lineWidth: 1)
            )
    }
}

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(VaultTheme.goldGradient)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(VaultTheme.gold)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .stroke(VaultTheme.gold.opacity(0.5), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func vaultCard() -> some View {
        modifier(VaultCardModifier())
    }
}

// MARK: - Haptics

enum Haptics {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    static func light() {
        lightGenerator.impactOccurred()
    }

    static func medium() {
        mediumGenerator.impactOccurred()
    }

    static func heavy() {
        heavyGenerator.impactOccurred()
    }

    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    static func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    static func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    static func selection() {
        selectionGenerator.selectionChanged()
    }
}

// MARK: - Animation Extensions

extension Animation {
    static let vaultSpring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let vaultBounce = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let vaultSnap = Animation.spring(response: 0.3, dampingFraction: 0.85)
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.12), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(20))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
