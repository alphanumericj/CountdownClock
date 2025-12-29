import WidgetKit
import SwiftUI

// MARK: - Short Countdown Formatting (for small complications)
private func shortCountdownComponents(from now: Date, to target: Date) -> [(String, Int)] {
    let cal = Calendar.current
    let start = min(now, target)
    let end = max(now, target)
    let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: start, to: end)
    var units: [(String, Int)] = []
    if let y = comps.year, y > 0 { units.append(("Y", y)) }
    if let m = comps.month, m > 0 { units.append(("M", m)) }
    if let d = comps.day, d > 0 { units.append(("D", d)) }
    if let h = comps.hour, h > 0 { units.append(("h", h)) }
    if let min = comps.minute, min > 0 { units.append(("m", min)) }
    if let s = comps.second, s > 0 { units.append(("s", s)) }
    return units
}

private func formattedShortCountdown(now: Date, to target: Date) -> String {
    var units = shortCountdownComponents(from: now, to: target)
    if units.isEmpty { return "0s" }
    // Short form: up to 2 leading nonzero units
    units = Array(units.prefix(2))
    return units.map { "\($0.1)\($0.0)" }.joined(separator: " ")
}

// MARK: - Timeline Entry
struct CountdownEntry: TimelineEntry {
    let date: Date
    let eventTitle: String
    let targetDate: Date
}

// MARK: - Timeline Provider
struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(
            date: Date(),
            eventTitle: "Midterms",
            targetDate: Date().addingTimeInterval(3600)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")
        let title = sharedDefaults?.string(forKey: "eventTitle") ?? "*No event"
        let timestamp = sharedDefaults?.double(forKey: "targetDate") ?? 0
        let targetDate = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : Date()
        completion(CountdownEntry(date: Date(), eventTitle: title, targetDate: targetDate))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let currentDate = Date()
        let sharedDefaults = UserDefaults(suiteName: "group.com.chipmania.CountdownClock")
        let title = sharedDefaults?.string(forKey: "eventTitle") ?? "------"
        let timestamp = sharedDefaults?.double(forKey: "targetDate") ?? 0
        let targetDate = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : currentDate

        let entry = CountdownEntry(date: currentDate, eventTitle: title, targetDate: targetDate)
        // Request a refresh roughly every minute to pick up data changes. The timer style handles ticking.
        let timeline = Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(60)))
        completion(timeline)
    }
}

// MARK: - Complication Views using live-updating timer style
struct CountdownCircularView: View {
    var entry: CountdownEntry
    var body: some View {
        if entry.eventTitle == "------" {
            Text("---")
                .font(.caption2)
                .containerBackground(Color.clear, for: .widget)
        } else {
            // Live-updating countdown using short format
            Text(formattedShortCountdown(now: entry.date, to: entry.targetDate))
                .font(.caption2)
                .containerBackground(Color.clear, for: .widget)
        }
    }
}

struct CountdownInlineView: View {
    var entry: CountdownEntry
    var body: some View {
        if entry.eventTitle == "------" {
            Text("---")
                .font(.caption2)
                .containerBackground(Color.clear, for: .widget)
        } else {
            // Live-updating countdown using short format
            Text(formattedShortCountdown(now: entry.date, to: entry.targetDate))
                .font(.caption2)
                .containerBackground(Color.clear, for: .widget)
        }
    }
}

struct CountdownRectangularView: View {
    var entry: CountdownEntry
    var body: some View {
        VStack(alignment: .leading) {
            if entry.eventTitle == "------" {
                Text("---")
                    .font(.caption2)
                    .containerBackground(Color.clear, for: .widget)
            } else {
                Text("\(entry.eventTitle) in:")
                    .font(.caption2)
                    .containerBackground(Color.clear, for: .widget)
                // Live-updating countdown
                Text(entry.targetDate, style: .timer)
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
            CountdownComplicationView(entry: entry)
        }
        .configurationDisplayName("Countdown Clock")
        .description("Shows countdown to your event.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct CountdownComplicationView: View {
    var entry: CountdownEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            if entry.eventTitle == "------" {
                Text("---")
                    .font(.caption2)
                    .containerBackground(Color.clear, for: .widget)
            } else {
                Text(formattedShortCountdown(now: entry.date, to: entry.targetDate))
                    .font(.caption2)
                    .containerBackground(Color.clear, for: .widget)
            }

        case .accessoryInline:
            if entry.eventTitle == "------" {
                Text("---")
                    .containerBackground(Color.clear, for: .widget)
            } else {
                Text(formattedShortCountdown(now: entry.date, to: entry.targetDate))
                    .containerBackground(Color.clear, for: .widget)
            }

        case .accessoryRectangular:
            if entry.eventTitle == "------" {
                VStack(alignment: .leading) {
                    Text("------")
                        .font(.caption2)
                        .containerBackground(Color.clear, for: .widget)
                    Text("------")
                        .font(.footnote)
                        .containerBackground(Color.clear, for: .widget)
                }
            } else {
                VStack(alignment: .leading) {
                    Text("\(entry.eventTitle) in:")
                        .font(.caption2)
                        .containerBackground(Color.clear, for: .widget)
                    Text(entry.targetDate, style: .timer)
                        .font(.footnote)
                        .containerBackground(Color.clear, for: .widget)
                }
            }

        default:
            Text(entry.targetDate, style: .timer)
        }
    }
}

