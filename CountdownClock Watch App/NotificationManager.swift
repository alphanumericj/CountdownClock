import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        if !granted { throw NSError(domain: "Notification", code: 1, userInfo: [NSLocalizedDescriptionKey: "Notifications not authorized"]) }
    }

    // Called from ContentView when the app is in the foreground and detects arrival.
    // Uses a stable identifier so it can't stack with the pre-scheduled notification.
    func scheduleEventArrivalNotification(eventTitle: String, eventID: UUID) async {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "WooHoo!!"
        content.body = "\(eventTitle) is here!"
        content.sound = .default
        content.categoryIdentifier = "arrival"
        content.userInfo = ["eventTitle": eventTitle]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "arrival-\(eventID.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {}
    }

    // Called whenever the events list changes. Cancels any existing arrival notifications
    // and schedules one at the exact targetDate for each future event, so "WooHoo!" fires
    // from the background even if the watch app is never opened.
    func scheduleArrivalNotifications(for events: [Event]) async {
        let center = UNUserNotificationCenter.current()

        // Cancel all pending arrival notifications before rescheduling
        let pending = await center.pendingNotificationRequests()
        let oldIDs = pending.filter { $0.identifier.hasPrefix("arrival-") }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: oldIDs)

        let now = Date()
        for event in events {
            let timeInterval = event.targetDate.timeIntervalSince(now)
            guard timeInterval > 0 else { continue }

            let content = UNMutableNotificationContent()
            content.title = "WooHoo!!"
            content.body = "\(event.title) is here!"
            content.sound = .default
            content.categoryIdentifier = "arrival"
            content.userInfo = ["eventTitle": event.title]

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "arrival-\(event.id.uuidString)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
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
