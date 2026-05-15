import Testing
@testable import Wayfound

@MainActor
struct WayfoundTests {
    @Test func freePlanStartsAtGoalLimit() {
        let store = WayfoundStore(state: .sample, persistence: InMemoryWayfoundPersistence())

        #expect(store.state.goals.count == store.freeGoalLimit)
        #expect(store.canCreateGoal == false)
    }

    @Test func loggingProgressImprovesMomentum() {
        let store = WayfoundStore(state: .sample, persistence: InMemoryWayfoundPersistence())
        let startingScore = store.momentumScore
        let goal = store.state.goals[0]

        store.logProgress(for: goal, amount: goal.weeklyTarget)

        #expect(store.momentumScore > startingScore)
        #expect(store.threshold(for: goal) == .gold)
    }

    @Test func archivingGoalRemovesItFromMomentum() {
        let store = WayfoundStore(state: .sample, persistence: InMemoryWayfoundPersistence())
        let goal = store.state.goals[0]

        store.archiveGoal(goal)

        #expect(store.visibleGoals.contains(goal) == false)
        #expect(store.activeGoals.contains(goal) == false)
    }
}
