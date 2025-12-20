//
//  ContentView.swift
//  CountdownClock
//
//  Created by Laure Chipman on 12/5/25.
//

import SwiftUI
import WidgetKit

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
    let eventTitle: String
    let targetDate: Date

    // This holds the current time and updates every second
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(eventTitle) in:")
                .font(.caption)

            Text(formatCountdown(from: now, to: targetDate))
                .font(.body)
        }
        .onReceive(timer) { date in
            // Update the "now" value every second
            now = date
        }
    }

    private func formatCountdown(from start: Date, to end: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: start, to: end)

        if let years = components.year, years > 0 {
            return "\(years)y \(components.month ?? 0)M \(components.day ?? 0)d \(components.hour ?? 0)h \(components.minute ?? 0)m \(components.second ?? 0)s"
        } else if let months = components.month, months > 0 {
            return "\(months)M \(components.day ?? 0)d \(components.hour ?? 0)h \(components.minute ?? 0)m \(components.second ?? 0)s"
        } else {
            return "\(components.day ?? 0)d \(components.hour ?? 0)h\(components.minute ?? 0)m \(components.second ?? 0)s"
        }
    }
}


#Preview {
    ContentView()
}
