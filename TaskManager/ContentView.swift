import SwiftUI

#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct ContentView: View {
    var body: some View {
        TabView {
            FinanceView()
                .tabItem {
                    Label("Финансы", systemImage: "rublesign.circle")
                }

            PlannerView()
                .tabItem {
                    Label("Ежедневник", systemImage: "calendar")
                }

            ProductsView()
                .tabItem {
                    Label("Продукты", systemImage: "basket")
                }
        }
    }
}

struct FinanceView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedPeriodID: UUID?
    @State private var entryTarget: EntryTarget?
    @State private var isAddingPeriod = false
    @State private var isShowingAllPeriods = false
    @State private var periodToDelete: PayPeriod?

    var body: some View {
        NavigationStack {
            Group {
                if store.data.periods.isEmpty {
                    EmptyStateView(title: "Нет периодов", subtitle: "Добавьте первый зарплатный период.")
                } else {
                    VStack(spacing: 0) {
                        periodPicker

                        if let index = selectedPeriodIndex {
                            PeriodDetailView(
                                period: $store.data.periods[index],
                                copySources: copySources(for: store.data.periods[index]),
                                onAddIncome: { entryTarget = .income },
                                onAddFixedExpense: { entryTarget = .fixedExpense },
                                onAddOneTimeExpense: { entryTarget = .oneTimeExpense },
                                onCopyFixedExpenses: copyFixedExpenses
                            )
                        }
                    }
                }
            }
            .navigationTitle("Финансы")
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button("Доход", systemImage: "plus.circle") {
                            entryTarget = .income
                        }
                        Button("Постоянный расход", systemImage: "repeat") {
                            entryTarget = .fixedExpense
                        }
                        Button("Разовый расход", systemImage: "bolt") {
                            entryTarget = .oneTimeExpense
                        }
                        Divider()
                        Button("Новый период", systemImage: "calendar.badge.plus") {
                            isAddingPeriod = true
                        }
                        if let index = selectedPeriodIndex {
                            Divider()
                            Button("Удалить период", systemImage: "trash", role: .destructive) {
                                periodToDelete = store.data.periods[index]
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $entryTarget) { target in
                AddMoneyEntryView(target: target) { entry in
                    guard let index = selectedPeriodIndex else { return }

                    switch target {
                    case .income:
                        store.data.periods[index].incomes.append(entry)
                    case .fixedExpense:
                        store.data.periods[index].fixedExpenses.append(entry)
                    case .oneTimeExpense:
                        store.data.periods[index].oneTimeExpenses.append(entry)
                    }
                }
            }
            .sheet(isPresented: $isAddingPeriod) {
                AddPeriodView { period in
                    store.data.periods.insert(period, at: 0)
                    selectedPeriodID = period.id
                }
            }
            .sheet(isPresented: $isShowingAllPeriods) {
                PeriodSelectionView(
                    periods: store.data.periods,
                    selectedPeriodID: selectedPeriodID ?? store.data.periods.first?.id,
                    onDeleteRequest: { period in
                        periodToDelete = period
                    }
                ) { period in
                    selectedPeriodID = period.id
                }
            }
            .confirmationDialog(
                "Удалить период?",
                isPresented: Binding(
                    get: { periodToDelete != nil },
                    set: { isPresented in
                        if !isPresented {
                            periodToDelete = nil
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("Удалить", role: .destructive) {
                    if let periodToDelete {
                        deletePeriod(periodToDelete)
                    }
                    periodToDelete = nil
                }
                Button("Отмена", role: .cancel) {
                    periodToDelete = nil
                }
            } message: {
                Text(periodToDelete?.title ?? "")
            }
            .onAppear {
                selectedPeriodID = selectedPeriodID ?? store.data.periods.first?.id
            }
        }
    }

    private var selectedPeriodIndex: Int? {
        if let selectedPeriodID,
           let index = store.data.periods.firstIndex(where: { $0.id == selectedPeriodID }) {
            return index
        }

        return store.data.periods.indices.first
    }

    private var visiblePeriods: [PayPeriod] {
        let recentPeriods = Array(store.data.periods.prefix(2))
        guard let selectedPeriodID,
              let selectedPeriod = store.data.periods.first(where: { $0.id == selectedPeriodID }),
              !recentPeriods.contains(where: { $0.id == selectedPeriod.id }) else {
            return recentPeriods
        }

        if let newestPeriod = store.data.periods.first, newestPeriod.id != selectedPeriod.id {
            return [selectedPeriod, newestPeriod]
        }

        return [selectedPeriod]
    }

    private func copySources(for period: PayPeriod) -> [PayPeriod] {
        store.data.periods.filter { $0.id != period.id && !$0.fixedExpenses.isEmpty }
    }

    private func copyFixedExpenses(from source: PayPeriod) {
        guard let index = selectedPeriodIndex else {
            return
        }

        store.data.periods[index].fixedExpenses = source.fixedExpenses.map {
            MoneyEntry(title: $0.title, amount: $0.amount, kind: .fixed)
        }
    }

    private func deletePeriod(_ period: PayPeriod) {
        store.data.periods.removeAll { $0.id == period.id }

        if selectedPeriodID == period.id {
            selectedPeriodID = store.data.periods.first?.id
        }
    }

    private var periodPicker: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(visiblePeriods) { period in
                        Button {
                            selectedPeriodID = period.id
                        } label: {
                            PeriodChip(period: period, isSelected: selectedPeriodID == period.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading)
                .padding(.vertical, 8)
            }

            if store.data.periods.count > 2 {
                Button {
                    isShowingAllPeriods = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.headline)
                        Text("Все")
                            .font(.caption.weight(.semibold))
                    }
                    .frame(width: 56, height: 54)
                    .background(AppColor.secondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.trailing)
            }
        }
        .background(AppColor.groupedBackground)
    }
}

struct PeriodSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let periods: [PayPeriod]
    let selectedPeriodID: UUID?
    let onDeleteRequest: (PayPeriod) -> Void
    let onSelect: (PayPeriod) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(periods) { period in
                    Button {
                        onSelect(period)
                        dismiss()
                    } label: {
                        PeriodSelectionRow(period: period, isSelected: selectedPeriodID == period.id)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        onDeleteRequest(periods[index])
                    }
                }
            }
            .navigationTitle("Все периоды")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Закрыть")
                    }
                }
            }
        }
    }
}

