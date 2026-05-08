import Foundation
import WidgetKit

@MainActor
final class EventStore: ObservableObject {
    @Published var events: [Event] = [] {
        didSet { if !isLoading { save() } }
    }
    private var isLoading = false

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
        } catch {}
    }

    func restore(_ restored: [Event]) {
        isLoading = true
        events = restored
        isLoading = false
        save()
        notifyWatchIfNeeded()
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }
        let shared = UserDefaults(suiteName: appGroup)
        guard let data = shared?.data(forKey: storageKey) else {
            print("EventStore.load: no data found for key '\(storageKey)'")
            return
        }
        print("EventStore.load: found \(data.count) bytes")
        do {
            events = try JSONDecoder().decode([Event].self, from: data)
            print("EventStore.load: decoded \(events.count) events OK")
        } catch {
            print("EventStore.load: DECODE FAILED — \(error)")
            // Do NOT overwrite storage — leave corrupt data for investigation
        }
    }

    // MARK: - Watch/Widget Sync
    private func notifyWatchIfNeeded() {
        // Write nominated event to the shared App Group for the lock-screen/watch-face widget
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

        // Send ALL events to the watch app (so it can display all as tiles)
        PhoneSessionManager.shared.sendEvents(events)
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
            if let first = events.first {
                nominate(first.id)
            }
        }
    }
}
