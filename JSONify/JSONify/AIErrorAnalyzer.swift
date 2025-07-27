//
//  AIErrorAnalyzer.swift
//  JSONify
//
//  Created by Claude on 7/27/25.
//

import Foundation
import NaturalLanguage
import CoreML

@available(macOS 15.0, *)
class AIErrorAnalyzer: ObservableObject {
    @Published var isAnalyzing = false
    @Published var aiSuggestion: String?
    @Published var confidence: Double = 0.0
    
    private let maxAnalysisLength = 2000 // 限制分析的文本长度
    
    /// 使用macOS AI能力分析JSON错误
    /// - Parameters:
    ///   - jsonInput: 原始JSON输入
    ///   - error: JSON解析错误
    ///   - completion: 分析完成回调
    func analyzeJSONError(
        jsonInput: String,
        error: JSONValidationError,
        completion: @escaping (String?) -> Void
    ) {
        Task {
            await MainActor.run {
                isAnalyzing = true
                aiSuggestion = nil
            }
            
            let suggestion = await performAIAnalysis(jsonInput: jsonInput, error: error)
            
            await MainActor.run {
                self.aiSuggestion = suggestion
                self.isAnalyzing = false
                completion(suggestion)
            }
        }
    }
    
    /// 执行AI分析
    private func performAIAnalysis(jsonInput: String, error: JSONValidationError) async -> String? {
        // 1. 首先尝试使用Apple Intelligence API (如果可用)
        if #available(macOS 15.1, *) {
            if let aiSuggestion = await analyzeWithAppleIntelligence(jsonInput: jsonInput, error: error) {
                return aiSuggestion
            }
        }
        
