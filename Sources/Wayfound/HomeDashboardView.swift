import SwiftUI

struct HomeDashboardView: View {
    @Environment(WayfoundStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    MomentumHeader(score: store.momentumScore)

                    if store.needsRecovery {
                        RecoveryCallout()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Goals")
                            .font(.title3.weight(.semibold))

                        ForEach(store.visibleGoals) { goal in
                            GoalCard(goal: goal)
                        }
                    }
                }
                .padding(18)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("Today")
        }
    }
}

struct MomentumHeader: View {
    let score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Momentum Score")
                        .font(.headline)
                        .foregroundStyle(WayfoundTheme.secondaryInk)
                    Text("\(score)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                }
                Spacer()
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(WayfoundTheme.sage)
            }

            ProgressView(value: Double(score), total: 100)
                .tint(WayfoundTheme.deepSage)

            Text(score < 35 ? "A lighter day still counts." : "You are building evidence, not pressure.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(WayfoundTheme.secondaryInk)
        }
        .premiumPanel()
    }
}

struct RecoveryCallout: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.title2)
                .foregroundStyle(WayfoundTheme.rose)
            VStack(alignment: .leading, spacing: 4) {
                Text("Recovery Mode suggested")
                    .font(.headline)
                Text("Choose one smaller version of a goal today. Momentum returns through kindness and repetition.")
                    .font(.subheadline)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }
        }
        .premiumPanel()
    }
}

struct GoalCard: View {
    @Environment(WayfoundStore.self) private var store
    let goal: Goal

    var body: some View {
        let progress = store.weeklyProgress(for: goal).clamped(to: 0...1)
        let threshold = store.threshold(for: goal)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: goal.category.symbol)
                    .foregroundStyle(goal.category.tint)
                    .frame(width: 32, height: 32)
                    .background(goal.category.tint.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.headline)
                    Text("\(goal.category.rawValue) · weight \(goal.weight)")
                        .font(.caption)
                        .foregroundStyle(WayfoundTheme.secondaryInk)
                }

                Spacer()

                ModeBadge(mode: goal.mode)
            }

            ProgressView(value: progress)
                .tint(goal.category.tint)

            HStack {
                Text(threshold?.rawValue ?? "Not started")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(threshold == nil ? WayfoundTheme.secondaryInk : goal.category.tint)
                Spacer()
                Text("\(Int((progress * 100).rounded()))% this week")
                    .font(.caption)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }
        }
        .premiumPanel()
    }
}

private struct ModeBadge: View {
    let mode: GoalMode

    var body: some View {
        Text(label)
            .font(.caption2.weight(.bold))
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        switch mode {
        case .active: "Active"
        case .recovery: "Recovery"
        case .sleeping: "Sleep"
        }
    }

    private var color: Color {
        switch mode {
        case .active: WayfoundTheme.deepSage
        case .recovery: WayfoundTheme.rose
        case .sleeping: WayfoundTheme.secondaryInk
        }
    }
}
