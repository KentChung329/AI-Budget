import Foundation

// MARK: - Expense 支出模型
struct Expense: Identifiable, Codable {
    let id: UUID
    var date: Date
    var amount: Int
    var categoryName: String
    var note: String?
}

// MARK: - Category 分類模型
struct Category: Identifiable, Codable {
    let id: UUID
    var name: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
}
