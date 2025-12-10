
import Foundation
import Combine
import SwiftUI


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

    // MARK: - 分類儲存 / 載入

    func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
           let decoded = try? JSONDecoder().decode([Category].self, from: data) {
            categories = decoded
        } else {
            categories = Category.defaults
            saveCategories()
        }
    }

    func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: categoriesKey)
        }
    }

    // MARK: - 記帳儲存 / 載入

    func loadExpenses() {
        if let data = UserDefaults.standard.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = decoded
        }
    }

    func saveExpenses() {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: expensesKey)
        }
    }

    // MARK: - 預算

    func loadBudget() {
        let saved = UserDefaults.standard.integer(forKey: budgetKey)
        if saved > 0 {
            monthlyBudget = saved
        }
    }

    func saveBudget() {
        UserDefaults.standard.set(monthlyBudget, forKey: budgetKey)
    }

    // MARK: - 分類 CRUD

    func addCategory(_ category: Category) {
        categories.append(category)
        saveCategories()
    }

    func deleteCategory(_ category: Category) {
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }

    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }

    // MARK: - 記帳 CRUD

    func addExpense(amount: Int, categoryName: String, note: String?) {
        let expense = Expense(date: Date(), amount: amount, categoryName: categoryName, note: note)
        expenses.append(expense)
        saveExpenses()
    }

    func deleteExpenses(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        saveExpenses()
    }

    // MARK: - 自動分類（依時間）

    func getCategoryByTime() -> Category? {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        return categories.first { $0.isInTimeRange(hour: hour, minute: minute) }
    }

    // MARK: - 統計

    func getMonthlySpent() -> Int {
        let calendar = Calendar.current
        let thisMonth = calendar.component(.month, from: Date())
        let thisYear = calendar.component(.year, from: Date())

        return expenses.filter {
            calendar.component(.month, from: $0.date) == thisMonth &&
            calendar.component(.year, from: $0.date) == thisYear
        }.reduce(0) { $0 + $1.amount }
    }

    func getTodaySpent() -> Int {
        let calendar = Calendar.current
        return expenses.filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

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
