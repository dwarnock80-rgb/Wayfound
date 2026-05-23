import Foundation
import SwiftUI

enum WayfoundCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case health
    case money
    case family
    case purpose
    case you

    var id: String { rawValue }

    var label: String {
        switch self {
        case .health: "Health"
        case .money: "Money"
        case .family: "Family"
        case .purpose: "Purpose"
        case .you: "You"
        }
    }

    var emoji: String {
        switch self {
        case .health: "💚"
        case .money: "💰"
        case .family: "🏠"
        case .purpose: "🎯"
        case .you: "✨"
        }
    }

    var symbol: String {
        switch self {
        case .health: "heart.fill"
        case .money: "banknote.fill"
        case .family: "house.fill"
        case .purpose: "target"
        case .you: "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .health: Color(hex: 0x4F8F69)
        case .money: Color(hex: 0xB7791F)
        case .family: Color(hex: 0xC75F7A)
        case .purpose: Color(hex: 0x5F6AB8)
        case .you: Color(hex: 0x278B84)
        }
    }
}

enum GoalFrequency: String, CaseIterable, Codable, Identifiable, Sendable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }
}

enum AchievementTier: String, CaseIterable, Codable, Identifiable, Comparable, Sendable {
    case none
    case bronze
    case silver
    case gold

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: "Not achieved"
        case .bronze: "Partially met"
        case .silver: "Achieved"
        case .gold: "Exceeded"
        }
    }

    var shortLabel: String {
        switch self {
        case .none: "None"
        case .bronze: "Some progress"
        case .silver: "Done"
        case .gold: "Beyond the goal"
        }
    }

    var emoji: String {
        switch self {
        case .none: "-"
        case .bronze: "🥉"
        case .silver: "🥈"
        case .gold: "🥇"
        }
    }

    var points: Int {
        switch self {
        case .none: 0
        case .bronze: 1
        case .silver: 2
        case .gold: 3
        }
    }

    var color: Color {
        switch self {
        case .none: Color(hex: 0xD8DEE6)
        case .bronze: Color(hex: 0xF0A6B7)
        case .silver: Color(hex: 0x9EB7DA)
        case .gold: Color(hex: 0x72C28A)
        }
    }

    static func < (lhs: AchievementTier, rhs: AchievementTier) -> Bool {
        lhs.points < rhs.points
    }
}

enum CheckInMood: String, CaseIterable, Codable, Identifiable, Sendable {
    case tough
    case okay
    case good
    case great

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var emoji: String {
        switch self {
        case .tough: "😓"
        case .okay: "😐"
        case .good: "😊"
        case .great: "😄"
        }
    }
}

struct Goal: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var category: WayfoundCategory
    var weight: Int
    var bronzeTarget: Int
    var silverTarget: Int
    var goldTarget: Int
    var frequency: GoalFrequency
    var emoji: String
    var isActive: Bool
    var isSleeping: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        category: WayfoundCategory = .health,
        weight: Int = 1,
        bronzeTarget: Int = 1,
        silverTarget: Int = 3,
        goldTarget: Int = 5,
        frequency: GoalFrequency = .daily,
        emoji: String = "💪",
        isActive: Bool = true,
        isSleeping: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.weight = weight
        self.bronzeTarget = bronzeTarget
        self.silverTarget = silverTarget
        self.goldTarget = goldTarget
        self.frequency = frequency
        self.emoji = emoji
        self.isActive = isActive
        self.isSleeping = isSleeping
        self.createdAt = createdAt
    }
}

struct CheckIn: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var goalID: UUID
    var date: Date
    var tier: AchievementTier
    var mood: CheckInMood?
    var note: String

    init(id: UUID = UUID(), goalID: UUID, date: Date = .now, tier: AchievementTier, mood: CheckInMood? = nil, note: String = "") {
        self.id = id
        self.goalID = goalID
        self.date = date
        self.tier = tier
        self.mood = mood
        self.note = note
    }
}

struct Todo: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

struct AppState: Codable, Sendable {
    var hasCompletedOnboarding: Bool
    var isPremium: Bool
    var dailyReminder: ReminderPreference
    var goals: [Goal]
    var checkIns: [CheckIn]
    var todos: [Todo]

    static let sample = AppState(
        hasCompletedOnboarding: false,
        isPremium: false,
        dailyReminder: ReminderPreference(),
        goals: [
            Goal(title: "Ten-minute reset walk", category: .health, weight: 3, emoji: "🚶"),
            Goal(title: "Family admin moment", category: .family, weight: 2, emoji: "🏡"),
            Goal(title: "Protect one quiet hour", category: .you, weight: 2, emoji: "😴")
        ],
        checkIns: [],
        todos: [
            Todo(title: "Add one task you have been carrying")
        ]
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
