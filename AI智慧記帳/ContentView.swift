//
//  ContentView.swift
//  AI智慧記帳
//
//  Created by ҡεηт ” on 2025/12/10.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var manager = CategoryManager()
    @State private var showingAddExpense = false
    @State private var showingSettings = false
    @State private var selectedCategory: Category?
    
    var dailyBudget: Int {
        manager.getDailyBudget()
    }
    
    var todaySpent: Int {
        manager.getTodaySpent()
    }
    
    var todayRemaining: Int {
        dailyBudget - todaySpent
    }
    
    var isOverBudget: Bool {
        todayRemaining < 0
    }
    
    var monthlySpent: Int {
        manager.getMonthlySpent()
    }
    
    var budgetProgress: Double {
        Double(monthlySpent) / Double(manager.monthlyBudget)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景漸層
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.85, blue: 1.0),
                        Color(red: 0.85, green: 0.95, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 今日可用額度卡片
                        VStack(spacing: 15) {
                            Text("今日可用")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("$\(abs(todayRemaining))")
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundColor(isOverBudget ? .red : .green)
                            
                            if isOverBudget {
                                Text("已超支")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            // 本月進度條
                            VStack(alignment: .leading, spacing: 8) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 20)
                                        
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.green, Color.yellow, Color.orange],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geometry.size.width * min(budgetProgress, 1.0), height: 20)
                                    }
                                }
                                .frame(height: 20)
                                
                                HStack {
                                    Text("本月已花 $\(monthlySpent)")
                                        .font(.caption)
                                    Spacer()
                                    Text("/ $\(manager.monthlyBudget)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(30)
                        .background(Color.white)
                        .cornerRadius(25)
                        .shadow(color: .gray.opacity(0.2), radius: 15, x: 0, y: 8)
                        .padding(.horizontal)
                        
                        // 快速記帳按鈕
                        VStack(spacing: 20) {
                            Text("快速記帳")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                ForEach(manager.categories) { category in
                                    CategoryButton(category: category) {
                                        selectedCategory = category
                                        showingAddExpense = true
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("💰 智慧記帳")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                if let category = selectedCategory {
                    AddExpenseView(manager: manager, category: category)
                }
            }
            .sheet(isPresented: $showingSettings) {
                CategorySettingsView(manager: manager)
            }
        }
    }
}

struct CategoryButton: View {
    let category: Category
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(getColor(category.color))
                        .frame(width: 65, height: 65)
                        .shadow(color: getColor(category.color).opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Text(category.name.prefix(2))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(category.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
        }
    }
    
    func getColor(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        default: return .gray
        }
    }
}

struct AddExpenseView: View {
    @ObservedObject var manager: CategoryManager
    @State var category: Category
    @Environment(\.dismiss) var dismiss
    @State private var amount = ""
    
    var body: some View {
        VStack(spacing: 30) {
            // 頂部顯示分類
            HStack {
                Button("取消") {
                    dismiss()
                }
                Spacer()
                Text(category.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("完成") {
                    if let amountInt = Int(amount), amountInt > 0 {
                        manager.addExpense(amount: amountInt, categoryName: category.name)
                        dismiss()
                    }
                }
                .disabled(amount.isEmpty || Int(amount) == nil)
            }
            .padding()
            
            // 金額顯示
            Text("$\(amount.isEmpty ? "0" : amount)")
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            // 數字鍵盤
            VStack(spacing: 15) {
                ForEach(0..<3) { row in
                    HStack(spacing: 15) {
                        ForEach(1..<4) { col in
                            let number = row * 3 + col
                            NumberButton(number: "\(number)") {
                                amount += "\(number)"
                            }
                        }
                    }
                }
                
                HStack(spacing: 15) {
                    NumberButton(number: "00") {
                        amount += "00"
                    }
                    NumberButton(number: "0") {
                        amount += "0"
                    }
                    NumberButton(number: "⌫", color: .red) {
                        if !amount.isEmpty {
                            amount.removeLast()
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            // 根據時間自動判斷分類
            if let autoCategory = manager.getCategoryByTime() {
                category = autoCategory
            }
        }
    }
}

struct NumberButton: View {
    let number: String
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(color)
                .cornerRadius(40)
        }
    }
}

#Preview {
    ContentView()
}

