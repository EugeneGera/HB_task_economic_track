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
    var nutrition: String
}
