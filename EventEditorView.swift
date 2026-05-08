import SwiftUI

struct EventEditorView: View {
    @State var event: Event
    @State private var showingEmojiPicker = false
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
                Section("Icon") {
                    Button {
                        showingEmojiPicker = true
                    } label: {
                        HStack(spacing: 16) {
                            Text(event.emoji)
                                .font(.system(size: 48))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Event Icon")
                                    .foregroundStyle(.primary)
                                    .font(.body)
                                Text("Tap to change")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section {
                    Toggle("Show on Watch", isOn: $event.isNominated)
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
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $event.emoji)
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
