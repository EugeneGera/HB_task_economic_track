import SwiftUI

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

            RecipesView()
                .tabItem {
                    Label("Рецепты", systemImage: "fork.knife")
                }
        }
        .appDismissKeyboardOnTap()
    }
}
