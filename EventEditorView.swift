import SwiftUI

struct EventEditorView: View {
    @State var event: Event
    var onSave: (Event) -> Void
    var onCancel: () -> Void
    var onNominate: (UUID) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $event.title)
                    DatePicker("Target date", selection: $event.targetDate, displayedComponents: [.date, .hourAndMinute])
                }
                Section {
                    Toggle("Nominate for Watch", isOn: $event.isNominated)
                        .onChange(of: event.isNominated) { _, newValue in
                            if newValue { onNominate(event.id) }
                        }
                }
            }
            .navigationTitle(event.title.isEmpty ? "New Event" : "Edit Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(event)
                    }
                    .disabled(event.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    EventEditorView(
        event: Event(title: "Demo", targetDate: .now.addingTimeInterval(3600)),
        onSave: { _ in },
        onCancel: {},
        onNominate: { _ in }
    )
}
