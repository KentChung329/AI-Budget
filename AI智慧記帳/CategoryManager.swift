import Foundation
import Combine
import SwiftUI

struct Category: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var color: String

    static let defaults: [Category] = [
        Category(name: "早餐", startHour: 5,  startMinute: 0,  endHour: 10, endMinute: 59, color: "yellow"),
        Category(name: "午餐", startHour: 11, startMinute: 0,  endHour: 13, endMinute: 59, color: "orange"),
        Category(name: "晚餐", startHour: 17, startMinute: 0,  endHour: 20, endMinute: 59, color: "green"),
        Category(name: "宵夜", startHour: 21, startMinute: 0,  endHour: 4,  endMinute: 59, color: "purple"),
        Category(name: "飲品", startHour: 0,  startMinute: 0,  endHour: 23, endMinute: 59, color: "blue"),
        Category(name: "購物", startHour: 0,  startMinute: 0,  endHour: 23, endMinute: 59, color: "orange"),
        Category(name: "點心", startHour: 0,  startMinute: 0,  endHour: 23, endMinute: 59, color: "pink"),
        Category(name: "交通", startHour: 0,  startMinute: 0,  endHour: 23, endMinute: 59, color: "blue"),
        Category(name: "娛樂", startHour: 0,  startMinute: 0,  endHour: 23, endMinute: 59, color: "red"),
        Category(name: "日用品", startHour: 0,  startMinute: 0,  endHour: 23, endMinute: 59, color: "green"),
        Category(name: "禮物", startHour: 0,  startMinute: 0,  endHour: 23, endMinute: 59, color: "pink"),
        Category(name: "洗衣服", startHour: 0,  startMinute: 0,  endHour: 23, endMinute: 59, color: "purple"),
        Category(name: "藥物", startHour: 0,  startMinute: 0,  endHour: 23, endMinute: 59, color: "red")
    ]

    func isInTimeRange(hour: Int, minute: Int) -> Bool {
        let currentMinutes = hour * 60 + minute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        if startMinutes <= endMinutes {
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }
}

struct Expense: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var amount: Int
    var categoryName: String
    var note: String?
}

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

    // MARK: - 分類相關
    func getCategoryByTime() -> Category? {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        return categories.first { $0.isInTimeRange(hour: hour, minute: minute) }
    }

    /// 調整指定分類的時間區間
    func updateCategoryTime(category: Category, startHour: Int, startMinute: Int,
                            endHour: Int, endMinute: Int) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[index].startHour = startHour
        categories[index].startMinute = startMinute
        categories[index].endHour = endHour
        categories[index].endMinute = endMinute
        saveCategories()
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
