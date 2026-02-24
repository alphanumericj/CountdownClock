
import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct CountdownEntry: TimelineEntry {
    let date: Date
    let eventTitle: String
    let targetDate: Date
    let hasEvent: Bool
}

// MARK: - Timeline Provider
struct CountdownProvider: TimelineProvider {

    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(
            date: Date(),
            eventTitle: "Sample Event",
            targetDate: Date().addingTimeInterval(3600),
            hasEvent: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")

        let title = sharedDefaults?.string(forKey: "eventTitle")
        let timestamp = sharedDefaults?.double(forKey: "targetDate") ?? 0

        let hasEvent = (title != nil && timestamp > 0)
        let eventTitle = title ?? "------"
        let targetDate = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : Date()

        completion(
            CountdownEntry(
                date: Date(),
                eventTitle: eventTitle,
                targetDate: targetDate,
                hasEvent: hasEvent
            )
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {

        let now = Date()
        let sharedDefaults = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")

        let title = sharedDefaults?.string(forKey: "eventTitle")
        let timestamp = sharedDefaults?.double(forKey: "targetDate") ?? 0

        let hasEvent = (title != nil && timestamp > 0)
        let eventTitle = title ?? "------"
        let targetDate = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : now

        // Entry for "now"
        let entryNow = CountdownEntry(
            date: now,
            eventTitle: eventTitle,
            targetDate: targetDate,
            hasEvent: hasEvent
        )

        // Entry for the exact arrival moment
        let entryArrival = CountdownEntry(
            date: targetDate,
            eventTitle: eventTitle,
            targetDate: targetDate,
            hasEvent: hasEvent
        )

        // After arrival, refresh again 1 minute later
        let refresh = max(now, targetDate).addingTimeInterval(60)

        let timeline = Timeline(
            entries: [entryNow, entryArrival],
            policy: .after(refresh)
        )

        completion(timeline)
    }
}

// MARK: - Widget Declaration
@main
struct CountdownWidget: Widget {
    let kind: String = "CountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownProvider()) { entry in
            CountdownComplicationView(entry: entry)
        }
        .configurationDisplayName("Countdown Clock")
        .description("Shows countdown to your event.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

// MARK: - Complication View
struct CountdownComplicationView: View {
    var entry: CountdownEntry
    @Environment(\.widgetFamily) var family

    var arrived: Bool {
        entry.hasEvent && entry.date >= entry.targetDate
    }

    var body: some View {
        switch family {

        // -------------------------
        // CIRCULAR
        // -------------------------
        case .accessoryCircular:
            if !entry.hasEvent {
                Text("---")
                    .font(.caption2)
                    .containerBackground(Color.clear, for: .widget)

            } else if arrived {
                Text("0:00")
                    .font(.caption2)
                    .containerBackground(Color.clear, for: .widget)

            } else {
                Text(entry.targetDate, style: .timer)
                    .font(.caption2)
                    .containerBackground(Color.clear, for: .widget)
            }

        // -------------------------
        // INLINE
        // -------------------------
        case .accessoryInline:
            if !entry.hasEvent {
                Text("---")
                    .containerBackground(Color.clear, for: .widget)

            } else if arrived {
                Text("0:00")
                    .containerBackground(Color.clear, for: .widget)

            } else {
                Text(entry.targetDate, style: .timer)
                    .font(.footnote)
                    .containerBackground(Color.clear, for: .widget)
            }

        // -------------------------
        // RECTANGULAR
        // -------------------------
        case .accessoryRectangular:
            if !entry.hasEvent {
                VStack(alignment: .leading) {
                    Text("------")
                        .font(.caption2)
                    Text("------")
                        .font(.footnote)
                }
                .containerBackground(Color.clear, for: .widget)

            } else if arrived {
                VStack(alignment: .leading) {
                    Text(entry.eventTitle)
                        .font(.caption2)
                    Text("Arrived!")
                        .font(.footnote)
                }
                .containerBackground(Color.clear, for: .widget)

            } else {
                VStack(alignment: .leading) {
                    Text("\(entry.eventTitle) in:")
                        .font(.caption2)
                    Text(entry.targetDate, style: .timer)
                        .font(.footnote)
                }
                .containerBackground(Color.clear, for: .widget)
            }

        default:
            Text(entry.targetDate, style: .timer)
        }
    }
}
