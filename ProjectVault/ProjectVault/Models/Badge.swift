import SwiftUI

struct Badge: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color

    static let allBadges: [Badge] = [
        Badge(id: "first_25", title: "Starter", description: "Answer 25 questions", icon: "book.fill", color: .blue),
        Badge(id: "first_100", title: "Century", description: "Answer 100 questions", icon: "100.circle.fill", color: .cyan),
        Badge(id: "first_250", title: "Scholar", description: "Answer 250 questions", icon: "books.vertical.fill", color: .green),
        Badge(id: "first_500", title: "Sage", description: "Answer 500 questions", icon: "brain.head.profile.fill", color: .purple),

        Badge(id: "week_streak", title: "Week Warrior", description: "7-day study streak", icon: "flame.fill", color: .orange),
        Badge(id: "month_streak", title: "Momentum", description: "30-day study streak", icon: "bolt.fill", color: .yellow),

        Badge(id: "domain_1_master", title: "Integration Master", description: "Master Domain 1", icon: "1.circle.fill", color: VaultTheme.gold),
        Badge(id: "domain_2_master", title: "Planning Expert", description: "Master Domain 2", icon: "2.circle.fill", color: VaultTheme.gold),
        Badge(id: "domain_3_master", title: "Execution Pro", description: "Master Domain 3", icon: "3.circle.fill", color: VaultTheme.gold),
        Badge(id: "domain_4_master", title: "Monitoring Wizard", description: "Master Domain 4", icon: "4.circle.fill", color: VaultTheme.gold),

        Badge(id: "accuracy_80", title: "Accuracy Expert", description: "80%+ overall accuracy", icon: "target", color: .red),
    ]

    static func badge(withId id: String) -> Badge? {
        allBadges.first { $0.id == id }
    }
}
