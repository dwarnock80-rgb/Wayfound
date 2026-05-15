import SwiftUI

@main
struct WayfoundApp: App {
    @State private var store = WayfoundStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
