import SwiftUI
import Combine

class CategoryManager: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var categories: [Category] = []
    @Published var monthlyBudget: Int = 10000
    
    init() {
        loadExpenses()
        loadCategories()
        loadBudget()
    }
    
    // MARK: - 儲存/讀取支出（UserDefaults）
    func saveExpenses() {
        if let data = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(data, forKey: "expenses")
        }
    }
    
    private func loadExpenses() {
        if let data = UserDefaults.standard.data(forKey: "expenses"),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
        }
    }
    
    // MARK: - 儲存/讀取分類（UserDefaults）
    private func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: "categories"),
           let decoded = try? JSONDecoder().decode([Category].self, from: data) {
            categories = decoded
        } else {
            categories = createDefaultCategories()
            saveCategories()
        }
    }
    
    private func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: "categories")
        }
    }
    
    private func createDefaultCategories() -> [Category] {
        return [
            Category(id: UUID(), name: "早餐", startHour: 5, startMinute: 0, endHour: 10, endMinute: 59),
            Category(id: UUID(), name: "午餐", startHour: 11, startMinute: 0, endHour: 13, endMinute: 59),
            Category(id: UUID(), name: "晚餐", startHour: 17, startMinute: 0, endHour: 20, endMinute: 59),
            Category(id: UUID(), name: "宵夜", startHour: 21, startMinute: 0, endHour: 4, endMinute: 59)
        ]
    }
    
    // MARK: - 儲存/讀取預算（UserDefaults）
    func saveBudget() {
        UserDefaults.standard.set(monthlyBudget, forKey: "monthlyBudget")
    }
    
    private func loadBudget() {
        let saved = UserDefaults.standard.integer(forKey: "monthlyBudget")
        if saved > 0 {
            monthlyBudget = saved
        }
    }
    
    // MARK: - 刪除支出
    func deleteExpense(id: UUID) {
        expenses.removeAll { $0.id == id }
        saveExpenses()
    }
    
    // MARK: - 更新分類時間
    func updateCategoryTime(category: Category, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index].startHour = startHour
            categories[index].startMinute = startMinute
            categories[index].endHour = endHour
            categories[index].endMinute = endMinute
            saveCategories()
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
