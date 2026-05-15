import SwiftUI

struct SubscriptionView: View {
    @Environment(WayfoundStore.self) private var store
    @State private var subscriptionService = SubscriptionService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wayfound Premium")
                            .font(.largeTitle.weight(.semibold))
                        Text("More room for a full life, still private and local.")
                            .font(.title3)
                            .foregroundStyle(WayfoundTheme.secondaryInk)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        PremiumFeature(symbol: "target", title: "More active goals", body: "Move beyond the free goal limit when life has more threads.")
                        PremiumFeature(symbol: "chart.line.uptrend.xyaxis", title: "Momentum analytics", body: "See category balance, recovery patterns, and weekly movement.")
                        PremiumFeature(symbol: "shippingbox.fill", title: "Advanced packs", body: "Guided goal sets for health resets, family admin, money calm, and purpose work.")
                    }
                    .premiumPanel()

                    VStack(spacing: 10) {
                        Button {
                            Task {
                                await subscriptionService.purchasePremium(store: store)
                            }
                        } label: {
                            Label(store.state.isPremium ? "Premium active" : purchaseButtonTitle, systemImage: "star.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(store.state.isPremium || subscriptionService.products.isEmpty || subscriptionService.isProcessing)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(WayfoundTheme.deepSage)

                        Button {
                            Task {
                                await subscriptionService.restore(store: store)
                            }
                        } label: {
                            Label("Restore purchases", systemImage: "arrow.clockwise.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(subscriptionService.isProcessing)
                        .buttonStyle(.bordered)
                    }

                    Text(subscriptionService.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(WayfoundTheme.secondaryInk)
                }
                .padding(18)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("Premium")
            .task {
                await subscriptionService.loadProducts()
                await subscriptionService.refreshEntitlements(store: store)
            }
        }
    }

    private var purchaseButtonTitle: String {
        if let product = subscriptionService.products.first {
            return "Start premium \(product.displayPrice)"
        }
        return "Premium unavailable"
    }
}

private struct PremiumFeature: View {
    let symbol: String
    let title: String
    let body: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(WayfoundTheme.deepSage)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }
        }
    }
}
