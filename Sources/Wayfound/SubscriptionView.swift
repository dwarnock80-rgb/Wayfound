import SwiftUI

struct TodosView: View {
    @Environment(WayfoundStore.self) private var store
    @State private var newTitle = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("YOUR TASKS")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WayfoundTheme.secondaryInk)
                        Text("To-Do List")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                    }

                    HStack(spacing: 10) {
                        TextField("What needs doing?", text: $newTitle)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                            .onSubmit(addTodo)

                        Button(action: addTodo) {
                            Image(systemName: "plus")
                                .font(.headline)
                                .frame(width: 42, height: 42)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(WayfoundTheme.deepSage)
                        .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    VStack(spacing: 10) {
                        if store.pendingTodos.isEmpty && store.completedTodos.isEmpty {
                            EmptyState(title: "A blank slate", message: "Add your first task above.")
                        }

                        ForEach(store.pendingTodos) { todo in
                            TodoRow(todo: todo)
                        }
                    }

                    if !store.completedTodos.isEmpty {
                        VStack(spacing: 10) {
                            Text("COMPLETED · \(store.completedTodos.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(WayfoundTheme.secondaryInk)
                                .frame(maxWidth: .infinity)

                            ForEach(store.completedTodos) { todo in
                                TodoRow(todo: todo)
                            }
                        }
                    }
                }
                .padding(18)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func addTodo() {
        store.addTodo(title: newTitle)
        newTitle = ""
    }
}

private struct TodoRow: View {
    @Environment(WayfoundStore.self) private var store
    let todo: Todo

    var body: some View {
        HStack(spacing: 12) {
            Button {
                store.toggleTodo(todo)
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(todo.isCompleted ? WayfoundTheme.deepSage : WayfoundTheme.secondaryInk.opacity(0.55))
            }
            .buttonStyle(.plain)

            Text(todo.title)
                .font(.subheadline.weight(.medium))
                .strikethrough(todo.isCompleted)
                .foregroundStyle(todo.isCompleted ? WayfoundTheme.secondaryInk.opacity(0.7) : WayfoundTheme.ink)

            Spacer()

            Button(role: .destructive) {
                store.deleteTodo(todo)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(WayfoundTheme.secondaryInk.opacity(0.55))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(todo.isCompleted ? WayfoundTheme.background : WayfoundTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(WayfoundTheme.line))
    }
}

struct SettingsView: View {
    @Environment(WayfoundStore.self) private var store
    @State private var reminderMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Settings")
                        .font(.system(size: 26, weight: .bold, design: .serif))

                    sleepModeCard
                    reminderCard
                    ownerPremiumCard
                    aboutCard
                }
                .padding(18)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var sleepModeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sleep Mode", systemImage: "moon.fill")
                .font(.headline)
                .foregroundStyle(WayfoundTheme.deepSage)
            Text("Going on holiday? Having a rough week? Put goals to sleep. Your momentum will not be affected.")
                .font(.subheadline)
                .foregroundStyle(WayfoundTheme.secondaryInk)

            HStack {
                Button("Sleep All (\(store.activeGoals.count))") {
                    store.setAllSleeping(true)
                }
                .buttonStyle(.bordered)
                .disabled(store.activeGoals.isEmpty)

                Button("Wake All (\(store.sleepingGoals.count))") {
                    store.setAllSleeping(false)
                }
                .buttonStyle(.borderedProminent)
                .tint(WayfoundTheme.deepSage)
                .disabled(store.sleepingGoals.isEmpty)
            }
        }
        .premiumPanel()
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Daily gentle reminder", isOn: enabledBinding)
                .font(.headline)

            if store.state.dailyReminder.isEnabled {
                DatePicker("Time", selection: reminderDateBinding, displayedComponents: .hourAndMinute)
            }

            if let reminderMessage {
                Text(reminderMessage)
                    .font(.caption)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }
        }
        .premiumPanel()
    }

    private var ownerPremiumCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Premium Access", systemImage: "star.circle.fill")
                .font(.headline)
                .foregroundStyle(WayfoundTheme.deepSage)

            if store.state.isPremium {
                Label("Premium is active on this device", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WayfoundTheme.deepSage)
            } else {
                Text("Use owner access to enable premium features on this device without a purchase.")
                    .font(.subheadline)
                    .foregroundStyle(WayfoundTheme.secondaryInk)

                Button("Unlock Premium") {
                    store.setPremium(true)
                }
                .buttonStyle(.borderedProminent)
                .tint(WayfoundTheme.deepSage)
            }
        }
        .premiumPanel()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("About Wayfound", systemImage: "heart.fill")
                .font(.headline)
                .foregroundStyle(WayfoundTheme.rose)
            Text("Making progress in the middle of chaos. Small progress still counts. Bad days are normal. Wayfound supports sustainable momentum rather than perfection.")
                .font(.subheadline)
                .foregroundStyle(WayfoundTheme.secondaryInk)
            Label("Version 1.0", systemImage: "sparkles")
                .font(.caption)
                .foregroundStyle(WayfoundTheme.secondaryInk)
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
                Calendar.current.date(bySettingHour: store.state.dailyReminder.hour, minute: store.state.dailyReminder.minute, second: 0, of: .now) ?? .now
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
                reminderMessage = preference.isEnabled ? "Reminder scheduled locally on this device." : "Reminder turned off."
            } else {
                var disabled = preference
                disabled.isEnabled = false
                store.updateReminder(disabled)
                reminderMessage = "Notifications were not allowed. You can enable them in Settings."
            }
        }
    }
}
