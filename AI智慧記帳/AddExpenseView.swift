import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: CategoryManager

    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var selectedCategoryName: String = ""
    @State private var selectedDate: Date = Date()

    @FocusState private var isAmountFieldFocused: Bool

    private let categoryOptions: [String] = [
        "早餐", "午餐", "晚餐", "宵夜",
        "飲品", "購物", "點心",
        "交通", "娛樂", "日用品",
        "禮物", "洗衣服", "藥物"
    ]
    
    // 跟主畫面一樣的顏色配置
    private let categoryColors: [String: Color] = [
        "早餐": .orange,
        "午餐": .blue,
        "晚餐": .purple,
        "宵夜": .yellow,
        "飲品": .green,
        "購物": .pink,
        "點心": .red,
        "交通": .red,
        "娛樂": .red,
        "日用品": .red,
        "禮物": .red,
        "洗衣服": .red,
        "藥物": .red
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    private var currentAutoCategoryName: String {
        if let c = manager.getCategoryByTime() {
            return c.name
        } else {
            return "未分類"
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {

                // 0. 日期選擇
                HStack {
                    Text("日期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                }
                .padding(.horizontal)

                // 1. 金額 + 備註
                VStack(alignment: .leading, spacing: 6) {
                    Text("金額")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(amount.isEmpty ? "0" : amount)
                        .font(.system(size: 32, weight: .bold, design: .rounded))

                    Text("備註")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    TextField("在此輸入備註(選填)", text: $note)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                // 2. 分類(直向捲動，一排 5 個) - 加上顏色
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(categoryOptions, id: \.self) { name in
                            categoryTile(name: name)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                .frame(maxHeight: 140)

                // 3. 自動分類提示
                Text("若未選擇分類，將依目前時間自動歸類為「\(currentAutoCategoryName)」。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                Spacer()

                // 4. 隱藏 TextField 用來叫出數字鍵盤
                TextField("", text: $amount)
                    .keyboardType(.numberPad)
                    .focused($isAmountFieldFocused)
                    .frame(width: 0, height: 0)
                    .opacity(0.01)
            }
            .navigationTitle("新增支出")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isAmountFieldFocused = false
                        dismiss()
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        Text("金額：\(amount.isEmpty ? "0" : amount) 元")
                            .font(.subheadline)
                        Spacer()
                        Button(action: saveTapped) {
                            Text("儲存")
                                .fontWeight(.semibold)
                        }
                        .disabled(Int(amount) == nil || Int(amount) ?? 0 <= 0)
                    }
                }
            }
            .onAppear {
                isAmountFieldFocused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isAmountFieldFocused = true
                }
            }
            .onDisappear {
                isAmountFieldFocused = false
            }
        }
    }

    // MARK: - 分類按鈕(加上顏色)
    private func categoryTile(name: String) -> some View {
        let isSelected = selectedCategoryName == name
        let baseColor = categoryColors[name] ?? .gray
        
        return Button {
            selectedCategoryName = name
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? baseColor : baseColor.opacity(0.2))
                        .frame(height: 40)

                    Text(String(name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : baseColor)
                        .fontWeight(isSelected ? .bold : .regular)
                }

                Text(name)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(isSelected ? baseColor : .primary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 儲存
    private func saveTapped() {
        guard let value = Int(amount), value > 0 else { return }

        let finalCategory: String
        if !selectedCategoryName.isEmpty {
            finalCategory = selectedCategoryName
        } else {
            finalCategory = currentAutoCategoryName
        }

        let expense = Expense(
            id: UUID(),
            date: selectedDate,
            amount: value,
            categoryName: finalCategory,
            note: note.isEmpty ? nil : note
        )
        manager.expenses.append(expense)
        manager.saveExpenses()

        isAmountFieldFocused = false
        dismiss()
    }
}
