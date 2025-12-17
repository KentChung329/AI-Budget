import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: CategoryManager

    @State private var budgetText: String = ""
    @State private var showDeleteTodayAlert = false
    @State private var showExportSuccess = false
    @State private var exportedFileURL: URL?

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

                // 歷史記帳查詢
                Section(header: Text("歷史記帳")) {
                    NavigationLink("查詢歷史月份記帳") {
                        HistoryView()
                            .environmentObject(manager)
                    }
                }

                // 匯出報表
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
                
                // 作者資訊
                Section {
                    Text("This app was created by 11鐘茝翔 51張博鈞")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
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
        }
    }

    // MARK: - 刪除本日所有記帳
    private func deleteTodayExpenses() {
        let calendar = Calendar.current
        manager.expenses.removeAll { expense in
            calendar.isDateInToday(expense.date)
        }
        manager.saveExpenses()
    }
    
    // MARK: - 匯出 CSV 報表
    private func exportToCSV() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        // CSV 標題列
        var csvText = "日期,時間,分類,金額,備註\n"
        
        // 依日期排序
        let sortedExpenses = manager.expenses.sorted { $0.date > $1.date }
        
        // 逐筆加入資料
        for expense in sortedExpenses {
            let dateString = dateFormatter.string(from: expense.date)
            let components = dateString.components(separatedBy: " ")
            let date = components[0]
            let time = components.count > 1 ? components[1] : ""
            let category = expense.categoryName
            let amount = "\(expense.amount)"
            let note = expense.note ?? ""
            
            // 處理備註中的逗號和換行（避免破壞 CSV 格式）
            let cleanNote = note.replacingOccurrences(of: ",", with: "，")
                               .replacingOccurrences(of: "\n", with: " ")
            
            csvText += "\(date),\(time),\(category),\(amount),\(cleanNote)\n"
        }
        
        // 產生檔案名稱
        let fileName = "記帳報表_\(dateFormatter.string(from: Date()).replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ":", with: "-")).csv"
        
        // 儲存到暫存目錄
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
}
