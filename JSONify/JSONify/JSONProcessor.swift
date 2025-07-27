import Foundation
import NaturalLanguage

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
    @Published var aiErrorSuggestion: String?
    @Published var isAIAnalyzing: Bool = false
    
    // TODO: 将来可以添加JSONHealer支持
    private var debounceTimer: Timer?
    private var processingTask: Task<Void, Never>?
    private var encodingConversionTimer: Timer?
    
    // AI错误分析器
    @available(macOS 15.0, *)
    private lazy var aiErrorAnalyzer = AIErrorAnalyzer()
    
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
        
        // 更新进度状态
        DispatchQueue.main.async {
            self.isProcessing = true
            self.processingProgress = 0.0
            self.processingStatus = "解析JSON..."
        }
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async {
                self.validationError = .emptyInput
                self.isValid = false
                self.formattedJSON = ""
                self.processingTime = nil
                self.isProcessing = false
            }
            return
        }
        
        do {
            // 第一步：解析JSON
            guard let data = inputText.data(using: String.Encoding.utf8) else {
                DispatchQueue.main.async {
                    self.validationError = .invalidJSON(message: "无法解析输入", line: nil, column: nil)
                    self.isValid = false
                    self.formattedJSON = ""
                    self.isProcessing = false
                }
                return
            }
            
            // 更新进度
            DispatchQueue.main.async {
                self.processingProgress = 0.3
                self.processingStatus = "验证JSON格式..."
            }
            
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            // 更新进度
            DispatchQueue.main.async {
                self.processingProgress = 0.6
                self.processingStatus = "格式化JSON..."
            }
            
            var options: JSONSerialization.WritingOptions = [.prettyPrinted]
            if sortKeys {
                options.insert(.sortedKeys)
            }
            
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
            
            // 更新进度
            DispatchQueue.main.async {
                self.processingProgress = 0.9
                self.processingStatus = "应用格式化结果..."
            }
            
            if let prettyString = String(data: prettyData, encoding: .utf8) {
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                
                // 对于大文件，异步渐进式设置结果，避免UI冻结
                if prettyString.count > 500000 {
                    self.setLargeFormattedJSON(prettyString, timeElapsed: timeElapsed)
                } else {
                    DispatchQueue.main.async {
                        self.formattedJSON = prettyString
                        self.isValid = true
                        self.validationError = nil
                        self.processingTime = timeElapsed
                        self.isProcessing = false
                        self.processingProgress = 1.0
                        self.processingStatus = "处理完成"
                    }
                }
            } else {
                throw JSONValidationError.invalidJSON(message: "格式化失败", line: nil, column: nil)
            }
            
        } catch {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            let jsonError: JSONValidationError
            if let validationError = error as? JSONValidationError {
                jsonError = validationError
            } else {
                jsonError = self.parseJSONError(error: error)
            }
            
            DispatchQueue.main.async {
                self.validationError = jsonError
                self.isValid = false
                self.formattedJSON = ""
                self.processingTime = timeElapsed
                self.isProcessing = false
                self.processingProgress = 0.0
                self.processingStatus = ""
                
                // 启动AI错误分析
                self.performAIErrorAnalysis(jsonInput: self.inputText, error: jsonError)
            }
        }
    }
    
    // 异步渐进式设置大JSON结果，避免UI冻结
    private func setLargeFormattedJSON(_ content: String, timeElapsed: TimeInterval) {
        // 延迟一帧，让进度条有时间更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.formattedJSON = content
            self.isValid = true
            self.validationError = nil
            self.processingTime = timeElapsed
            self.isProcessing = false
            self.processingProgress = 1.0
            self.processingStatus = "处理完成"
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
    
    // 同步版本供测试使用
    func convertUnicodeToChineseCharactersSync() {
        inputText = convertUnicodeSequences(inputText)
    }
    
    func convertHTMLToChineseCharactersSync() {
        inputText = convertHTMLEntities(inputText)
    }
    
    func convertURLEncodingSync() {
        inputText = convertURLEncodedString(inputText)
    }
    
    private func performEncodingConversion(type: String, converter: @escaping (String) -> String) {
        // 取消之前的处理
        cancelCurrentProcessing()
        
        let inputLength = inputText.count
        
        // 防抖延迟：根据文本长度调整
        let debounceDelay: TimeInterval = inputLength > 50000 ? 0.8 : (inputLength > 10000 ? 0.5 : 0.2)
        
        encodingConversionTimer = Timer.scheduledTimer(withTimeInterval: debounceDelay, repeats: false) { _ in
            Task {
                await self.performAsyncEncodingConversion(type: type, converter: converter)
            }
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
        return performBatchReplacement(
            input: input,
            pattern: #"\\u([0-9a-fA-F]{4})"#,
            transformer: { match, input in
                // 提取十六进制值
                guard let hexRange = Range(match.range(at: 1), in: input) else {
                    return nil // 保留原文
                }
                let hexString = String(input[hexRange])
                
                // 转换为Unicode字符
                guard let unicodeValue = UInt32(hexString, radix: 16),
                      let scalar = UnicodeScalar(unicodeValue) else {
                    return nil // 保留原文
                }
                
                return String(Character(scalar))
            }
        )
    }
    
    /// 批量替换算法核心实现
    /// - Parameters:
    ///   - input: 输入字符串  
    ///   - pattern: 正则表达式模式
    ///   - transformer: 转换函数，返回nil表示保留原文
    /// - Returns: 处理后的字符串
    private func performBatchReplacement(
        input: String,
        pattern: String,
        transformer: (NSTextCheckingResult, String) -> String?
    ) -> String {
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.count))
            
            if matches.isEmpty {
                return input // 没有匹配，直接返回
            }
            
            // 第一阶段：批量收集所有转换结果
            var replacements: [(range: NSRange, replacement: String)] = []
            replacements.reserveCapacity(matches.count)
            
            for (index, match) in matches.enumerated() {
                if let replacement = transformer(match, input) {
                    replacements.append((range: match.range, replacement: replacement))
                }
                // nil表示保留原文，不加入替换列表
                
                // 进度反馈：处理大批量匹配时更新进度
                if matches.count > 1000 && index % 100 == 0 {
                    let progress = Double(index) / Double(matches.count) * 0.3 // 第一阶段占30%
                    DispatchQueue.main.async {
                        if self.isProcessing {
                            self.processingProgress = 0.1 + progress
                        }
                    }
                }
            }
            
            if replacements.isEmpty {
                return input // 没有需要替换的内容
            }
            
            // 第二阶段：计算最终字符串长度并预分配
            let originalLength = input.count
            let totalReplacementLength = replacements.reduce(0) { sum, item in
                sum + item.replacement.count - item.range.length
            }
            let estimatedFinalLength = originalLength + totalReplacementLength
            
            // 第三阶段：一次性构建最终字符串
            var result = ""
            result.reserveCapacity(max(estimatedFinalLength, originalLength))
            
            var lastLocation = 0
            
            for (index, replacement) in replacements.enumerated() {
                let matchRange = replacement.range
                
                // 添加匹配前的原始文本
                if lastLocation < matchRange.location {
                    let startIndex = input.index(input.startIndex, offsetBy: lastLocation)
                    let endIndex = input.index(input.startIndex, offsetBy: matchRange.location)
                    result.append(contentsOf: input[startIndex..<endIndex])
                }
                
                // 添加替换文本
                result.append(replacement.replacement)
                
                lastLocation = matchRange.location + matchRange.length
                
                // 进度反馈：构建阶段进度
                if replacements.count > 1000 && index % 200 == 0 {
                    let progress = Double(index) / Double(replacements.count) * 0.5 // 第三阶段占50%
                    DispatchQueue.main.async {
                        if self.isProcessing {
                            self.processingProgress = 0.4 + progress
                        }
                    }
                }
            }
            
            // 添加最后剩余的原始文本
            if lastLocation < input.count {
                let startIndex = input.index(input.startIndex, offsetBy: lastLocation)
                result.append(contentsOf: input[startIndex...])
            }
            
            return result
            
        } catch {
            // 正则表达式错误，返回原字符串
            return input
        }
    }
    
    private func convertHTMLEntities(_ input: String) -> String {
        return performBatchReplacement(
            input: input,
            pattern: #"&(?:amp|lt|gt|quot|apos|nbsp);|&#(\d+);|&#x([0-9a-fA-F]+);|&#39;|&#34;|&#38;|&#60;|&#62;|&#160;"#,
            transformer: { match, input in
                // 获取匹配的实体
                let fullRange = Range(match.range, in: input)!
                let entity = String(input[fullRange])
                
                // 转换实体
                return self.convertSingleHTMLEntity(entity)
            }
        )
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
        // URL解码使用Foundation的内置方法，它对整个字符串更有效
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
    
    // MARK: - AI错误分析
    
    /// 执行AI错误分析
    private func performAIErrorAnalysis(jsonInput: String, error: JSONValidationError) {
        // 检查系统版本和功能可用性
        if #available(macOS 15.0, *) {
            isAIAnalyzing = true
            aiErrorSuggestion = nil
            
            aiErrorAnalyzer.analyzeJSONError(jsonInput: jsonInput, error: error) { [weak self] suggestion in
                DispatchQueue.main.async {
                    self?.aiErrorSuggestion = suggestion
                    self?.isAIAnalyzing = false
                }
            }
        } else {
            // 系统版本不支持AI分析，提供基础建议
            aiErrorSuggestion = generateBasicErrorSuggestion(error: error)
            isAIAnalyzing = false
        }
    }
    
    /// 为不支持AI的系统生成基础错误建议
    private func generateBasicErrorSuggestion(error: JSONValidationError) -> String {
        switch error {
        case .invalidJSON(let message, let line, let column):
            var suggestion = "🔧 **JSON格式错误**\n\n"
            suggestion += "错误信息：\(message)\n\n"
            
            if let line = line, let column = column {
                suggestion += "📍 错误位置：第 \(line) 行，第 \(column) 列\n\n"
            }
            
            suggestion += "💡 **常见解决方案**:\n"
            suggestion += "• 检查大括号 {} 和方括号 [] 是否配对\n"
            suggestion += "• 确保所有字符串用双引号包围\n"
            suggestion += "• 移除多余的逗号\n"
            suggestion += "• 确保键名和字符串值都用双引号\n"
            suggestion += "• 检查布尔值是否为小写 (true/false)\n"
            suggestion += "• 检查空值是否为小写 (null)"
            
            return suggestion
            
        case .emptyInput:
            return "📝 请输入要格式化的JSON数据"
        }
    }
    
    /// 清除AI错误建议
    func clearAIErrorSuggestion() {
        aiErrorSuggestion = nil
        isAIAnalyzing = false
    }
}