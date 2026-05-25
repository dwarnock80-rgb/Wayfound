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
        state.goals
            .filter { $0.isActive && !$0.isSleeping }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var sleepingGoals: [Goal] {
        state.goals
            .filter(\.isSleeping)
            .sorted { $0.createdAt > $1.createdAt }
    }

    var archivedGoals: [Goal] {
        state.goals
            .filter { !$0.isActive }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var visibleGoals: [Goal] {
        state.goals.sorted { $0.createdAt > $1.createdAt }
    }

    var freeGoalLimit: Int { 3 }

    var canCreateGoal: Bool {
        state.isPremium || state.goals.filter(\.isActive).count < freeGoalLimit
    }

    var momentumScore: Int {
        calculateMomentumScore(goals: state.goals, checkIns: state.checkIns)
    }

    var momentumLevel: MomentumLevel {
        MomentumLevel(score: momentumScore)
    }

    var needsRecovery: Bool {
        momentumScore < 20 && !activeGoals.isEmpty
    }

    var pendingTodos: [Todo] {
        state.todos.filter { !$0.isCompleted }.sorted { $0.createdAt > $1.createdAt }
    }

    var completedTodos: [Todo] {
        state.todos.filter(\.isCompleted).sorted { $0.createdAt > $1.createdAt }
    }

    func completeOnboarding() {
        state.hasCompletedOnboarding = true
        save()
    }

    func addGoal(title: String, category: WayfoundCategory, weight: Int, frequency: GoalFrequency, emoji: String) {
        guard canCreateGoal else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        state.goals.append(
            Goal(
                title: cleanTitle,
                category: category,
                weight: weight.clamped(to: 1...5),
                frequency: frequency,
                emoji: emoji
            )
        )
        save()
    }

    func updateGoal(_ goal: Goal, title: String, category: WayfoundCategory, weight: Int, frequency: GoalFrequency, emoji: String, isActive: Bool, isSleeping: Bool) {
        guard let index = state.goals.firstIndex(where: { $0.id == goal.id }) else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        state.goals[index].title = cleanTitle
        state.goals[index].category = category
        state.goals[index].weight = weight.clamped(to: 1...5)
        state.goals[index].frequency = frequency
        state.goals[index].emoji = emoji
        state.goals[index].isActive = isActive
        state.goals[index].isSleeping = isSleeping
        save()
    }

    func setSleeping(_ goal: Goal, isSleeping: Bool) {
        guard let index = state.goals.firstIndex(where: { $0.id == goal.id }) else { return }
        state.goals[index].isSleeping = isSleeping
        save()
    }

    func setAllSleeping(_ isSleeping: Bool) {
        for index in state.goals.indices where state.goals[index].isActive {
            state.goals[index].isSleeping = isSleeping
        }
        save()
    }

    func archiveGoal(_ goal: Goal) {
        guard let index = state.goals.firstIndex(where: { $0.id == goal.id }) else { return }
        state.goals[index].isActive = false
        state.goals[index].isSleeping = false
        save()
    }

    func restoreGoal(_ goal: Goal) {
        guard canCreateGoal, let index = state.goals.firstIndex(where: { $0.id == goal.id }) else { return }
        state.goals[index].isActive = true
        state.goals[index].isSleeping = false
        save()
    }

    func deleteGoal(_ goal: Goal) {
        state.goals.removeAll { $0.id == goal.id }
        state.checkIns.removeAll { $0.goalID == goal.id }
        save()
    }

    func saveCheckIns(_ drafts: [UUID: CheckInDraft]) {
        let today = startOfDay(.now)
        for goal in activeGoals {
            let draft = drafts[goal.id] ?? CheckInDraft()
            let note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
            let checkIn = CheckIn(goalID: goal.id, date: today, tier: draft.tier, mood: draft.mood, note: note)

            if let index = state.checkIns.firstIndex(where: { $0.goalID == goal.id && calendar.isDate($0.date, inSameDayAs: today) }) {
                state.checkIns[index] = checkIn
            } else {
                state.checkIns.append(checkIn)
            }
        }
        save()
    }

    func checkIn(for goal: Goal, on date: Date = .now) -> CheckIn? {
        state.checkIns.first { $0.goalID == goal.id && calendar.isDate($0.date, inSameDayAs: date) }
    }

    func checkInsForLastSevenDays(goal: Goal) -> [(date: Date, checkIn: CheckIn?)] {
        lastSevenDays().map { day in
            (day, checkIn(for: goal, on: day))
        }
    }

    func lastSevenDays() -> [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset - 6, to: startOfDay(.now))
        }
    }

    func addTodo(title: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        state.todos.append(Todo(title: cleanTitle))
        save()
    }

    func toggleTodo(_ todo: Todo) {
        guard let index = state.todos.firstIndex(where: { $0.id == todo.id }) else { return }
        state.todos[index].isCompleted.toggle()
        save()
    }

    func deleteTodo(_ todo: Todo) {
        state.todos.removeAll { $0.id == todo.id }
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

    func calculateMomentumScore(goals: [Goal], checkIns: [CheckIn]) -> Int {
        let goals = goals.filter { $0.isActive && !$0.isSleeping }
        guard !goals.isEmpty else { return 0 }

        let days = Set(lastSevenDays().map(startOfDay))
        var totalWeightedScore = 0.0
        var totalWeight = 0.0

        for goal in goals {
            let goalCheckIns = checkIns.filter { checkIn in
                checkIn.goalID == goal.id && days.contains(startOfDay(checkIn.date))
            }
            let goalScore = goalCheckIns.reduce(0) { $0 + $1.tier.points }
            let maxPossible = goal.frequency == .daily ? 21.0 : 3.0
            let weight = Double(goal.weight)
            totalWeightedScore += (Double(goalScore) / maxPossible) * weight
            totalWeight += weight
        }

        guard totalWeight > 0 else { return 0 }
        return Int((totalWeightedScore / totalWeight * 100).rounded()).clamped(to: 0...100)
    }

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func save() {
        persistence.save(state)
    }
}

struct CheckInDraft: Equatable {
    var tier: AchievementTier = .none
    var mood: CheckInMood?
    var note: String = ""
}

struct MomentumLevel: Equatable {
    let label: String
    let emoji: String
    let message: String

    init(score: Int) {
        if score >= 80 {
            label = "Thriving"
            emoji = "🌟"
            message = "You're in an incredible flow right now."
        } else if score >= 60 {
            label = "Growing"
            emoji = "🌱"
            message = "Steady progress. You're doing great."
        } else if score >= 40 {
            label = "Building"
            emoji = "🔨"
            message = "Every small step is building something."
        } else if score >= 20 {
            label = "Stirring"
            emoji = "💫"
            message = "Movement is happening. That matters."
        } else {
            label = "Resting"
            emoji = "🌙"
            message = "Rest is part of the journey too."
        }
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
