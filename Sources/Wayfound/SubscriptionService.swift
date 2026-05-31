import Foundation
import Observation
import StoreKit

@Observable
@MainActor
final class SubscriptionService {
    private let productIDs = ["wayfound.premium.monthly"]
    private(set) var products: [Product] = []
    private(set) var statusMessage = "Loading purchases..."
    private(set) var isProcessing = false

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            statusMessage = products.isEmpty
                ? "Purchases are not configured yet."
                : "Premium purchase is ready."
        } catch {
            statusMessage = "Purchases are unavailable right now."
        }
    }

    func refreshEntitlements(store: WayfoundStore) async {
        var hasPremiumEntitlement = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  productIDs.contains(transaction.productID) else {
                continue
            }
            hasPremiumEntitlement = true
        }

        if hasPremiumEntitlement {
            store.setPremium(true)
        }
    }

    func purchasePremium(store: WayfoundStore) async {
        guard let product = products.first else {
            statusMessage = "Add the premium product in App Store Connect before release."
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    statusMessage = "Purchase could not be verified."
                    return
                }
                await transaction.finish()
                store.setPremium(true)
                statusMessage = "Premium is active."
            case .pending:
                statusMessage = "Purchase is pending approval."
            case .userCancelled:
                statusMessage = "Purchase cancelled."
            @unknown default:
                statusMessage = "Purchase state changed. Please try restore."
            }
        } catch {
            statusMessage = "Purchase failed. Please try again."
        }
    }

    func restore(store: WayfoundStore) async {
        isProcessing = true
        defer { isProcessing = false }
        try? await AppStore.sync()
        await refreshEntitlements(store: store)
        statusMessage = store.state.isPremium ? "Premium restored." : "No premium purchase found."
    }
}
