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
                                            .stroke(borderColor, lineWidth: 1.5)
                                    )
                                    .cornerRadius(8)
                                    .onChange(of: jsonProcessor.inputText) { _ in
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
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
                                        JSONPathResultRow(
                                            result: result,
                                            isSelected: selectedResult?.id == result.id,
                                            onSelect: { selectedResult = result }
                                        )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(width: geometry.size.width * 0.5)
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
    }
    
    private var borderColor: Color {
        if !jsonProcessor.inputText.isEmpty {
            return jsonProcessor.isValid ? Color.green : Color.red
        }
        return Color.gray
    }
    
    private func performQuery() {
        guard jsonProcessor.isValid && !pathQuery.isEmpty else { return }
        pathEngine.query(jsonProcessor.inputText, path: pathQuery)
    }
}

// 查询结果行
struct JSONPathResultRow: View {
    let result: JSONPathResult
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 路径和值摘要
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.path)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    HStack {
                        Text(result.formattedValue)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if canExpand {
                            Button(action: { isExpanded.toggle() }) {
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                
                Button(action: copyPath) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("复制路径")
            }
            
            // 展开的详细内容
            if isExpanded, let detailedJSON = JSONPathEngine.getDetailedJSON(result.value) {
                ScrollView(.horizontal, showsIndicators: true) {
                    Text(detailedJSON)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(4)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
    
    private var canExpand: Bool {
        result.value is [Any] || result.value is [String: Any]
    }
    
    private func copyPath() {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(result.path, forType: .string)
    }
}

// JSONPath语法帮助视图
struct JSONPathHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("JSONPath 语法帮助")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(JSONPathExample.examples, id: \.syntax) { example in
                        HStack(alignment: .top, spacing: 16) {
                            Text(example.syntax)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.blue)
                                .frame(width: 150, alignment: .leading)
                            
                            Text(example.description)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                    }
                }
            }
            
            Text("提示：点击查询结果可以查看详细内容")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    JSONPathQueryView()
}