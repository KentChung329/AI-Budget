import Foundation

class GeminiService {
    private let apiKey = Config.geminiAPIKey
    
    func queryExpenses(expenses: [Expense], question: String) async throws -> String {
        // 檢查是否有支出資料
        guard !expenses.isEmpty else {
            return "目前還沒有任何支出記錄，無法進行分析。請先記帳後再來問我問題！"
        }
        
        // 將支出資料轉換成文字格式
        let expenseData = formatExpenses(expenses)
        
        // 建立提示詞
        let prompt = """
        你是一個專業的記帳分析助手。以下是使用者的所有支出記錄：
        
        \(expenseData)
        
        使用者問題：\(question)
        
        請根據上述資料回答問題。如果需要計算金額，請提供準確的數字。回答要簡潔、清楚，用繁體中文。
        """
        
        // 使用 gemini-2.5-flash 模型
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "無效的 URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2048,  // 增加到 2048（原本 500 太小）
                "topP": 0.9,
                "topK": 40
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw NSError(domain: "GeminiService", code: -2, userInfo: [NSLocalizedDescriptionKey: "無法序列化請求"])
        }
        
        // 發送請求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "GeminiService", code: -3, userInfo: [NSLocalizedDescriptionKey: "無效的回應"])
            }
            
            // 處理錯誤狀態碼
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "未知錯誤"
                print("❌ API 錯誤 (\(httpResponse.statusCode)): \(errorMessage)")
                
                let friendlyMessage: String
                switch httpResponse.statusCode {
                case 401:
                    friendlyMessage = "API Key 無效，請檢查設定"
                case 403:
                    friendlyMessage = "API 存取被拒絕，請確認 API Key 權限"
                case 404:
                    friendlyMessage = "API 端點不存在，請聯絡開發者"
                case 429:
                    friendlyMessage = "請求次數超過限制，請稍後再試（免費版：15次/分鐘）"
                case 500...599:
                    friendlyMessage = "Google 伺服器錯誤，請稍後再試"
                default:
                    friendlyMessage = "API 錯誤 (\(httpResponse.statusCode))"
                }
                
                throw NSError(domain: "GeminiService", code: httpResponse.statusCode,
                             userInfo: [NSLocalizedDescriptionKey: friendlyMessage])
            }
            
            // 解析回應
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let candidates = json?["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                return text
            }
            
            // 檢查是否因為安全過濾被截斷
            if let candidates = json?["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let finishReason = firstCandidate["finishReason"] as? String {
                
                if finishReason == "MAX_TOKENS" {
                    throw NSError(domain: "GeminiService", code: -5,
                                 userInfo: [NSLocalizedDescriptionKey: "回答太長被截斷，請簡化問題"])
                } else if finishReason == "SAFETY" {
                    throw NSError(domain: "GeminiService", code: -6,
                                 userInfo: [NSLocalizedDescriptionKey: "內容被安全過濾器阻擋"])
                }
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "無法解析"
            print("❌ 無法解析回應: \(responseString)")
            throw NSError(domain: "GeminiService", code: -4, userInfo: [NSLocalizedDescriptionKey: "無法解析 API 回應"])
            
        } catch let error as NSError {
            if error.domain == NSURLErrorDomain {
                throw NSError(domain: "GeminiService", code: error.code,
                             userInfo: [NSLocalizedDescriptionKey: "網路連線失敗，請檢查網路設定"])
            }
            throw error
        }
    }
    
    // 將支出資料格式化成文字
    private func formatExpenses(_ expenses: [Expense]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        var result = ""
        // 限制最近 50 筆，避免 prompt 太長
        let recentExpenses = expenses.sorted(by: { $0.date > $1.date }).prefix(50)
        
        for expense in recentExpenses {
            let dateStr = dateFormatter.string(from: expense.date)
            let note = expense.note ?? ""
            result += "日期：\(dateStr)，分類：\(expense.categoryName)，金額：\(expense.amount) 元"
            if !note.isEmpty {
                result += "，備註：\(note)"
            }
            result += "\n"
        }
        
        return result
    }
}
