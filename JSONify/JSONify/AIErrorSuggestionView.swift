//
//  AIErrorSuggestionView.swift
//  JSONify
//
//  Created by Claude on 7/27/25.
//

import SwiftUI

struct AIErrorSuggestionView: View {
    let suggestion: String
    let isAnalyzing: Bool
    let onDismiss: () -> Void
    let onAIRepair: (() -> Void)?
    
    @State private var isExpanded = false
    
    // 直接使用AnimationManager.shared避免环境依赖问题
    private let animationManager = AnimationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            if isAnalyzing {
                analyzingView
            } else if !suggestion.isEmpty {
                suggestionView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isAnalyzing)
        .animation(.easeInOut(duration: 0.3), value: suggestion)
    }
    
    private var analyzingView: some View {
        HStack(spacing: 12) {
            // AI分析指示器
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("🤖 AI正在分析错误...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("正在使用macOS AI能力推理错误原因")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .pageTransition(isActive: isAnalyzing)
    }
    
    private var suggestionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🤖 AI错误分析")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("基于macOS AI能力的智能建议")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // 展开/收起按钮
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    // 关闭按钮
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // 建议内容
            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(parseSuggestionLines(suggestion), id: \.id) { line in
                            suggestionLineView(line)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 300)
                .pageTransition(isActive: isExpanded)
            } else {
                // 折叠状态显示摘要
                Text(extractSummary(from: suggestion))
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // 底部操作按钮
            if isExpanded {
                HStack(spacing: 12) {
                    Button(action: {
                        copyToClipboard(suggestion)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                            Text("复制建议")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(EnhancedButtonStyle(variant: .secondary))
                    
                    // AI智能修复按钮
                    if let onAIRepair = onAIRepair {
                        Button(action: onAIRepair) {
                            HStack(spacing: 6) {
                                Image(systemName: "wand.and.stars")
                                Text("AI智能修复")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(EnhancedButtonStyle(variant: .primary))
                    }
                    
                    Spacer()
                    
                    Text("由macOS AI提供支持")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            // 默认展开显示详细建议
            withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                isExpanded = true
            }
        }
    }
    
    @ViewBuilder
    private func suggestionLineView(_ line: SuggestionLine) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if line.isHeader {
                Image(systemName: line.icon)
                    .foregroundColor(line.color)
                    .font(.subheadline)
                    .frame(width: 16)
            } else if line.isBulletPoint {
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 4, height: 4)
                    .padding(.top, 6)
            } else {
                Spacer()
                    .frame(width: 16)
            }
            
            Text(line.content)
                .font(line.isHeader ? .subheadline.weight(.medium) : .body)
                .foregroundColor(line.isHeader ? .primary : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func parseSuggestionLines(_ text: String) -> [SuggestionLine] {
        let lines = text.components(separatedBy: .newlines)
        var result: [SuggestionLine] = []
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            var suggestionLine = SuggestionLine(
                id: index,
                content: trimmed,
                isHeader: false,
                isBulletPoint: false,
                icon: "circle",
                color: .secondary
            )
            
            // 解析不同类型的行
            if trimmed.hasPrefix("🔧") || trimmed.hasPrefix("📝") || trimmed.hasPrefix("🔸") || 
               trimmed.hasPrefix("🔑") || trimmed.hasPrefix("⚠️") || trimmed.hasPrefix("📍") || 
               trimmed.hasPrefix("💡") {
                suggestionLine.isHeader = true
                suggestionLine.color = .blue
                suggestionLine.icon = "info.circle"
            } else if trimmed.hasPrefix("•") {
                suggestionLine.isBulletPoint = true
                suggestionLine.content = String(trimmed.dropFirst(1).trimmingCharacters(in: .whitespaces))
            }
            
            result.append(suggestionLine)
        }
        
        return result
    }
    
    private func extractSummary(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        if nonEmptyLines.count >= 2 {
            return nonEmptyLines.prefix(2).joined(separator: " ")
        } else if let firstLine = nonEmptyLines.first {
            return firstLine
        }
        
        return "AI检测到JSON格式问题，点击查看详细建议"
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - 建议行模型
struct SuggestionLine {
    let id: Int
    var content: String
    var isHeader: Bool
    var isBulletPoint: Bool
    var icon: String
    var color: Color
}

// MARK: - 预览
struct AIErrorSuggestionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AIErrorSuggestionView(
                suggestion: """
                🔧 **语法结构问题**
                • 大括号不匹配：发现 2 个 `{` 和 1 个 `}`
                • JSON必须以 `{` 或 `[` 开头
                
                📍 **错误位置**
                • 第 3 行，第 15 列附近
                • 问题行内容：`"name": "value",`
                
                💡 **修复建议**
                • 使用在线JSON验证器进行详细检查
                • 逐步删除内容定位具体错误位置
                """,
                isAnalyzing: false,
                onDismiss: {},
                onAIRepair: {}
            )
            
            AIErrorSuggestionView(
                suggestion: "",
                isAnalyzing: true,
                onDismiss: {},
                onAIRepair: nil
            )
        }
        .padding()
    }
}