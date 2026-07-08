import Foundation

struct GroceryItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var note: String
    var isChecked: Bool
}

struct GroceryCategory: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var items: [GroceryItem]
}

struct Recipe: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var ingredients: String
    var instructions: String
    var proteinPer100g: Double
    var fatPer100g: Double
    var carbsPer100g: Double

    var caloriesPer100g: Double {
        proteinPer100g * 4 + fatPer100g * 9 + carbsPer100g * 4
    }

    init(
        id: UUID = UUID(),
        title: String,
        ingredients: String,
        instructions: String,
        proteinPer100g: Double = 0,
        fatPer100g: Double = 0,
        carbsPer100g: Double = 0
    ) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.proteinPer100g = proteinPer100g
        self.fatPer100g = fatPer100g
        self.carbsPer100g = carbsPer100g
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case ingredients
        case instructions
        case proteinPer100g
        case fatPer100g
        case carbsPer100g
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        ingredients = try container.decode(String.self, forKey: .ingredients)
        instructions = try container.decode(String.self, forKey: .instructions)
        proteinPer100g = try container.decodeIfPresent(Double.self, forKey: .proteinPer100g) ?? 0
        fatPer100g = try container.decodeIfPresent(Double.self, forKey: .fatPer100g) ?? 0
        carbsPer100g = try container.decodeIfPresent(Double.self, forKey: .carbsPer100g) ?? 0
    }
}
