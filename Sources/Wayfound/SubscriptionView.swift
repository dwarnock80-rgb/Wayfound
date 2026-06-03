import StoreKit
import SwiftUI

struct PremiumUnlockSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WayfoundStore.self) private var store
    @Environment(SubscriptionService.self) private var subscriptionService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: store.state.isPremium ? "checkmark.seal.fill" : "star.circle.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(WayfoundTheme.deepSage)
                            .accessibilityHidden(true)

                        Text(store.state.isPremium ? "Premium is unlocked" : "Unlock Premium")
                            .font(.system(size: 28, weight: .bold, design: .serif))

                        Text(store.state.isPremium ? "You already have access to Wayfound Premium on this device." : "Premium is for seasons when three goals is not enough. Unlock unlimited active goals and keep your routines flexible as life changes.")
                            .font(.subheadline)
                            .foregroundStyle(WayfoundTheme.secondaryInk)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        PremiumFeatureRow(symbol: "target", title: "Unlimited active goals", message: "Track everything you are actively rebuilding without archiving a goal to make room.")
                        PremiumFeatureRow(symbol: "plus.circle.fill", title: "Add goals as life changes", message: "Make room for health, family, money, purpose, and personal goals at the same time.")
                        PremiumFeatureRow(symbol: "arrow.uturn.backward.circle.fill", title: "Restore anytime", message: "Already unlocked Premium? Restore your purchase with your Apple ID.")
                    }

                    Text(subscriptionStatusText)
                        .font(.footnote)
                        .foregroundStyle(WayfoundTheme.secondaryInk)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !store.state.isPremium {
                        Button {
                            Task { await subscriptionService.purchasePremium(store: store) }
                        } label: {
                            Text(unlockButtonTitle)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(WayfoundTheme.deepSage)
                        .disabled(subscriptionService.products.isEmpty || subscriptionService.isProcessing)

                        Button {
                            Task { await subscriptionService.restore(store: store) }
                        } label: {
                            Text("Restore Purchase")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(subscriptionService.isProcessing)
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(WayfoundTheme.deepSage)
                    }
                }
                .padding(20)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var unlockButtonTitle: String {
        if subscriptionService.isProcessing {
            "Processing..."
        } else if let product = subscriptionService.products.first {
            "Unlock Premium \(product.displayPrice)"
        } else {
            "Unlock Premium"
        }
    }

    private var subscriptionStatusText: String {
        store.state.isPremium ? "Premium is active." : subscriptionService.statusMessage
    }
}

private struct PremiumFeatureRow: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(WayfoundTheme.deepSage)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }
        }
        .padding(14)
        .background(WayfoundTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(WayfoundTheme.line))
    }
}

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
    @State private var showingPremiumUnlock = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("More")
                        .font(.system(size: 26, weight: .bold, design: .serif))

                    unlockPremiumButton
                    sleepModeCard
                    reminderCard
                    aboutCard
                }
                .padding(18)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPremiumUnlock) {
                PremiumUnlockSheet()
            }
        }
    }

    private var unlockPremiumButton: some View {
        Button {
            showingPremiumUnlock = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: store.state.isPremium ? "checkmark.seal.fill" : "star.circle.fill")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.state.isPremium ? "Premium unlocked" : "Unlock Premium")
                        .font(.headline)
                    Text(store.state.isPremium ? "Premium is active on this device." : "Unlimited active goals and the full Wayfound toolkit.")
                        .font(.subheadline)
                        .foregroundStyle(WayfoundTheme.secondaryInk)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }
            .foregroundStyle(WayfoundTheme.ink)
            .padding(16)
            .background(WayfoundTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(WayfoundTheme.line))
        }
        .buttonStyle(.plain)
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
