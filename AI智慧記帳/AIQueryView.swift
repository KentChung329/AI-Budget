import SwiftUI

struct AIQueryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var manager: CategoryManager
    
    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    private let geminiService = GeminiService()
    
    // 常見問題範例
    private let exampleQuestions = [
        "這個月飲品花了多少？",
        "上週晚餐總共多少錢？",
        "我哪一天花最多錢？",
        "本月交通費用統計",
        "分析我的消費習慣"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 回答區域
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isLoading {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("AI 正在分析中...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.top, 60)
                        } else if !answer.isEmpty {
                            // AI 回答
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.orange)
                                    Text("AI 回答")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                }
                                
                                Text(answer)
                                    .font(.body)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.orange.opacity(0.1))
                                    )
                            }
                            .padding()
                        } else {
                            // 歡迎畫面
                            VStack(spacing: 20) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 60))
                                    .foregroundColor(.orange)
                                    .padding(.top, 40)
                                
                                Text("AI 智能查詢")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("問我任何關於你的支出問題")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // 常見問題
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("試試看這些問題：")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                    
                                    ForEach(exampleQuestions, id: \.self) { example in
                                        Button {
                                            question = example
                                        } label: {
                                            HStack {
                                                Image(systemName: "lightbulb.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.yellow)
                                                Text(example)
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                            }
                                            .padding(8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.gray.opacity(0.1))
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                Divider()
                
                // 輸入區域
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        TextField("輸入你的問題...", text: $question)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isLoading)
                        
                        Button {
                            askAI()
                        } label: {
                            Image(systemName: isLoading ? "stop.circle.fill" : "paperplane.fill")
                                .font(.title2)
                                .foregroundColor(question.isEmpty ? .gray : .orange)
                        }
                        .disabled(question.isEmpty || isLoading)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if !answer.isEmpty {
                        Button {
                            question = ""
                            answer = ""
                        } label: {
                            Text("清除對話")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 4)
                    }
                }
                .padding(.bottom, 8)
                .background(Color(.systemBackground))
            }
            .navigationTitle("AI 智能查詢")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
            .alert("錯誤", isPresented: $showError) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - 詢問 AI
    private func askAI() {
        guard !question.isEmpty else { return }
        
        isLoading = true
        answer = ""
        
        Task {
            do {
                let response = try await geminiService.queryExpenses(
                    expenses: manager.expenses,
                    question: question
                )
                
                await MainActor.run {
                    answer = response
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
