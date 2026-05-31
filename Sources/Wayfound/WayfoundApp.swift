import SwiftUI

@main
struct WayfoundApp: App {
    @State private var store = WayfoundStore()
    @State private var subscriptionService = SubscriptionService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(subscriptionService)
                .task {
                    await subscriptionService.loadProducts()
                    await subscriptionService.refreshEntitlements(store: store)
                }
        }
    }
}
