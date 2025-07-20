//
//  JSONPathQueryView.swift
//  JSONify
//
//  Created by 张涛 on 7/19/25.
//

import SwiftUI

struct JSONPathQueryView: View {
    @StateObject private var jsonProcessor = JSONProcessor()
    @StateObject private var pathEngine = JSONPathEngine()
    
    @State private var pathQuery = ""
    @State private var selectedResult: JSONPathResult?
    @State private var showingHelp = false
    @AppStorage("pathQueryFontSize") private var fontSize = 14.0
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                Text("JSONPath 查询")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 帮助按钮
                Button(action: { showingHelp.toggle() }) {
                    Label("语法帮助", systemImage: "questionmark.circle")
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showingHelp) {
                    JSONPathHelpView()
                        .frame(width: 400, height: 500)
                }
                
                // 查询按钮
                Button(action: performQuery) {
                    Label("查询", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .disabled(jsonProcessor.inputText.isEmpty || pathQuery.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 主要内容区域
            GeometryReader { geometry in
                HStack(spacing: 1) {
                    // 左侧：JSON输入和路径查询
                    VStack(spacing: 12) {
                        // JSON输入区
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("JSON 数据")
                                    .font(.headline)
                                Spacer()
                                if jsonProcessor.isValid {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $jsonProcessor.inputText)
                                    .font(.system(size: fontSize, design: .monospaced))
                                    .padding(8)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.gray, lineWidth: 1.5)
                                    )
                                    .cornerRadius(8)
                                    .onChange(of: jsonProcessor.inputText) { _, _ in
                                        jsonProcessor.processJSON(sortKeys: false)
                                    }
                                
                                if jsonProcessor.inputText.isEmpty {
                                    Text("在此粘贴或输入 JSON...")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: fontSize, design: .monospaced))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                            .frame(height: geometry.size.height * 0.7)
                            
                            if let error = jsonProcessor.validationError {
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
                        
                        // JSONPath查询输入
                        VStack(alignment: .leading, spacing: 8) {
                            Text("JSONPath 查询")
                                .font(.headline)
                            
                            HStack {
                                TextField("输入JSONPath，例如: $.users[0].name", text: $pathQuery)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: fontSize, design: .monospaced))
                                    .onSubmit {
                                        performQuery()
                                    }
                                
                                Button(action: { pathQuery = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .opacity(pathQuery.isEmpty ? 0 : 1)
                            }
                            
                            // 快速示例
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(["$", "$.*", "$..[*]", "$..name"], id: \.self) { example in
                                        Button(example) {
                                            pathQuery = example
                                        }
                                        .buttonStyle(.borderless)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                        .font(.caption)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .frame(width: geometry.size.width * 0.5)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 1)
                    
                    // 右侧：查询结果
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("查询结果")
                                .font(.headline)
                            
                            Spacer()
                            
                            if !pathEngine.results.isEmpty {
                                Text("\(pathEngine.results.count) 个匹配")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if pathEngine.isSearching {
                            VStack {
                                ProgressView("正在查询...")
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let error = pathEngine.error {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.red)
                                Text("查询失败")
                                    .font(.headline)
                                Text(error.localizedDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if pathEngine.results.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("输入JSONPath进行查询")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("例如: $.users[*].name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(pathEngine.results) { result in
                                        EnhancedJSONPathResultRow(
                                            result: result,
                                            isSelected: selectedResult?.id == result.id,
                                            onSelect: { 
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                    selectedResult = result
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .frame(width: geometry.size.width * 0.5)
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
    }
    
    
    private func performQuery() {
        guard jsonProcessor.isValid && !pathQuery.isEmpty else { return }
        pathEngine.query(jsonProcessor.inputText, path: pathQuery)
    }
}

// 增强的查询结果行
struct EnhancedJSONPathResultRow: View {
    let result: JSONPathResult
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isExpanded = false
    @State private var isHovered = false
    @State private var showCopyAlert = false
    @StateObject private var animationManager = AnimationManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 路径和值摘要
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    // 路径
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text(result.path)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .textSelection(.enabled)
                    }
                    
                    // 值
                    HStack {
                        Image(systemName: valueIcon)
                            .font(.caption)
                            .foregroundColor(valueColor)
                        
                        Text(result.formattedValue)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(isExpanded ? nil : 1)
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                        
                        Spacer()
                    }
                }
                
                // 操作按钮
                HStack(spacing: 8) {
                    if canExpand {
                        Button(action: {
                            withAnimation(animationManager.spring) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .animatedScale(trigger: isExpanded)
                    }
                    
                    Button(action: copyPath) {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.body)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    .help("复制路径")
                    .animatedScale(trigger: isHovered)
                }
            }
            
            // 展开的详细内容
            if isExpanded, let detailedJSON = JSONPathEngine.getDetailedJSON(result.value) {
                EnhancedCard {
                    ScrollView(.horizontal, showsIndicators: true) {
                        Text(detailedJSON)
                            .themeAwareMonospacedFont(size: 12 * themeManager.uiDensity.fontSizeMultiplier)
                            .foregroundColor(Color(hex: themeManager.currentSyntaxColors.textColor))
                            .textSelection(.enabled)
                            .padding(8)
                    }
                    .frame(maxHeight: 200)
                }
                .pageTransition(isActive: isExpanded)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: themeManager.currentSyntaxColors.backgroundColor) ?? .clear)
                .shadow(
                    color: Color.black.opacity(themeManager.effectiveColorScheme == .dark ? 0.3 : 0.1),
                    radius: isSelected ? 6 : 2,
                    x: 0,
                    y: isSelected ? 2 : 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isSelected ? Color.blue : (isHovered ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2)),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .scaleEffect(isSelected ? 1.02 : (isHovered ? 1.01 : 1.0))
        .onHover { hovering in
            withAnimation(animationManager.spring) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .alert("已复制", isPresented: $showCopyAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("路径已复制到剪贴板")
        }
    }
    
    private var canExpand: Bool {
        result.value is [Any] || result.value is [String: Any]
    }
    
    private var valueIcon: String {
        if result.value is String {
            return "textformat"
        } else if result.value is NSNumber {
            return "number"
        } else if result.value is [Any] {
            return "list.bullet"
        } else if result.value is [String: Any] {
            return "curlybraces"
        } else {
            return "questionmark"
        }
    }
    
    private var valueColor: Color {
        if result.value is String {
            return .green
        } else if result.value is NSNumber {
            return .orange
        } else if result.value is [Any] {
            return .purple
        } else if result.value is [String: Any] {
            return .blue
        } else {
            return .gray
        }
    }
    
    private func copyPath() {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(result.path, forType: .string)
        
        withAnimation(animationManager.bouncy) {
            showCopyAlert = true
        }
    }
}

// JSONPath语法帮助视图
struct JSONPathHelpView: View {
    @StateObject private var animationManager = AnimationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题区域
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("JSONPath 语法帮助")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text("学习如何使用JSONPath查询表达式")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .pageTransition(isActive: true)
            
            // 语法示例
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(JSONPathExample.examples, id: \.syntax) { example in
                        EnhancedCard {
                            HStack(alignment: .top, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(example.syntax)
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                        .textSelection(.enabled)
                                    
                                    Text(example.description)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    // 复制示例到剪贴板
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.declareTypes([.string], owner: nil)
                                    pasteboard.setString(example.syntax, forType: .string)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                                .help("复制示例")
                            }
                        }
                        .pageTransition(isActive: true)
                    }
                }
            }
            
            // 提示信息
            EnhancedCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("使用技巧")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 点击查询结果可以查看详细内容")
                        Text("• 使用快速示例快速开始")
                        Text("• 支持复杂的嵌套查询")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .pageTransition(isActive: true)
        }
        .padding()
    }
}

#Preview {
    JSONPathQueryView()
}