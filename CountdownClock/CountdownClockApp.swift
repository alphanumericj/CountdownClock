//
//  CountdownClockApp.swift
//  CountdownClock
//
//  Created by Laure Chipman on 12/5/25.
//

import SwiftUI

@main
struct CountdownClockApp: App {
    init() {
        PhoneSessionManager.shared.startSession()
    }

    var body: some Scene {
        WindowGroup {
            EventListView()
        }
    }
}
