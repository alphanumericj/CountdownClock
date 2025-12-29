import Foundation
import WidgetKit

@MainActor
final class EventStore: ObservableObject {
    @Published var events: [Event] = [] {
        didSet { save() }
    }

    private let storageKey = "events.v1"
    private let appGroup = "group.com.chipmania.CountdownClock"

    init() {
        load()
    }

    func add(_ event: Event) {
        var new = event
        // If this is the first event, nominate it by default
        if events.isEmpty { new.isNominated = true }
        events.append(new)
        if new.isNominated { enforceSingleNomination(for: new.id) }
        notifyWatchIfNeeded()
    }

    func update(_ event: Event) {
        guard let idx = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[idx] = event
        if event.isNominated { enforceSingleNomination(for: event.id) }
        notifyWatchIfNeeded()
    }

    func delete(at offsets: IndexSet) {
        events.remove(atOffsets: offsets)
        // If no nominated event remains, nominate the first if any
        if nominatedEvent == nil, let first = events.first {
            nominate(first.id)
        } else {
            notifyWatchIfNeeded()
        }
    }

    func nominate(_ id: UUID) {
        events = events.map { e in
            var copy = e
            copy.isNominated = (e.id == id)
            return copy
        }
        notifyWatchIfNeeded()
    }

    var nominatedEvent: Event? { events.first(where: { $0.isNominated }) }

    // MARK: - Persistence
    private func save() {
        do {
            let data = try JSONEncoder().encode(events)
            let shared = UserDefaults(suiteName: appGroup)
            shared?.set(data, forKey: storageKey)
            shared?.synchronize()
        } catch {
            // Handle encoding error if desired
        }
    }

    private func load() {
        let shared = UserDefaults(suiteName: appGroup)
        if let data = shared?.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            events = decoded
        } else {
            events = []
        }
    }

    // MARK: - Watch/Widget Sync
    private func notifyWatchIfNeeded() {
        // Write nominated event to the shared App Group for widgets
        let shared = UserDefaults(suiteName: appGroup)
        if let nominated = nominatedEvent {
            shared?.set(nominated.title, forKey: "eventTitle")
            shared?.set(nominated.targetDate.timeIntervalSince1970, forKey: "targetDate")
        } else {
            shared?.removeObject(forKey: "eventTitle")
            shared?.removeObject(forKey: "targetDate")
        }
        shared?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()

        // Send to watch using existing PhoneSessionManager if present
        #if canImport(SwiftUI)
        PhoneSessionManager.shared.sendCountdownSettings(
            eventTitle: nominatedEvent?.title ?? "",
            targetDate: nominatedEvent?.targetDate ?? Date()
        )
        #endif
    }

    private func enforceSingleNomination(for id: UUID) {
        var found = false
        events = events.map { event in
            var copy = event
            if copy.id == id {
                copy.isNominated = true
                found = true
            } else if copy.isNominated {
                copy.isNominated = false
            }
            return copy
        }
        if !found {
            // Ensure at most one nomination
            if let first = events.first {
                nominate(first.id)
            }
        }
    }
}
