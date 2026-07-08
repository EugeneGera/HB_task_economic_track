import SwiftUI

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
