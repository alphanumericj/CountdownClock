import Foundation

struct Event: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var targetDate: Date
    var isNominated: Bool = false
}
