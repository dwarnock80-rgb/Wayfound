import SwiftUI

struct SubscriptionView: View {
    @Environment(WayfoundStore.self) private var store

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

                    Button {
                        store.setPremium(!store.state.isPremium)
                    } label: {
                        Label(store.state.isPremium ? "Premium enabled" : "Preview premium unlock", systemImage: "star.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(WayfoundTheme.deepSage)

                    Text("StoreKit can replace this preview toggle when product identifiers are ready.")
                        .font(.footnote)
                        .foregroundStyle(WayfoundTheme.secondaryInk)
                }
                .padding(18)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("Premium")
        }
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
