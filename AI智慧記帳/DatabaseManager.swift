import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private init() {
        openDatabase()
        createTables()
    }
    
    // MARK: - 開啟資料庫
    private func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("BudgetTracker.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("❌ 無法開啟資料庫")
            return
        }
        print("✅ 資料庫已開啟: \(fileURL.path)")
    }
    
    // MARK: - 建立資料表
    private func createTables() {
        // 建立 expenses 資料表
        let createExpensesTable = """
        CREATE TABLE IF NOT EXISTS expenses (
            id TEXT PRIMARY KEY,
            date REAL NOT NULL,
            amount INTEGER NOT NULL,
            categoryName TEXT NOT NULL,
            note TEXT
        );
        """
        
        // 建立 categories 資料表
        let createCategoriesTable = """
        CREATE TABLE IF NOT EXISTS categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            startHour INTEGER NOT NULL,
            startMinute INTEGER NOT NULL,
            endHour INTEGER NOT NULL,
            endMinute INTEGER NOT NULL
        );
        """
        
        // 建立 settings 資料表
        let createSettingsTable = """
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        """
        
        executeSQL(createExpensesTable)
        executeSQL(createCategoriesTable)
        executeSQL(createSettingsTable)
    }
    
    // MARK: - 執行 SQL
    private func executeSQL(_ sql: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ SQL 執行成功")
            } else {
                print("❌ SQL 執行失敗")
            }
        } else {
            print("❌ SQL 準備失敗: \(sql)")
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - 儲存支出
    func saveExpense(_ expense: Expense) {
        let sql = """
        INSERT OR REPLACE INTO expenses (id, date, amount, categoryName, note)
        VALUES (?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, expense.id.uuidString, -1, nil)
            sqlite3_bind_double(statement, 2, expense.date.timeIntervalSince1970)
            sqlite3_bind_int(statement, 3, Int32(expense.amount))
            sqlite3_bind_text(statement, 4, expense.categoryName, -1, nil)
            if let note = expense.note {
                sqlite3_bind_text(statement, 5, note, -1, nil)
            } else {
                sqlite3_bind_null(statement, 5)
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ 支出已儲存")
            } else {
                print("❌ 儲存支出失敗")
            }
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - 讀取所有支出
    func loadExpenses() -> [Expense] {
        let sql = "SELECT id, date, amount, categoryName, note FROM expenses;"
        var statement: OpaquePointer?
        var expenses: [Expense] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let idString = String(cString: sqlite3_column_text(statement, 0))
                let dateInterval = sqlite3_column_double(statement, 1)
                let amount = Int(sqlite3_column_int(statement, 2))
                let categoryName = String(cString: sqlite3_column_text(statement, 3))
                let notePointer = sqlite3_column_text(statement, 4)
                let note = notePointer != nil ? String(cString: notePointer!) : nil
                
                if let uuid = UUID(uuidString: idString) {
                    let expense = Expense(
                        id: uuid,
                        date: Date(timeIntervalSince1970: dateInterval),
                        amount: amount,
                        categoryName: categoryName,
                        note: note
                    )
                    expenses.append(expense)
                }
            }
        }
        sqlite3_finalize(statement)
        print("✅ 讀取 \(expenses.count) 筆支出")
        return expenses
    }
    
    // MARK: - 刪除支出
    func deleteExpense(id: UUID) {
        let sql = "DELETE FROM expenses WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id.uuidString, -1, nil)
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ 支出已刪除")
            }
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - 儲存分類
    func saveCategory(_ category: Category) {
        let sql = """
        INSERT OR REPLACE INTO categories (id, name, startHour, startMinute, endHour, endMinute)
        VALUES (?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, category.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, category.name, -1, nil)
            sqlite3_bind_int(statement, 3, Int32(category.startHour))
            sqlite3_bind_int(statement, 4, Int32(category.startMinute))
            sqlite3_bind_int(statement, 5, Int32(category.endHour))
            sqlite3_bind_int(statement, 6, Int32(category.endMinute))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ 分類已儲存")
            }
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - 讀取所有分類
    func loadCategories() -> [Category] {
        let sql = "SELECT id, name, startHour, startMinute, endHour, endMinute FROM categories;"
        var statement: OpaquePointer?
        var categories: [Category] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let idString = String(cString: sqlite3_column_text(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let startHour = Int(sqlite3_column_int(statement, 2))
                let startMinute = Int(sqlite3_column_int(statement, 3))
                let endHour = Int(sqlite3_column_int(statement, 4))
                let endMinute = Int(sqlite3_column_int(statement, 5))
                
                if let uuid = UUID(uuidString: idString) {
                    let category = Category(
                        id: uuid,
                        name: name,
                        startHour: startHour,
                        startMinute: startMinute,
                        endHour: endHour,
                        endMinute: endMinute
                    )
                    categories.append(category)
                }
            }
        }
        sqlite3_finalize(statement)
        return categories
    }
    
    // MARK: - 儲存預算
    func saveBudget(_ budget: Int) {
        let sql = "INSERT OR REPLACE INTO settings (key, value) VALUES ('monthlyBudget', ?);"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, String(budget), -1, nil)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - 讀取預算
    func loadBudget() -> Int {
        let sql = "SELECT value FROM settings WHERE key = 'monthlyBudget';"
        var statement: OpaquePointer?
        var budget = 10000 // 預設值
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let value = String(cString: sqlite3_column_text(statement, 0))
                budget = Int(value) ?? 10000
            }
        }
        sqlite3_finalize(statement)
        return budget
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
}
