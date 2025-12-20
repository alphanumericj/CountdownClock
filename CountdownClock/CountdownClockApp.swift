//
//  CountdownClockApp.swift
//  CountdownClock
//
//  Created by Laure Chipman on 12/5/25.
//

import SwiftUI

@main
struct CountdownClockApp: App {
    @AppStorage("eventTitle") private var eventTitle: String = ""
    @AppStorage("targetDate") private var targetDate: Double = 0.0
    init() {
            PhoneSessionManager.shared.startSession()
        }
    var body: some Scene {
        WindowGroup {
            
            if eventTitle.isEmpty || targetDate == 0.0 {
                // First run → show setup
                CountdownClockSetupView { title, date in
                    eventTitle = title
                    targetDate = date.timeIntervalSince1970
                }
            } else {
                // Already have settings → show countdown
                CountdownView(
                    eventTitle: eventTitle,
                    targetDate: Date(timeIntervalSince1970: targetDate)
                )
            }
        }
    }
}
