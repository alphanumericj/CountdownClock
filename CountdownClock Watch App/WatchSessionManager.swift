import Foundation
import WatchConnectivity
import WidgetKit

class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
      //  <#code#>
    }
    
    @Published var eventTitle: String = ""
    @Published var targetDate: Date = Date()
    
    override init() {
        super.init()

        // Load any previously saved values from the App Group so they persist across launches
        let shared = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")
        if let savedTitle = shared?.string(forKey: "eventTitle") {
            eventTitle = savedTitle
        }
        let savedTimestamp = shared?.double(forKey: "targetDate") ?? 0
        if savedTimestamp > 0 {
            targetDate = Date(timeIntervalSince1970: savedTimestamp)
        }

        // Start WatchConnectivity session
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String : Any]) {

        if let title = applicationContext["eventTitle"] as? String,
           let timestamp = applicationContext["targetDate"] as? TimeInterval {
            let date = Date(timeIntervalSince1970: timestamp)

            DispatchQueue.main.async {
                // Update UI state
                self.eventTitle = title
                self.targetDate = date

                // Persist into the shared App Group so the complication can read it
                let shared = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")
                shared?.set(title, forKey: "eventTitle")
                shared?.set(timestamp, forKey: "targetDate")

                // Now that data is stored where the widget reads it, refresh timelines on the watch
                WidgetCenter.shared.reloadAllTimelines()

                print("Received context from phone: \(title), \(self.targetDate)")
            }
        }
    }
    
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("WCSession reachability changed: \(session.isReachable)")
    }
    

}
