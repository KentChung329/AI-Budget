import Foundation

struct Category: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var color: String // "red", "blue", "green", "yellow", "purple", "orange"
    
    // 預設分類
    static let defaults: [Category] = [
        Category(name: "早餐", startHour: 5, startMinute: 0, endHour: 10, endMinute: 59, color: "yellow"),
        Category(name: "午餐", startHour: 11, startMinute: 0, endHour: 13, endMinute: 59, color: "orange"),
        Category(name: "點心", startHour: 14, startMinute: 0, endHour: 16, endMinute: 29, color: "pink"),
        Category(name: "晚餐", startHour: 16, startMinute: 30, endHour: 20, endMinute: 29, color: "green"),
        Category(name: "宵夜", startHour: 20, startMinute: 30, endHour: 4, endMinute: 59, color: "purple"),
        Category(name: "交通", startHour: 0, startMinute: 0, endHour: 23, endMinute: 59, color: "blue"),
        Category(name: "娛樂", startHour: 0, startMinute: 0, endHour: 23, endMinute: 59, color: "red")
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
}
