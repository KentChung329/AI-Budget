import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: CategoryManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingAddExpense = true
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        summaryCard
                        spendingCircle
                        expenseSection
                    }
                    .padding(.bottom, 80)
                    .background(Color(.systemGroupedBackground).ignoresSafeArea())
                }

                addButton
            }
            .navigationTitle("AI 智慧記帳")
            .toolbar {
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
        .onAppear {
            showingAddExpense = true
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // 每次從背景回到前景都自動跳出新增支出
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
        .padding([.horizontal, .top])
    }

    // MARK: - 簡單圓圈圖
    private var spendingCircle: some View {
        let monthSpent = Double(manager.getMonthlySpent())
        let budget = Double(max(manager.monthlyBudget, 1))
        let ratio = min(monthSpent / budget, 1.0)

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 16)

                Circle()
                    .trim(from: 0, to: ratio)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.blue, Color.orange]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("本月使用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f%%", ratio * 100))
                        .font(.title2).bold()
                }
            }
            .frame(width: 180, height: 180)

            Text("圓圈代表本月支出佔預算比例")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - 支出列表（依日期分段＋可刪除）
    private var expenseSection: some View {
        let sorted = manager.expenses.sorted(by: { $0.date > $1.date })
        let grouped = Dictionary(grouping: sorted) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
        let sortedKeys = grouped.keys.sorted(by: >)

        return VStack(alignment: .leading, spacing: 8) {
            ForEach(sortedKeys, id: \.self) { date in
                let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
                let y = comps.year ?? 0
                let m = comps.month ?? 0
                let d = comps.day ?? 0

                Text(String(format: "%04d/%02d/%02d", y, m, d))
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 4)

                List {
                    ForEach(grouped[date] ?? []) { expense in
                        expenseRow(expense)
                    }
                    .onDelete { offsets in
                        let dayExpenses = grouped[date] ?? []
                        let idsToDelete = offsets.map { dayExpenses[$0].id }
                        let indices = IndexSet(
                            manager.expenses.indices.filter { idsToDelete.contains(manager.expenses[$0].id) }
                        )
                        manager.deleteExpenses(at: indices)
                    }
                }
                .listStyle(.plain)
                .frame(height: CGFloat((grouped[date]?.count ?? 0) * 70))
                .scrollDisabled(true)
            }
        }
        .padding(.bottom, 8)
    }

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

            Text(expense.date.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        )
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
        .padding(.bottom, 8)
    }
}
