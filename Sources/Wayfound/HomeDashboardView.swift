import SwiftUI

struct HomeDashboardView: View {
    @Environment(WayfoundStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    CategoryRow()
                    todayFocus
                    TodoWidget()
                    SleepModeNudge()
                }
                .padding(18)
            }
            .background(WayfoundTheme.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.callout)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
                Text("Wayfound")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .allowsTightening(true)
                Text("Small steps. Real progress.")
                    .font(.subheadline)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            NavigationLink {
                MomentumView()
            } label: {
                MomentumRing(score: store.momentumScore, level: store.momentumLevel)
            }
            .buttonStyle(.plain)
        }
    }

    private var todayFocus: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's focus")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    GoalCreationView()
                } label: {
                    Label(store.activeGoals.isEmpty ? "Add" : "Manage", systemImage: store.activeGoals.isEmpty ? "plus.circle.fill" : "slider.horizontal.3")
                        .labelStyle(.titleAndIcon)
                }
                .font(.caption.weight(.semibold))
                if !store.activeGoals.isEmpty {
                    NavigationLink("Check in all") {
                        DailyCheckInView()
                    }
                    .font(.caption.weight(.semibold))
                }
            }

            if store.activeGoals.isEmpty {
                EmptyState(title: "Add your first goal", message: "Start with something small enough to do on a noisy day.")
            } else {
                ForEach(store.activeGoals) { goal in
                    TodayGoalRow(goal: goal)
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "Good morning," }
        if hour < 17 { return "Good afternoon," }
        return "Good evening,"
    }
}

private struct MomentumRing: View {
    let score: Int
    let level: MomentumLevel

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .stroke(WayfoundTheme.line, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: Double(score) / 100)
                    .stroke(WayfoundTheme.deepSage, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(score)")
                    .font(.headline.weight(.bold))
            }
            .frame(width: 70, height: 70)

            Text(level.label)
                .font(.caption.weight(.semibold))
            Text("View momentum")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WayfoundTheme.deepSage)
        }
        .frame(width: 112)
        .padding(12)
        .premiumPanel()
    }
}

private struct CategoryRow: View {
    @Environment(WayfoundStore.self) private var store

    var body: some View {
        HStack(spacing: 7) {
            ForEach(WayfoundCategory.allCases) { category in
                let goals = store.activeGoals.filter { $0.category == category }
                let hasActivity = goals.contains { store.checkIn(for: $0) != nil }

                VStack(spacing: 4) {
                    Text(category.emoji)
                        .font(.title3)
                    Text(category.label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(WayfoundTheme.secondaryInk)

                    HStack(spacing: 2) {
                        ForEach(goals.prefix(4)) { goal in
                            Circle()
                                .fill(store.checkIn(for: goal) == nil ? WayfoundTheme.line : WayfoundTheme.deepSage)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(height: 6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(hasActivity ? category.tint.opacity(0.12) : WayfoundTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(hasActivity ? category.tint.opacity(0.35) : WayfoundTheme.line))
            }
        }
    }
}

private struct TodayGoalRow: View {
    @Environment(WayfoundStore.self) private var store
    let goal: Goal

    var body: some View {
        let checkIn = store.checkIn(for: goal)
        let checked = (checkIn?.tier ?? .none) != .none

        NavigationLink {
            DailyCheckInView()
        } label: {
            HStack(spacing: 12) {
                Text(goal.emoji.isEmpty ? goal.category.emoji : goal.emoji)
                    .font(.title2)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title)
                        .font(.subheadline.weight(.semibold))
                        .strikethrough(checked)
                        .foregroundStyle(checked ? WayfoundTheme.secondaryInk : WayfoundTheme.ink)
                    Text("\(goal.category.label) · \(goal.frequency.label)")
                        .font(.caption2)
                        .foregroundStyle(WayfoundTheme.secondaryInk)
                }

                Spacer()

                Text(checked ? "Done" : "Check in")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(checked ? WayfoundTheme.deepSage : WayfoundTheme.background, in: Capsule())
                    .foregroundStyle(checked ? .white : WayfoundTheme.ink)
                    .overlay(Capsule().stroke(checked ? WayfoundTheme.deepSage : WayfoundTheme.line))
            }
            .padding(14)
            .background(checked ? WayfoundTheme.deepSage.opacity(0.08) : WayfoundTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(checked ? WayfoundTheme.deepSage.opacity(0.25) : WayfoundTheme.line))
        }
        .buttonStyle(.plain)
    }
}

private struct TodoWidget: View {
    @Environment(WayfoundStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("To-do list")
                    .font(.headline)
                Spacer()
                NavigationLink("Open") {
                    TodosView()
                }
                .font(.caption.weight(.semibold))
            }

            if store.pendingTodos.isEmpty {
                Text("A blank slate.")
                    .font(.subheadline)
                    .foregroundStyle(WayfoundTheme.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(store.pendingTodos.prefix(3)) { todo in
                    Button {
                        store.toggleTodo(todo)
                    } label: {
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(WayfoundTheme.secondaryInk)
                            Text(todo.title)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .premiumPanel()
    }
}

private struct SleepModeNudge: View {
    @Environment(WayfoundStore.self) private var store

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "moon.fill")
                .font(.title)
                .foregroundStyle(.white.opacity(0.85))
            VStack(alignment: .leading, spacing: 3) {
                Text("Need a reset?")
                    .font(.subheadline.weight(.bold))
                Text("Pause goals and protect your momentum.")
                    .font(.caption)
                    .opacity(0.75)
            }
            Spacer()
            Button("Sleep All") {
                store.setAllSleeping(true)
            }
            .font(.caption.weight(.bold))
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .padding(16)
        .background(WayfoundTheme.ink)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
