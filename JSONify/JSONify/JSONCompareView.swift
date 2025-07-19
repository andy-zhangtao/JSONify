//
//  JSONCompareView.swift
//  JSONify
//
//  Created by 张涛 on 7/19/25.
//

import SwiftUI

struct JSONCompareView: View {
    @StateObject private var leftProcessor = JSONProcessor()
    @StateObject private var rightProcessor = JSONProcessor()
    @StateObject private var diffEngine = JSONDiffEngine()
    
    @State private var compareOptions = CompareOptions()
    @State private var showingOptions = false
    @AppStorage("compareFontSize") private var fontSize = 14.0
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                Text("JSON 比较工具")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 比较选项
                Button(action: { showingOptions.toggle() }) {
                    Label("选项", systemImage: "gear")
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showingOptions) {
                    CompareOptionsView(options: $compareOptions)
                        .padding()
                        .frame(width: 300)
                }
                
                // 比较按钮
                Button(action: performComparison) {
                    Label("比较", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderedProminent)
                .disabled(leftProcessor.inputText.isEmpty || rightProcessor.inputText.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 主要内容区域
            GeometryReader { geometry in
                HStack(spacing: 1) {
                    // 左侧JSON输入
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("JSON A")
                                .font(.headline)
                            Spacer()
                            if leftProcessor.isValid {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        JSONInputEditor(
                            text: $leftProcessor.inputText,
                            isValid: leftProcessor.isValid,
                            validationError: leftProcessor.validationError,
                            fontSize: fontSize
                        )
                        .onChange(of: leftProcessor.inputText) { _ in
                            leftProcessor.processJSON(sortKeys: false)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(width: geometry.size.width * 0.35)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 1)
                    
                    // 右侧JSON输入
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("JSON B")
                                .font(.headline)
                            Spacer()
                            if rightProcessor.isValid {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        JSONInputEditor(
                            text: $rightProcessor.inputText,
                            isValid: rightProcessor.isValid,
                            validationError: rightProcessor.validationError,
                            fontSize: fontSize
                        )
                        .onChange(of: rightProcessor.inputText) { _ in
                            rightProcessor.processJSON(sortKeys: false)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(width: geometry.size.width * 0.35)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 1)
                    
                    // 差异结果视图
                    DiffResultView(
                        differences: diffEngine.differences,
                        isComparing: diffEngine.isComparing,
                        error: diffEngine.error
                    )
                    .frame(width: geometry.size.width * 0.3)
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
    }
    
    private func performComparison() {
        diffEngine.setOptions(compareOptions)
        diffEngine.compareJSON(leftProcessor.inputText, rightProcessor.inputText)
    }
}

// JSON输入编辑器组件
struct JSONInputEditor: View {
    @Binding var text: String
    let isValid: Bool
    let validationError: Error?
    let fontSize: Double
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: fontSize, design: .monospaced))
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1.5)
                )
                .cornerRadius(8)
            
            if text.isEmpty {
                Text("在此粘贴或输入 JSON...")
                    .foregroundColor(.secondary)
                    .font(.system(size: fontSize, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
        }
        
        if let error = validationError {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.caption)
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red.opacity(0.1))
            .cornerRadius(4)
        }
    }
    
    private var borderColor: Color {
        if !text.isEmpty {
            return isValid ? Color.green : Color.red
        }
        return Color.gray
    }
}

// 比较选项视图
struct CompareOptionsView: View {
    @Binding var options: CompareOptions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("比较选项")
                .font(.headline)
            
            Toggle("忽略空格", isOn: $options.ignoreWhitespace)
            Toggle("忽略数组顺序", isOn: $options.ignoreArrayOrder)
            Toggle("忽略大小写", isOn: $options.ignoreCase)
            Toggle("仅比较结构", isOn: $options.compareOnlyStructure)
            
            Divider()
            
            Text("说明：")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("• 忽略空格：忽略字符串值的前后空格")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("• 忽略数组顺序：不考虑数组元素的顺序")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("• 仅比较结构：只比较JSON的结构，不比较具体值")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    JSONCompareView()
}