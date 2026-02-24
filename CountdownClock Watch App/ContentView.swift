//
//  ContentView.swift
//  CountdownClock
//
//  Created by Laure Chipman on 12/5/25.
//

import SwiftUI
import WidgetKit


class CountdownModel: ObservableObject {
    @Published var now = Date()
    @Published var eventReached = false   // <— NEW

    private var didNotify = false
    private let sessionManager: WatchSessionManager

       init(sessionManager: WatchSessionManager) {
           self.sessionManager = sessionManager
       }
    func update(date: Date, target: Date) {
        if !didNotify && date >= target {
            didNotify = true
            eventReached = true

            Task {
                await NotificationManager.shared.scheduleEventArrivalNotification(
                    eventTitle: sessionManager.eventTitle,
                    fireDate: target
                )
            }
        }
    }
    
    func resetNotificationFlag() {
            didNotify = false
            eventReached = false
        }
}

//struct ContentView: View {
 //   var body: some View {
 //       VStack {
 //           Image(systemName: "globe")
 //               .imageScale(.large)
 //               .foregroundStyle(.tint)
 //           Text("Hello, world!")
 //       }
 //       .padding()
 //   }
//}
struct ContentView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    
       var body: some View {
           CountdownView(
            sessionManager: sessionManager,
               eventTitle: sessionManager.eventTitle.isEmpty
                   ? "No event set"
                   : sessionManager.eventTitle,
               targetDate: sessionManager.targetDate
           )
       }
   }

struct CountdownEntry: TimelineEntry {
    let date: Date
    let eventTitle: String
    let targetDate: Date
}

struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: Date(), eventTitle: "Midterms", targetDate: Date().addingTimeInterval(3600))
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let shared = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")
        let title = shared?.string(forKey: "eventTitle") ?? "No event"
        let timestamp = shared?.double(forKey: "targetDate") ?? 0
        let targetDate = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : Date()
        
        let entry = CountdownEntry(date: Date(), eventTitle: title, targetDate: targetDate)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        var entries: [CountdownEntry] = []
        let currentDate = Date()
        let shared = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")
        let title = shared?.string(forKey: "eventTitle") ?? "No event"
        let timestamp = shared?.double(forKey: "targetDate") ?? 0
        let targetDate = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : Date()
        
        for minuteOffset in 0..<60*24*7 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            
            let entry = CountdownEntry(date: entryDate, eventTitle: title, targetDate: targetDate)
            entries.append(entry)
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}


struct CountdownView: View {
    let sessionManager: WatchSessionManager
    @StateObject private var model: CountdownModel
    @State private var showConfetti = false
    
    let eventTitle: String
    let targetDate: Date

    init(sessionManager: WatchSessionManager, eventTitle: String, targetDate: Date) {
        self.sessionManager = sessionManager
        self.eventTitle = eventTitle
        self.targetDate = targetDate

        _model = StateObject(wrappedValue: CountdownModel(sessionManager: sessionManager))
    }



    //private let timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()
    private var timer: Timer.TimerPublisher {
        if Date() < targetDate {
            return Timer.publish(every: 20, on: .main, in: .common)
        } else {
            return Timer.publish(every: 1, on: .main, in: .common)
        }
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                Text("\(eventTitle) ")
                    .font(.caption)
            
                if eventTitle != "No event set" && Date() < targetDate {
                    Text(formatCountdown(from: Date(), to: targetDate))
                        .font(.body)
                }
                else if eventTitle != "No event set" && Date() >= targetDate {
                    Text("🎉 Arrived! 🎉")
                        .font(.body)
                }
            }

            if Date() >= targetDate {
                ConfettiView()   // <— your animation
            }
        }
        .onReceive(timer.autoconnect()) { date in
            model.update(date: date, target: targetDate)
        
        }
        .onChange(of: sessionManager.eventTitle) {
            model.resetNotificationFlag()
        }
        
        .onChange(of: sessionManager.targetDate) {
            model.resetNotificationFlag()
        
        }
        /*
        .onAppear { //Just always trigger confetti, why not
            
                triggerConfetti()
                
        }
         */
        .onDisappear{
            //showConfetti = false
        }
    }
    
    private func triggerConfetti() {
        withAnimation {
            showConfetti = true
        }
/*
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
               showConfetti = false
            }
        }
 */
    }
    
    private func unit(_ value: Int, _ singular: String, _ plural: String) -> String {
        value == 1 ? singular : plural
    }
    
    private func formatCountdown(from start: Date, to end: Date) -> String {
        if start >= end {
            return "happening now!"
        }

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: start,
            to: end
        )

        if let years = comps.year, years > 0 {
            let months = comps.month ?? 0
            return "in: \(years) \(unit(years, "year", "years")) \(months) \(unit(months, "month", "months"))"
        }
        else if let months = comps.month, months > 0 {
            let days = comps.day ?? 0
            return "in: \(months) \(unit(months, "month", "months")) \(days) \(unit(days, "day", "days"))"
        }
        else if let days = comps.day, days > 0 {
            let hours = comps.hour ?? 0
            let minutes = comps.minute ?? 0
            let seconds = comps.second ?? 0
            return "in: \(days) \(unit(days, "day", "days")) \(hours) \(unit(hours, "hour", "hours")) \(minutes)m \(seconds)s"
        }
        else if let hours = comps.hour, hours > 0 {
            let minutes = comps.minute ?? 0
            return "in: \(hours) \(unit(hours, "hour", "hours")) \(minutes) \(unit(minutes, "minute", "minutes"))"
        }
        else {
            let minutes = comps.minute ?? 0
            return "in: \(minutes) \(unit(minutes, "minute", "minutes"))"
        }
    }
}


#Preview {
    ContentView()
}
