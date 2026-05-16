import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private let appGroup = "group.com.chipmania.CountdownClock"
    private let notifiedKey = "notifiedArrivalEventIDs"

    // MARK: - Persistent notified-ID tracking

    private func persistedNotifiedIDs() -> Set<String> {
        let arr = UserDefaults(suiteName: appGroup)?.stringArray(forKey: notifiedKey) ?? []
        return Set(arr)
    }

    private func markNotified(_ id: UUID) {
        var current = persistedNotifiedIDs()
        current.insert(id.uuidString)
        UserDefaults(suiteName: appGroup)?.set(Array(current), forKey: notifiedKey)
    }

    // Prune notified IDs for events that no longer exist, so storage doesn't grow forever.
    func pruneNotifiedIDs(keepingEventIDs activeIDs: Set<UUID>) {
        let active = Set(activeIDs.map(\.uuidString))
        let pruned = persistedNotifiedIDs().filter { active.contains($0) }
        UserDefaults(suiteName: appGroup)?.set(Array(pruned), forKey: notifiedKey)
    }

    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        if !granted { throw NSError(domain: "Notification", code: 1, userInfo: [NSLocalizedDescriptionKey: "Notifications not authorized"]) }
    }

    // Called from ContentView when the app is in the foreground and detects arrival.
    // Uses a stable identifier so it can't stack with the pre-scheduled notification.
    func scheduleEventArrivalNotification(eventTitle: String, eventID: UUID) async {
        guard !persistedNotifiedIDs().contains(eventID.uuidString) else { return }
        markNotified(eventID)

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
        let alreadyNotified = persistedNotifiedIDs()

        // Prune IDs for events that no longer exist
        pruneNotifiedIDs(keepingEventIDs: Set(events.map(\.id)))

        for event in events {
            // Never re-notify an event that already got a WooHoo!
            guard !alreadyNotified.contains(event.id.uuidString) else { continue }

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
            do {
                try await center.add(request)
                markNotified(event.id)  // persisted so this event is never re-notified
            } catch {}
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
