//
//  ContentView.swift
//  JSONify
//
//  Created by 张涛 on 7/14/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var jsonProcessor = JSONProcessor()
    @StateObject private var historyManager = SessionHistoryManager()
    @State private var showingCopyAlert = false
    @State private var viewMode: ViewMode = .formatted
    @State private var saveTimer: Timer?
    @AppStorage("sortKeys") private var sortKeys = true
    @AppStorage("fontSize") private var fontSize = 14.0
    @AppStorage("autoFormat") private var autoFormat = true
    
    enum ViewMode: String, CaseIterable {
        case formatted = "格式化"
        case tree = "树形视图"
    }
    
    var body: some View {
        NavigationView {
            HSplitView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("JSON 输入")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $jsonProcessor.inputText)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(jsonProcessor.isValid ? Color.green : (jsonProcessor.validationError != nil ? Color.red : Color.gray), lineWidth: 2)
                            )
                            .cornerRadius(8)
                            .onChange(of: jsonProcessor.inputText) { newValue in
                                if autoFormat {
                                    jsonProcessor.processJSON(sortKeys: sortKeys)
                                }
                                
                                // 取消之前的定时器
                                saveTimer?.invalidate()
                                
                                // 设置新的定时器，延迟1.5秒后保存
                                if jsonProcessor.isValid && !newValue.isEmpty {
                                    saveTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                                        historyManager.addSession(newValue)
                                    }
                                }
                            }
                            .font(.system(size: fontSize, design: .monospaced))
                        
                        if jsonProcessor.inputText.isEmpty {
                            Text("在此粘贴或输入您的 JSON 数据...")
                                .foregroundColor(.secondary)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }
                    
                    if let error = jsonProcessor.validationError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error.localizedDescription)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.8)), 
                                               removal: .opacity.combined(with: .scale(scale: 0.8))))
                        .animation(.easeInOut(duration: 0.3), value: jsonProcessor.validationError)
                    }
                    
                    if jsonProcessor.isValid {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("JSON 格式正确")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.8)), 
                                               removal: .opacity.combined(with: .scale(scale: 0.8))))
                        .animation(.easeInOut(duration: 0.3), value: jsonProcessor.isValid)
                    }
                    
                    if !autoFormat && !jsonProcessor.inputText.isEmpty {
                        Button(action: {
                            jsonProcessor.processJSON(sortKeys: sortKeys)
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("格式化 JSON")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: autoFormat)
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(minWidth: 400)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("显示结果")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if jsonProcessor.isValid {
                            Picker("视图模式", selection: $viewMode) {
                                ForEach(ViewMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                            
                            Button(action: copyToClipboard) {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("复制")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    Group {
                        if jsonProcessor.isValid {
                            switch viewMode {
                            case .formatted:
                                ScrollView {
                                    HStack {
                                        Text(jsonProcessor.formattedJSON)
                                            .font(.system(size: fontSize, design: .monospaced))
                                            .foregroundColor(.primary)
                                            .textSelection(.enabled)
                                            .frame(maxWidth: .infinity, alignment: .topLeading)
                                        Spacer()
                                    }
                                    .padding()
                                }
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .transition(.asymmetric(insertion: .opacity.combined(with: .slide), 
                                                       removal: .opacity.combined(with: .slide)))
                            case .tree:
                                JSONTreeView(jsonString: jsonProcessor.formattedJSON)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .transition(.asymmetric(insertion: .opacity.combined(with: .slide), 
                                                           removal: .opacity.combined(with: .slide)))
                            }
                        } else {
                            ScrollView {
                                HStack {
                                    Text("格式化的 JSON 将在此显示...")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .topLeading)
                                    Spacer()
                                }
                                .padding()
                            }
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.4), value: jsonProcessor.isValid)
                    .animation(.easeInOut(duration: 0.3), value: viewMode)
                }
                .padding()
                .frame(minWidth: 400)
                
                // 会话历史视图
                SessionHistoryView(
                    historyManager: historyManager,
                    selectedContent: $jsonProcessor.inputText
                )
                .frame(width: 300)
                .padding(.trailing)
            }
            .overlay(
                VStack {
                    Spacer()
                    StatusBarView(
                        isValid: jsonProcessor.isValid,
                        characterCount: jsonProcessor.inputText.count,
                        lineCount: jsonProcessor.inputText.components(separatedBy: .newlines).count,
                        processingTime: jsonProcessor.processingTime
                    )
                }
            )
        }
        .navigationTitle("JSONify")
        .alert("已复制", isPresented: $showingCopyAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("JSON 数据已复制到剪贴板")
        }
        .onReceive(NotificationCenter.default.publisher(for: .clearInput)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                jsonProcessor.inputText = ""
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .copyFormatted)) { _ in
            if jsonProcessor.isValid {
                copyToClipboard()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pasteToInput)) { _ in
            let pasteboard = NSPasteboard.general
            if let string = pasteboard.string(forType: .string) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    jsonProcessor.inputText = string
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleViewMode)) { _ in
            if jsonProcessor.isValid {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewMode = viewMode == .formatted ? .tree : .formatted
                }
            }
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(jsonProcessor.formattedJSON, forType: .string)
        showingCopyAlert = true
    }
}

#Preview {
    ContentView()
}
