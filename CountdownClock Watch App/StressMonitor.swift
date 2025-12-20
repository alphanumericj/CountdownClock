import Foundation

/// Bootstraps HealthKit + Notifications and posts an encouragement when HRV is below threshold.
/// Call `StressMonitor.shared.start()` from your Watch app's `@main` App `init` or `onAppear`.
final class StressMonitor {
    static let shared = StressMonitor()

    // Tunables
    var hrvThresholdMilliseconds: Double = 25 // Example threshold; adjust as needed
    var encouragingMessages: [String] = [
        "You're doing great.",
        "One step at a time.",
        "Breathe in, breathe out.",
        "You've got this.",
        "Keep going, you're closer than you think."
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
        // Read event + target from app group to compose message
        let sharedDefaults = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")
        let title = sharedDefaults?.string(forKey: "eventTitle") ?? "Your event"
        let timestamp = sharedDefaults?.double(forKey: "targetDate") ?? 0
        let targetDate = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : Date()
        let remaining = Self.formatRemaining(from: Date(), to: targetDate)

        // Record the time of this notification so we enforce cooldown next time
        let defaults = sharedDefaults ?? .standard
        defaults.set(Date(), forKey: lastNotificationDateKey)

        Task {
            await NotificationManager.shared.scheduleEncouragement(
                eventTitle: title,
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
