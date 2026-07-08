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
