import StoreKit
import SwiftUI

/// Manages all StoreKit 2 interactions for the freemium model.
@MainActor
@Observable
final class StoreKitManager: @unchecked Sendable {
    // MARK: - Product IDs

    static let premiumLifetimeID = "com.projectvault.premium.lifetime"
    static let premiumMonthlyID  = "com.projectvault.premium.monthly"

    private static let productIDs: Set<String> = [
        premiumLifetimeID,
        premiumMonthlyID
    ]

    // MARK: - State

    var products: [Product] = []
    var isPremium = false
    var purchaseInProgress = false
    var errorMessage: String?

    // Specific products for easy access
    var lifetimeProduct: Product? { products.first { $0.id == Self.premiumLifetimeID } }
    var monthlyProduct: Product?  { products.first { $0.id == Self.premiumMonthlyID } }

    // MARK: - Free Tier Limits

    static let freeQuestionLimit = 50

    // MARK: - Init

    init() {
        Task { await self.loadProducts() }
        Task { await self.updateEntitlements() }
        Task {
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    await self.updateEntitlements()
                }
            }
        }
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: Self.productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products."
            print("[StoreKit] Product load error: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        purchaseInProgress = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateEntitlements()

            case .userCancelled:
                break

            case .pending:
                errorMessage = "Purchase is pending approval."

            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
            print("[StoreKit] Purchase error: \(error)")
        }

        purchaseInProgress = false
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        errorMessage = nil
        do {
            try await AppStore.sync()
            await updateEntitlements()
            if !isPremium {
                errorMessage = "No previous purchases found."
            }
        } catch {
            errorMessage = "Restore failed. Please try again."
            print("[StoreKit] Restore error: \(error)")
        }
    }

    // MARK: - Entitlement Check

    func updateEntitlements() async {
        var hasPremium = false

        // Check lifetime (non-consumable)
        if let result = await Transaction.latest(for: Self.premiumLifetimeID) {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    hasPremium = true
                }
            }
        }

        // Check monthly subscription
        if !hasPremium, let result = await Transaction.latest(for: Self.premiumMonthlyID) {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil && !transaction.isUpgraded {
                    if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                        hasPremium = true
                    }
                }
            }
        }

        isPremium = hasPremium
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Free Tier Helpers

    func canAnswerMoreToday(questionsAnsweredToday: Int) -> Bool {
        isPremium || questionsAnsweredToday < Self.freeQuestionLimit
    }

    func remainingFreeQuestions(questionsAnsweredToday: Int) -> Int {
        isPremium ? .max : max(0, Self.freeQuestionLimit - questionsAnsweredToday)
    }
}
