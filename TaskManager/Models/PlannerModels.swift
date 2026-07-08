import Foundation

struct PlannerItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var section: String
    var title: String
    var time: String
    var isDone: Bool
    var order: Int

    init(
        id: UUID = UUID(),
        date: Date,
        section: String,
        title: String,
        time: String,
        isDone: Bool,
        order: Int = 0
    ) {
        self.id = id
        self.date = date
        self.section = section
        self.title = title
        self.time = time
        self.isDone = isDone
        self.order = order
    }

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case section
        case title
        case time
        case isDone
        case order
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        section = try container.decode(String.self, forKey: .section)
        title = try container.decode(String.self, forKey: .title)
        time = try container.decode(String.self, forKey: .time)
        isDone = try container.decode(Bool.self, forKey: .isDone)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
    }
}
