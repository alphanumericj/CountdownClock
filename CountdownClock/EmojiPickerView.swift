import SwiftUI

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

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

    private var displayCategories: [(String, [String])] {
        guard !searchText.isEmpty else { return categories }
        let query = searchText.lowercased()
        let matches = categories.flatMap(\.1).filter { emoji in
            emoji.unicodeScalars.contains {
                $0.properties.name?.lowercased().contains(query) ?? false
            }
        }
        return matches.isEmpty ? [] : [("Results", matches)]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search emoji", text: $searchText)
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                ScrollView {
                    if displayCategories.isEmpty && !searchText.isEmpty {
                        Text("No results for \"\(searchText)\"")
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                            .frame(maxWidth: .infinity)
                    } else {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(displayCategories, id: \.0) { name, emojis in
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
                }
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
