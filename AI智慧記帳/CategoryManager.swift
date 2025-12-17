import SwiftUI
import Combine

class CategoryManager: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var categories: [Category] = []
    @Published var monthlyBudget: Int = 10000
    
    private let db = DatabaseManager.shared
    
    init() {
        loadData()
    }
    
    // MARK: - 從 SQLite 載入資料
    private func loadData() {
        // 載入分類
        let loadedCategories = db.loadCategories()
        if loadedCategories.isEmpty {
            // 如果沒有分類，建立預設分類
            categories = createDefaultCategories()
            for category in categories {
                db.saveCategory(category)
            }
        } else {
            categories = loadedCategories
        }
        
        // 載入支出
        expenses = db.loadExpenses()
        
        // 載入預算
        monthlyBudget = db.loadBudget()
    }
    
    // MARK: - 建立預設分類
    private func createDefaultCategories() -> [Category] {
        return [
            Category(id: UUID(), name: "早餐", startHour: 5, startMinute: 0, endHour: 10, endMinute: 59),
            Category(id: UUID(), name: "午餐", startHour: 11, startMinute: 0, endHour: 13, endMinute: 59),
            Category(id: UUID(), name: "晚餐", startHour: 17, startMinute: 0, endHour: 20, endMinute: 59),
            Category(id: UUID(), name: "宵夜", startHour: 21, startMinute: 0, endHour: 4, endMinute: 59)
        ]
    }
    
    // MARK: - 儲存支出到 SQLite
    func saveExpenses() {
        for expense in expenses {
            db.saveExpense(expense)
        }
    }
    
    // MARK: - 儲存預算到 SQLite
    func saveBudget() {
        db.saveBudget(monthlyBudget)
    }
    
    // MARK: - 刪除支出
    func deleteExpense(id: UUID) {
        expenses.removeAll { $0.id == id }
        db.deleteExpense(id: id)
    }
    
    // MARK: - 更新分類時間
    func updateCategoryTime(category: Category, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index].startHour = startHour
            categories[index].startMinute = startMinute
            categories[index].endHour = endHour
            categories[index].endMinute = endMinute
            
            db.saveCategory(categories[index])
        }
    }
    
    // MARK: - 根據時間自動判斷分類
    func getCategoryByTime() -> Category? {
        let now = Date()
        let calendar = Calendar.current
        let comp = calendar.dateComponents([.hour, .minute], from: now)
        let nowHour = comp.hour ?? 0
        let nowMinute = comp.minute ?? 0
        
        for cat in categories {
            if isInTimeRange(nowHour: nowHour, nowMinute: nowMinute, cat: cat) {
                return cat
            }
        }
        return nil
    }
    
    private func isInTimeRange(nowHour: Int, nowMinute: Int, cat: Category) -> Bool {
        let nowTotalMinutes = nowHour * 60 + nowMinute
        let startTotalMinutes = cat.startHour * 60 + cat.startMinute
        let endTotalMinutes = cat.endHour * 60 + cat.endMinute
        
        if startTotalMinutes <= endTotalMinutes {
            return nowTotalMinutes >= startTotalMinutes && nowTotalMinutes <= endTotalMinutes
        } else {
            return nowTotalMinutes >= startTotalMinutes || nowTotalMinutes <= endTotalMinutes
        }
    }
    
    // MARK: - 統計
    func getTodaySpent() -> Int {
        let calendar = Calendar.current
        return expenses
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
    }
    
    func getMonthlySpent() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let comp = calendar.dateComponents([.year, .month], from: now)
        
        return expenses.filter {
            let eComp = calendar.dateComponents([.year, .month], from: $0.date)
            return eComp.year == comp.year && eComp.month == comp.month
        }.reduce(0) { $0 + $1.amount }
    }
}
