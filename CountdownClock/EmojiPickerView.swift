import SwiftUI

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss

    private let categories: [(String, [String])] = [
        ("Celebrations", ["🎉", "🎊", "🥳", "🎂", "🎁", "🎈", "🥂", "🍾", "🪅", "🎆", "🎇", "🏆", "🥇"]),
        ("Travel",       ["✈️", "🏖️", "🏝️", "🗺️", "🌍", "🗼", "🏔️", "⛵", "🚢", "🚂", "🏕️", "🌄", "🧳"]),
        ("Holidays",     ["🎄", "🎃", "🐰", "🦃", "🕎", "🎋", "🎍", "🏮", "🎑", "🌸", "❄️", "☃️"]),
        ("Family",       ["💒", "💍", "👶", "🏠", "❤️", "👨‍👩‍👧‍👦", "🐣", "🌷", "🤱"]),
        ("Health",       ["🏃", "🏋️", "🧘", "💪", "🏅", "🎯", "🚴", "🧗", "🏊", "🩺"]),
        ("School & Work",["🎓", "📚", "💼", "📝", "🎤", "💡", "🔬", "🏛️", "📊"]),
        ("Sports",       ["⚽", "🏈", "🎾", "⛳", "🎿", "🏄", "🏀", "⚾", "🎳", "🏒", "🎣"]),
        ("Food & Drink", ["🍕", "🍰", "🥗", "🍣", "☕", "🧁", "🍺", "🫖", "🥘"]),
        ("Nature",       ["🌈", "🌟", "⭐", "🔥", "🌊", "🌺", "🦋", "🐶", "🐱", "🦁", "🌙", "☀️"]),
        ("Music & Art",  ["🎵", "🎸", "🎹", "🎺", "🎨", "🎭", "🎬", "🎮", "📷"]),
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(categories, id: \.0) { name, emojis in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)
                            LazyVGrid(columns: columns, spacing: 6) {
                                ForEach(emojis, id: \.self) { emoji in
                                    Button {
                                        selectedEmoji = emoji
                                        dismiss()
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 30))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 4)
                                            .background(
                                                selectedEmoji == emoji
                                                    ? Color.accentColor.opacity(0.15)
                                                    : Color.clear
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    EmojiPickerView(selectedEmoji: .constant("🎉"))
}
