import Foundation
import WatchConnectivity
import WidgetKit

class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    @Published var events: [Event] = []

    private let appGroup = "group.com.chipmania.CountdownClock"
    private let storageKey = "events.v1"

    override init() {
        super.init()

        // Load previously saved events from the App Group so they persist across launches
        let shared = UserDefaults(suiteName: appGroup)
        if let data = shared?.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            events = decoded
        }

        // Start WatchConnectivity session
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // Push local events to the phone (used for recovery when phone list is empty)
    func sendEventsToPhone() {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable,
              let data = try? JSONEncoder().encode(events) else { return }
        WCSession.default.sendMessage(["watchEventsData": data], replyHandler: nil)
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: (any Error)?) {}

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["eventsData"] as? Data,
              let decoded = try? JSONDecoder().decode([Event].self, from: data) else { return }

        DispatchQueue.main.async {
            self.events = decoded

            let shared = UserDefaults(suiteName: self.appGroup)

            // Persist full events array for next launch
            shared?.set(data, forKey: self.storageKey)

            // Write nominated event's title/date for the watch-face widget complication
            if let nominated = decoded.first(where: { $0.isNominated }) {
                shared?.set(nominated.title, forKey: "eventTitle")
                shared?.set(nominated.targetDate.timeIntervalSince1970, forKey: "targetDate")
            } else if let first = decoded.first {
                shared?.set(first.title, forKey: "eventTitle")
                shared?.set(first.targetDate.timeIntervalSince1970, forKey: "targetDate")
            } else {
                shared?.removeObject(forKey: "eventTitle")
                shared?.removeObject(forKey: "targetDate")
            }

            // Refresh watch face complications
            WidgetCenter.shared.reloadAllTimelines()

            print("Received \(decoded.count) events from phone")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable { sendEventsToPhone() }
    }
}
