import Testing
@testable import Wayfound

@MainActor
struct WayfoundTests {
    @Test func freePlanStartsAtGoalLimit() {
        let store = WayfoundStore(state: .sample, persistence: InMemoryWayfoundPersistence())

        #expect(store.state.goals.count == store.freeGoalLimit)
        #expect(store.canCreateGoal == false)
    }

    @Test func achievedCheckInImprovesMomentum() {
        let store = WayfoundStore(state: .sample, persistence: InMemoryWayfoundPersistence())
        let startingScore = store.momentumScore
        let goal = store.state.goals[0]

        store.saveCheckIns([goal.id: CheckInDraft(tier: .silver, mood: .good)])

        #expect(store.momentumScore > startingScore)
        #expect(store.checkIn(for: goal)?.tier == .silver)
    }

    @Test func sleepModeRemovesGoalFromMomentum() {
        let store = WayfoundStore(state: .sample, persistence: InMemoryWayfoundPersistence())
        let goal = store.state.goals[0]

        store.setSleeping(goal, isSleeping: true)

        #expect(store.sleepingGoals.contains { $0.id == goal.id })
        #expect(!store.activeGoals.contains { $0.id == goal.id })
    }

    @Test func todosCanBeCompleted() {
        let store = WayfoundStore(state: .sample, persistence: InMemoryWayfoundPersistence())
        let todo = store.state.todos[0]

        store.toggleTodo(todo)

        #expect(store.completedTodos.contains { $0.id == todo.id })
    }
}