struct PeriodSelectionRow: View {
    let period: PayPeriod
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(period.title)
                    .font(.headline)
                Text(periodRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(period.balance.moneyString)
                .foregroundStyle(period.balance >= 0 ? .green : .red)

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private var periodRange: String {
        "\(period.startDate.shortDateString) - \(period.endDate.shortDateString)"
    }
}

struct PeriodChip: View {
    let period: PayPeriod
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(period.title)
                .font(.subheadline.weight(.semibold))
            Text(period.balance.moneyString)
                .font(.caption)
                .foregroundStyle(period.balance >= 0 ? .green : .red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: 128, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.14) : AppColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PeriodDetailView: View {
    @Binding var period: PayPeriod
    let copySources: [PayPeriod]
    let onAddIncome: () -> Void
    let onAddFixedExpense: () -> Void
    let onAddOneTimeExpense: () -> Void
    let onCopyFixedExpenses: (PayPeriod) -> Void

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    HStack {
                        FinanceMetric(title: "Доход", value: period.totalIncome, color: .green)
                        FinanceMetric(title: "Расходы", value: period.totalExpenses, color: .red)
                    }

                    HStack {
                        Text("Остаток")
                            .font(.headline)
                        Spacer()
                        Text(period.balance.moneyString)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(period.balance >= 0 ? .green : .red)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text(periodTitle)
            }

            moneySection(title: "Доход", entries: $period.incomes, addAction: onAddIncome)
            fixedExpensesSection
            moneySection(title: "Разовые расходы", entries: $period.oneTimeExpenses, addAction: onAddOneTimeExpense)

            Section("Заметка") {
                TextEditor(text: $period.note)
                    .frame(minHeight: 96)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var periodTitle: String {
        "\(period.startDate.shortDateString) - \(period.endDate.shortDateString)"
    }

    private var fixedExpensesSection: some View {
        Section {
            ForEach($period.fixedExpenses) { $entry in
                MoneyEntryRow(entry: $entry)
            }
            .onDelete { offsets in
                period.fixedExpenses.remove(atOffsets: offsets)
            }

            Button(action: onAddFixedExpense) {
                Label("Добавить", systemImage: "plus.circle")
            }

            if !copySources.isEmpty {
                Menu {
                    ForEach(copySources) { source in
                        Button(source.title) {
                            onCopyFixedExpenses(source)
                        }
                    }
                } label: {
                    Label("Скопировать из периода", systemImage: "doc.on.doc")
                }
            }
        } header: {
            Text("Постоянные расходы")
        } footer: {
            Text("Итого: \(period.totalFixed.moneyString)")
        }
    }

    private func moneySection(title: String, entries: Binding<[MoneyEntry]>, addAction: @escaping () -> Void) -> some View {
        Section {
            ForEach(entries) { $entry in
                MoneyEntryRow(entry: $entry)
            }
            .onDelete { offsets in
                entries.wrappedValue.remove(atOffsets: offsets)
            }

            Button(action: addAction) {
                Label("Добавить", systemImage: "plus.circle")
            }
        } header: {
            Text(title)
        } footer: {
            Text("Итого: \(entries.wrappedValue.reduce(0) { $0 + $1.amount }.moneyString)")
        }
    }
}

struct MoneyEntryRow: View {
    @Binding var entry: MoneyEntry

    var body: some View {
        HStack(spacing: 12) {
            TextField("Название", text: $entry.title)
                .appLowercaseInput()

            TextField("0", value: $entry.amount, format: .number)
                .appDecimalKeyboard()
                .multilineTextAlignment(.trailing)
                .frame(width: 104)
        }
    }
}

struct FinanceMetric: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.moneyString)
                .font(.headline)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

enum EntryTarget: String, Identifiable {
    case income
    case fixedExpense
    case oneTimeExpense

