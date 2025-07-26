import Foundation

enum JSONValidationError: Error, Equatable {
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
    
    // TODO: 将来可以添加JSONHealer支持
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
            // 先尝试直接解析JSON
            guard let data = inputText.data(using: String.Encoding.utf8) else {
                DispatchQueue.main.async {
                    self.validationError = .invalidJSON(message: "无法解析输入", line: nil, column: nil)
                    self.isValid = false
                    self.formattedJSON = ""
                }
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
    
    func unescapeJSONString() {
        let unescaped = unescapeString(inputText)
        DispatchQueue.main.async {
            self.inputText = unescaped
        }
    }
    
    func convertUnicodeToChineseCharacters() {
        let converted = convertUnicodeSequences(inputText)
        DispatchQueue.main.async {
            self.inputText = converted
        }
    }
    
    func convertHTMLToChineseCharacters() {
        let converted = convertHTMLEntities(inputText)
        DispatchQueue.main.async {
            self.inputText = converted
        }
    }
    
    func convertURLEncoding() {
        let converted = convertURLEncodedString(inputText)
        DispatchQueue.main.async {
            self.inputText = converted
        }
    }
    
    private func unescapeString(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 尝试使用JSON反序列化来正确处理转义的JSON字符串
        if let data = trimmed.data(using: .utf8) {
            do {
                // 尝试将输入作为JSON字符串解析，使用allowFragments选项
                if let jsonString = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? String {
                    return jsonString
                }
            } catch {
                // 如果不是JSON字符串，继续尝试其他方法
            }
        }
        
        // 如果JSON解析失败，返回原始输入（去掉外层引号）
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
            return String(trimmed.dropFirst().dropLast())
        }
        
        return trimmed
    }
    
    private func convertUnicodeSequences(_ input: String) -> String {
        var result = input
        
        // 匹配 \uXXXX 格式的Unicode序列
        let unicodePattern = #"\\u([0-9a-fA-F]{4})"#
        
        do {
            let regex = try NSRegularExpression(pattern: unicodePattern, options: [])
            let matches = regex.matches(in: result, options: [], range: NSRange(location: 0, length: result.count))
            
            // 从后往前替换，避免索引偏移问题
            for match in matches.reversed() {
                if let unicodeRange = Range(match.range(at: 1), in: result),
                   let fullRange = Range(match.range, in: result) {
                    let unicodeHex = String(result[unicodeRange])
                    if let unicodeValue = UInt32(unicodeHex, radix: 16),
                       let scalar = UnicodeScalar(unicodeValue) {
                        let character = String(Character(scalar))
                        result.replaceSubrange(fullRange, with: character)
                    }
                }
            }
        } catch {
            // 如果正则表达式失败，返回原字符串
            return input
        }
        
        return result
    }
    
    private func convertHTMLEntities(_ input: String) -> String {
        var result = input
        
        // HTML实体映射表
        let htmlEntities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&nbsp;": " ",
            "&#39;": "'",
            "&#34;": "\"",
            "&#38;": "&",
            "&#60;": "<",
            "&#62;": ">",
            "&#160;": " "
        ]
        
        // 替换命名实体
        for (entity, replacement) in htmlEntities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        // 处理数字实体 &#数字; 格式
        let numericPattern = #"&#(\d+);"#
        do {
            let regex = try NSRegularExpression(pattern: numericPattern, options: [])
            let matches = regex.matches(in: result, options: [], range: NSRange(location: 0, length: result.count))
            
            for match in matches.reversed() {
                if let numberRange = Range(match.range(at: 1), in: result),
                   let fullRange = Range(match.range, in: result) {
                    let numberString = String(result[numberRange])
                    if let number = UInt32(numberString),
                       let scalar = UnicodeScalar(number) {
                        let character = String(Character(scalar))
                        result.replaceSubrange(fullRange, with: character)
                    }
                }
            }
        } catch {
            // 如果正则表达式失败，返回原字符串
            return input
        }
        
        // 处理十六进制实体 &#x十六进制; 格式
        let hexPattern = #"&#x([0-9a-fA-F]+);"#
        do {
            let regex = try NSRegularExpression(pattern: hexPattern, options: [])
            let matches = regex.matches(in: result, options: [], range: NSRange(location: 0, length: result.count))
            
            for match in matches.reversed() {
                if let hexRange = Range(match.range(at: 1), in: result),
                   let fullRange = Range(match.range, in: result) {
                    let hexString = String(result[hexRange])
                    if let number = UInt32(hexString, radix: 16),
                       let scalar = UnicodeScalar(number) {
                        let character = String(Character(scalar))
                        result.replaceSubrange(fullRange, with: character)
                    }
                }
            }
        } catch {
            return input
        }
        
        return result
    }
    
    private func convertURLEncodedString(_ input: String) -> String {
        // 使用 Foundation 的 URL 解码功能
        guard let decoded = input.removingPercentEncoding else {
            return input
        }
        return decoded
    }
    
    private func parseJSONError(error: Error) -> JSONValidationError {
        let errorString = error.localizedDescription
        
        if let nsError = error as NSError? {
            var line: Int?
            var column: Int?
            
            let userInfo = nsError.userInfo
            if let lineNumber = userInfo["NSJSONReadingErrorLineNumber"] as? Int {
                line = lineNumber
            }
            if let columnNumber = userInfo["NSJSONReadingErrorColumnNumber"] as? Int {
                column = columnNumber
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