import SwiftUI

struct EventListView: View {
    @StateObject private var store = EventStore()
    @State private var isPresentingAdd = false
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
                                Label("Nominated", systemImage: "applewatch")
                                    .font(.caption)
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .contextMenu {
                        Button {
                            store.nominate(event.id)
                        } label: {
                            Label("Nominate for Watch", systemImage: "applewatch")
                        }
                    }
                }
                .onDelete(perform: store.delete)
            }
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAdd = true
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
        }
    }
}

#Preview {
    EventListView()
}
