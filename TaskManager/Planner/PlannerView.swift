import SwiftUI

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