    var id: String { rawValue }

    var title: String {
        switch self {
        case .income:
            return "Новый доход"
        case .fixedExpense:
            return "Постоянный расход"
        case .oneTimeExpense:
            return "Разовый расход"
        }
    }
}

struct AddMoneyEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let target: EntryTarget
    let onSave: (MoneyEntry) -> Void

    @State private var title = ""
    @State private var amount = 0.0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название", text: $title)
                TextField("Сумма", value: $amount, format: .number)
                    .appDecimalKeyboard()
            }
            .navigationTitle(target.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        let kind: ExpenseKind?
                        switch target {
                        case .income:
                            kind = nil
                        case .fixedExpense:
                            kind = .fixed
                        case .oneTimeExpense:
                            kind = .oneTime
                        }

                        onSave(MoneyEntry(title: title.trimmedOrFallback("Без названия"), amount: amount, kind: kind))
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddPeriodView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (PayPeriod) -> Void

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название периода", text: $title)
                DatePicker("Начало", selection: $startDate, displayedComponents: .date)
                DatePicker("Конец", selection: $endDate, displayedComponents: .date)
            }
            .navigationTitle("Новый период")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        let fallbackTitle = "\(startDate.shortDateString)-\(endDate.shortDateString)"
                        onSave(PayPeriod(
                            title: title.trimmedOrFallback(fallbackTitle),
                            startDate: startDate,
                            endDate: endDate,
                            incomes: [],
                            fixedExpenses: [],
                            oneTimeExpenses: [],
                            note: ""
                        ))
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PlannerView: View {
    @EnvironmentObject private var store: AppStore
    @State private var weekStart = Calendar.app.startOfWeek(containing: Date())
    @State private var addTaskDate: PlannerDate?
    @State private var editingTask: PlannerItem?
    @State private var isChoosingWeek = false
    @State private var isEditingSections = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    weekHeader
                }

