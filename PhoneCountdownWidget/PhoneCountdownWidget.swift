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

func moodColor(for date: Date) -> Color {
    let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
    switch days {
    case ..<0:   return Color(red: 0.20, green: 0.78, blue: 0.35)
    case 0:      return Color(red: 0.98, green: 0.75, blue: 0.05)
    case 1...7:  return Color(red: 0.98, green: 0.48, blue: 0.10)
    case 8...30: return Color(red: 0.95, green: 0.68, blue: 0.10)
    default:     return Color(red: 0.28, green: 0.56, blue: 0.90)
    }
}

// Short form for small widget
private func countdownText(to date: Date) -> String {
    let now = Date.now
    if date <= now { return "Today!" }
    let c = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: date)
    let days = c.day ?? 0; let hours = c.hour ?? 0; let minutes = c.minute ?? 0
    if days > 365 { return "\(days / 365)y \(days % 365 / 30)mo" }
    if days > 30  { return "\(days / 30)mo \(days % 30)d" }
    if days > 0   { return "\(days)d \(hours)h" }
    if hours > 0  { return "\(hours)h \(minutes)m" }
    return "\(minutes)m"
}

// Full-word form for medium widget: "2 hours, 40 minutes"
private let fullFormatter: DateComponentsFormatter = {
    let f = DateComponentsFormatter()
    f.maximumUnitCount = 2
    f.unitsStyle = .full
    f.allowedUnits = [.year, .month, .day, .hour, .minute]
    return f
}()

private func fullCountdownText(to date: Date) -> String {
    let now = Date.now
    if date <= now { return "Today! 🎉" }
    return fullFormatter.string(from: now, to: date) ?? countdownText(to: date)
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
    let date: Date
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

        // Generate entries at intervals matched to how soon the nearest event is,
        // so the small widget text stays accurate.
        let soonest = events.first?.targetDate.timeIntervalSince(now) ?? .infinity
        let (step, count): (TimeInterval, Int) = {
            switch soonest {
            case ..<3600:   return (60,   60)   // < 1 h  → every minute for 1 h
            case ..<86400:  return (900,  48)   // < 1 d  → every 15 min for 12 h
            default:        return (3600, 24)   // farther → every hour for 24 h
            }
        }()

        let entries = (0..<count).map { i in
            PhoneCountdownEntry(date: now.addingTimeInterval(Double(i) * step),
                                events: events,
                                displayIndex: safeIndex)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Small widget

struct SmallCountdownView: View {
    let entry: PhoneCountdownEntry

    private var event: Event? {
        entry.events.first(where: { $0.isNominated }) ?? entry.events.first
    }

    @ViewBuilder
    private func countdownView(for date: Date) -> some View {
        let style: Font = .system(size: 20, weight: .bold, design: .rounded)
        if date <= .now {
            Text("Today! 🎉")
                .font(style).foregroundStyle(.white)
        } else if date.timeIntervalSinceNow < 86400 {
            Text(date, style: .relative)
                .font(style).foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        } else {
            Text(countdownText(to: date))
                .font(style).foregroundStyle(.white)
                .shadow(radius: 1)
        }
    }

    var body: some View {
        if let event {
            VStack(spacing: 4) {
                Text(event.emoji)
                    .font(.system(size: 48))
                countdownView(for: event.targetDate)
                Text(event.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.90))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) { moodColor(for: event.targetDate) }
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

    // Live-updating for < 24 h (where every minute matters);
    // full-word custom text for ≥ 24 h (hourly timeline refresh is accurate enough).
    @ViewBuilder
    private func countdownView(for date: Date) -> some View {
        let style: Font = .system(size: 26, weight: .bold, design: .rounded)
        if date <= .now {
            Text("Today! 🎉")
                .font(style).foregroundStyle(.white)
        } else if date.timeIntervalSinceNow < 86400 {
            Text(date, style: .relative)
                .font(style).foregroundStyle(.white)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
        } else {
            Text(fullCountdownText(to: date))
                .font(style).foregroundStyle(.white)
                .shadow(color: .black.opacity(0.15), radius: 1)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
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
            .containerBackground(for: .widget) { moodColor(for: event.targetDate) }
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
