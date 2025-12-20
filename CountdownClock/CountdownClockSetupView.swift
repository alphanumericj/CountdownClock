import SwiftUI
import WidgetKit

struct CountdownClockSetupView: View {
    @State private var eventTitle: String = ""
    @State private var targetDate: Date = Date().addingTimeInterval(3600)
    var onSave: (String, Date) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Countdown Clock Setup")
                .font(.title)
            
            Text("What are you looking forward to?")
                .font(.headline)
            
            TextField("Event name", text: $eventTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Text("When does it happen?")
                .font(.headline)
            
            DatePicker("Target date", selection: $targetDate, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .padding(.horizontal)
            
            Button("OK") {
                            // Save locally
                            //UserDefaults.standard.set(eventTitle, forKey: "eventTitle")
                            //UserDefaults.standard.set(targetDate.timeIntervalSince1970, //forKey: "targetDate")
                
                let sharedDefaults = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")
                sharedDefaults?.set(eventTitle, forKey: "eventTitle")
                sharedDefaults?.set(targetDate.timeIntervalSince1970, forKey: "targetDate")
                
                // Notify parent view
                            onSave(eventTitle, targetDate)
                            
                            // Send to watch
                            PhoneSessionManager.shared.sendCountdownSettings(eventTitle: eventTitle,
                                                                            targetDate: targetDate)
                WidgetCenter.shared.reloadAllTimelines() //??
                        }

            .buttonStyle(.borderedProminent)
            .padding()
        }
        .onAppear {
            let sharedDefaults = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")
            if let savedTitle = sharedDefaults?.string(forKey: "eventTitle") {
                eventTitle = savedTitle
            }
            let savedTimestamp = sharedDefaults?.double(forKey: "targetDate") ?? 0
            if savedTimestamp > 0 {
                targetDate = Date(timeIntervalSince1970: savedTimestamp)
            }
        }
    }
}

