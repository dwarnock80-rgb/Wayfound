import SwiftUI

struct GoalCreationView: View {
    @Environment(WayfoundStore.self) private var store
    @State private var title = ""
    @State private var category: WayfoundCategory = .health
    @State private var weight = 2
    @State private var weeklyTarget = 3

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create a gentle target")
                            .font(.title2.weight(.semibold))
                        Text("Weight reflects emotional or practical importance. Targets stay weekly so bad days do not break the system.")
                            .font(.subheadline)
                            .foregroundStyle(WayfoundTheme.secondaryInk)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        TextField("Goal title", text: $title)
                            .textFieldStyle(.roundedBorder)

                        Picker("Category", selection: $category) {
                            ForEach(WayfoundCategory.allCases) { category in
                                Label(category.rawValue, systemImage: category.symbol)
                                    .tag(category)
                            }
                        }

                        Stepper("Weight: \(weight)", value: $weight, in: 1...5)
                        Stepper("Weekly target: \(weeklyTarget)", value: $weeklyTarget, in: 1...14)

                        Button {
                            store.addGoal(title: title, category: category, weight: weight, weeklyTarget: weeklyTarget)
                            title = ""
                            category = .health
                            weight = 2
                            weeklyTarget = 3
                        } label: {
                            Label(store.canCreateGoal ? "Add goal" : "Premium unlock required", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(!store.canCreateGoal)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(WayfoundTheme.deepSage)
                    }
                    .premiumPanel()

                    if !store.state.isPremium {
                        Text("Free plan includes up to \(store.freeGoalLimit) active goals.")
                            .font(.footnote)
                            .foregroundStyle(WayfoundTheme.secondaryInk)
                    }

                    ForEach(store.state.goals) { goal in
                        GoalManagementRow(goal: goal)
                    }
                }
                .padding(18)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("Goals")
        }
    }
}

private struct GoalManagementRow: View {
    @Environment(WayfoundStore.self) private var store
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(goal.title, systemImage: goal.category.symbol)
                    .font(.headline)
                    .foregroundStyle(goal.category.tint)
                Spacer()
            }

            Picker("Mode", selection: modeBinding) {
                Text("Active").tag(GoalMode.active)
                Text("Recovery").tag(GoalMode.recovery)
                Text("Sleep").tag(GoalMode.sleeping)
            }
            .pickerStyle(.segmented)
        }
        .premiumPanel()
    }

    private var modeBinding: Binding<GoalMode> {
        Binding(
            get: { goal.mode },
            set: { store.updateMode(for: goal, mode: $0) }
        )
    }
}
