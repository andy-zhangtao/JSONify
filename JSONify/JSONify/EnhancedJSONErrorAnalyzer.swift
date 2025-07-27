//
//  EnhancedJSONErrorAnalyzer.swift
//  JSONify
//
//  Created by Claude on 7/27/25.
//

import Foundation
import NaturalLanguage

/// 增强版JSON错误分析器 - 提供精确的错误定位和修复建议
@available(macOS 15.0, *)
class EnhancedJSONErrorAnalyzer: ObservableObject {
    @Published var isAnalyzing = false
    @Published var aiSuggestion: String?
    @Published var confidence: Double = 0.0
    
    private let maxAnalysisLength = 5000
    
    /// 主要分析入口
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
            
            let suggestion = await performDetailedAnalysis(jsonInput: jsonInput, error: error)
            
            await MainActor.run {
                self.aiSuggestion = suggestion
                self.isAnalyzing = false
                completion(suggestion)
            }
        }
    }
    
    /// 执行详细的JSON错误分析
    private func performDetailedAnalysis(jsonInput: String, error: JSONValidationError) async -> String? {
        let truncatedInput = String(jsonInput.prefix(maxAnalysisLength))
        
        // 使用多种分析方法
        let structuralAnalysis = analyzeStructuralErrors(input: truncatedInput, error: error)
        let syntaxAnalysis = analyzeSyntaxErrors(input: truncatedInput)
        let semanticAnalysis = analyzeSemanticErrors(input: truncatedInput)
        
        // 组合分析结果
        return combineAnalysisResults(
            input: truncatedInput,
            error: error,
            structural: structuralAnalysis,
            syntax: syntaxAnalysis,
            semantic: semanticAnalysis
        )
    }
    
    /// 结构性错误分析（括号、引号匹配等）
    private func analyzeStructuralErrors(input: String, error: JSONValidationError) -> StructuralAnalysis {
        var issues: [StructuralIssue] = []
        
        // 1. 括号匹配分析
        let bracketAnalysis = analyzeBrackets(input)
        issues.append(contentsOf: bracketAnalysis)
        
        // 2. 引号匹配分析
        let quoteAnalysis = analyzeQuotes(input)
        issues.append(contentsOf: quoteAnalysis)
        
        // 3. 逗号分析
        let commaAnalysis = analyzeCommas(input)
        issues.append(contentsOf: commaAnalysis)
        
        return StructuralAnalysis(issues: issues)
    }
    
    /// 语法错误分析（键值对格式等）
    private func analyzeSyntaxErrors(input: String) -> SyntaxAnalysis {
        var issues: [SyntaxIssue] = []
        
        // 1. 键名格式检查
        let keyIssues = analyzeKeys(input)
        issues.append(contentsOf: keyIssues)
        
        // 2. 值格式检查
        let valueIssues = analyzeValues(input)
        issues.append(contentsOf: valueIssues)
        
        // 3. 分隔符检查
        let separatorIssues = analyzeSeparators(input)
        issues.append(contentsOf: separatorIssues)
        
        return SyntaxAnalysis(issues: issues)
    }
    
    /// 语义错误分析（重复键名等）
    private func analyzeSemanticErrors(input: String) -> SemanticAnalysis {
        var issues: [SemanticIssue] = []
        
        // 1. 重复键名检查
        let duplicateKeys = findDuplicateKeys(input)
        issues.append(contentsOf: duplicateKeys)
        
        // 2. 数据类型一致性检查
        let typeIssues = analyzeTypeConsistency(input)
        issues.append(contentsOf: typeIssues)
        
        return SemanticAnalysis(issues: issues)
    }
    
    /// 括号匹配分析
    private func analyzeBrackets(_ input: String) -> [StructuralIssue] {
        var issues: [StructuralIssue] = []
        var stack: [(Character, Int)] = []
        let lines = input.components(separatedBy: .newlines)
        
        for (lineIndex, line) in lines.enumerated() {
            for (charIndex, char) in line.enumerated() {
                let position = "\(lineIndex + 1):\(charIndex + 1)"
                
                switch char {
                case "{", "[":
                    stack.append((char, lineIndex + 1))
                case "}", "]":
                    if stack.isEmpty {
                        issues.append(StructuralIssue(
                            type: .unmatchedClosingBracket,
                            position: position,
                            line: lineIndex + 1,
                            column: charIndex + 1,
                            character: char,
                            suggestion: "多余的闭合括号 '\(char)'，请检查是否有对应的开放括号"
                        ))
                    } else {
                        let (openChar, _) = stack.removeLast()
                        let expectedClose: Character = openChar == "{" ? "}" : "]"
                        if char != expectedClose {
                            issues.append(StructuralIssue(
                                type: .mismatchedBracket,
                                position: position,
                                line: lineIndex + 1,
                                column: charIndex + 1,
                                character: char,
                                suggestion: "括号类型不匹配：期望 '\(expectedClose)'，实际是 '\(char)'"
                            ))
                        }
                    }
                default:
                    break
                }
            }
        }
        
        // 检查未闭合的括号
        for (openChar, line) in stack {
            let expectedClose: Character = openChar == "{" ? "}" : "]"
            issues.append(StructuralIssue(
                type: .unmatchedOpeningBracket,
                position: "\(line):?",
                line: line,
                column: nil,
                character: openChar,
                suggestion: "第 \(line) 行的 '\(openChar)' 缺少对应的 '\(expectedClose)'"
            ))
        }
        
        return issues
    }
    
    /// 引号匹配分析
    private func analyzeQuotes(_ input: String) -> [StructuralIssue] {
        var issues: [StructuralIssue] = []
        let lines = input.components(separatedBy: .newlines)
        
        for (lineIndex, line) in lines.enumerated() {
            var inString = false
            var escaped = false
            var lastQuoteIndex: Int?
            
            for (charIndex, char) in line.enumerated() {
                defer { escaped = false }
                
                if escaped {
                    continue
                }
                
                switch char {
                case "\\":
                    if inString {
                        escaped = true
                    }
                case "\"":
                    if inString {
                        inString = false
                        lastQuoteIndex = nil
                    } else {
                        inString = true
                        lastQuoteIndex = charIndex
                    }
                case "'":
                    if !inString {
                        issues.append(StructuralIssue(
                            type: .singleQuote,
                            position: "\(lineIndex + 1):\(charIndex + 1)",
                            line: lineIndex + 1,
                            column: charIndex + 1,
                            character: char,
                            suggestion: "发现单引号，JSON标准要求使用双引号"
                        ))
                    }
                default:
                    break
                }
            }
            
            // 检查未闭合的字符串
            if inString, let quoteIndex = lastQuoteIndex {
                issues.append(StructuralIssue(
                    type: .unterminatedString,
                    position: "\(lineIndex + 1):\(quoteIndex + 1)",
                    line: lineIndex + 1,
                    column: quoteIndex + 1,
                    character: "\"",
                    suggestion: "字符串未正确闭合，缺少结束的双引号"
                ))
            }
        }
        
        return issues
    }
    
    /// 逗号分析
    private func analyzeCommas(_ input: String) -> [StructuralIssue] {
        var issues: [StructuralIssue] = []
        let lines = input.components(separatedBy: .newlines)
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 检查多余的逗号
            if trimmed.hasSuffix(",}") || trimmed.hasSuffix(",]") {
                if let commaIndex = line.lastIndex(of: ",") {
                    let column = line.distance(from: line.startIndex, to: commaIndex) + 1
                    issues.append(StructuralIssue(
                        type: .trailingComma,
                        position: "\(lineIndex + 1):\(column)",
                        line: lineIndex + 1,
                        column: column,
                        character: ",",
                        suggestion: "多余的逗号，JSON不允许在最后一个元素后使用逗号"
                    ))
                }
            }
        }
        
        return issues
    }
    
    /// 键名格式检查
    private func analyzeKeys(_ input: String) -> [SyntaxIssue] {
        var issues: [SyntaxIssue] = []
        let lines = input.components(separatedBy: .newlines)
        
        let keyPattern = #"^\s*([^"\s:]+)\s*:"#
        let regex = try? NSRegularExpression(pattern: keyPattern)
        
        for (lineIndex, line) in lines.enumerated() {
            let range = NSRange(location: 0, length: line.count)
            if let match = regex?.firstMatch(in: line, range: range),
               let keyRange = Range(match.range(at: 1), in: line) {
                let key = String(line[keyRange])
                
                if !key.hasPrefix("\"") || !key.hasSuffix("\"") {
                    issues.append(SyntaxIssue(
                        type: .unquotedKey,
                        position: "\(lineIndex + 1):?",
                        line: lineIndex + 1,
                        content: key,
                        suggestion: "键名必须用双引号包围：\"\(key)\""
                    ))
                }
            }
        }
        
        return issues
    }
    
    /// 值格式检查
    private func analyzeValues(_ input: String) -> [SyntaxIssue] {
        var issues: [SyntaxIssue] = []
        let lines = input.components(separatedBy: .newlines)
        
        for (lineIndex, line) in lines.enumerated() {
            // 检查大写布尔值
            if line.contains("True") || line.contains("False") || line.contains("TRUE") || line.contains("FALSE") {
                issues.append(SyntaxIssue(
                    type: .invalidBoolean,
                    position: "\(lineIndex + 1):?",
                    line: lineIndex + 1,
                    content: line.trimmingCharacters(in: .whitespacesAndNewlines),
                    suggestion: "布尔值必须是小写：true/false"
                ))
            }
            
            // 检查错误的null值
            if line.contains("nil") || line.contains("NULL") || line.contains("None") {
                issues.append(SyntaxIssue(
                    type: .invalidNull,
                    position: "\(lineIndex + 1):?",
                    line: lineIndex + 1,
                    content: line.trimmingCharacters(in: .whitespacesAndNewlines),
                    suggestion: "空值必须是小写：null"
                ))
            }
        }
        
        return issues
    }
    
    /// 分隔符检查
    private func analyzeSeparators(_ input: String) -> [SyntaxIssue] {
        var issues: [SyntaxIssue] = []
        let lines = input.components(separatedBy: .newlines)
        
        for (lineIndex, line) in lines.enumerated() {
            // 检查缺少冒号的键值对
            if line.contains("\"") && !line.contains(":") && !line.contains("[") && !line.contains("]") {
                if line.trimmingCharacters(in: .whitespacesAndNewlines).count > 2 {
                    issues.append(SyntaxIssue(
                        type: .missingColon,
                        position: "\(lineIndex + 1):?",
                        line: lineIndex + 1,
                        content: line.trimmingCharacters(in: .whitespacesAndNewlines),
                        suggestion: "键值对缺少冒号分隔符"
                    ))
                }
            }
        }
        
        return issues
    }
    
    /// 查找重复键名
    private func findDuplicateKeys(_ input: String) -> [SemanticIssue] {
        var issues: [SemanticIssue] = []
        var keyOccurrences: [String: [Int]] = [:]
        let lines = input.components(separatedBy: .newlines)
        
        let keyPattern = #""([^"]+)"\s*:"#
        let regex = try? NSRegularExpression(pattern: keyPattern)
        
        for (lineIndex, line) in lines.enumerated() {
            let range = NSRange(location: 0, length: line.count)
            let matches = regex?.matches(in: line, range: range) ?? []
            
            for match in matches {
                if let keyRange = Range(match.range(at: 1), in: line) {
                    let key = String(line[keyRange])
                    keyOccurrences[key, default: []].append(lineIndex + 1)
                }
            }
        }
        
        for (key, lines) in keyOccurrences {
            if lines.count > 1 {
                issues.append(SemanticIssue(
                    type: .duplicateKey,
                    key: key,
                    lines: lines,
                    suggestion: "键名 \"\(key)\" 在第 \(lines.map(String.init).joined(separator: ", ")) 行重复出现"
                ))
            }
        }
        
        return issues
    }
    
    /// 类型一致性分析
    private func analyzeTypeConsistency(_ input: String) -> [SemanticIssue] {
        // 这里可以添加更高级的类型一致性检查
        // 目前返回空数组，后续可以扩展
        return []
    }
    
    /// 组合所有分析结果
    private func combineAnalysisResults(
        input: String,
        error: JSONValidationError,
        structural: StructuralAnalysis,
        syntax: SyntaxAnalysis,
        semantic: SemanticAnalysis
    ) -> String {
        var result: [String] = []
        
        // 标题
        result.append("🤖 **AI智能错误分析**")
        result.append("")
        
        // 原始错误信息
        result.append("📋 **错误信息**")
        result.append(error.localizedDescription)
        result.append("")
        
        // 结构性问题
        if !structural.issues.isEmpty {
            result.append("🔧 **结构问题** (\(structural.issues.count)个)")
            for (index, issue) in structural.issues.enumerated() {
                result.append("\(index + 1). **位置** \(issue.position): \(issue.suggestion)")
            }
            result.append("")
        }
        
        // 语法问题
        if !syntax.issues.isEmpty {
            result.append("📝 **语法问题** (\(syntax.issues.count)个)")
            for (index, issue) in syntax.issues.enumerated() {
                result.append("\(index + 1). **第\(issue.line)行**: \(issue.suggestion)")
            }
            result.append("")
        }
        
        // 语义问题
        if !semantic.issues.isEmpty {
            result.append("🔑 **语义问题** (\(semantic.issues.count)个)")
            for (index, issue) in semantic.issues.enumerated() {
                result.append("\(index + 1). \(issue.suggestion)")
            }
            result.append("")
        }
        
        // 修复建议
        result.append("💡 **修复建议**")
        
        if let firstStructural = structural.issues.first {
            result.append("• **优先修复**: \(firstStructural.suggestion)")
        }
        
        result.append("• **验证工具**: 修复后使用JSONLint等工具验证")
        result.append("• **分步调试**: 逐行检查，从错误位置开始")
        
        // 如果没有发现具体问题，提供通用建议
        if structural.issues.isEmpty && syntax.issues.isEmpty && semantic.issues.isEmpty {
            result.append("")
            result.append("⚠️ **通用建议**")
            result.append("• 检查所有括号是否正确配对")
            result.append("• 确保所有字符串使用双引号")
            result.append("• 移除多余的逗号")
            result.append("• 验证所有键名都用双引号包围")
        }
        
        return result.joined(separator: "\n")
    }
}

// MARK: - 分析结果数据模型

struct StructuralAnalysis {
    let issues: [StructuralIssue]
}

struct SyntaxAnalysis {
    let issues: [SyntaxIssue]
}

struct SemanticAnalysis {
    let issues: [SemanticIssue]
}

struct StructuralIssue {
    enum IssueType {
        case unmatchedOpeningBracket
        case unmatchedClosingBracket
        case mismatchedBracket
        case singleQuote
        case unterminatedString
        case trailingComma
    }
    
    let type: IssueType
    let position: String
    let line: Int
    let column: Int?
    let character: Character
    let suggestion: String
}

struct SyntaxIssue {
    enum IssueType {
        case unquotedKey
        case invalidBoolean
        case invalidNull
        case missingColon
    }
    
    let type: IssueType
    let position: String
    let line: Int
    let content: String
    let suggestion: String
}

struct SemanticIssue {
    enum IssueType {
        case duplicateKey
        case typeInconsistency
    }
    
    let type: IssueType
    let key: String?
    let lines: [Int]?
    let suggestion: String
    
    init(type: IssueType, key: String? = nil, lines: [Int]? = nil, suggestion: String) {
        self.type = type
        self.key = key
        self.lines = lines
        self.suggestion = suggestion
    }
}