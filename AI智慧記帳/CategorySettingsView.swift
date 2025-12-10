//
//  CategorySettingsView.swift
//  AI智慧記帳
//
//  Created by ҡεηт ” on 2025/12/10.
//
import SwiftUI

struct CategorySettingsView: View {
    @ObservedObject var manager: CategoryManager
    @Environment(\.dismiss) var dismiss
    @State private var showingAddCategory = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(manager.categories) { category in
                    NavigationLink(destination: EditCategoryView(manager: manager, category: category)) {
                        HStack {
                            Circle()
                                .fill(getColor(category.color))
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading) {
                                Text(category.name)
                                    .font(.headline)
                                Text(timeRangeText(category))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteCategories)
            }
            .navigationTitle("管理分類")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(manager: manager)
            }
        }
    }
    
    func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = manager.categories[index]
            manager.deleteCategory(category)
        }
    }
    
    func timeRangeText(_ category: Category) -> String {
        return String(format: "%02d:%02d - %02d:%02d",
                     category.startHour, category.startMinute,
                     category.endHour, category.endMinute)
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

struct EditCategoryView: View {
    @ObservedObject var manager: CategoryManager
    @State var category: Category
    @Environment(\.dismiss) var dismiss
    
    let colors = ["red", "blue", "green", "yellow", "purple", "orange", "pink"]
    
    var body: some View {
        Form {
            Section("基本資訊") {
                TextField("分類名稱", text: $category.name)
                
                Picker("顏色", selection: $category.color) {
                    ForEach(colors, id: \.self) { color in
                        HStack {
                            Circle()
                                .fill(getColor(color))
                                .frame(width: 20, height: 20)
                            Text(color.capitalized)
                        }
                        .tag(color)
                    }
                }
            }
            
            Section("自動判斷時間") {
                HStack {
                    Text("開始時間")
                    Spacer()
                    Picker("小時", selection: $category.startHour) {
                        ForEach(0..<24) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 60)
                    
                    Text(":")
                    
                    Picker("分鐘", selection: $category.startMinute) {
                        ForEach(0..<60) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 60)
                }
                
                HStack {
                    Text("結束時間")
                    Spacer()
                    Picker("小時", selection: $category.endHour) {
                        ForEach(0..<24) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 60)
                    
                    Text(":")
                    
                    Picker("分鐘", selection: $category.endMinute) {
                        ForEach(0..<60) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 60)
                }
            }
        }
        .navigationTitle("編輯分類")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("儲存") {
                    manager.updateCategory(category)
                    dismiss()
                }
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

struct AddCategoryView: View {
    @ObservedObject var manager: CategoryManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var startHour = 0
    @State private var startMinute = 0
    @State private var endHour = 23
    @State private var endMinute = 59
    @State private var color = "blue"
    
    let colors = ["red", "blue", "green", "yellow", "purple", "orange", "pink"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本資訊") {
                    TextField("分類名稱", text: $name)
                    
                    Picker("顏色", selection: $color) {
                        ForEach(colors, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(getColor(color))
                                    .frame(width: 20, height: 20)
                                Text(color.capitalized)
                            }
                            .tag(color)
                        }
                    }
                }
                
                Section("自動判斷時間") {
                    HStack {
                        Text("開始")
                        Spacer()
                        Picker("", selection: $startHour) {
                            ForEach(0..<24) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                        Text(":")
                        Picker("", selection: $startMinute) {
                            ForEach(0..<60) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                    }
                    
                    HStack {
                        Text("結束")
                        Spacer()
                        Picker("", selection: $endHour) {
                            ForEach(0..<24) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                        Text(":")
                        Picker("", selection: $endMinute) {
                            ForEach(0..<60) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60)
                    }
                }
            }
            .navigationTitle("新增分類")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新增") {
                        let newCategory = Category(
                            name: name,
                            startHour: startHour,
                            startMinute: startMinute,
                            endHour: endHour,
                            endMinute: endMinute,
                            color: color
                        )
                        manager.addCategory(newCategory)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
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

