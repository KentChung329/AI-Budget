import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: CategoryManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingAddExpense = true
    @State private var showingSettings = false
    @State private var showingAIQuery = false

    private let chartColors: [String: Color] = [
        "早餐": .orange,
        "午餐": .blue,
        "晚餐": .purple,
        "宵夜": .yellow,
        "飲品": .green,
        "其他": .red
    ]

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                List {
                    Section {
                        summaryCard
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)

                        spendingCircle
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }

                    expenseSection
                }
                .listStyle(.plain)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())

                addButton
            }
            .navigationTitle("AI 智慧記帳")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingAIQuery = true
                    } label: {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.orange)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
                .environmentObject(manager)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(manager)
        }
        .sheet(isPresented: $showingAIQuery) {
            AIQueryView()
                .environmentObject(manager)
        }
        .onAppear {
            showingAddExpense = true
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                showingAddExpense = true
            }
        }
    }

    // MARK: - 上方摘要卡片
    private var summaryCard: some View {
        let today = manager.getTodaySpent()
        let month = manager.getMonthlySpent()
        let remaining = max(manager.monthlyBudget - month, 0)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("本日已花")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(today) 元")
                    .font(.title3).bold()
            }

            HStack {
                Text("本月已花")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(month) 元")
                    .font(.headline)
            }

            HStack {
                Text("本月預算剩餘")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(remaining) 元 / 預算 \(manager.monthlyBudget) 元")
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, 8)
    }

    // MARK: - Chart slice model & data
    private struct ChartSlice: Identifiable {
        let id = UUID()
        let name: String
        let color: Color
        let start: CGFloat
        let end: CGFloat
        let amount: Int
    }

    private func buildChartDataAgainstBudget() -> (slices: [ChartSlice], remainStart: CGFloat) {
        let budget = max(manager.monthlyBudget, 1)
        let mainNames = ["早餐", "午餐", "晚餐", "宵夜", "飲品"]
        var sums: [String: Int] = [:]
        var otherSum = 0

        for e in manager.expenses {
            let comp = Calendar.current.dateComponents([.year, .month], from: e.date)
            let nowComp = Calendar.current.dateComponents([.year, .month], from: Date())
            guard comp.year == nowComp.year, comp.month == nowComp.month else { continue }

            if mainNames.contains(e.categoryName) {
                sums[e.categoryName, default: 0] += e.amount
            } else {
                otherSum += e.amount
            }
        }

        var slices: [ChartSlice] = []
        var current: CGFloat = 0

        func appendSlice(name: String, amount: Int) {
            guard amount > 0, current < 1 else { return }
            let ratio = min(CGFloat(amount) / CGFloat(budget), 1 - current)
            guard ratio > 0 else { return }
            let color = chartColors[name] ?? .orange
            slices.append(
                ChartSlice(
                    name: name,
                    color: color,
                    start: current,
                    end: current + ratio,
                    amount: amount
                )
            )
            current += ratio
        }

        for name in mainNames {
            appendSlice(name: name, amount: sums[name, default: 0])
        }
        appendSlice(name: "其他", amount: otherSum)

        return (slices, current)
    }

    // MARK: - 圓餅圖
    private var spendingCircle: some View {
        let (slices, _) = buildChartDataAgainstBudget()
        let monthSpent = manager.getMonthlySpent()
        let budget = max(manager.monthlyBudget, 1)
        let remaining = max(budget - monthSpent, 0)
        let lineWidth: CGFloat = 24

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                // 左邊圖例
                let legendOrder = ["早餐", "午餐", "晚餐", "宵夜", "飲品", "其他", "剩餘預算"]
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(legendOrder, id: \.self) { name in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(name == "剩餘預算"
                                      ? Color.gray.opacity(0.2)
                                      : (chartColors[name] ?? .gray))
                                .frame(width: 10, height: 10)
                            Text(name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 100)
                
                // 右邊甜甜圈
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

                    ForEach(slices) { s in
                        Circle()
                            .trim(from: s.start, to: s.end)
                            .stroke(
                                s.color,
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                            )
                            .rotationEffect(.degrees(-90))
                    }

                    VStack(spacing: 4) {
                        Text("本月剩餘")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(remaining) 元")
                            .font(.title3).bold()
                    }
                }
                .frame(width: 190, height: 190)
                .padding(.top, 20)
                .padding(.trailing, 90)

            }
            .padding(.horizontal)
            .padding(.top, 8)

            Text("一整圈代表本月預算，彩色為各分類已花比例，灰色為尚未花掉的預算。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 支出列表
    private var expenseSection: some View {
        let sorted = manager.expenses.sorted(by: { $0.date > $1.date })
        let grouped = Dictionary(grouping: sorted) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
        let sortedKeys = grouped.keys.sorted(by: >)

        return ForEach(sortedKeys, id: \.self) { date in
            let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
            let y = comps.year ?? 0
            let m = comps.month ?? 0
            let d = comps.day ?? 0

            Section(header:
                Text(String(format: "%04d/%02d/%02d", y, m, d))
                    .font(.headline)
            ) {
                ForEach(grouped[date] ?? []) { expense in
                    expenseRow(expense)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteSingle(expense)
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                }
            }
        }
    }

    // MARK: - 單筆支出列
    private func expenseRow(_ expense: Expense) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text(String(expense.categoryName.prefix(1)))
                        .font(.subheadline)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.categoryName)
                        .font(.subheadline)
                    if let note = expense.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text("-\(expense.amount) 元")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        )
    }

    // MARK: - 刪除單筆
    private func deleteSingle(_ expense: Expense) {
        if let index = manager.expenses.firstIndex(where: { $0.id == expense.id }) {
            manager.expenses.remove(at: index)
            manager.saveExpenses()
        }
    }

    // MARK: - 底部大＋按鈕
    private var addButton: some View {
        Button {
            showingAddExpense = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.pink)
                    .frame(width: 72, height: 72)

                Image(systemName: "plus")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .padding(.bottom, 24)
    }
}
