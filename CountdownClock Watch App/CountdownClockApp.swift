//
//  CountdownClockApp.swift
//  CountdownClock Watch App
//
//  Created by Laure Chipman on 12/5/25.
//

import SwiftUI
import WatchKit

@main
struct CountdownClock_Watch_AppApp: App {
    @StateObject private var sessionManager = WatchSessionManager()

    init() {
        // Start HRV monitoring and notifications
        StressMonitor.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
        }
        // Custom notification interface for arrival celebrations ("WooHoo!!")
        WKNotificationScene(controller: NotificationController.self, category: "arrival")
    }
}
