import SwiftUI

struct OnboardingView: View {
    @Environment(WayfoundStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Wayfound")
                        .font(.system(size: 44, weight: .semibold, design: .rounded))
                    Text("Making progress in the middle of chaos")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(WayfoundTheme.secondaryInk)
                }
                .padding(.top, 28)

                VStack(alignment: .leading, spacing: 14) {
                    PhilosophyRow(symbol: "smallcircle.filled.circle", title: "Small progress counts", body: "Partially met, achieved, and exceeded check-ins reward movement instead of perfection.")
                    PhilosophyRow(symbol: "moon.zzz.fill", title: "Life can pause", body: "Sleep Mode protects holidays, illness, and heavy seasons from becoming failure.")
                    PhilosophyRow(symbol: "heart.text.square.fill", title: "Recovery is built in", body: "When consistency dips, Wayfound softens the next step instead of adding guilt.")
                }
                .premiumPanel()

                Button {
                    store.completeOnboarding()
                } label: {
                    Label("Begin gently", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(WayfoundTheme.deepSage)
            }
            .padding(22)
        }
        .background(WayfoundTheme.background)
    }
}

private struct PhilosophyRow: View {
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
                Text(title).font(.headline)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }
        }
    }
}
