import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: CategoryManager
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    
    private let chartColors: [String: Color] = [
        "早餐": .orange,
        "午餐": .green,
        "晚餐": .blue,
        "宵夜": .purple,
        "飲品": .pink,
        "其他": .gray
    ]
    
    private var yearMonthString: String {
        String(format: "%04d/%02d", selectedYear, selectedMonth)
    }
    
    private var filteredExpenses: [Expense] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM"
        
        return manager.expenses.filter { expense in
            formatter.string(from: expense.date) == yearMonthString
        }
    }
    
    private var totalSpent: Int {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var categoryStats: [(name: String, amount: Int, color: Color)] {
        let grouped = Dictionary(grouping: filteredExpenses) { $0.categoryName }
        return grouped.map { name, expenses in
            let total = expenses.reduce(0) { $0 + $1.amount }
            let color = chartColors[name] ?? .gray
            return (name: name, amount: total, color: color)
        }.sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 年月選擇器
                Form {
                    Section(header: Text("選擇年月")) {
                        HStack {
                            Text("年份")
                            Spacer()
                            Picker("", selection: $selectedYear) {
                                ForEach(2025...2029, id: \.self) { year in
                                    Text(String(format: "%d", year)).tag(year)
                                }
                            }

                            .pickerStyle(.menu)
                        }
                        
                        HStack {
                            Text("月份")
                            Spacer()
                            Picker("", selection: $selectedMonth) {
                                ForEach(1...12, id: \.self) { month in
                                    Text("\(month)月").tag(month)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .frame(height: 160)
                
                Divider()
                
                // 查詢結果
                if filteredExpenses.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("查無資料")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("此月份沒有記帳紀錄")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // 月份標題與總支出
                            VStack(spacing: 8) {
                                Text("\(yearMonthString) 記帳紀錄")
                                    .font(.title2.bold())
                                Text("總支出：NT$ \(totalSpent)")
                                    .font(.title3)
                                    .foregroundColor(.orange)
                            }
                            .padding(.top, 16)
                            
                            // 圓餅圖
                            if !categoryStats.isEmpty {
                                ZStack {
                                    // 繪製多段圓餅圖
                                    ForEach(Array(categoryStats.enumerated()), id: \.offset) { index, stat in
                                        let startAngle = calculateStartAngle(upToIndex: index)
                                        let percentage = Double(stat.amount) / Double(totalSpent)
                                        let endAngle = startAngle + Angle(degrees: 360 * percentage)
                                        
                                        Circle()
                                            .trim(from: startAngle.degrees / 360,
                                                  to: endAngle.degrees / 360)
                                            .stroke(stat.color, lineWidth: 40)
                                            .rotationEffect(.degrees(-90))
                                    }
                                }
                                .frame(width: 190, height: 190)
                                .padding(.top, 20)
                                
                                // 圖例
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(categoryStats, id: \.name) { stat in
                                        HStack {
                                            Circle()
                                                .fill(stat.color)
                                                .frame(width: 12, height: 12)
                                            Text(stat.name)
                                                .font(.caption)
                                            Spacer()
                                            Text("NT$ \(stat.amount)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 40)
                                .padding(.top, 10)
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // 支出列表
                            VStack(alignment: .leading, spacing: 12) {
                                Text("詳細記錄")
                                    .font(.headline)
                                    .padding(.horizontal, 16)
                                
                                ForEach(groupedByDate(), id: \.key) { dateString, expenses in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(dateString)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 16)
                                            .padding(.top, 8)
                                        
                                        ForEach(expenses) { expense in
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(expense.categoryName)
                                                        .font(.body.bold())
                                                    if let note = expense.note, !note.isEmpty {
                                                        Text(note)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                Spacer()
                                                Text("NT$ \(expense.amount)")
                                                    .font(.body.bold())
                                                    .foregroundColor(.orange)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("歷史記帳")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // 計算圓餅圖起始角度
    private func calculateStartAngle(upToIndex: Int) -> Angle {
        var totalPercentage: Double = 0
        for i in 0..<upToIndex {
            let stat = categoryStats[i]
            totalPercentage += Double(stat.amount) / Double(totalSpent)
        }
        return Angle(degrees: 360 * totalPercentage)
    }
    
    // 依日期分組
    private func groupedByDate() -> [(key: String, value: [Expense])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        
        let grouped = Dictionary(grouping: filteredExpenses.sorted { $0.date > $1.date }) { expense in
            formatter.string(from: expense.date)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
}
