import SwiftUI

struct EventListView: View {
    @StateObject private var store = EventStore()
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var isPresentingAdd = false
    @State private var isPresentingPaywall = false
    @State private var editedEvent: Event?

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.events) { event in
                    Button {
                        editedEvent = event
                    } label: {
                        HStack {
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
                    // Called after the paywall dismisses on successful purchase.
                    // Small delay lets the paywall sheet fully close before
                    // the add-event sheet opens.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPresentingAdd = true
                    }
                }
            }
        }
    }

    // MARK: - Private

    private func addTapped() {
        // Free tier: allow only one event at a time.
        // Purchased: unlimited.
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
