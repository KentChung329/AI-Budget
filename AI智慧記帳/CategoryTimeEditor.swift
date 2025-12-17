import SwiftUI

struct CategoryTimeEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: CategoryManager

    let category: Category

    @State private var startHour: Int
    @State private var startMinute: Int
    @State private var endHour: Int
    @State private var endMinute: Int

    init(category: Category) {
        self.category = category
        _startHour = State(initialValue: category.startHour)
        _startMinute = State(initialValue: category.startMinute)
        _endHour = State(initialValue: category.endHour)
        _endMinute = State(initialValue: category.endMinute)
    }

    var body: some View {
        Form {
            Section(header: Text("開始時間")) {
                timeRow(title: "開始", hour: $startHour, minute: $startMinute)
            }
            Section(header: Text("結束時間")) {
                timeRow(title: "結束", hour: $endHour, minute: $endMinute)
            }

            Section {
                Button("儲存") {
                    manager.updateCategoryTime(
                        categoryName: category.name,
                        startHour: startHour,
                        startMinute: startMinute,
                        endHour: endHour,
                        endMinute: endMinute
                    )
                    dismiss()
                }
            }
        }
        .navigationTitle(category.name)
    }

    private func timeRow(title: String,
                         hour: Binding<Int>,
                         minute: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer()

            HStack(spacing: 4) {
                Picker("時", selection: hour) {
                    ForEach(0..<24) { h in
                        Text("\(h)").tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 70)

                Text("時")

                Picker("分", selection: minute) {
                    ForEach(0..<60) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)

                Text("分")
            }
        }
    }
}
