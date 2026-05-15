import Foundation
import UserNotifications

enum NotificationService {
    static let dailyReminderIdentifier = "wayfound.daily.checkin"

    static func applyDailyReminder(_ preference: ReminderPreference) async -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])

        guard preference.isEnabled else { return true }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return false }

            var dateComponents = DateComponents()
            dateComponents.hour = preference.hour
            dateComponents.minute = preference.minute

            let content = UNMutableNotificationContent()
            content.title = "A tiny check-in?"
            content.body = "Small progress still counts. Log the smallest honest version."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: dailyReminderIdentifier, content: content, trigger: trigger)
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }
}
