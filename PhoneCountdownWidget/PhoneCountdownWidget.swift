import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Helpers

private let appGroup = "group.com.chipmania.CountdownClock"
private let indexKey  = "widgetEventIndex"

private func loadEvents() -> [Event] {
    guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: "events.v1"),
          let events = try? JSONDecoder().decode([Event].self, from: data)
    else { return [] }
    return events.sorted { $0.targetDate < $1.targetDate }
}

// Pass `relativeTo` so color is computed for the entry's point in time, not .now at render.
func moodColor(for targetDate: Date, relativeTo ref: Date = .now) -> Color {
    let seconds = targetDate.timeIntervalSince(ref)
    guard seconds > 0 else { return Color(red: 0.20, green: 0.78, blue: 0.35) }  // past: green
    let hours = seconds / 3600.0
    if hours < 1    { return Color(red: 0.73, green: 0.84, blue: 0.42) }  // yellow-green (< 1 h)
    if hours < 5    { return Color(red: 0.96, green: 0.70, blue: 0.15) }  // eggnog     (< 5 h)
    if hours < 24   { return Color(red: 0.92, green: 0.46, blue: 0.08) }  // exotic mushroom (< 24 h)
    if hours < 192  { return Color(red: 0.86, green: 0.07, blue: 0.05) }  // mild red   (1–7 d)
    if hours < 744  { return Color(red: 0.71, green: 0.13, blue: 0.37) }  // wild flower (8–30 d)
    return             Color(red: 0.31, green: 0.23, blue: 0.60)           // casual lavender (31+ d)
}

// Short form for small widget — uses calendar-aware formatter so month counts match the medium widget
private let shortFormatter: DateComponentsFormatter = {
    let f = DateComponentsFormatter()
    f.maximumUnitCount = 2
    f.unitsStyle = .abbreviated
    f.allowedUnits = [.year, .month, .day, .hour, .minute]
    return f
}()

private func countdownText(to date: Date, ref: Date = .now) -> String {
    if date <= ref { return "Now!" }
    let effectiveRef = date.timeIntervalSince(ref) >= 86400
        ? Calendar.current.startOfDay(for: ref) : ref
    return shortFormatter.string(from: effectiveRef, to: date) ?? "?"
}

// Full-word form for medium widget: "2 hours, 40 minutes"
private let fullFormatter: DateComponentsFormatter = {
    let f = DateComponentsFormatter()
    f.maximumUnitCount = 2
    f.unitsStyle = .full
    f.allowedUnits = [.year, .month, .day, .hour, .minute]
    return f
}()

private func fullCountdownText(to date: Date, ref: Date = .now) -> String {
    if date <= ref { return "Now!" }
    let effectiveRef = date.timeIntervalSince(ref) >= 86400
        ? Calendar.current.startOfDay(for: ref) : ref
    return fullFormatter.string(from: effectiveRef, to: date) ?? countdownText(to: date, ref: ref)
}

private let defaultColor = Color(red: 0.28, green: 0.56, blue: 0.90)

// MARK: - App Intent

struct AdvanceEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Event"

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: appGroup)
        let current  = defaults?.integer(forKey: indexKey) ?? 0
        guard let data   = defaults?.data(forKey: "events.v1"),
              let events = try? JSONDecoder().decode([Event].self, from: data),
              !events.isEmpty else { return .result() }
        defaults?.set((current + 1) % events.count, forKey: indexKey)
        return .result()
    }
}

// MARK: - Timeline

struct PhoneCountdownEntry: TimelineEntry {
    let date: Date       // the point in time this entry represents
    let events: [Event]
    let displayIndex: Int

    var displayEvent: Event? {
        guard !events.isEmpty else { return nil }
        return events[displayIndex % events.count]
    }
}

