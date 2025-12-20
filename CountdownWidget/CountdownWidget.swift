import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct CountdownEntry: TimelineEntry {
    let date: Date
    let eventTitle: String
    let targetDate: Date
}

// MARK: - Timeline Provider
struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: Date(), eventTitle: "Midterms",
                       targetDate: Date().addingTimeInterval(3600))
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        //let title = UserDefaults.standard.string(forKey: "eventTitle") ?? "No event"
        //let timestamp = UserDefaults.standard.double(forKey: "targetDate")
        let sharedDefaults = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")
        let title = sharedDefaults?.string(forKey: "eventTitle") ?? "*No event"
        let timestamp = sharedDefaults?.double(forKey: "targetDate") ?? 0
        let targetDate = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : Date()
        completion(CountdownEntry(date: Date(), eventTitle: title, targetDate: targetDate))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let currentDate = Date()
        //let title = UserDefaults.standard.string(forKey: "eventTitle") ?? "ccNo event"
        //let timestamp = UserDefaults.standard.double(forKey: "targetDate")
        let sharedDefaults = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")
        let title = sharedDefaults?.string(forKey: "eventTitle") ?? "------"
        let timestamp = sharedDefaults?.double(forKey: "targetDate") ?? 0


        let targetDate = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : currentDate

        let entry = CountdownEntry(date: currentDate, eventTitle: title, targetDate: targetDate)
        let timeline = Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(60)))
        completion(timeline)
    }
}

// MARK: - Complication Views
struct CountdownCircularView: View {
    var entry: CountdownEntry
    var body: some View {
        if(entry.eventTitle == "------")
        {
            Text("---")
                .font(.caption2)
                .containerBackground(Color.clear, for: .widget)
        }
        else
        {
            Text(shortCountdownString(from: entry.date, to: entry.targetDate))
                .font(.caption2)
                .containerBackground(Color.clear, for: .widget)
        }

    }
}

struct CountdownInlineView: View {
    var entry: CountdownEntry
    var body: some View {
        if(entry.eventTitle == "------")
        {
            Text("---")
                .font(.caption2)
                .containerBackground(Color.clear, for: .widget)
        }
        else
        {
            Text(shortCountdownString(from: entry.date, to: entry.targetDate))
                .font(.caption2)
                .containerBackground(Color.clear, for: .widget)
        }
    }
}

struct CountdownRectangularView: View {
    var entry: CountdownEntry
    var body: some View {
        VStack(alignment: .leading) {
            if(entry.eventTitle == "------")
            {
                Text("---")
                    .font(.caption2)
                    .containerBackground(Color.clear, for: .widget)
            }
            else
            {
                Text("\(entry.eventTitle) in:")
                    .font(.caption2)
                    .containerBackground(Color.clear, for: .widget)
                Text(longCountdownString(from: entry.date, to: entry.targetDate))
                    .font(.footnote)
                    .containerBackground(Color.clear, for: .widget)
            }

        }
    }
}

// MARK: - Widget Declaration
@main
struct CountdownWidget: Widget {
    let kind: String = "CountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownProvider()) { entry in
            CountdownComplicationView(entry: entry)   // 👈 single view
        }
        .configurationDisplayName("Countdown Clock")
        .description("Shows countdown to your event.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}
struct CountdownComplicationView: View {
    var entry: CountdownEntry
    @Environment(\.widgetFamily) var family   // 👈 environment gives you the family

    var body: some View {
        switch family {
        case .accessoryCircular:
            Text(shortCountdownString(from: entry.date, to: entry.targetDate))
                .font(.caption2)
                .containerBackground(Color.clear, for: .widget)
        case .accessoryInline:
            Text(shortCountdownString(from: entry.date, to: entry.targetDate))
                .containerBackground(Color.clear, for: .widget)
        case .accessoryRectangular:
            if(entry.eventTitle == "------")
            {
                VStack(alignment: .leading) {
                    Text("------")
                        .font(.caption2)
                        .containerBackground(Color.clear, for: .widget)
                    Text("------")
                        .font(.footnote)
                        .containerBackground(Color.clear, for: .widget)
                }
            }
            else
            {
                VStack(alignment: .leading) {
                    Text("\(entry.eventTitle) in:")
                        .font(.caption2)
                        .containerBackground(Color.clear, for: .widget)
                    Text(longCountdownString(from: entry.date, to: entry.targetDate))
                        .font(.footnote)
                        .containerBackground(Color.clear, for: .widget)
            }

            }

        default:
            Text(shortCountdownString(from: entry.date, to: entry.targetDate))
        }
    }
}