        // 2. 回退到Natural Language Framework + 规则分析
        return await analyzeWithNaturalLanguage(jsonInput: jsonInput, error: error)
    }
    
    /// 使用Apple Intelligence进行分析
    @available(macOS 15.1, *)
    private func analyzeWithAppleIntelligence(jsonInput: String, error: JSONValidationError) async -> String? {
        // 构建提示词
        let prompt = buildAnalysisPrompt(jsonInput: jsonInput, error: error)
        
        // 注意：这里使用假设的Apple Intelligence API
        // 实际实现需要根据Apple最新的AI框架文档调整
        // 这是概念性代码，实际需要根据Apple Intelligence API调整
        return await requestAppleIntelligenceAnalysis(prompt: prompt)
    }
    
    /// 使用Natural Language Framework进行分析
    private func analyzeWithNaturalLanguage(jsonInput: String, error: JSONValidationError) async -> String? {
        return await Task.detached {
            // 截断过长的输入
            let analysisInput = String(jsonInput.prefix(self.maxAnalysisLength))
            
            // 使用Natural Language进行语言分析
            let analyzer = NLLanguageRecognizer()
            analyzer.processString(analysisInput)
            
            // 基于错误类型和文本特征进行智能推理
            return self.generateIntelligentSuggestion(
                input: analysisInput,
                error: error,
                languageAnalysis: analyzer
            )
        }.value
    }
    
    /// 构建分析提示词
    private func buildAnalysisPrompt(jsonInput: String, error: JSONValidationError) -> String {
        let truncatedInput = String(jsonInput.prefix(maxAnalysisLength))
        
        return """
        请分析以下JSON字符串的错误，并提供友好的修复建议：
        
        错误信息: \(error.localizedDescription)
        
        JSON内容:
        \(truncatedInput)
        
        请提供：
        1. 错误的具体位置
        2. 错误的可能原因
        3. 具体的修复建议
        4. 修复后的示例（如果适用）
        
        请用中文回答，语言要友好易懂。
        """
    }
    
    /// 请求Apple Intelligence分析（概念性实现）
    @available(macOS 15.1, *)
    private func requestAppleIntelligenceAnalysis(prompt: String) async -> String? {
        // 这里是概念性代码，实际需要根据Apple Intelligence API实现
        // 目前Apple Intelligence可能还没有公开的文本分析API
        // 所以这里返回nil，让系统回退到Natural Language分析
        return nil
    }
    
    /// 生成智能建议
    private func generateIntelligentSuggestion(
        input: String,
        error: JSONValidationError,
        languageAnalysis: NLLanguageRecognizer
    ) -> String {
        
        switch error {
        case .invalidJSON(let message, let line, let column):
            return analyzeSpecificJSONError(
                input: input,
                message: message,
                line: line,
                column: column
            )
        case .emptyInput:
            return "📝 输入为空，请粘贴或输入您要格式化的JSON数据。"
        }
    }
    
    /// 分析具体的JSON错误
    private func analyzeSpecificJSONError(
        input: String,
        message: String,
        line: Int?,
        column: Int?
    ) -> String {
        
        var suggestions: [String] = []
        let lowerInput = input.lowercased()
        
        // 🔍 智能模式识别和建议
        
        // 1. 检查常见的语法错误
        if message.contains("badly formed object") || message.contains("Expected") {
            suggestions.append("🔧 **语法结构问题**")
            
            if !input.hasPrefix("{") && !input.hasPrefix("[") {
                suggestions.append("• JSON必须以 `{` 或 `[` 开头")
            }
            
            let openBraces = input.filter { $0 == "{" }.count
            let closeBraces = input.filter { $0 == "}" }.count
            if openBraces != closeBraces {
                suggestions.append("• 大括号不匹配：发现 \(openBraces) 个 `{` 和 \(closeBraces) 个 `}`")
            }
            
            let openBrackets = input.filter { $0 == "[" }.count
            let closeBrackets = input.filter { $0 == "]" }.count
            if openBrackets != closeBrackets {
                suggestions.append("• 方括号不匹配：发现 \(openBrackets) 个 `[` 和 \(closeBrackets) 个 `]`")
            }
        }
        
        // 2. 检查引号问题
        if message.contains("Unterminated string") || lowerInput.contains("unterminated") {
            suggestions.append("📝 **字符串引号问题**")
            suggestions.append("• 检查所有字符串是否用双引号 `\"` 包围")
            suggestions.append("• 确保字符串内的引号已正确转义为 `\\\"`")
            
            // 智能检测单引号使用
            if input.contains("'") {
                suggestions.append("• 发现单引号 `'`，JSON标准要求使用双引号 `\"`")
            }
        }
        
        // 3. 检查逗号问题
        if message.contains("trailing comma") || input.contains(",}") || input.contains(",]") {
            suggestions.append("🔸 **多余逗号问题**")
            suggestions.append("• 移除对象或数组最后一个元素后的多余逗号")
            suggestions.append("• 例如：`{\"name\": \"value\",}` → `{\"name\": \"value\"}`")
        }
        
        // 4. 检查键名问题
        if message.contains("duplicate key") {
            suggestions.append("🔑 **重复键名问题**")
            suggestions.append("• JSON对象中不能有重复的键名")
            suggestions.append("• 检查并合并或重命名重复的键")
        }
        
        // 5. 检查值类型问题
        if message.contains("No value") || message.contains("Invalid character") {
            suggestions.append("⚠️ **值格式问题**")
            
            // 检测可能的布尔值错误
            if lowerInput.contains("true") || lowerInput.contains("false") {
                suggestions.append("• 布尔值必须是小写：`true`、`false`")
            }
            
            // 检测可能的null值错误
            if lowerInput.contains("null") || lowerInput.contains("nil") {
                suggestions.append("• 空值必须是小写：`null`（不是 `nil` 或 `NULL`）")
            }
            
            // 检测未引用的字符串
            let words = input.components(separatedBy: .whitespacesAndNewlines)
            for word in words {
                if word.count > 1 && !word.hasPrefix("\"") && !word.hasSuffix("\"") 
                   && !["true", "false", "null"].contains(word.lowercased())
                   && !word.allSatisfy({ $0.isNumber || $0 == "." || $0 == "-" }) {
                    suggestions.append("• 字符串值需要用双引号包围：`\"\(word)\"`")
                    break
                }
            }
        }
        
        // 6. 位置信息
        if let line = line, let column = column {
            suggestions.append("📍 **错误位置**")
            suggestions.append("• 第 \(line) 行，第 \(column) 列附近")
            
            // 尝试提取问题行的内容
            let lines = input.components(separatedBy: .newlines)
            if line <= lines.count && line > 0 {
                let problemLine = lines[line - 1]
                if !problemLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    suggestions.append("• 问题行内容：`\(problemLine.trimmingCharacters(in: .whitespacesAndNewlines))`")
                }
            }
        }
        
        // 7. 通用建议
        suggestions.append("")
        suggestions.append("💡 **修复建议**")
        suggestions.append("• 使用在线JSON验证器进行详细检查")
        suggestions.append("• 逐步删除内容定位具体错误位置")
        suggestions.append("• 确保遵循JSON标准格式规范")
        
        return suggestions.joined(separator: "\n")
    }
}

// MARK: - 错误分析结果模型
struct AIErrorAnalysis {
    let suggestion: String
    let confidence: Double
    let analysisType: AnalysisType
    
    enum AnalysisType {
        case appleIntelligence
        case naturalLanguage
        case rulesBased
    }
}