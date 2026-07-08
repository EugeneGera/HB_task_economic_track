import SwiftUI

struct ProductsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var isAddingCategory = false

    var body: some View {
        NavigationStack {
            List {
                Section {
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
