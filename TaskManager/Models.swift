import Foundation

enum ExpenseKind: String, Codable, CaseIterable, Identifiable {
    case fixed
    case oneTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fixed:
            return "Постоянные"
        case .oneTime:
            return "Разовые"
        }
    }
}

struct MoneyEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var amount: Double
    var kind: ExpenseKind?
}

struct PayPeriod: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var startDate: Date
    var endDate: Date
    var incomes: [MoneyEntry]
    var fixedExpenses: [MoneyEntry]
    var oneTimeExpenses: [MoneyEntry]
    var note: String

    var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.amount }
    }

    var totalFixed: Double {
        fixedExpenses.reduce(0) { $0 + $1.amount }
    }

    var totalOneTime: Double {
        oneTimeExpenses.reduce(0) { $0 + $1.amount }
    }

    var totalExpenses: Double {
        totalFixed + totalOneTime
    }

    var balance: Double {
        totalIncome - totalExpenses
    }
}

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
