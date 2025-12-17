import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: CategoryManager

    @State private var budgetText: String = ""
    @State private var showDeleteTodayAlert = false
    @State private var showExportSuccess = false
    @State private var exportedFileURL: URL?
    @State private var showDatabaseAlert = false
    @State private var databasePath = ""

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

                // 資料管理
                Section(header: Text("資料管理")) {
                    Button {
                        exportToCSV()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("匯出報表 (CSV)")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let url = exportedFileURL {
                        ShareLink(item: url) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.on.square")
                                    .foregroundColor(.green)
                                Text("分享已匯出的檔案")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Button {
                        showDatabasePath()
                    } label: {
                        HStack {
                            Image(systemName: "cylinder.fill")
                                .foregroundColor(.purple)
                            Text("顯示資料庫位置")
                                .foregroundColor(.purple)
                        }
                    }
                }

                // 刪除本日所有記帳
                Section(header: Text("危險操作")) {
                    Button(role: .destructive) {
                        showDeleteTodayAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("刪除本日所有記帳")
                        }
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
            .alert("確定要刪除本日所有記帳？", isPresented: $showDeleteTodayAlert) {
                Button("取消", role: .cancel) { }
                Button("確定刪除", role: .destructive) {
                    deleteTodayExpenses()
                }
            } message: {
                Text("此操作無法復原。")
            }
            .alert("匯出成功", isPresented: $showExportSuccess) {
                Button("確定", role: .cancel) { }
            } message: {
                Text("報表已匯出至「檔案」App，可使用下方「分享」按鈕傳送。")
            }
            .alert("資料庫位置", isPresented: $showDatabaseAlert) {
                Button("確定", role: .cancel) { }
                Button("複製路徑") {
                    UIPasteboard.general.string = databasePath
                }
            } message: {
                Text(databasePath)
            }
        }
    }

    // MARK: - 刪除本日所有記帳
    private func deleteTodayExpenses() {
        manager.expenses.removeAll { expense in
            Calendar.current.isDateInToday(expense.date)
        }
        manager.saveExpenses()
    }
    
    // MARK: - 匯出 CSV 報表
    private func exportToCSV() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        var csvText = "日期,時間,分類,金額,備註\n"
        
        let sortedExpenses = manager.expenses.sorted { $0.date > $1.date }
        
        for expense in sortedExpenses {
            let dateString = dateFormatter.string(from: expense.date)
            let components = dateString.components(separatedBy: " ")
            let date = components[0]
            let time = components.count > 1 ? components[1] : ""
            let category = expense.categoryName
            let amount = "\(expense.amount)"
            let note = expense.note ?? ""
            
            let cleanNote = note.replacingOccurrences(of: ",", with: "，")
                               .replacingOccurrences(of: "\n", with: " ")
            
            csvText += "\(date),\(time),\(category),\(amount),\(cleanNote)\n"
        }
        
        let fileName = "記帳報表_\(dateFormatter.string(from: Date()).replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ":", with: "-")).csv"
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            exportedFileURL = fileURL
            showExportSuccess = true
            print("✅ CSV 已匯出至: \(fileURL.path)")
        } catch {
            print("❌ 匯出失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 顯示資料庫路徑
    private func showDatabasePath() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("BudgetTracker.sqlite")
        
        databasePath = fileURL.path
        showDatabaseAlert = true
        
        print("📂 資料庫位置: \(fileURL.path)")
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

// 單一分類時間編輯
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

    private func timeRow(title: String,
                         hour: Binding<Int>,
                         minute: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer()

            HStack(spacing: 4) {
                Picker("時", selection: hour) {
                    ForEach(0..<24) { h in
                        Text("\(h)").tag(h)
                    }
                }
                .frame(width: 70)

                Text("時")

                Picker("分", selection: minute) {
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
