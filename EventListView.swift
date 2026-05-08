import SwiftUI

struct EventListView: View {
    @StateObject private var store = EventStore()
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var isPresentingAdd = false
    @State private var isPresentingPaywall = false
    @State private var editedEvent: Event?
    @State private var restoredCount: Int?

    var body: some View {
        NavigationStack {
            List {
                if store.events.isEmpty {
                    VStack(spacing: 8) {
                        Text("No events yet.")
                            .foregroundStyle(.secondary)
                        Text("If you have events on your Watch, open CountdownClock there and they'll appear here automatically.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        if let count = restoredCount {
                            Text("Restored \(count) event\(count == 1 ? "" : "s") from Watch.")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                }
                ForEach(store.events) { event in
                    Button {
                        editedEvent = event
                    } label: {
                        HStack(spacing: 12) {
                            Text(event.emoji)
                                .font(.system(size: 36))
                                .frame(width: 44)
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(.headline)
                                Text(event.targetDate, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if event.isNominated {
                                Label("Shown on Watch", systemImage: "applewatch")
                                    .font(.caption)
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .contextMenu {
                        Button {
                            store.nominate(event.id)
                        } label: {
                            Label("Show on Watch", systemImage: "applewatch")
                        }
                    }
                }
                .onDelete(perform: store.delete)
            }
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addTapped()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                PhoneSessionManager.shared.onEventsReceivedFromWatch = { events in
                    guard store.events.isEmpty, !events.isEmpty else { return }
                    store.restore(events)
                    restoredCount = events.count
                }
            }
            .sheet(item: $editedEvent) { event in
                EventEditorView(
                    event: event,
                    onSave: { store.update($0); editedEvent = nil },
                    onCancel: { editedEvent = nil },
                    onNominate: { store.nominate($0) }
                )
            }
            .sheet(isPresented: $isPresentingAdd) {
                EventEditorView(
                    event: Event(title: "", targetDate: .now),
                    onSave: { store.add($0); isPresentingAdd = false },
                    onCancel: { isPresentingAdd = false },
                    onNominate: { store.nominate($0) }
                )
            }
            .sheet(isPresented: $isPresentingPaywall) {
                PaywallView {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPresentingAdd = true
                    }
                }
            }
        }
    }

    // MARK: - Private

    private func addTapped() {
        if !purchaseManager.isUnlocked && store.events.count >= 1 {
            isPresentingPaywall = true
        } else {
            isPresentingAdd = true
        }
    }
}

#Preview {
    EventListView()
        .environmentObject(PurchaseManager())
}
