import WatchKit
import SwiftUI
import UserNotifications

/// Drives the custom notification interface for arrival celebrations.
/// Registered against the "arrival" category in CountdownClockApp.
class NotificationController: WKUserNotificationHostingController<NotificationView> {

    private var eventTitle: String = "Your event"

    override var body: NotificationView {
        NotificationView(eventTitle: eventTitle)
    }

    override func didReceive(_ notification: UNNotification) {
        // Pull the event title from userInfo (set by NotificationManager)
        if let title = notification.request.content.userInfo["eventTitle"] as? String {
            eventTitle = title
        }
    }
}
