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
    
    /// Send latest countdown settings to the watch
    func sendCountdownSettings(eventTitle: String, targetDate: Date) {
        let payload: [String: Any] = [
            "eventTitle": eventTitle,
            "targetDate": targetDate.timeIntervalSince1970
        ]
        
        do {
            if WCSession.default.activationState == .activated {
                try WCSession.default.updateApplicationContext(payload)
                print("Sent context to watch: \(payload)")
            } else {
                print("WCSession not activated yet")
            }
        } catch {
            print("Error updating context: \(error)")
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
