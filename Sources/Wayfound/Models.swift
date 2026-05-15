import Foundation
import SwiftUI

enum WayfoundCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case health = "Health"
    case money = "Money"
    case family = "Family"
    case purpose = "Purpose"
    case you = "You"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .health: "heart.fill"
        case .money: "banknote.fill"
        case .family: "figure.2.and.child.holdinghands"
        case .purpose: "sparkles"
        case .you: "person.crop.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .health: Color(hex: 0x6B8F71)
        case .money: Color(hex: 0x7CA7A5)
        case .family: Color(hex: 0xC4936D)
        case .purpose: Color(hex: 0x8A7FA8)
        case .you: Color(hex: 0xB76E79)
        }
    }
}

enum GoalThreshold: String, CaseIterable, Codable, Identifiable, Sendable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"

    var id: String { rawValue }

    var requiredFraction: Double {
        switch self {
        case .bronze: 0.35
        case .silver: 0.7
        case .gold: 1.0
        }
    }

    var symbol: String {
        switch self {
        case .bronze: "circle.lefthalf.filled"
        case .silver: "circle.righthalf.filled"
        case .gold: "seal.fill"
        }
    }
}

enum GoalMode: String, Codable, Sendable {
    case active
    case recovery
    case sleeping
}

struct Goal: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var category: WayfoundCategory
    var weight: Int
    var weeklyTarget: Int
    var mode: GoalMode
    var archivedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        category: WayfoundCategory,
        weight: Int,
        weeklyTarget: Int,
        mode: GoalMode = .active,
        archivedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.weight = weight
        self.weeklyTarget = weeklyTarget
        self.mode = mode
        self.archivedAt = archivedAt
        self.createdAt = createdAt
    }
}

struct CheckIn: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var goalID: UUID
    var date: Date
    var amount: Int
    var note: String

    init(id: UUID = UUID(), goalID: UUID, date: Date = .now, amount: Int, note: String = "") {
        self.id = id
        self.goalID = goalID
        self.date = date
        self.amount = amount
        self.note = note
    }
}

struct AppState: Codable, Sendable {
    var hasCompletedOnboarding: Bool
    var isPremium: Bool
    var dailyReminder: ReminderPreference
    var goals: [Goal]
    var checkIns: [CheckIn]

    static let sample = AppState(
        hasCompletedOnboarding: false,
        isPremium: false,
        dailyReminder: ReminderPreference(),
        goals: [
            Goal(title: "Ten-minute reset walk", category: .health, weight: 3, weeklyTarget: 4),
            Goal(title: "Family admin moment", category: .family, weight: 2, weeklyTarget: 3),
            Goal(title: "Protect one quiet hour", category: .you, weight: 2, weeklyTarget: 2)
        ],
        checkIns: []
    )
}

struct ReminderPreference: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var hour: Int
    var minute: Int

    init(isEnabled: Bool = false, hour: Int = 20, minute: Int = 30) {
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
    }
}
