import Foundation

struct Event: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var targetDate: Date
    var isNominated: Bool = false
    var emoji: String = "🎉"

    private enum CodingKeys: String, CodingKey {
        case id, title, targetDate, isNominated, emoji
    }

    // Custom decoder so old saved events (without emoji) load fine
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,   forKey: .id)
        title       = try c.decode(String.self, forKey: .title)
        targetDate  = try c.decode(Date.self,   forKey: .targetDate)
        isNominated = try c.decode(Bool.self,   forKey: .isNominated)
        emoji       = (try? c.decodeIfPresent(String.self, forKey: .emoji)) ?? "🎉"
    }

    init(id: UUID = UUID(), title: String, targetDate: Date, isNominated: Bool = false, emoji: String = "🎉") {
        self.id          = id
        self.title       = title
        self.targetDate  = targetDate
        self.isNominated = isNominated
        self.emoji       = emoji
    }
}
