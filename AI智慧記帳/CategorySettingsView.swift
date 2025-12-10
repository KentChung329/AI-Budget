import SwiftUI

struct CategorySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: CategoryManager

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("所有分類（顯示用）")) {
                    ForEach(manager.categories) { category in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.name)
                                .font(.headline)

                            Text(
                                String(
                                    format: "時間：%02d:%02d ~ %02d:%02d",
                                    category.startHour, category.startMinute,
                                    category.endHour, category.endMinute
                                )
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("餐點時間快速設定")) {
                    NavigationLink("編輯早餐 / 午餐 / 晚餐 / 宵夜時間") {
                        MealTimeSettingsView()
                            .environmentObject(manager)
                    }
                }
            }
            .navigationTitle("分類設定")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
}
