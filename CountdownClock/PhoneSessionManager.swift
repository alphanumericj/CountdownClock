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
    
    func sendCountdownSettings(eventTitle: String, targetDate: Date) {
        if WCSession.default.isReachable {
            let payload: [String: Any] = [
                "eventTitle": eventTitle,
                "targetDate": targetDate.timeIntervalSince1970
            ]
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                print("Error sending message: \(error)")
            }
        }
    }
}
