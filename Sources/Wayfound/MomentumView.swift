import SwiftUI

struct MomentumView: View {
    @Environment(WayfoundStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    MomentumHeader(score: store.momentumScore)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Review")
                            .font(.title2.weight(.semibold))

                        ForEach(store.visibleGoals) { goal in
                            WeeklyGoalReview(goal: goal)
                        }
                    }
                }
                .padding(18)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("Momentum")
        }
    }
}

private struct WeeklyGoalReview: View {
    @Environment(WayfoundStore.self) private var store
    let goal: Goal

    var body: some View {
        let progress = store.weeklyProgress(for: goal)
        let checkIns = store.checkInsThisWeek(for: goal)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title)
                        .font(.headline)
                    Text("\(checkIns.reduce(0) { $0 + $1.amount }) of \(goal.weeklyTarget) units")
                        .font(.caption)
                        .foregroundStyle(WayfoundTheme.secondaryInk)
                }
                Spacer()
                ThresholdStack(progress: progress)
            }

            ProgressView(value: progress.clamped(to: 0...1))
                .tint(goal.category.tint)

            Text(reviewLine(progress: progress))
                .font(.subheadline)
                .foregroundStyle(WayfoundTheme.secondaryInk)

            if progress < GoalThreshold.bronze.requiredFraction {
                Text(store.recoverySuggestion(for: goal))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WayfoundTheme.rose)
            }
        }
        .premiumPanel()
    }

    private func reviewLine(progress: Double) -> String {
        if progress >= GoalThreshold.gold.requiredFraction {
            "Gold reached. Notice what made this easier."
        } else if progress >= GoalThreshold.silver.requiredFraction {
            "Silver reached. This is real momentum."
        } else if progress >= GoalThreshold.bronze.requiredFraction {
            "Bronze reached. The week has a foothold."
        } else {
            "A tiny version may be the right version this week."
        }
    }
}

private struct ThresholdStack: View {
    let progress: Double

    var body: some View {
        HStack(spacing: 6) {
            ForEach(GoalThreshold.allCases) { threshold in
                Image(systemName: threshold.symbol)
                    .foregroundStyle(progress >= threshold.requiredFraction ? WayfoundTheme.warm : WayfoundTheme.line)
            }
        }
    }
}
