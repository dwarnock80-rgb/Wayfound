import SwiftUI

struct RootView: View {
    @Environment(WayfoundStore.self) private var store

    var body: some View {
        ZStack {
            WayfoundTheme.background.ignoresSafeArea()

            if store.state.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(WayfoundTheme.deepSage)
        .foregroundStyle(WayfoundTheme.ink)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeDashboardView()
                .tabItem { Label("Today", systemImage: "leaf.fill") }

            DailyCheckInView()
                .tabItem { Label("Check In", systemImage: "checkmark.circle.fill") }

            GoalCreationView()
                .tabItem { Label("Goals", systemImage: "target") }

            TodosView()
                .tabItem { Label("To-Dos", systemImage: "checklist") }

            MomentumView()
                .tabItem { Label("Momentum", systemImage: "chart.xyaxis.line") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
