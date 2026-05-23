import SwiftUI

struct DailyCheckInView: View {
    @Environment(WayfoundStore.self) private var store
    @State private var currentIndex = 0
    @State private var drafts: [UUID: CheckInDraft] = [:]
    @State private var isComplete = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.activeGoals.isEmpty {
                    EmptyState(title: "No active goals", message: "Wake a sleeping goal or create a new one when life gives you room.")
                        .padding(18)
                } else if isComplete {
                    completionView
                } else {
                    checkInFlow
                }
            }
            .background(WayfoundTheme.background)
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: seedDrafts)
        }
    }

    private var checkInFlow: some View {
        let goals = store.activeGoals
        let index = min(currentIndex, max(goals.count - 1, 0))
        let goal = goals[index]
        let isLast = index == goals.count - 1

        return VStack(spacing: 18) {
            progressDots(count: goals.count, current: index)

            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 6) {
                        Text(goal.emoji.isEmpty ? goal.category.emoji : goal.emoji)
                            .font(.system(size: 42))
                        Text(goal.title)
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .multilineTextAlignment(.center)
                        Text("\(goal.category.label) · \(goal.frequency.label)")
                            .font(.caption)
                            .foregroundStyle(WayfoundTheme.secondaryInk)
                    }

                    tierPicker(goal: goal)
                    moodPicker(goal: goal)

                    TextField("Any thoughts? (optional)", text: noteBinding(for: goal), axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                        .textFieldStyle(.roundedBorder)
                        .padding(.top, 2)
                }
                .padding(18)
            }

            HStack(spacing: 12) {
                if index > 0 {
                    Button("Back") {
                        currentIndex -= 1
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button {
                    if isLast {
                        store.saveCheckIns(drafts)
                        isComplete = true
                    } else {
                        currentIndex += 1
                    }
                } label: {
                    Label(isLast ? "Done" : "Next", systemImage: isLast ? "checkmark" : "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(WayfoundTheme.deepSage)
            }
            .padding(18)
        }
    }

    private var completionView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 62, weight: .semibold))
                .foregroundStyle(WayfoundTheme.deepSage)
            Text("You showed up today.")
                .font(.system(size: 24, weight: .bold, design: .serif))
            Text("That's what matters most. Whatever you logged, it counts.")
                .font(.subheadline)
                .foregroundStyle(WayfoundTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            Button("Check in again") {
                isComplete = false
                currentIndex = 0
                seedDrafts()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(WayfoundTheme.deepSage)
            Spacer()
        }
        .padding(18)
    }

    private func progressDots(count: Int, current: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? WayfoundTheme.deepSage.opacity(index == current ? 1 : 0.45) : WayfoundTheme.line)
                    .frame(width: index == current ? 28 : 8, height: 7)
            }
        }
        .padding(.top, 14)
    }

    private func tierPicker(goal: Goal) -> some View {
        VStack(spacing: 10) {
            Text("How did it go today?")
                .font(.caption)
                .foregroundStyle(WayfoundTheme.secondaryInk)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(AchievementTier.allCases) { tier in
                    let selected = draft(for: goal).tier == tier
                    Button {
                        var draft = draft(for: goal)
                        draft.tier = tier
                        drafts[goal.id] = draft
                    } label: {
                        VStack(spacing: 4) {
                            Text(tier.emoji)
                                .font(.title2)
                            Text(tier.label)
                                .font(.caption.weight(.bold))
                                .multilineTextAlignment(.center)
                            Text(tier.shortLabel)
                                .font(.caption2)
                                .foregroundStyle(WayfoundTheme.secondaryInk)
                        }
                        .frame(maxWidth: .infinity, minHeight: 92)
                        .background(selected ? tier.color.opacity(0.22) : WayfoundTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? tier.color : WayfoundTheme.line, lineWidth: selected ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func moodPicker(goal: Goal) -> some View {
        VStack(spacing: 10) {
            Text("How did it feel?")
                .font(.caption)
                .foregroundStyle(WayfoundTheme.secondaryInk)

            HStack(spacing: 8) {
                ForEach(CheckInMood.allCases) { mood in
                    let selected = draft(for: goal).mood == mood
                    Button {
                        var draft = draft(for: goal)
                        draft.mood = mood
                        drafts[goal.id] = draft
                    } label: {
                        VStack(spacing: 3) {
                            Text(mood.emoji)
                                .font(.title3)
                            Text(mood.label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(WayfoundTheme.secondaryInk)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selected ? WayfoundTheme.deepSage.opacity(0.12) : WayfoundTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? WayfoundTheme.deepSage : WayfoundTheme.line))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func draft(for goal: Goal) -> CheckInDraft {
        drafts[goal.id] ?? CheckInDraft()
    }

    private func noteBinding(for goal: Goal) -> Binding<String> {
        Binding(
            get: { draft(for: goal).note },
            set: { newValue in
                var draft = draft(for: goal)
                draft.note = newValue
                drafts[goal.id] = draft
            }
        )
    }

    private func seedDrafts() {
        var seeded: [UUID: CheckInDraft] = [:]
        for goal in store.activeGoals {
            if let checkIn = store.checkIn(for: goal) {
                seeded[goal.id] = CheckInDraft(tier: checkIn.tier, mood: checkIn.mood, note: checkIn.note)
            } else {
                seeded[goal.id] = CheckInDraft()
            }
        }
        drafts = seeded
        currentIndex = min(currentIndex, max(store.activeGoals.count - 1, 0))
    }
}

struct EmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "moon.stars.fill")
                .font(.largeTitle)
                .foregroundStyle(WayfoundTheme.teal)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(WayfoundTheme.secondaryInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .premiumPanel()
    }
}