                ForEach(weekDays, id: \.self) { day in
                    let dayItems = items(for: day)

                    ForEach(Array(sectionOrder.enumerated()), id: \.element) { sectionIndex, section in
                        let sectionItems = dayItems.filter { $0.section == section }

                        Section {
                            if sectionItems.isEmpty {
                                Text("Нет задач")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 4)
                            } else {
                                ForEach(sectionItems) { item in
                                    PlannerTaskRow(
                                        item: item,
                                        onToggle: toggleTask,
                                        onEdit: { editingTask = $0 },
                                        onDelete: deleteTask
                                    )
                                }
                                .onMove { offsets, destination in
                                    moveTasks(on: day, in: section, from: offsets, to: destination)
                                }
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 8) {
                                if sectionIndex == 0 {
                                    DayHeaderRow(date: day, taskCount: dayItems.count) {
                                        addTaskDate = PlannerDate(date: day)
                                    }
                                }

                                PlannerSectionHeaderRow(title: section, taskCount: sectionItems.count)
                            }
                            .textCase(nil)
                        }
                    }
                }
            }
            .appAlwaysEditMode()
            .navigationTitle("Ежедневник")
            .toolbar {
                ToolbarItem {
                    Button {
                        isEditingSections = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .sheet(item: $addTaskDate) { date in
                PlannerItemEditorView(date: date.date, sections: sectionOrder) { item in
                    var newItem = item
                    newItem.order = nextOrder(for: item.date, section: item.section)
                    store.data.plannerItems.append(newItem)
                }
            }
            .sheet(item: $editingTask) { task in
                PlannerItemEditorView(date: task.date, sections: sectionOrder, item: task) { updatedTask in
                    updateTask(updatedTask)
                }
            }
            .sheet(isPresented: $isChoosingWeek) {
                WeekPickerView(selectedDate: weekStart) { date in
                    weekStart = Calendar.app.startOfWeek(containing: date)
                }
            }
            .sheet(isPresented: $isEditingSections) {
                PlannerSectionsView(sections: sectionOrder) { sections in
                    applyPlannerSections(sections)
                }
            }
        }
    }

    private var sectionOrder: [String] {
        store.data.plannerSections.isEmpty ? AppData.defaultPlannerSections : store.data.plannerSections
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { Calendar.app.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private var weekHeader: some View {
        HStack {
            Button {
                weekStart = Calendar.app.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.bordered)

            Spacer()

            Button {
                isChoosingWeek = true
            } label: {
                VStack(spacing: 2) {
                    Text("Неделя")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(weekStart.shortDateString) - \(weekDays.last?.shortDateString ?? "")")
                        .font(.headline)
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                weekStart = Calendar.app.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.bordered)
        }
    }

    private func items(for date: Date) -> [PlannerItem] {
        store.data.plannerItems
            .filter { Calendar.app.isDate($0.date, inSameDayAs: date) }
            .sorted { lhs, rhs in
                if lhs.section == rhs.section {
                    if lhs.order == rhs.order {
                        if lhs.time == rhs.time {
                            return lhs.title < rhs.title
                        }
                        return lhs.time < rhs.time
                    }
                    return lhs.order < rhs.order
                }
                return sectionIndex(lhs.section) < sectionIndex(rhs.section)
            }
    }

    private func sectionIndex(_ section: String) -> Int {
        sectionOrder.firstIndex(of: section) ?? Int.max
    }

    private func toggleTask(_ task: PlannerItem) {
        guard let index = store.data.plannerItems.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        store.data.plannerItems[index].isDone.toggle()
    }

    private func deleteTask(_ task: PlannerItem) {
        store.data.plannerItems.removeAll { $0.id == task.id }
    }

    private func updateTask(_ task: PlannerItem) {
        guard let index = store.data.plannerItems.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        let oldTask = store.data.plannerItems[index]
        var updatedTask = task

        if oldTask.section != task.section || !Calendar.app.isDate(oldTask.date, inSameDayAs: task.date) {
            updatedTask.order = nextOrder(for: task.date, section: task.section)
        }

        store.data.plannerItems[index] = updatedTask
    }

    private func moveTasks(on date: Date, in section: String, from offsets: IndexSet, to destination: Int) {
        var sameGroup = store.data.plannerItems
            .filter { Calendar.app.isDate($0.date, inSameDayAs: date) && $0.section == section }
            .sorted(by: sortPlannerItems)

        sameGroup.move(fromOffsets: offsets, toOffset: destination)

        var updatedItems = store.data.plannerItems
        for (order, item) in sameGroup.enumerated() {
            if let sourceIndex = updatedItems.firstIndex(where: { $0.id == item.id }) {
                updatedItems[sourceIndex].order = order
            }
        }
        store.data.plannerItems = updatedItems
    }

    private func nextOrder(for date: Date, section: String) -> Int {
        let existingOrders = store.data.plannerItems
            .filter { Calendar.app.isDate($0.date, inSameDayAs: date) && $0.section == section }
            .map(\.order)

        return (existingOrders.max() ?? -1) + 1
    }

    private func sortPlannerItems(_ lhs: PlannerItem, _ rhs: PlannerItem) -> Bool {
        if lhs.order == rhs.order {
            if lhs.time == rhs.time {
                return lhs.title < rhs.title
            }
            return lhs.time < rhs.time
        }
        return lhs.order < rhs.order
    }

    private func applyPlannerSections(_ proposedSections: [String]) {
        let oldSections = sectionOrder
        let sanitizedSections = uniqueSections(from: proposedSections)
        let newSections = sanitizedSections.isEmpty ? AppData.defaultPlannerSections : sanitizedSections
        let fallbackSection = newSections.first ?? "Личное"

        for index in store.data.plannerItems.indices {
            let currentSection = store.data.plannerItems[index].section

            if newSections.contains(currentSection) {
                continue
            } else if let oldIndex = oldSections.firstIndex(of: currentSection),
                      newSections.indices.contains(oldIndex) {
                store.data.plannerItems[index].section = newSections[oldIndex]
            } else {
                store.data.plannerItems[index].section = fallbackSection
                store.data.plannerItems[index].order = nextOrder(for: store.data.plannerItems[index].date, section: fallbackSection)
            }
        }

        store.data.plannerSections = newSections
    }

    private func uniqueSections(from sections: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for section in sections {
            let trimmed = section.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(trimmed) else {
                continue
            }
            seen.insert(trimmed)
            result.append(trimmed)
        }

        return result
    }
}

struct PlannerSectionHeaderRow: View {
    let title: String
    let taskCount: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.headline.weight(.semibold))
            Spacer()
            if taskCount > 0 {
                Text("\(taskCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColor.secondaryGroupedBackground)
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

struct PlannerTaskRow: View {
    let item: PlannerItem
    let onToggle: (PlannerItem) -> Void
    let onEdit: (PlannerItem) -> Void
    let onDelete: (PlannerItem) -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button {
                onToggle(item)
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(item.isDone ? .green : .secondary)
                    .frame(width: 36, height: 24)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)

                if !item.time.isEmpty {
                    Text(item.time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Menu {
                Button("Редактировать", systemImage: "pencil") {
                    onEdit(item)
                }
                Divider()
                Button("Удалить", systemImage: "trash", role: .destructive) {
                    onDelete(item)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .frame(width: 34, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

struct DayHeaderRow: View {
    let date: Date
    let taskCount: Int
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(date.weekdayString)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)

                    if Calendar.app.isDateInToday(date) {
                        Text("Сегодня")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                HStack(alignment: .center, spacing: 8) {
                    Text(date.dayMonthString)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.primary)

                    Text(taskCountLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColor.secondaryGroupedBackground)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 8)
    }

    private var taskCountLabel: String {
        "\(taskCount) \(taskWord)"
    }

    private var taskWord: String {
        let lastTwo = taskCount % 100
        let last = taskCount % 10

        if (11...14).contains(lastTwo) {
            return "задач"
        }

        switch last {
        case 1:
            return "задача"
        case 2...4:
            return "задачи"
        default:
            return "задач"
        }
    }
}

struct PlannerItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let sections: [String]
    let onSave: (PlannerItem) -> Void
    let item: PlannerItem?

    @State private var title = ""
    @State private var hasTime = false
    @State private var selectedTime = Date()
    @State private var selectedSection: String

    init(date: Date, sections: [String], item: PlannerItem? = nil, onSave: @escaping (PlannerItem) -> Void) {
        self.date = date
        self.sections = sections
        self.item = item
        self.onSave = onSave
        _title = State(initialValue: item?.title ?? "")
        _hasTime = State(initialValue: !(item?.time ?? "").isEmpty)
        _selectedTime = State(initialValue: Date.time(from: item?.time ?? "") ?? Date())
        _selectedSection = State(initialValue: item?.section ?? sections.first ?? "Личное")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Задача", text: $title)

                Toggle("Указать время", isOn: $hasTime)

                if hasTime {
                    DatePicker("Время", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }

                Picker("Раздел", selection: $selectedSection) {
                    ForEach(sections, id: \.self) { section in
                        Text(section).tag(section)
                    }
                }
            }
            .navigationTitle(date.dayMonthString)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        onSave(PlannerItem(
                            id: item?.id ?? UUID(),
                            date: date,
                            section: selectedSection,
                            title: title.trimmedOrFallback("Новая задача"),
                            time: hasTime ? selectedTime.timeString : "",
                            isDone: item?.isDone ?? false,
                            order: item?.order ?? 0
                        ))
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WeekPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Date) -> Void

    @State private var selectedDate: Date

    init(selectedDate: Date, onSelect: @escaping (Date) -> Void) {
        self.onSelect = onSelect
        _selectedDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Дата", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }
            .navigationTitle("Выбрать неделю")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        onSelect(selectedDate)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PlannerSectionsView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: ([String]) -> Void

    @State private var sections: [PlannerSectionDraft]
    @State private var newSection = ""

    init(sections: [String], onSave: @escaping ([String]) -> Void) {
        self.onSave = onSave
        _sections = State(initialValue: sections.map { PlannerSectionDraft(name: $0) })
    }

    var body: some View {
        NavigationStack {
            List {
                sectionsSection
                addSection
            }
            .appAlwaysEditMode()
            .navigationTitle("Разделы")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        onSave(sections.map(\.name))
                        dismiss()
                    }
                }
            }
        }
    }

    private var sectionsSection: some View {
        Section("Разделы") {
            ForEach($sections) { $section in
                PlannerSectionDraftRow(section: $section) {
                    sections.removeAll { $0.id == section.id }
                }
            }
            .onMove { offsets, destination in
                sections.move(fromOffsets: offsets, toOffset: destination)
            }
        }
    }

    private var addSection: some View {
        Section("Добавить") {
            HStack {
                TextField("Новый раздел", text: $newSection)
                Button {
                    addNewSection()
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func addNewSection() {
        let trimmed = newSection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        sections.append(PlannerSectionDraft(name: trimmed))
        newSection = ""
    }
}

struct PlannerSectionDraftRow: View {
    @Binding var section: PlannerSectionDraft
    let onDelete: () -> Void

    var body: some View {
        HStack {
            TextField("Раздел", text: $section.name)
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
    }
}

struct PlannerSectionDraft: Identifiable, Equatable {
    var id = UUID()
    var name: String
}

struct ProductsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var isAddingCategory = false
    @State private var isAddingRecipe = false

    var body: some View {
        NavigationStack {
            List {
                Section("Списки продуктов") {
                    ForEach(store.data.groceryCategories.indices, id: \.self) { categoryIndex in
                        ProductCategoryRow(category: $store.data.groceryCategories[categoryIndex])
                    }
                    .onDelete { offsets in
                        store.data.groceryCategories.remove(atOffsets: offsets)
                    }

                    Button {
                        isAddingCategory = true
                    } label: {
                        Label("Добавить категорию", systemImage: "folder.badge.plus")
                    }
                }

                Section("Блюда") {
                    ForEach(store.data.recipes.indices, id: \.self) { recipeIndex in
                        NavigationLink {
                            RecipeDetailView(recipe: $store.data.recipes[recipeIndex])
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(store.data.recipes[recipeIndex].title)
                                Text(store.data.recipes[recipeIndex].ingredients)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .onDelete { offsets in
                        store.data.recipes.remove(atOffsets: offsets)
                    }

                    Button {
                        isAddingRecipe = true
                    } label: {
                        Label("Добавить блюдо", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Продукты")
            .toolbar {
                ToolbarItem {
                    AppEditButton()
                }
            }
            .sheet(isPresented: $isAddingCategory) {
                AddTextItemView(title: "Новая категория", placeholder: "Название") { name in
                    store.data.groceryCategories.append(GroceryCategory(name: name, items: []))
                }
            }
            .sheet(isPresented: $isAddingRecipe) {
                AddTextItemView(title: "Новое блюдо", placeholder: "Название") { title in
                    store.data.recipes.append(Recipe(title: title, ingredients: "", instructions: "", nutrition: ""))
                }
            }
        }
    }
}

struct ProductCategoryRow: View {
    @Binding var category: GroceryCategory
    @State private var isAddingItem = false

    var body: some View {
        DisclosureGroup {
            ForEach(category.items.indices, id: \.self) { itemIndex in
                GroceryItemRow(item: $category.items[itemIndex])
            }
            .onDelete { offsets in
                category.items.remove(atOffsets: offsets)
            }

            Button {
                isAddingItem = true
            } label: {
                Label("Добавить продукт", systemImage: "plus.circle")
            }
        } label: {
            TextField("Категория", text: $category.name)
                .font(.headline)
        }
        .sheet(isPresented: $isAddingItem) {
            AddTextItemView(title: "Новый продукт", placeholder: "Название") { name in
                category.items.append(GroceryItem(name: name, note: "", isChecked: false))
            }
        }
    }
}

struct GroceryItemRow: View {
    @Binding var item: GroceryItem

    var body: some View {
        HStack(spacing: 10) {
            Button {
                item.isChecked.toggle()
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            TextField("Продукт", text: $item.name)
                .strikethrough(item.isChecked)

            TextField("Пометка", text: $item.note)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .frame(width: 72)
        }
    }
}

struct RecipeDetailView: View {
    @Binding var recipe: Recipe

    var body: some View {
        Form {
            Section("Название") {
                TextField("Название", text: $recipe.title)
            }

            Section("Продукты") {
                TextEditor(text: $recipe.ingredients)
                    .frame(minHeight: 90)
            }

            Section("Как приготовить") {
                TextEditor(text: $recipe.instructions)
                    .frame(minHeight: 140)
            }

            Section("КБЖУ") {
                TextEditor(text: $recipe.nutrition)
                    .frame(minHeight: 80)
            }
        }
        .navigationTitle(recipe.title.isEmpty ? "Блюдо" : recipe.title)
        .appInlineNavigationTitle()
    }
}

struct AddTextItemView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let placeholder: String
    let onSave: (String) -> Void

    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(placeholder, text: $value)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        onSave(value.trimmedOrFallback("Без названия"))
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct AppEditButton: View {
    var body: some View {
        #if os(iOS)
        EditButton()
        #else
        EmptyView()
        #endif
    }
}

extension Double {
    var moneyString: String {
        formatted(.currency(code: "RUB").precision(.fractionLength(0)))
    }
}

extension String {
    func trimmedOrFallback(_ fallback: String) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

extension Calendar {
    static var app: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        return calendar
    }

    func startOfWeek(containing date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}

extension Date {
    static func time(from value: String) -> Date? {
        let components = value.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else {
            return nil
        }

        var dateComponents = Calendar.app.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = components[0]
        dateComponents.minute = components[1]
        return Calendar.app.date(from: dateComponents)
    }

    var shortDateString: String {
        formatted(.dateTime.day().month(.twoDigits).year(.twoDigits))
    }

    var dayMonthString: String {
        formatted(.dateTime.day().month(.wide))
    }

    var weekdayString: String {
        formatted(.dateTime.weekday(.wide))
    }

    var timeString: String {
        formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }
}

struct PlannerDate: Identifiable {
    let date: Date

    var id: TimeInterval {
        date.timeIntervalSinceReferenceDate
    }
}

enum AppColor {
    static var groupedBackground: Color {
        #if os(iOS)
        Color(.systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var secondaryGroupedBackground: Color {
        #if os(iOS)
        Color(.secondarySystemGroupedBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var systemBackground: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color(nsColor: .textBackgroundColor)
        #endif
    }
}

extension View {
    @ViewBuilder
    func appDecimalKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appNumbersAndPunctuationKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.numbersAndPunctuation)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appLowercaseInput() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appInlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appAlwaysEditMode() -> some View {
        #if os(iOS)
        environment(\.editMode, .constant(.active))
        #else
        self
        #endif
    }
}
