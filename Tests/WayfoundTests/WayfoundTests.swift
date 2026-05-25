import Testing
@testable import Wayfound

@MainActor
struct WayfoundTests {
    @Test func freePlanStartsWithRoomForAGoal() {
        let store = WayfoundStore(state: .sample, persistence: InMemoryWayfoundPersistence())

        #expect(store.state.goals.isEmpty)
        #expect(store.canCreateGoal)
    }

    @Test func freePlanStopsAtGoalLimit() {
        let store = WayfoundStore(state: .sample, persistence: InMemoryWayfoundPersistence())

        store.addGoal(title: "One personal habit", category: .you, weight: 2, frequency: .daily, emoji: "🌱")
        store.addGoal(title: "One health habit", category: .health, weight: 2, frequency: .daily, emoji: "🚶")
        store.addGoal(title: "One family habit", category: .family, weight: 2, frequency: .daily, emoji: "🏡")

        #expect(store.state.goals.count == store.freeGoalLimit)
        #expect(!store.canCreateGoal)
    }

    @Test func achievedCheckInImprovesMomentum() {
        let store = WayfoundStore(state: stateWithGoals(), persistence: InMemoryWayfoundPersistence())
        let startingScore = store.momentumScore
        let goal = store.state.goals[0]

        store.saveCheckIns([goal.id: CheckInDraft(tier: .silver, mood: .good)])

        #expect(store.momentumScore > startingScore)
        #expect(store.checkIn(for: goal)?.tier == .silver)
    }

    @Test func sleepModeRemovesGoalFromMomentum() {
        let store = WayfoundStore(state: stateWithGoals(), persistence: InMemoryWayfoundPersistence())
        let goal = store.state.goals[0]

        store.setSleeping(goal, isSleeping: true)

        #expect(store.sleepingGoals.contains { $0.id == goal.id })
        #expect(!store.activeGoals.contains { $0.id == goal.id })
    }

    @Test func archivedGoalFreesAFreePlanSlot() {
        let store = WayfoundStore(state: stateWithGoals(), persistence: InMemoryWayfoundPersistence())
        let goal = store.state.goals[0]

        store.archiveGoal(goal)

        #expect(store.canCreateGoal)
        #expect(store.archivedGoals.contains { $0.id == goal.id })
    }

    @Test func deletingGoalRemovesItsCheckIns() {
        let store = WayfoundStore(state: stateWithGoals(), persistence: InMemoryWayfoundPersistence())
        let goal = store.state.goals[0]

        store.saveCheckIns([goal.id: CheckInDraft(tier: .silver, mood: .good)])
        store.deleteGoal(goal)

        #expect(!store.state.goals.contains { $0.id == goal.id })
        #expect(!store.state.checkIns.contains { $0.goalID == goal.id })
    }

    @Test func todosCanBeCompleted() {
        let store = WayfoundStore(state: .sample, persistence: InMemoryWayfoundPersistence())
        let todo = store.state.todos[0]

        store.toggleTodo(todo)

        #expect(store.completedTodos.contains { $0.id == todo.id })
    }

    private func stateWithGoals() -> AppState {
        var state = AppState.sample
        state.goals = [
            Goal(title: "Ten-minute reset walk", category: .health, weight: 3, emoji: "🚶"),
            Goal(title: "Family admin moment", category: .family, weight: 2, emoji: "🏡"),
            Goal(title: "Protect one quiet hour", category: .you, weight: 2, emoji: "😴")
        ]
        return state
    }
}
