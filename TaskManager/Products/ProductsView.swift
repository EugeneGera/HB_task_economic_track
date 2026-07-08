import SwiftUI

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
