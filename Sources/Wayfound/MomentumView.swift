import SwiftUI

struct MomentumView: View {
    @Environment(WayfoundStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Momentum")
                        .font(.system(size: 26, weight: .bold, design: .serif))

                    if store.needsRecovery {
                        RecoveryBanner()
                    }

                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(WayfoundTheme.line, lineWidth: 14)
                            Circle()
                                .trim(from: 0, to: Double(store.momentumScore) / 100)
                                .stroke(WayfoundTheme.deepSage, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            VStack(spacing: 4) {
                                Text("\(store.momentumScore)")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                Text(store.momentumLevel.label)
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .frame(width: 180, height: 180)

                        Text(store.momentumLevel.message)
                            .font(.subheadline)
                            .foregroundStyle(WayfoundTheme.secondaryInk)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    heatmap
                    goalBreakdown
                }
                .padding(18)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var heatmap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LAST 7 DAYS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WayfoundTheme.secondaryInk)

            HStack(alignment: .top, spacing: 6) {
                ForEach(store.lastSevenDays(), id: \.self) { day in
                    VStack(spacing: 5) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(WayfoundTheme.secondaryInk)

                        VStack(spacing: 3) {
                            ForEach(store.activeGoals) { goal in
                                let tier = store.checkIn(for: goal, on: day)?.tier ?? .none
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(tier.color)
                                    .frame(height: 13)
                                    .accessibilityLabel("\(goal.title), \(tier.label)")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 12) {
                ForEach(AchievementTier.allCases) { tier in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(tier.color)
                            .frame(width: 10, height: 10)
                        Text(tier.shortLabel)
                            .font(.system(size: 10))
                            .foregroundStyle(WayfoundTheme.secondaryInk)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .premiumPanel()
    }

    private var goalBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GOAL BREAKDOWN")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WayfoundTheme.secondaryInk)

            if store.activeGoals.isEmpty {
                Text("No active goals yet.")
                    .font(.subheadline)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            } else {
                ForEach(store.activeGoals) { goal in
                    GoalMomentumRow(goal: goal)
                }
            }
        }
    }
}

private struct GoalMomentumRow: View {
    @Environment(WayfoundStore.self) private var store
    let goal: Goal

    var body: some View {
        let days = store.checkInsForLastSevenDays(goal: goal)
        let daysHit = days.filter { ($0.checkIn?.tier ?? .none) != .none }.count

        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(goal.emoji.isEmpty ? goal.category.emoji : goal.emoji)
                Text(goal.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(daysHit)/7")
                    .font(.caption)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }

            HStack(spacing: 3) {
                ForEach(days, id: \.date) { item in
                    RoundedRectangle(cornerRadius: 4)
                        .fill((item.checkIn?.tier ?? .none).color)
                        .frame(height: 8)
                }
            }
        }
        .padding(12)
        .background(goal.category.tint.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(goal.category.tint.opacity(0.25)))
    }
}

private struct RecoveryBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.title2)
                .foregroundStyle(WayfoundTheme.rose)
            VStack(alignment: .leading, spacing: 4) {
                Text("Recovery Mode")
                    .font(.headline)
                Text("A lighter day still counts. Choose the smallest version that keeps you connected.")
                    .font(.subheadline)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }
        }
        .premiumPanel()
    }
}
