import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: CategoryManager

    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var selectedCategoryName: String = ""

    @FocusState private var isAmountFieldFocused: Bool

    // 全部分類
    private let categoryOptions: [String] = [
        "早餐", "午餐", "晚餐", "宵夜",
        "飲品", "購物", "點心",
        "交通", "娛樂", "日用品",
        "禮物", "洗衣服", "藥物"
    ]

    // 一排 5 個
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    // 目前時間自動分類
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

                // 1. 金額 + 備註顯示
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

                    TextField("在此輸入備註（選填）", text: $note)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                // 2. 分類區：直向捲動，一排 5 個，超過兩行往下捲
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(categoryOptions, id: \.self) { name in
                            categoryTile(name: name)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                .frame(maxHeight: 120) // 大約兩行高度，超過就往下捲

                // 3. 自動分類提示
                Text("若未選擇分類，將依目前時間自動歸類為「\(currentAutoCategoryName)」。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                Spacer()

                // 4. 隱藏金額輸入欄，只用來叫出數字鍵盤
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
                        dismiss()
                    }
                }
            }
            // 鍵盤上方工具列：顯示金額 + 儲存按鈕
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAmountFieldFocused = true
                }
            }
        }
    }

    // MARK: - 分類方塊（5 個一排）

    private func categoryTile(name: String) -> some View {
        Button {
            selectedCategoryName = name
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selectedCategoryName == name ? Color.orange : Color.gray.opacity(0.15))
                        .frame(height: 40)

                    Text(String(name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(selectedCategoryName == name ? .white : .black)
                }

                Text(name)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(selectedCategoryName == name ? .orange : .primary)
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

        manager.addExpense(
            amount: value,
            categoryName: finalCategory,
            note: note.isEmpty ? nil : note
        )
        dismiss()
    }
}
