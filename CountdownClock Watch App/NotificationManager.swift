import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        if !granted { throw NSError(domain: "Notification", code: 1, userInfo: [NSLocalizedDescriptionKey: "Notifications not authorized"]) }
    }

    func scheduleEncouragement(eventTitle: String, timeRemaining: String, messages: [String]) async {
        let center = UNUserNotificationCenter.current()

        // Random encouraging message
        let base = messages.randomElement() ?? "You've got this!"
        let body = "\(base) \(eventTitle) happens in \(timeRemaining)!"

        let content = UNMutableNotificationContent()
        content.title = "Take a breath"
        content.body = body
        content.sound = .default

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            // Silently ignore errors in scheduling
        }
    }
}
