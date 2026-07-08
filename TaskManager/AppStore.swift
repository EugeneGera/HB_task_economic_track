import Foundation

final class AppStore: ObservableObject {
    @Published var data: AppData {
        didSet {
            scheduleSave()
        }
    }

    private let fileURL: URL
    private var saveWorkItem: DispatchWorkItem?

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent("task-manager-data.json")

        if let savedData = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder.appDecoder.decode(AppData.self, from: savedData) {
            data = decoded
        } else {
            data = AppData.defaultData
        }
    }

    deinit {
        saveImmediately()
    }

    func resetToDefaultData() {
        data = AppData.defaultData
    }

    func saveImmediately() {
        saveWorkItem?.cancel()
        save()
    }

    private func scheduleSave() {
        saveWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.save()
        }
        saveWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }

    private func save() {
        guard let encoded = try? JSONEncoder.appEncoder.encode(data) else {
            return
        }

        try? encoded.write(to: fileURL, options: [.atomic])
    }
}

extension JSONDecoder {
    static var appDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    static var appEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension AppData {
    static var defaultData: AppData {
        AppData(
            periods: [
                PayPeriod(
                    title: "10.7-24.7.26",
                    startDate: Date.make(year: 2026, month: 7, day: 10),
                    endDate: Date.make(year: 2026, month: 7, day: 24),
                    incomes: [
                        MoneyEntry(title: "mantera", amount: 60_000, kind: nil),
                        MoneyEntry(title: "кэш", amount: 0, kind: nil)
                    ],
                    fixedExpenses: [
                        MoneyEntry(title: "еда", amount: 20_000, kind: .fixed),
                        MoneyEntry(title: "коммуналка", amount: 3_500, kind: .fixed),
                        MoneyEntry(title: "маник", amount: 2_200, kind: .fixed),
                        MoneyEntry(title: "проезд", amount: 500, kind: .fixed),
                        MoneyEntry(title: "педикюр", amount: 0, kind: .fixed),
                        MoneyEntry(title: "зал", amount: 1_600, kind: .fixed),
                        MoneyEntry(title: "бассейн", amount: 0, kind: .fixed),
                        MoneyEntry(title: "психолог", amount: 5_000, kind: .fixed),
                        MoneyEntry(title: "лазер", amount: 2_000, kind: .fixed),
                        MoneyEntry(title: "подолог", amount: 1_000, kind: .fixed)
                    ],
                    oneTimeExpenses: [
                        MoneyEntry(title: "копилка", amount: 15_000, kind: .oneTime),
                        MoneyEntry(title: "на лето", amount: 5_000, kind: .oneTime),
                        MoneyEntry(title: "кок", amount: 2_500, kind: .oneTime)
                    ],
                    note: "Планы по крупным тратам: дни рождения, праздники, накопления."
                )
            ],
            plannerItems: Self.defaultPlannerItems,
            groceryCategories: Self.defaultGroceryCategories,
            recipes: [
                Recipe(
                    title: "Сырники",
                    ingredients: "творог, яйца, мука, сгущенка",
                    instructions: "Смешать ингредиенты, сформировать сырники и обжарить до румяной корочки.",
                    nutrition: "КБЖУ можно заполнить позже"
                ),
                Recipe(
                    title: "Салат с авокадо",
                    ingredients: "руккола, помидоры, авокадо, моцарелла, семечки",
                    instructions: "Нарезать овощи, добавить моцареллу и семечки, заправить по вкусу.",
                    nutrition: "КБЖУ можно заполнить позже"
                )
            ]
        )
    }

    private static var defaultPlannerItems: [PlannerItem] {
        let today = Date()
        return [
            PlannerItem(date: today, section: "Личное", title: "Разобрать личные задачи на неделю", time: "", isDone: false, order: 0),
            PlannerItem(date: today, section: "Мантера", title: "Проверить рабочий список", time: "11:00", isDone: false, order: 0),
            PlannerItem(date: today, section: "Красная Поляна", title: "Записать ближайшие действия", time: "", isDone: false, order: 0)
        ]
    }

    private static var defaultGroceryCategories: [GroceryCategory] {
        [
            GroceryCategory(name: "ЗАВТРАК", items: [
                GroceryItem(name: "молоко", note: "", isChecked: false),
                GroceryItem(name: "овсянка", note: "", isChecked: false),
                GroceryItem(name: "яйца", note: "", isChecked: false),
                GroceryItem(name: "сыр", note: "", isChecked: false),
                GroceryItem(name: "индилайт грудинка", note: "", isChecked: false),
                GroceryItem(name: "творог 5%", note: "", isChecked: false),
                GroceryItem(name: "йогурт греческий", note: "", isChecked: false),
                GroceryItem(name: "хлеб черный", note: "", isChecked: false),
                GroceryItem(name: "творог на сырники", note: "", isChecked: false),
                GroceryItem(name: "сгущенка", note: "Жене", isChecked: false)
            ]),
            GroceryCategory(name: "ФРУКТЫ", items: [
                GroceryItem(name: "киви", note: "", isChecked: false),
                GroceryItem(name: "яблоки", note: "", isChecked: false),
                GroceryItem(name: "заморож клубника", note: "", isChecked: false),
                GroceryItem(name: "лимон", note: "", isChecked: false)
            ]),
            GroceryCategory(name: "САЛАТ", items: [
                GroceryItem(name: "руккола", note: "", isChecked: false),
                GroceryItem(name: "помидоры", note: "", isChecked: false),
                GroceryItem(name: "авокадо", note: "", isChecked: false),
                GroceryItem(name: "моцарелла", note: "", isChecked: false),
                GroceryItem(name: "семечки тыкв", note: "", isChecked: false),
                GroceryItem(name: "черри", note: "Жене", isChecked: false),
                GroceryItem(name: "огурцы", note: "Жене", isChecked: false)
            ]),
            GroceryCategory(name: "ГАРНИР", items: [
                GroceryItem(name: "гречка", note: "", isChecked: false),
                GroceryItem(name: "картошка", note: "", isChecked: false),
                GroceryItem(name: "макароны", note: "", isChecked: false)
            ]),
            GroceryCategory(name: "МЯСО", items: [
                GroceryItem(name: "фарш самсон", note: "", isChecked: false),
                GroceryItem(name: "куриное филе", note: "", isChecked: false),
                GroceryItem(name: "печень", note: "", isChecked: false),
                GroceryItem(name: "говядина", note: "", isChecked: false),
                GroceryItem(name: "стрипсы", note: "", isChecked: false)
            ]),
            GroceryCategory(name: "ДР ЗАПАСЫ", items: [
                GroceryItem(name: "масло сливочное", note: "", isChecked: false),
                GroceryItem(name: "масло растительное", note: "", isChecked: false),
                GroceryItem(name: "сметана", note: "", isChecked: false),
                GroceryItem(name: "соль", note: "", isChecked: false),
                GroceryItem(name: "сахар", note: "", isChecked: false),
                GroceryItem(name: "чай черный зеленый", note: "", isChecked: false)
            ]),
            GroceryCategory(name: "МЫЛЬНОЕ", items: [
                GroceryItem(name: "туалетная бумага", note: "", isChecked: false),
                GroceryItem(name: "шарики для туалета", note: "", isChecked: false),
                GroceryItem(name: "зубная паста", note: "", isChecked: false),
                GroceryItem(name: "чистящее средство для унитаза", note: "", isChecked: false),
                GroceryItem(name: "чистящее средство для раковин", note: "", isChecked: false),
                GroceryItem(name: "ежедневки", note: "", isChecked: false),
                GroceryItem(name: "прокладки", note: "", isChecked: false)
            ])
        ]
    }
}

extension Date {
    static func make(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.year = year
        components.month = month
        components.day = day
        return components.date ?? Date()
    }
}
