import SwiftUI

struct RecipesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var isAddingRecipe = false

    var body: some View {
        NavigationStack {
            List {
                Section {
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
                        Label("Добавить рецепт", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Рецепты")
            .toolbar {
                ToolbarItem {
                    AppEditButton()
                }
            }
            .sheet(isPresented: $isAddingRecipe) {
                AddTextItemView(title: "Новый рецепт", placeholder: "Название") { title in
                    store.data.recipes.append(Recipe(title: title, ingredients: "", instructions: ""))
                }
            }
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

            Section("БЖУ на 100 г") {
                NutrientInputRow(title: "Белки", value: $recipe.proteinPer100g)
                NutrientInputRow(title: "Жиры", value: $recipe.fatPer100g)
                NutrientInputRow(title: "Углеводы", value: $recipe.carbsPer100g)

                HStack {
                    Text("Калорийность")
                    Spacer()
                    Text("\(recipe.caloriesPer100g.formatted(.number.precision(.fractionLength(0)))) ккал")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(recipe.title.isEmpty ? "Рецепт" : recipe.title)
        .appInlineNavigationTitle()
    }
}

struct NutrientInputRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: $value, format: .number.precision(.fractionLength(0...1)))
                .multilineTextAlignment(.trailing)
                .appDecimalKeyboard()
                .frame(width: 96)
            Text("г")
                .foregroundStyle(.secondary)
        }
    }
}
