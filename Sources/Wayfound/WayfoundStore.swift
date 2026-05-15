import Foundation
import Observation

@Observable
@MainActor
final class WayfoundStore {
    private let calendar = Calendar.current
    private let persistence: WayfoundPersistence
    private(set) var state: AppState

    init(state initialState: AppState? = nil, persistence: WayfoundPersistence = FileWayfoundPersistence()) {
        self.persistence = persistence

        if let initialState {
            state = initialState
        } else if let loaded = persistence.load() {
            state = loaded
        } else {
            state = .sample
        }
    }

    var activeGoals: [Goal] {
        state.goals.filter { $0.mode != .sleeping && $0.archivedAt == nil }
    }

    var visibleGoals: [Goal] {
        state.goals.filter { $0.archivedAt == nil }
    }

    var freeGoalLimit: Int { 3 }

    var canCreateGoal: Bool {
        state.isPremium || visibleGoals.count < freeGoalLimit
    }

    var momentumScore: Int {
        let goals = activeGoals
        guard !goals.isEmpty else { return 0 }

        let weightedTotal = goals.reduce(0.0) { total, goal in
            total + weeklyProgress(for: goal).clamped(to: 0...1) * Double(goal.weight)
        }
        let possible = goals.reduce(0.0) { $0 + Double($1.weight) }
        return Int((weightedTotal / possible * 100).rounded())
    }

    var needsRecovery: Bool {
        momentumScore < 35 && !activeGoals.isEmpty
    }

    func completeOnboarding() {
        state.hasCompletedOnboarding = true
        save()
    }

    func addGoal(title: String, category: WayfoundCategory, weight: Int, weeklyTarget: Int) {
        guard canCreateGoal else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        state.goals.append(
            Goal(
                title: cleanTitle,
                category: category,
                weight: weight.clamped(to: 1...5),
                weeklyTarget: weeklyTarget.clamped(to: 1...14)
            )
        )
        save()
    }

    func updateGoal(_ goal: Goal, title: String, category: WayfoundCategory, weight: Int, weeklyTarget: Int) {
        guard let index = state.goals.firstIndex(where: { $0.id == goal.id }) else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        state.goals[index].title = cleanTitle
        state.goals[index].category = category
        state.goals[index].weight = weight.clamped(to: 1...5)
        state.goals[index].weeklyTarget = weeklyTarget.clamped(to: 1...14)
        save()
    }

    func archiveGoal(_ goal: Goal) {
        guard let index = state.goals.firstIndex(where: { $0.id == goal.id }) else { return }
        state.goals[index].archivedAt = .now
        state.goals[index].mode = .sleeping
        save()
    }

    func deleteGoal(_ goal: Goal) {
        state.goals.removeAll { $0.id == goal.id }
        state.checkIns.removeAll { $0.goalID == goal.id }
        save()
    }

    func logProgress(for goal: Goal, amount: Int, note: String = "") {
        guard amount > 0 else { return }
        state.checkIns.append(CheckIn(goalID: goal.id, amount: amount, note: note))
        if weeklyProgress(for: goal) >= GoalThreshold.bronze.requiredFraction,
           goal.mode == .recovery {
            updateMode(for: goal, mode: .active)
        } else {
            save()
        }
    }

    func updateMode(for goal: Goal, mode: GoalMode) {
        guard let index = state.goals.firstIndex(where: { $0.id == goal.id }) else { return }
        state.goals[index].mode = mode
        save()
    }

    func setPremium(_ isPremium: Bool) {
        state.isPremium = isPremium
        save()
    }

    func updateReminder(_ preference: ReminderPreference) {
        state.dailyReminder = ReminderPreference(
            isEnabled: preference.isEnabled,
            hour: preference.hour.clamped(to: 0...23),
            minute: preference.minute.clamped(to: 0...59)
        )
        save()
    }

    func recoverySuggestion(for goal: Goal) -> String {
        switch goal.category {
        case .health:
            "Try the two-minute version: stretch, drink water, or step outside."
        case .money:
            "Open the account, note one number, then stop. That counts."
        case .family:
            "Send one message or clear one tiny admin item."
        case .purpose:
            "Protect ten minutes for the next smallest meaningful step."
        case .you:
            "Choose one restorative action that future-you would recognize."
        }
    }

    func weeklyProgress(for goal: Goal) -> Double {
        let start = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        let total = state.checkIns
            .filter { $0.goalID == goal.id && $0.date >= start }
            .reduce(0) { $0 + $1.amount }
        return Double(total) / Double(max(goal.weeklyTarget, 1))
    }

    func threshold(for goal: Goal) -> GoalThreshold? {
        let progress = weeklyProgress(for: goal)
        return GoalThreshold.allCases.last { progress >= $0.requiredFraction }
    }

    func checkInsThisWeek(for goal: Goal) -> [CheckIn] {
        let start = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return state.checkIns
            .filter { $0.goalID == goal.id && $0.date >= start }
            .sorted { $0.date > $1.date }
    }

    private func save() {
        persistence.save(state)
    }
}

extension JSONEncoder {
    static var wayfound: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var wayfound: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
