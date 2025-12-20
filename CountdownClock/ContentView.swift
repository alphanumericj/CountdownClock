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
    var body: some View {
        CountdownView(
            eventTitle: "Midterms",
            targetDate: Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 3))!
        )
        .padding()
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
        let entry = CountdownEntry(date: Date(), eventTitle: "Midterms", targetDate: Date().addingTimeInterval(3600))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        var entries: [CountdownEntry] = []
        let currentDate = Date()
        let targetDate = Date(timeIntervalSinceNow: 60*60*24*300) // Example: 300 days from now

        // Generate entries every minute until target date
        for minuteOffset in 0..<60*24*7 { // one week of updates
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = CountdownEntry(date: entryDate, eventTitle: "Midterms", targetDate: targetDate)
            entries.append(entry)
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}



struct CountdownView: View {
    let eventTitle: String
    let targetDate: Date
    @State private var showingSetup = false

    var body: some View {
        ZStack {
            // Centered countdown text
            VStack {
                Text("\(eventTitle) in:")
                    .font(.caption)
                Text(formatCountdown(from: Date(), to: targetDate))
                    .font(.body)
            }
            .multilineTextAlignment(.center)

            // Gear icon in top-right corner
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showingSetup = true
                    } label: {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showingSetup) {
            CountdownClockSetupView { title, date in
                UserDefaults.standard.set(title, forKey: "eventTitle")
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "targetDate")
                PhoneSessionManager.shared.sendCountdownSettings(eventTitle: title, targetDate: date)
                
                showingSetup = false
            }
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
