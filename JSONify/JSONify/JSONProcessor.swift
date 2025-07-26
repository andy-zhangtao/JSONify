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
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0.0
    @Published var processingStatus: String = ""
    
    // TODO: 将来可以添加JSONHealer支持
    private var debounceTimer: Timer?
    private var processingTask: Task<Void, Never>?
    private var encodingConversionTimer: Timer?
    
    deinit {
        debounceTimer?.invalidate()
        encodingConversionTimer?.invalidate()
        processingTask?.cancel()
    }
    
    private func cancelCurrentProcessing() {
        debounceTimer?.invalidate()
        encodingConversionTimer?.invalidate()
        processingTask?.cancel()
        
        DispatchQueue.main.async {
            self.isProcessing = false
            self.processingProgress = 0.0
            self.processingStatus = ""
        }
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
        performEncodingConversion(
            type: "Unicode转换",
            converter: convertUnicodeSequences
        )
    }
    
    func convertHTMLToChineseCharacters() {
        performEncodingConversion(
            type: "HTML转换",
            converter: convertHTMLEntities
        )
    }
    
    func convertURLEncoding() {
        performEncodingConversion(
            type: "URL解码",
            converter: convertURLEncodedString
        )
    }
    
    private func performEncodingConversion(type: String, converter: @escaping (String) -> String) {
        // 取消之前的处理
        cancelCurrentProcessing()
        
        let inputLength = inputText.count
        
        // 防抖延迟：根据文本长度调整
        let debounceDelay: TimeInterval = inputLength > 50000 ? 0.8 : (inputLength > 10000 ? 0.5 : 0.2)
        
        encodingConversionTimer = Timer.scheduledTimer(withTimeInterval: debounceDelay, repeats: false) { _ in
            self.performAsyncEncodingConversion(type: type, converter: converter)
        }
    }
    
    @MainActor
    private func performAsyncEncodingConversion(type: String, converter: @escaping (String) -> String) {
        isProcessing = true
        processingProgress = 0.0
        processingStatus = "\(type)中..."
        
        let inputToProcess = inputText
        
        processingTask = Task {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // 更新进度
            await MainActor.run {
                self.processingProgress = 0.1
            }
            
            // 检查取消
            if Task.isCancelled { return }
            
            let result = await Task.detached {
                return converter(inputToProcess)
            }.value
            
            // 检查取消
            if Task.isCancelled { return }
            
            await MainActor.run {
                self.processingProgress = 0.9
            }
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            // 模拟最后的处理阶段
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            
            await MainActor.run {
                if !Task.isCancelled {
                    self.inputText = result
                    self.processingProgress = 1.0
                    self.processingStatus = "\(type)完成"
                    self.processingTime = timeElapsed
                    
                    // 延迟隐藏进度条
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isProcessing = false
                        self.processingProgress = 0.0
                        self.processingStatus = ""
                    }
                }
            }
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
        // 使用流式字符串构建器，避免频繁内存重分配
        var result = ""
        result.reserveCapacity(input.count) // 预分配容量
        
        let unicodePattern = #"\\u([0-9a-fA-F]{4})"#
        
        do {
            let regex = try NSRegularExpression(pattern: unicodePattern, options: [])
            let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.count))
            
            if matches.isEmpty {
                return input // 没有匹配，直接返回
            }
            
            var lastLocation = 0
            
            // 一次性构建结果字符串，避免反复替换
            for match in matches {
                let matchRange = match.range
                let hexRange = match.range(at: 1)
                
                // 添加匹配前的部分
                if lastLocation < matchRange.location {
                    let startIndex = input.index(input.startIndex, offsetBy: lastLocation)
                    let endIndex = input.index(input.startIndex, offsetBy: matchRange.location)
                    result.append(String(input[startIndex..<endIndex]))
                }
                
                // 转换Unicode序列
                if let hexStringRange = Range(hexRange, in: input) {
                    let hexString = String(input[hexStringRange])
                    if let unicodeValue = UInt32(hexString, radix: 16),
                       let scalar = UnicodeScalar(unicodeValue) {
                        result.append(Character(scalar))
                    } else {
                        // 如果转换失败，保留原始文本
                        let fullRange = Range(matchRange, in: input)!
                        result.append(String(input[fullRange]))
                    }
                } else {
                    // 如果范围无效，保留原始文本
                    let fullRange = Range(matchRange, in: input)!
                    result.append(String(input[fullRange]))
                }
                
                lastLocation = matchRange.location + matchRange.length
            }
            
            // 添加最后一部分
            if lastLocation < input.count {
                let startIndex = input.index(input.startIndex, offsetBy: lastLocation)
                result.append(String(input[startIndex...]))
            }
            
        } catch {
            // 如果正则表达式失败，返回原字符串
            return input
        }
        
        return result
    }
    
    private func convertHTMLEntities(_ input: String) -> String {
        // 使用流式字符串构建，一次性处理所有类型的HTML实体
        var result = ""
        result.reserveCapacity(input.count)
        
        // 合并所有HTML实体模式，一次扫描处理
        let combinedPattern = #"&(?:amp|lt|gt|quot|apos|nbsp);|&#(\d+);|&#x([0-9a-fA-F]+);|&#39;|&#34;|&#38;|&#60;|&#62;|&#160;"#
        
        do {
            let regex = try NSRegularExpression(pattern: combinedPattern, options: [])
            let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.count))
            
            if matches.isEmpty {
                return input // 没有HTML实体，直接返回
            }
            
            var lastLocation = 0
            
            for match in matches {
                let matchRange = match.range
                
                // 添加匹配前的部分
                if lastLocation < matchRange.location {
                    let startIndex = input.index(input.startIndex, offsetBy: lastLocation)
                    let endIndex = input.index(input.startIndex, offsetBy: matchRange.location)
                    result.append(String(input[startIndex..<endIndex]))
                }
                
                // 获取匹配的实体
                let fullRange = Range(matchRange, in: input)!
                let entity = String(input[fullRange])
                
                // 转换实体
                let replacement = convertSingleHTMLEntity(entity)
                result.append(replacement)
                
                lastLocation = matchRange.location + matchRange.length
            }
            
            // 添加最后一部分
            if lastLocation < input.count {
                let startIndex = input.index(input.startIndex, offsetBy: lastLocation)
                result.append(String(input[startIndex...]))
            }
            
        } catch {
            return input
        }
        
        return result
    }
    
    private func convertSingleHTMLEntity(_ entity: String) -> String {
        // 命名实体映射
        switch entity {
        case "&amp;": return "&"
        case "&lt;": return "<"
        case "&gt;": return ">"
        case "&quot;": return "\""
        case "&apos;": return "'"
        case "&nbsp;": return " "
        case "&#39;": return "'"
        case "&#34;": return "\""
        case "&#38;": return "&"
        case "&#60;": return "<"
        case "&#62;": return ">"
        case "&#160;": return " "
        default:
            // 处理数字实体和十六进制实体
            if entity.hasPrefix("&#x") && entity.hasSuffix(";") {
                // 十六进制实体
                let hexString = String(entity.dropFirst(3).dropLast(1))
                if let number = UInt32(hexString, radix: 16),
                   let scalar = UnicodeScalar(number) {
                    return String(Character(scalar))
                }
            } else if entity.hasPrefix("&#") && entity.hasSuffix(";") {
                // 数字实体
                let numberString = String(entity.dropFirst(2).dropLast(1))
                if let number = UInt32(numberString),
                   let scalar = UnicodeScalar(number) {
                    return String(Character(scalar))
                }
            }
            // 如果无法转换，返回原实体
            return entity
        }
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