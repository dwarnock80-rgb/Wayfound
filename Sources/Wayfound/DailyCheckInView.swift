import SwiftUI

struct DailyCheckInView: View {
    @Environment(WayfoundStore.self) private var store
    @State private var selectedGoalID: Goal.ID?
    @State private var amount = 1
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("What moved today?")
                        .font(.title2.weight(.semibold))

                    if store.activeGoals.isEmpty {
                        EmptyState(title: "No active goals", message: "Wake a sleeping goal or create a new one when life gives you room.")
                    } else {
                        Picker("Goal", selection: selectionBinding) {
                            ForEach(store.activeGoals) { goal in
                                Text(goal.title).tag(Optional(goal.id))
                            }
                        }
                        .pickerStyle(.inline)
                        .premiumPanel()

                        Stepper("Progress units: \(amount)", value: $amount, in: 1...5)
                            .premiumPanel()

                        TextField("Optional note", text: $note, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .textFieldStyle(.roundedBorder)
                            .premiumPanel()

                        Button {
                            guard let goal = selectedGoal else { return }
                            store.logProgress(for: goal, amount: amount, note: note)
                            amount = 1
                            note = ""
                        } label: {
                            Label("Count this", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(WayfoundTheme.deepSage)
                    }
                }
                .padding(18)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("Daily Check-In")
            .onAppear {
                selectedGoalID = selectedGoalID ?? store.activeGoals.first?.id
            }
        }
    }

    private var selectedGoal: Goal? {
        store.activeGoals.first { $0.id == selectedGoalID }
    }

    private var selectionBinding: Binding<Goal.ID?> {
        Binding(
            get: { selectedGoalID ?? store.activeGoals.first?.id },
            set: { selectedGoalID = $0 }
        )
    }
}

struct EmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
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
