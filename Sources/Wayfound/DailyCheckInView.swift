import SwiftUI

struct DailyCheckInView: View {
    @Environment(WayfoundStore.self) private var store
    @State private var selectedGoalID: Goal.ID?
    @State private var amount = 1
    @State private var note = ""
    @State private var reminderMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("What moved today?")
                        .font(.title2.weight(.semibold))

                    ReminderSettingsCard(message: $reminderMessage)

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

private struct ReminderSettingsCard: View {
    @Environment(WayfoundStore.self) private var store
    @Binding var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Daily gentle reminder", isOn: enabledBinding)
                .font(.headline)

            if store.state.dailyReminder.isEnabled {
                DatePicker(
                    "Time",
                    selection: reminderDateBinding,
                    displayedComponents: .hourAndMinute
                )
            }

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }
        }
        .premiumPanel()
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { store.state.dailyReminder.isEnabled },
            set: { isEnabled in
                var preference = store.state.dailyReminder
                preference.isEnabled = isEnabled
                apply(preference)
            }
        )
    }

    private var reminderDateBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: store.state.dailyReminder.hour,
                    minute: store.state.dailyReminder.minute,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                var preference = store.state.dailyReminder
                preference.hour = components.hour ?? preference.hour
                preference.minute = components.minute ?? preference.minute
                apply(preference)
            }
        )
    }

    private func apply(_ preference: ReminderPreference) {
        Task {
            let scheduled = await NotificationService.applyDailyReminder(preference)
            if scheduled {
                store.updateReminder(preference)
                message = preference.isEnabled ? "Reminder scheduled locally on this device." : "Reminder turned off."
            } else {
                var disabled = preference
                disabled.isEnabled = false
                store.updateReminder(disabled)
                message = "Notifications were not allowed. You can enable them in Settings."
            }
        }
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
