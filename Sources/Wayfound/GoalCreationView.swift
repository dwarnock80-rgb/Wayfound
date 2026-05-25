import SwiftUI

struct GoalCreationView: View {
    @Environment(WayfoundStore.self) private var store
    @State private var showingEditor = false
    @State private var editingGoal: Goal?
    @State private var deleteCandidate: Goal?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if store.visibleGoals.isEmpty {
                        EmptyState(title: "No goals yet", message: "Start with something small.")
                    } else {
                        goalSection("Active", goals: store.activeGoals)
                        goalSection("Sleeping", goals: store.sleepingGoals)
                        goalSection("Archived", goals: store.archivedGoals)
                    }
                }
                .padding(18)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addGoal()
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                    .disabled(!store.canCreateGoal)
                }
            }
            .sheet(isPresented: $showingEditor) {
                GoalEditorView(goal: editingGoal)
            }
            .confirmationDialog("Delete this goal and its check-ins?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                if let deleteCandidate {
                    Button("Delete permanently", role: .destructive) {
                        store.deleteGoal(deleteCandidate)
                        self.deleteCandidate = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    deleteCandidate = nil
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goals")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                    if !store.state.isPremium {
                        Text(store.canCreateGoal ? "Free plan includes up to \(store.freeGoalLimit) active goals." : "Free plan limit reached.")
                            .font(.footnote)
                            .foregroundStyle(WayfoundTheme.secondaryInk)
                    }
                }

                Spacer()

                Button {
                    addGoal()
                } label: {
                    Label("Add Goal", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!store.canCreateGoal)
            }
        }
    }

    private func addGoal() {
        editingGoal = nil
        showingEditor = true
    }

    private func goalSection(_ title: String, goals: [Goal]) -> some View {
        Group {
            if !goals.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WayfoundTheme.secondaryInk)

                    ForEach(goals) { goal in
                        GoalRow(goal: goal) {
                            editingGoal = goal
                            showingEditor = true
                        } onSleepToggle: {
                            store.setSleeping(goal, isSleeping: !goal.isSleeping)
                        } onArchive: {
                            store.archiveGoal(goal)
                        } onRestore: {
                            store.restoreGoal(goal)
                        } onDelete: {
                            deleteCandidate = goal
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
        }
    }
}

private struct GoalRow: View {
    let goal: Goal
    let onEdit: () -> Void
    let onSleepToggle: () -> Void
    let onArchive: () -> Void
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onEdit) {
                rowContent
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                if goal.isActive {
                    Button {
                        onSleepToggle()
                    } label: {
                        Label(goal.isSleeping ? "Wake" : "Sleep", systemImage: goal.isSleeping ? "sun.max" : "moon")
                    }

                    Button {
                        onArchive()
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                } else {
                    Button {
                        onRestore()
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                    }
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Goal actions")
            .buttonStyle(.plain)
        }
        .padding(.trailing, 10)
        .background(goal.category.tint.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(goal.category.tint.opacity(0.25)))
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            Text(goal.emoji.isEmpty ? goal.category.emoji : goal.emoji)
                .font(.title3)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(goal.isSleeping)
                Text("\(goal.category.label) · \(goal.frequency.label)")
                    .font(.caption2)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }
            Spacer()
            Text("Weight: \(goal.weight)")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(WayfoundTheme.background, in: Capsule())
            if goal.isSleeping {
                Image(systemName: "moon.fill")
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }
        }
        .padding(14)
    }
}

private struct GoalEditorView: View {
    private let emojis = ["💪", "🏃", "🧘", "📚", "💰", "🍎", "🎯", "🧠", "❤️", "🌱", "✍️", "🎨", "🏡", "🧑‍🍳", "💊", "🚶", "😴", "🧹"]

    @Environment(\.dismiss) private var dismiss
    @Environment(WayfoundStore.self) private var store
    let goal: Goal?
    @State private var title: String
    @State private var category: WayfoundCategory
    @State private var weight: Int
    @State private var frequency: GoalFrequency
    @State private var emoji: String
    @State private var isSleeping: Bool
    @State private var isActive: Bool
    @State private var showDeleteConfirmation = false

    init(goal: Goal?) {
        self.goal = goal
        _title = State(initialValue: goal?.title ?? "")
        _category = State(initialValue: goal?.category ?? .health)
        _weight = State(initialValue: goal?.weight ?? 1)
        _frequency = State(initialValue: goal?.frequency ?? .daily)
        _emoji = State(initialValue: goal?.emoji ?? "💪")
        _isSleeping = State(initialValue: goal?.isSleeping ?? false)
        _isActive = State(initialValue: goal?.isActive ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(emojis, id: \.self) { option in
                            Button {
                                emoji = option
                            } label: {
                                Text(option)
                                    .font(.title2)
                                    .frame(width: 42, height: 42)
                                    .background(emoji == option ? WayfoundTheme.deepSage.opacity(0.16) : WayfoundTheme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(emoji == option ? WayfoundTheme.deepSage : WayfoundTheme.line))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section {
                    TextField("Goal name", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(WayfoundCategory.allCases) { category in
                            Text("\(category.emoji) \(category.label)").tag(category)
                        }
                    }
                    Picker("Frequency", selection: $frequency) {
                        ForEach(GoalFrequency.allCases) { frequency in
                            Text(frequency.label).tag(frequency)
                        }
                    }
                    Stepper("Importance Weight: \(weight) / 5", value: $weight, in: 1...5)
                }

                Section("Momentum weighting") {
                    Text("Each check-in contributes to your momentum score. A weight 5 goal has more impact than a weight 1 goal, so use higher weights for the goals that define your week.")
                        .font(.footnote)
                        .foregroundStyle(WayfoundTheme.secondaryInk)
                }

                if goal != nil {
                    Section {
                        Toggle("Sleep Mode", isOn: $isSleeping)
                        Toggle("Active", isOn: $isActive)
                    }

                    Section {
                        Button("Delete Goal", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog("Delete this goal and its check-ins?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete permanently", role: .destructive) {
                    if let goal {
                        store.deleteGoal(goal)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() {
        if let goal {
            store.updateGoal(goal, title: title, category: category, weight: weight, frequency: frequency, emoji: emoji, isActive: isActive, isSleeping: isSleeping)
        } else {
            store.addGoal(title: title, category: category, weight: weight, frequency: frequency, emoji: emoji)
        }
        dismiss()
    }
}
