//
//  ContentView.swift
//  CountdownClock
//
//  Created by Laure Chipman on 12/5/25.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @State private var now = Date()
    @State private var notifiedIDs: Set<UUID> = []

    private let timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if sessionManager.events.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No Events")
                        .font(.headline)
                    Text("Add events on your iPhone")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(sessionManager.events) { event in
                            EventTileView(
                                event: event,
                                now: now,
                                hasNotified: notifiedIDs.contains(event.id)
                            ) {
                                notifiedIDs.insert(event.id)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
            }
        }
        .onReceive(timer) { date in
            now = date
        }
        .onChange(of: sessionManager.events) {
            // Keep a notified ID only if the event still exists AND has already arrived.
            // If the event was rescheduled to the future, drop it so it can notify again.
            notifiedIDs = notifiedIDs.filter { id in
                guard let event = sessionManager.events.first(where: { $0.id == id }) else { return false }
                return Date() >= event.targetDate
            }
        }
    }
}

struct EventTileView: View {
    let event: Event
    let now: Date
    let hasNotified: Bool
    let onNotify: () -> Void

    var hasArrived: Bool { now >= event.targetDate }

    var tileColor: Color {
        if hasArrived { return Color.green.opacity(0.45) }
        if event.isNominated { return Color.blue.opacity(0.4) }
        return Color.purple.opacity(0.4)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(tileColor)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(event.emoji) \(event.title)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if hasArrived {
                        Text("🎉 Arrived!")
                            .font(.headline)
                    } else {
                        Text(countdownText(from: now, to: event.targetDate))
                            .font(.headline)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .onAppear {
            guard hasArrived, !hasNotified else { return }
            onNotify()
            Task {
                await NotificationManager.shared.scheduleEventArrivalNotification(
                    eventTitle: event.title, eventID: event.id
                )
            }
        }
        .onChange(of: hasArrived) { _, arrived in
            guard arrived, !hasNotified else { return }
            onNotify()
            Task {
                await NotificationManager.shared.scheduleEventArrivalNotification(
                    eventTitle: event.title, eventID: event.id
                )
            }
        }
    }

    private func countdownText(from start: Date, to end: Date) -> String {
        if start >= end { return "now!" }
        let effectiveStart = end.timeIntervalSince(start) >= 30 * 86400
            ? Calendar.current.startOfDay(for: start) : start
        let c = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: effectiveStart, to: end)
        let yr = c.year ?? 0
        let mo = c.month ?? 0
        let d  = c.day ?? 0
        let h  = c.hour ?? 0
        let m  = c.minute ?? 0
        let s  = c.second ?? 0
        if yr > 0 { return "\(yr)yr \(mo)mo" }
        if mo > 0 { return "\(mo)mo \(d)d" }
        if d  > 0 { return "\(d)d \(h)h" }
        if h  > 0 { return "\(h)h \(m)m" }
        if m  > 0 { return "\(m)m \(s)s" }
        return "now!"
    }
}

#Preview {
    ContentView()
}
