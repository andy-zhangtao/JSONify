import Foundation
import JSONHealer

enum JSONValidationError: Error {
    case invalidJSON(message: String, line: Int?, column: Int?)
    case emptyInput
    
    var localizedDescription: String {
        switch self {
        case .invalidJSON(let message, let line, let column):
            if let line = line, let column = column {
                return "第 \(line) 行，第 \(column) 列：\(message)"
            } else {
                return "JSON 格式错误：\(message)"
            }
        case .emptyInput:
            return "输入不能为空"
        }
    }
}

class JSONProcessor: ObservableObject {
    @Published var inputText: String = ""
    @Published var formattedJSON: String = ""
    @Published var validationError: JSONValidationError?
    @Published var isValid: Bool = false
    @Published var processingTime: TimeInterval?
    
    private let jsonHealer = JSONHealer()
    private var debounceTimer: Timer?
    
    deinit {
        debounceTimer?.invalidate()
    }
    
    func processJSON(sortKeys: Bool = true) {
        debounceTimer?.invalidate()
        
        let inputLength = inputText.count
        let debounceDelay: TimeInterval = inputLength > 10000 ? 0.5 : 0.3
        
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDelay, repeats: false) { _ in
            if inputLength > 100000 {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.performJSONProcessing(sortKeys: sortKeys)
                }
            } else {
                DispatchQueue.main.async {
                    self.performJSONProcessing(sortKeys: sortKeys)
                }
            }
        }
    }
    
    private func performJSONProcessing(sortKeys: Bool) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async {
                self.validationError = .emptyInput
                self.isValid = false
                self.formattedJSON = ""
                self.processingTime = nil
            }
            return
        }
        
        do {
            let healedJSON = try jsonHealer.heal(jsonString: inputText)
            
            guard let data = healedJSON.data(using: .utf8) else {
                validationError = .invalidJSON(message: "无法解析输入", line: nil, column: nil)
                isValid = false
                formattedJSON = ""
                return
            }
            
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            var options: JSONSerialization.WritingOptions = [.prettyPrinted]
            if sortKeys {
                options.insert(.sortedKeys)
            }
            
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
            
            if let prettyString = String(data: prettyData, encoding: .utf8) {
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                DispatchQueue.main.async {
                    self.formattedJSON = prettyString
                    self.isValid = true
                    self.validationError = nil
                    self.processingTime = timeElapsed
                }
            } else {
                throw JSONValidationError.invalidJSON(message: "格式化失败", line: nil, column: nil)
            }
            
        } catch {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            DispatchQueue.main.async {
                if let jsonError = error as? JSONValidationError {
                    self.validationError = jsonError
                } else {
                    self.validationError = self.parseJSONError(error: error)
                }
                self.isValid = false
                self.formattedJSON = ""
                self.processingTime = timeElapsed
            }
        }
    }
    
    private func parseJSONError(error: Error) -> JSONValidationError {
        let errorString = error.localizedDescription
        
        if let nsError = error as NSError? {
            var line: Int?
            var column: Int?
            
            if let userInfo = nsError.userInfo as? [String: Any] {
                if let lineNumber = userInfo["NSJSONReadingErrorLineNumber"] as? Int {
                    line = lineNumber
                }
                if let columnNumber = userInfo["NSJSONReadingErrorColumnNumber"] as? Int {
                    column = columnNumber
                }
            }
            
            var message = "JSON 格式错误"
            if errorString.contains("badly formed object") {
                message = "对象格式错误，请检查大括号是否正确闭合"
            } else if errorString.contains("Invalid character") {
                message = "无效字符，请检查是否有非法字符"
            } else if errorString.contains("Expected") {
                message = "语法错误，请检查JSON结构"
            } else if errorString.contains("Unterminated string") {
                message = "字符串未正确结束，请检查引号是否配对"
            } else if errorString.contains("duplicate key") {
                message = "存在重复的键名"
            } else if errorString.contains("trailing comma") {
                message = "存在多余的逗号"
            } else if errorString.contains("No value") {
                message = "缺少值"
            }
            
            return JSONValidationError.invalidJSON(message: message, line: line, column: column)
        }
        
        return JSONValidationError.invalidJSON(message: "JSON解析失败: \(errorString)", line: nil, column: nil)
    }
}