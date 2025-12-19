import WatchConnectivity
import SwiftUI

class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    @Published var eventTitle: String = ""
    @Published var targetDate: Date = Date()
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let title = message["eventTitle"] as? String,
           let timestamp = message["targetDate"] as? TimeInterval {
            DispatchQueue.main.async {
                self.eventTitle = title
                self.targetDate = Date(timeIntervalSince1970: timestamp)
                
                // Persist locally so it survives relaunch
                UserDefaults.standard.set(title, forKey: "eventTitle")
                UserDefaults.standard.set(timestamp, forKey: "targetDate")
            }
        }
    }
}
