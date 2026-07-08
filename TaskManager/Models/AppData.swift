import Foundation

struct AppData: Codable, Equatable {
    var periods: [PayPeriod]
    var plannerSections: [String]
    var plannerItems: [PlannerItem]
    var groceryCategories: [GroceryCategory]
    var recipes: [Recipe]

    init(
        periods: [PayPeriod],
        plannerSections: [String] = Self.defaultPlannerSections,
        plannerItems: [PlannerItem],
        groceryCategories: [GroceryCategory],
        recipes: [Recipe]
    ) {
        self.periods = periods
        self.plannerSections = plannerSections.isEmpty ? Self.defaultPlannerSections : plannerSections
        self.plannerItems = plannerItems
        self.groceryCategories = groceryCategories
        self.recipes = recipes
    }

    enum CodingKeys: String, CodingKey {
        case periods
        case plannerSections
        case plannerItems
        case groceryCategories
        case recipes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        periods = try container.decode([PayPeriod].self, forKey: .periods)
        plannerSections = try container.decodeIfPresent([String].self, forKey: .plannerSections) ?? Self.defaultPlannerSections
        if plannerSections.isEmpty {
            plannerSections = Self.defaultPlannerSections
        }
        plannerItems = try container.decode([PlannerItem].self, forKey: .plannerItems)
        groceryCategories = try container.decode([GroceryCategory].self, forKey: .groceryCategories)
        recipes = try container.decode([Recipe].self, forKey: .recipes)
    }

    static let defaultPlannerSections = ["Личное", "Мантера", "Красная Поляна"]
}
