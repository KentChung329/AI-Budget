import SwiftUI

struct MealTimeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: CategoryManager

    private var mealCategories: [Category] {
        manager.categories.filter { ["早餐", "午餐", "晚餐", "宵夜"].contains($0.name) }
    }

    var body: some View {
        List {
            ForEach(mealCategories, id: \.id) { category in
                NavigationLink(category.name) {
                    CategoryTimeEditor(category: category)
                        .environmentObject(manager)
                }
            }
        }
        .navigationTitle("餐點時間")
    }
}
//1