struct PhoneCountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> PhoneCountdownEntry {
        PhoneCountdownEntry(date: .now, events: [
            Event(title: "Summer Vacation", targetDate: .now.addingTimeInterval(86400 * 45), emoji: "✈️"),
            Event(title: "Mom's Birthday",  targetDate: .now.addingTimeInterval(86400 * 7),  emoji: "🎂"),
            Event(title: "New Year's Eve",  targetDate: .now.addingTimeInterval(86400 * 120), emoji: "🎆"),
        ], displayIndex: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (PhoneCountdownEntry) -> Void) {
        let events = loadEvents()
        completion(PhoneCountdownEntry(date: .now, events: events, displayIndex: 0))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PhoneCountdownEntry>) -> Void) {
        let events    = loadEvents()
        let stored    = UserDefaults(suiteName: appGroup)?.integer(forKey: indexKey) ?? 0
        let safeIndex = events.isEmpty ? 0 : stored % events.count
        let now       = Date.now

        // Regular interval entries — frequency based on nearest event
        let soonest = events.first?.targetDate.timeIntervalSince(now) ?? .infinity
        let (step, count): (TimeInterval, Int) = {
            switch soonest {
            case ..<3600:  return (60,   60)  // < 1 h  → every minute for 1 h
            case ..<86400: return (900,  48)  // < 1 d  → every 15 min for 12 h
            default:       return (3600, 24)  // farther → every hour for 24 h
            }
        }()

        var entries = (0..<count).map { i in
            PhoneCountdownEntry(date: now.addingTimeInterval(Double(i) * step),
                                events: events,
                                displayIndex: safeIndex)
        }

        // Add entries at exact event arrival time + color-change thresholds so the
        // widget snaps to "Now!" and correct background color without waiting for
        // the next regular interval.
        for event in events {
            let specialDates: [Date] = [
                event.targetDate,                                      // arrival → green
                event.targetDate.addingTimeInterval(-3_600),           // 1 h out → egg white
                event.targetDate.addingTimeInterval(-5 * 3_600),       // 5 h out → eggnog
                event.targetDate.addingTimeInterval(-24 * 3_600),      // 24 h out → exotic mushroom
                event.targetDate.addingTimeInterval(-7 * 86_400),      // 7 d out → mild red
                event.targetDate.addingTimeInterval(-30 * 86_400),     // 30 d out → wild flower
            ]
            for d in specialDates where d > now {
                if !entries.contains(where: { abs($0.date.timeIntervalSince(d)) < 60 }) {
                    entries.append(PhoneCountdownEntry(date: d, events: events, displayIndex: safeIndex))
                }
            }
        }

        entries.sort { $0.date < $1.date }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Small widget

struct SmallCountdownView: View {
    let entry: PhoneCountdownEntry

    // Use entry.date (not .now) so "Now!" triggers exactly when the arrival entry fires.
    // Smaller font (17 pt) for the .relative case to give "59 minutes, 41 seconds" room to wrap.
    @ViewBuilder
    private func countdownView(for date: Date) -> some View {
        if date <= entry.date {
            Text("Now!")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        } else if date.timeIntervalSince(entry.date) < 86400 {
            Text(date, style: .relative)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(countdownText(to: date, ref: entry.date))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 1)
        }
    }

    var body: some View {
        if let event = entry.displayEvent {
            VStack(spacing: 0) {
                VStack(spacing: 3) {
                    Text(event.emoji)
                        .font(.system(size: 46))
                    countdownView(for: event.targetDate)
                    Text(event.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.90))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if entry.events.count > 1 {
                    HStack {
                        Spacer()
                        Button(intent: AdvanceEventIntent()) {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
            .containerBackground(for: .widget) {
                moodColor(for: event.targetDate, relativeTo: entry.date)
            }
        } else {
            Text("Open iCountdown Clock to add an event")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(for: .widget) { defaultColor }
        }
    }
}

// MARK: - Medium widget

struct MediumCountdownView: View {
    let entry: PhoneCountdownEntry

    @ViewBuilder
    private func countdownView(for date: Date) -> some View {
        let style: Font = .system(size: 26, weight: .bold, design: .rounded)
        if date <= entry.date {
            Text("Now!")
                .font(style).foregroundStyle(.white)
        } else if date.timeIntervalSince(entry.date) < 86400 {
            // Live-updating for < 24 h; .relative stops at "0 seconds" but we intercept
            // before it reaches zero via the arrival timeline entry above.
            Text(date, style: .relative)
                .font(style).foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(fullCountdownText(to: date, ref: entry.date))
                .font(style).foregroundStyle(.white)
                .shadow(color: .black.opacity(0.15), radius: 1)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var body: some View {
        if let event = entry.displayEvent {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Text(event.emoji)
                        .font(.system(size: 72))
                        .frame(width: 84, alignment: .center)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.92))
                            .lineLimit(2)
                        countdownView(for: event.targetDate)
                        Text(event.targetDate, style: .date)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if entry.events.count > 1 {
                    HStack {
                        Text("\(entry.displayIndex + 1) of \(entry.events.count)")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.60))
                        Spacer()
                        Button(intent: AdvanceEventIntent()) {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white.opacity(0.80))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                moodColor(for: event.targetDate, relativeTo: entry.date)
            }
        } else {
            Text("Open iCountdown Clock to add events")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(for: .widget) { defaultColor }
        }
    }
}

// MARK: - Entry view

struct PhoneCountdownWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PhoneCountdownEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallCountdownView(entry: entry)
        default:
            MediumCountdownView(entry: entry)
        }
    }
}

// MARK: - Widget

struct PhoneCountdownWidget: Widget {
    let kind = "PhoneCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PhoneCountdownProvider()) { entry in
            PhoneCountdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Countdown")
        .description("Your upcoming events at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    PhoneCountdownWidget()
} timeline: {
    PhoneCountdownEntry(date: .now, events: [
        Event(title: "Summer Vacation", targetDate: .now.addingTimeInterval(86400 * 45), emoji: "✈️"),
        Event(title: "Mom's Birthday",  targetDate: .now.addingTimeInterval(86400 * 7),  emoji: "🎂"),
    ], displayIndex: 0)
}

#Preview(as: .systemMedium) {
    PhoneCountdownWidget()
} timeline: {
    PhoneCountdownEntry(date: .now, events: [
        Event(title: "Summer Vacation", targetDate: .now.addingTimeInterval(86400 * 45), emoji: "✈️"),
        Event(title: "Mom's Birthday",  targetDate: .now.addingTimeInterval(86400 * 7),  emoji: "🎂"),
        Event(title: "New Year's Eve",  targetDate: .now.addingTimeInterval(86400 * 120), emoji: "🎆"),
    ], displayIndex: 0)
}
