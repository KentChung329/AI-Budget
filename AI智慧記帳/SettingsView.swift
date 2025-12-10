import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: CategoryManager

    @State private var budgetText: String = ""

    @FocusState private var isBudgetFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                // 每月預算：用鍵盤直接輸入
                Section(header: Text("每月預算")) {
                    HStack {
                        Text("預算金額")
                        TextField("輸入金額", text: $budgetText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isBudgetFocused)
                            .onAppear {
                                budgetText = String(manager.monthlyBudget)
                            }
                    }
                    Text("關閉設定畫面前記得按鍵盤上的「儲存」按鈕。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 餐點時間設定入口
                Section(header: Text("餐點時間設定")) {
                    NavigationLink("設定早餐 / 午餐 / 晚餐 / 宵夜時間") {
                        MealTimeSettingsView()
                            .environmentObject(manager)
                    }
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
            // 鍵盤上方工具列：預算顯示＋儲存鈕
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        Text("預算：\(budgetText.isEmpty ? "0" : budgetText) 元")
                            .font(.subheadline)
                        Spacer()
                        Button("儲存") {
                            if let value = Int(budgetText), value >= 0 {
                                manager.monthlyBudget = value
                                manager.saveBudget()
                            }
                            isBudgetFocused = false
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }
}

// 早餐 / 午餐 / 晚餐 / 宵夜 列表
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

// 單一分類時間編輯（排版已調整）
struct CategoryTimeEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: CategoryManager

    let category: Category

    @State private var startHour: Int
    @State private var startMinute: Int
    @State private var endHour: Int
    @State private var endMinute: Int

    init(category: Category) {
        self.category = category
        _startHour = State(initialValue: category.startHour)
        _startMinute = State(initialValue: category.startMinute)
        _endHour = State(initialValue: category.endHour)
        _endMinute = State(initialValue: category.endMinute)
    }

    var body: some View {
        Form {
            Section(header: Text("開始時間")) {
                timeRow(title: "開始", hour: $startHour, minute: $startMinute)
            }
            Section(header: Text("結束時間")) {
                timeRow(title: "結束", hour: $endHour, minute: $endMinute)
            }

            Section {
                Button("儲存") {
                    manager.updateCategoryTime(
                        category: category,
                        startHour: startHour,
                        startMinute: startMinute,
                        endHour: endHour,
                        endMinute: endMinute
                    )
                    dismiss()
                }
            }
        }
        .navigationTitle(category.name)
    }

    // ✅ 左邊顯示「開始 / 結束」，中間 Picker 選「x 時」「y 分」，文字跟數字對應
    private func timeRow(title: String,
                         hour: Binding<Int>,
                         minute: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer()

            HStack(spacing: 4) {
                Picker("", selection: hour) {
                    ForEach(0..<24) { h in
                        Text("\(h)").tag(h)
                    }
                }
                .frame(width: 70)

                Text("時")

                Picker("", selection: minute) {
                    ForEach(0..<60) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .frame(width: 80)

                Text("分")
            }
        }
    }
}

