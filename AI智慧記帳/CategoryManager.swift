import Foundation
import Combine

class CategoryManager: ObservableObject {
    @Published var categories: [Category] = []
    @Published var expenses: [Expense] = []
    @Published var monthlyBudget: Int = 10000
    
    private let categoriesKey = "saved_categories"
    private let expensesKey = "saved_expenses"
    private let budgetKey = "monthly_budget"
    
    init() {
        loadCategories()
        loadExpenses()
        loadBudget()
    }
    
    // 載入分類
    func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
           let decoded = try? JSONDecoder().decode([Category].self, from: data) {
            categories = decoded
        } else {
            categories = Category.defaults
            saveCategories()
        }
    }
    
    // 儲存分類
    func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: categoriesKey)
        }
    }
    
    // 載入記帳紀錄
    func loadExpenses() {
        if let data = UserDefaults.standard.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
        }
    }
    
    // 儲存記帳紀錄
    func saveExpenses() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: expensesKey)
        }
    }
    
    // 載入預算
    func loadBudget() {
        let saved = UserDefaults.standard.integer(forKey: budgetKey)
        if saved > 0 {
            monthlyBudget = saved
        }
    }
    
    // 儲存預算
    func saveBudget() {
        UserDefaults.standard.set(monthlyBudget, forKey: budgetKey)
    }
    
    // 新增分類
    func addCategory(_ category: Category) {
        categories.append(category)
        saveCategories()
    }
    
    // 刪除分類
    func deleteCategory(_ category: Category) {
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }
    
    // 更新分類
    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }
    
    // 新增記帳
    func addExpense(amount: Int, categoryName: String) {
        let expense = Expense(date: Date(), amount: amount, categoryName: categoryName)
        expenses.append(expense)
        saveExpenses()
    }
    
    // 根據時間取得預設分類
    func getCategoryByTime() -> Category? {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        
        return categories.first { $0.isInTimeRange(hour: hour, minute: minute) }
    }
    
    // 計算本月已花
    func getMonthlySpent() -> Int {
        let calendar = Calendar.current
        let thisMonth = calendar.component(.month, from: Date())
        let thisYear = calendar.component(.year, from: Date())
        
        return expenses.filter {
            calendar.component(.month, from: $0.date) == thisMonth &&
            calendar.component(.year, from: $0.date) == thisYear
        }.reduce(0) { $0 + $1.amount }
    }
    
    // 計算今日已花
    func getTodaySpent() -> Int {
        let calendar = Calendar.current
        return expenses.filter {
            calendar.isDateInToday($0.date)
        }.reduce(0) { $0 + $1.amount }
    }
    
    // 計算每日可用額度
    func getDailyBudget() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let range = calendar.range(of: .day, in: .month, for: today)!
        let daysInMonth = range.count
        let currentDay = calendar.component(.day, from: today)
        let remainingDays = daysInMonth - currentDay + 1
        
        let monthlySpent = getMonthlySpent()
        let remainingBudget = monthlyBudget - monthlySpent
        
        return max(0, remainingBudget / max(1, remainingDays))
    }
}
