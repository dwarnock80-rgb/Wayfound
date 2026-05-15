import Foundation
import Observation

@Observable
@MainActor
final class WayfoundStore {
    private let storageKey = "wayfound.local.state.v1"
    private let calendar = Calendar.current
    private let userDefaults: UserDefaults
    private(set) var state: AppState

    init(state initialState: AppState? = nil, userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let initialState {
            state = initialState
        } else if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder.wayfound.decode(AppState.self, from: data) {
            state = decoded
        } else {
            state = .sample
        }
    }

    var activeGoals: [Goal] {
        state.goals.filter { $0.mode != .sleeping }
    }

    var freeGoalLimit: Int { 3 }

    var canCreateGoal: Bool {
        state.isPremium || state.goals.count < freeGoalLimit
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
        guard let data = try? JSONEncoder.wayfound.encode(state) else { return }
        userDefaults.set(data, forKey: storageKey)
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
