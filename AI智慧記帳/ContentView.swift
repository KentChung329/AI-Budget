import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: CategoryManager
    @State private var showingAddExpense = true   // App 一啟動就跳新增

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack(spacing: 12) {
                    summarySection
                    expenseList
                }
                .padding(.bottom, 40)
                .background(Color(.systemGroupedBackground).ignoresSafeArea())

                addButton
            }
            .navigationTitle("AI 智慧記帳")
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
                .environmentObject(manager)
        }
        .onAppear {
            showingAddExpense = true
        }
    }

    // 上方摘要
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("本日已花：\(manager.getTodaySpent()) 元")
                .font(.title3).bold()
            Text("本月已花：\(manager.getMonthlySpent()) 元")
                .font(.subheadline)
            Text("建議今日可用：\(manager.getDailyBudget()) 元")
                .font(.subheadline)
                .foregroundColor(.secondary)
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

    // 列表
    private var expenseList: some View {
        List {
            ForEach(Array(manager.expenses.sorted(by: { $0.date > $1.date })), id: \.id) { expense in
                expenseRow(expense)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteExpenses)
        }
        .listStyle(.plain)
        .background(Color.clear)
    }

    private func expenseRow(_ expense: Expense) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 42, height: 42)
                    Text(String(expense.categoryName.prefix(1)))
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.categoryName)
                        .font(.headline)
                    Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let note = expense.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text("-\(expense.amount) 元")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

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

    private func deleteExpenses(at offsets: IndexSet) {
        manager.deleteExpenses(at: offsets)
    }
}
