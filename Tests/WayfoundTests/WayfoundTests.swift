import Testing
@testable import Wayfound

@MainActor
struct WayfoundTests {
    @Test func freePlanStartsAtGoalLimit() {
        let store = WayfoundStore(state: .sample)

        #expect(store.state.goals.count == store.freeGoalLimit)
        #expect(store.canCreateGoal == false)
    }

    @Test func loggingProgressImprovesMomentum() {
        let store = WayfoundStore(state: .sample)
        let startingScore = store.momentumScore
        let goal = store.state.goals[0]

        store.logProgress(for: goal, amount: goal.weeklyTarget)

        #expect(store.momentumScore > startingScore)
        #expect(store.threshold(for: goal) == .gold)
    }
}
