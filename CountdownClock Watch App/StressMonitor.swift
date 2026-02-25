import Foundation

/// Bootstraps HealthKit + Notifications and posts an encouragement when HRV is below threshold.
/// Call `StressMonitor.shared.start()` from your Watch app's `@main` App `init` or `onAppear`.
final class StressMonitor {
    static let shared = StressMonitor()

    // Tunables
    var hrvThresholdMilliseconds: Double = 25 // Example threshold; adjust as needed
    var encouragingMessages: [String] = [
        "You're doing great.",
        "Hang in there.",
        "Breathe in, breathe out.",
        "Look on the bright side",
        "Keep calm and carry on!",
        "One moment at a time.",
        "Something to look forward to!",
        "Keep going, it's closer than you think."
    ]

    private var hasRequestedAuth = false
    private let lastNotificationDateKey = "LastNotificationDate"
    private let cooldownInterval: TimeInterval = 2 * 60 * 60 // 2 hours

    func start() {
        // Request notifications first
        Task { try? await NotificationManager.shared.requestAuthorization() }

        // Request HealthKit and start observing HRV
        HealthKitManager.shared.requestAuthorization { success in
            guard success else { return }
            HealthKitManager.shared.startObservingHRV(thresholdInMilliseconds: self.hrvThresholdMilliseconds) { [weak self] latest in
                guard let self, let latest else { return }
                if latest < self.hrvThresholdMilliseconds, self.isOutsideCooldown() {
                    self.handleLowHRV(latest)
                }
            }
        }
    }

    private func isOutsideCooldown() -> Bool {
        // Use app group defaults to share across app/extension if needed
        let defaults = UserDefaults(suiteName: "group.com.chipmania.CountdownClock") ?? .standard
        if let lastDate = defaults.object(forKey: lastNotificationDateKey) as? Date {
            return Date().timeIntervalSince(lastDate) >= cooldownInterval
        }
        // No prior notification recorded: allow
        return true
    }

    private func handleLowHRV(_ latest: Double) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")
        let now = Date()

        // Pick a random event from the three soonest upcoming events.
        // Falls back to the legacy single-event keys if the full array isn't available yet.
        let chosenTitle: String
        let chosenTargetDate: Date

        if let data = sharedDefaults?.data(forKey: "events.v1"),
           let allEvents = try? JSONDecoder().decode([Event].self, from: data) {
            // Filter to future events, sort ascending, take up to 3, pick one at random
            let upcoming = allEvents
                .filter { $0.targetDate > now }
                .sorted { $0.targetDate < $1.targetDate }
                .prefix(3)
            guard let chosen = upcoming.randomElement() else { return }
            chosenTitle = chosen.title
            chosenTargetDate = chosen.targetDate
        } else {
            // Fallback: use the nominated event written by WatchSessionManager
            let title = sharedDefaults?.string(forKey: "eventTitle") ?? "Your event"
            let timestamp = sharedDefaults?.double(forKey: "targetDate") ?? 0
            let targetDate = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : now
            guard now < targetDate else { return }
            chosenTitle = title
            chosenTargetDate = targetDate
        }

        let remaining = Self.formatRemaining(from: now, to: chosenTargetDate)

        // Record the time of this notification so we enforce cooldown next time
        let defaults = sharedDefaults ?? .standard
        defaults.set(now, forKey: lastNotificationDateKey)

        Task {
            await NotificationManager.shared.scheduleEncouragement(
                eventTitle: chosenTitle,
                timeRemaining: remaining,
                messages: encouragingMessages
            )
        }
    }

    // Formats remaining time similar to your widget's short/long helpers.
    static func formatRemaining(from: Date, to: Date) -> String {
        if to <= from { return "now" }
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: from, to: to)
        var parts: [String] = []
        
        if let d = components.day, d > 0 { parts.append("\(d)d") }
        if let h = components.hour, h > 0 { parts.append("\(h)h") }
        if let m = components.minute, m > 0, parts.isEmpty || parts.count < 2 { parts.append("\(m)m") }
        return parts.joined(separator: " ")
    }
}
