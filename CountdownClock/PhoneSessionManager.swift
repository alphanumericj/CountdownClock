import Foundation
import WatchConnectivity

class PhoneSessionManager: NSObject, WCSessionDelegate {
    static let shared = PhoneSessionManager()
    private override init() {}

    func startSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    /// Send all events to the watch
    func sendEvents(_ events: [Event]) {
        guard WCSession.default.activationState == .activated,
              let data = try? JSONEncoder().encode(events) else { return }
        let payload: [String: Any] = ["eventsData": data]
        do {
            try WCSession.default.updateApplicationContext(payload)
        } catch {
            print("Error sending events to watch: \(error)")
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("Phone WCSession activated: \(activationState.rawValue), error: \(String(describing: error))")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
}
