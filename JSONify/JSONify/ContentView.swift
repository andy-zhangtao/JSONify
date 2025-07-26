//
//  ContentView.swift
//  JSONify
//
//  Created by 张涛 on 7/14/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var jsonProcessor = JSONProcessor()
    @StateObject private var historyManager = SessionHistoryManager()
    @StateObject private var animationManager = AnimationManager.shared
    @StateObject private var fileManager = JSONFileManager()
    @State private var showingCopyAlert = false
    @State private var showingFileError = false
    @State private var viewMode: ViewMode = .formatted
    @State private var saveTimer: Timer?
    @State private var isProcessing = false
    @State private var showSuccessIndicator = false
    @EnvironmentObject private var themeManager: ThemeManager
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
                leftInputArea
                rightDisplayArea
            }
            .overlay(alignment: .bottom) {
                StatusBarView(
                    isValid: jsonProcessor.isValid,
                    characterCount: jsonProcessor.inputText.count,
                    lineCount: jsonProcessor.inputText.components(separatedBy: .newlines).count,
                    processingTime: jsonProcessor.processingTime
                )
            }
        }
        .navigationTitle("JSONify")
        .alert("已复制", isPresented: $showingCopyAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("JSON 数据已复制到剪贴板")
        }
        .alert("文件读取错误", isPresented: $showingFileError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(fileManager.fileError?.localizedDescription ?? "未知错误")
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
        .onReceive(NotificationCenter.default.publisher(for: .formatLargeFile)) { _ in
            // 处理大文件格式化请求
            performLargeFileFormat()
        }
    }
}

// MARK: - 子视图扩展
extension ContentView {
    private var leftInputArea: some View {
        VStack(alignment: .leading, spacing: 20) {
            inputHeaderView
            fileSelectionView
            inputEditorView
            inputErrorView
            manualFormatButtonView
            historyView
            Spacer()
        }
        .padding()
        .frame(minWidth: 450)
        .background(
            FilePicker(selectedURL: $fileManager.selectedFileURL, isPresented: $fileManager.isFilePickerPresented)
                .frame(width: 0, height: 0)
                .hidden()
        )
        .onChange(of: fileManager.selectedFileURL) { _, newURL in
            if newURL != nil {
                Task {
                    await loadSelectedFile()
                }
            }
        }
        .onChange(of: fileManager.fileError) { _, error in
            if error != nil {
                showingFileError = true
            }
        }
    }
    
    private var inputHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("JSON 输入")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                StatusIndicator(status: currentStatus)
                    .pageTransition(isActive: true)
            }
            
            Spacer()
            
            if isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("处理中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .pageTransition(isActive: isProcessing)
            } else if jsonProcessor.isProcessing {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        ProgressView(value: jsonProcessor.processingProgress)
                            .frame(width: 120)
                        Text(jsonProcessor.processingStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if jsonProcessor.processingProgress > 0 {
                        Text("\(Int(jsonProcessor.processingProgress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .pageTransition(isActive: jsonProcessor.isProcessing)
            }
            
            if showSuccessIndicator {
                InfoBubble(text: "处理完成", type: .success)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(animationManager.smooth) {
                                showSuccessIndicator = false
                            }
                        }
                    }
            }
        }
    }
    
    private var inputEditorView: some View {
        EnhancedCard {
            EnhancedTextEditor(
                text: $jsonProcessor.inputText,
                placeholder: "在此粘贴或输入您的 JSON 数据...\n\n支持格式:\n• 标准 JSON\n• 压缩或格式化的 JSON\n• 包含注释的 JSON",
                isValid: jsonProcessor.isValid
            )
            .frame(minHeight: 300)
            .onChange(of: jsonProcessor.inputText) { _, newValue in
                handleTextChange(newValue)
            }
        }
    }
    
    private var inputErrorView: some View {
        Group {
            if let error = jsonProcessor.validationError {
                InfoBubble(text: error.localizedDescription, type: .error)
                    .pageTransition(isActive: jsonProcessor.validationError != nil)
            }
        }
    }
    
    private var manualFormatButtonView: some View {
        Group {
            if !jsonProcessor.inputText.isEmpty {
                VStack(spacing: 12) {
                    // 第一行：主要功能按钮
                    HStack(spacing: 12) {
                        if !autoFormat {
                            Button(action: performManualFormat) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                    Text("格式化 JSON")
                                }
                            }
                            .buttonStyle(EnhancedButtonStyle(variant: .primary))
                            .animatedScale(trigger: !jsonProcessor.inputText.isEmpty)
                        }
                        
                        Button(action: performUnescape) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                                Text("反转义")
                            }
                        }
                        .buttonStyle(EnhancedButtonStyle(variant: .secondary))
                        .animatedScale(trigger: !jsonProcessor.inputText.isEmpty)
                        
                        Spacer()
                    }
                    
                    // 第二行：编码转换功能按钮
                    HStack(spacing: 8) {
                        Button(action: performUnicodeConversion) {
                            HStack(spacing: 6) {
                                Image(systemName: "textformat.123")
                                Text("Unicode转中文")
                            }
                        }
                        .buttonStyle(EnhancedButtonStyle(variant: .secondary))
                        .animatedScale(trigger: !jsonProcessor.inputText.isEmpty, scale: 0.98)
                        
                        Button(action: performHTMLConversion) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.richtext")
                                Text("HTML转中文")
                            }
                        }
                        .buttonStyle(EnhancedButtonStyle(variant: .secondary))
                        .animatedScale(trigger: !jsonProcessor.inputText.isEmpty, scale: 0.98)
                        
                        Button(action: performURLDecoding) {
                            HStack(spacing: 6) {
                                Image(systemName: "link.badge.plus")
                                Text("URL解码")
                            }
                        }
                        .buttonStyle(EnhancedButtonStyle(variant: .secondary))
                        .animatedScale(trigger: !jsonProcessor.inputText.isEmpty, scale: 0.98)
                        
                        Spacer()
                    }
                }
                .pageTransition(isActive: !jsonProcessor.inputText.isEmpty)
            }
        }
    }
    
    private var fileSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    fileManager.presentFilePicker()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                        Text("选择文件")
                    }
                }
                .buttonStyle(EnhancedButtonStyle(variant: .primary))
                .animatedScale(trigger: true)
                
                if fileManager.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("读取中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .pageTransition(isActive: fileManager.isLoading)
                }
                
                if !fileManager.selectedFileName.isEmpty {
                    Button(action: {
                        fileManager.clearSelection()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("清除选择")
                        }
                    }
                    .buttonStyle(EnhancedButtonStyle(variant: .secondary))
                    .animatedScale(trigger: !fileManager.selectedFileName.isEmpty, scale: 0.98)
                }
                
                Spacer()
            }
            
            if !fileManager.selectedFileName.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                    Text("已选择：\(fileManager.selectedFileName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .pageTransition(isActive: !fileManager.selectedFileName.isEmpty)
            }
            
            // 最近文件列表
            if !fileManager.recentFiles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("最近打开的文件")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            fileManager.clearRecentFiles()
                        }) {
                            Text("清空")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(fileManager.recentFiles.prefix(5)) { recentFile in
                                RecentFileButton(
                                    file: recentFile,
                                    onSelect: { url in
                                        fileManager.selectedFileURL = url
                                    },
                                    onRemove: { file in
                                        fileManager.removeFromRecentFiles(file)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(height: 60)
                }
                .pageTransition(isActive: !fileManager.recentFiles.isEmpty)
            }
        }
    }
    
    private var historyView: some View {
        Group {
            if !historyManager.sessions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("历史记录")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: clearHistory) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(historyManager.sessions.enumerated()), id: \.offset) { index, session in
                                SimpleHistoryBubble(
                                    session: session,
                                    index: index,
                                    onTap: { restoreFromHistory(session) },
                                    onDelete: { deleteHistory(at: index) }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(height: 60)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
    }
    
    private var rightDisplayArea: some View {
        VStack(alignment: .leading, spacing: 20) {
            displayHeaderView
            displayContentView
        }
        .padding()
        .frame(minWidth: 500)
    }
    
    private var displayHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("显示结果")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if jsonProcessor.isValid {
                    HStack(spacing: 12) {
                        Text("已处理")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        if let processingTime = jsonProcessor.processingTime {
                            Text("耗时: \(String(format: "%.2f", processingTime * 1000))ms")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            if jsonProcessor.isValid {
                HStack(spacing: 12) {
                    SlidingSegmentedControl(
                        selection: Binding(
                            get: { ViewMode.allCases.firstIndex(of: viewMode) ?? 0 },
                            set: { viewMode = ViewMode.allCases[$0] }
                        ),
                        options: ViewMode.allCases.map { $0.rawValue }
                    )
                    .frame(width: 200)
                    
                    Button(action: copyToClipboard) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                            Text("复制")
                        }
                    }
                    .buttonStyle(EnhancedButtonStyle(variant: .primary))
                    .animatedScale(trigger: jsonProcessor.isValid)
                }
                .pageTransition(isActive: jsonProcessor.isValid)
            }
        }
    }
    
    private var displayContentView: some View {
        EnhancedCard {
            Group {
                if jsonProcessor.isValid {
                    switch viewMode {
                    case .formatted:
                        formattedJSONView
                    case .tree:
                        JSONTreeView(jsonString: jsonProcessor.formattedJSON)
                            .frame(minHeight: 400)
                            .pageTransition(isActive: viewMode == .tree)
                    }
                } else {
                    emptyStateView
                }
            }
        }
        .animatedScale(trigger: jsonProcessor.isValid, scale: 1.01)
    }
    
    private var formattedJSONView: some View {
        ScrollView {
            if themeManager.useCustomColors {
                // 对于大文件，语法高亮器也需要截断
                let displayText = jsonProcessor.formattedJSON.count > 200000 ? 
                    String(jsonProcessor.formattedJSON.prefix(200000)) + "\n\n... (JSON内容过长，已截断显示前200KB，完整内容可复制)" :
                    jsonProcessor.formattedJSON
                
                NewSyntaxHighlightedTextView(
                    text: .constant(displayText),
                    fontSize: CGFloat(fontSize),
                    isEditable: false
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                VStack(alignment: .leading) {
                    Group {
                        // 对大文件截断显示，避免Text组件性能问题
                        if jsonProcessor.formattedJSON.count > 200000 {
                            VStack(alignment: .leading, spacing: 8) {
                                // 截断提示
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.orange)
                                    Text("大文件显示模式：仅显示前200KB，完整内容可复制")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                .padding(.bottom, 4)
                                
                                // 截断内容
                                Text(String(jsonProcessor.formattedJSON.prefix(200000)) + "\n\n... (内容已截断)")
                                    .themeAwareMonospacedFont(size: fontSize * themeManager.uiDensity.fontSizeMultiplier)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                            }
                        } else {
                            Text(jsonProcessor.formattedJSON)
                                .themeAwareMonospacedFont(size: fontSize * themeManager.uiDensity.fontSizeMultiplier)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    }
                    Spacer()
                }
            }
        }
        .frame(minHeight: 400)
        .pageTransition(isActive: viewMode == .formatted)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .pulseEffect(isActive: true)
            
            VStack(spacing: 8) {
                Text("等待 JSON 输入")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("格式化的 JSON 将在此显示")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 400)
        .pageTransition(isActive: !jsonProcessor.isValid)
    }
}

// MARK: - 辅助方法
extension ContentView {
    private var currentStatus: StatusIndicator.Status {
        if isProcessing {
            return .processing
        } else if jsonProcessor.isValid {
            return .valid
        } else if jsonProcessor.validationError != nil {
            return .invalid
        } else {
            return .idle
        }
    }
    
    private func loadSelectedFile() async {
        guard let content = await fileManager.readSelectedFile() else {
            return
        }
        
        // 对于大文件（>500KB），采用渐进式加载
        if content.count > 500000 {
            await loadLargeFileContent(content)
        } else {
            await MainActor.run {
                withAnimation(animationManager.smooth) {
                    jsonProcessor.inputText = content
                    showSuccessIndicator = true
                }
            }
        }
    }
    
    private func loadLargeFileContent(_ content: String) async {
        await MainActor.run {
            isProcessing = true
        }
        
        // 延迟更新，让UI有时间响应
        try? await Task.sleep(for: .milliseconds(200))
        
        // 简化大文件加载：直接设置内容，不进行分块
        await MainActor.run {
            // 直接设置内容，让EnhancedTextEditor处理大文件显示
            jsonProcessor.inputText = content
            
            // 标记加载完成
            isProcessing = false
            showSuccessIndicator = true
            
            // 大文件加载完成后自动触发格式化
            if autoFormat {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    jsonProcessor.processJSON(sortKeys: sortKeys)
                }
            }
        }
    }
    
    private func handleTextChange(_ newValue: String) {
        // 如果正在分块加载大文件，跳过自动格式化以避免重复处理
        if isProcessing {
            return
        }
        
        withAnimation(animationManager.quick) {
            isProcessing = !newValue.isEmpty
        }
        
        // 根据文件大小调整处理延迟
        let processingDelay: TimeInterval = newValue.count > 500000 ? 1.0 : 0.3
        
        DispatchQueue.main.asyncAfter(deadline: .now() + processingDelay) {
            if autoFormat {
                jsonProcessor.processJSON(sortKeys: sortKeys)
            }
            
            withAnimation(animationManager.quick) {
                isProcessing = false
                if jsonProcessor.isValid {
                    showSuccessIndicator = true
                }
            }
        }
        
        saveTimer?.invalidate()
        
        // 对大文件延迟保存到历史记录
        let saveDelay: TimeInterval = newValue.count > 500000 ? 3.0 : 1.5
        
        if jsonProcessor.isValid && !newValue.isEmpty {
            saveTimer = Timer.scheduledTimer(withTimeInterval: saveDelay, repeats: false) { _ in
                historyManager.addSession(newValue)
            }
        }
    }
    
    private func performManualFormat() {
        withAnimation(animationManager.spring) {
            isProcessing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            jsonProcessor.processJSON(sortKeys: sortKeys)
            withAnimation(animationManager.spring) {
                isProcessing = false
                showSuccessIndicator = true
            }
        }
    }
    
    private func performUnescape() {
        withAnimation(animationManager.spring) {
            isProcessing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            jsonProcessor.unescapeJSONString()
            withAnimation(animationManager.spring) {
                isProcessing = false
                showSuccessIndicator = true
            }
        }
    }
    
    private func performUnicodeConversion() {
        jsonProcessor.convertUnicodeToChineseCharacters()
    }
    
    private func performHTMLConversion() {
        jsonProcessor.convertHTMLToChineseCharacters()
    }
    
    private func performURLDecoding() {
        jsonProcessor.convertURLEncoding()
    }
    
    private func performLargeFileFormat() {
        withAnimation(animationManager.spring) {
            isProcessing = true
        }
        
        // 大文件格式化使用更长的延迟，避免阻塞UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            jsonProcessor.processJSON(sortKeys: sortKeys)
            withAnimation(animationManager.spring) {
                isProcessing = false
                showSuccessIndicator = true
            }
        }
    }
    
    private func clearHistory() {
        withAnimation(animationManager.spring) {
            historyManager.clearAllSessions()
        }
    }
    
    private func restoreFromHistory(_ session: JSONSession) {
        withAnimation(animationManager.bouncy) {
            jsonProcessor.inputText = session.content
        }
    }
    
    private func deleteHistory(at index: Int) {
        withAnimation(animationManager.spring) {
            let session = historyManager.sessions[index]
            historyManager.deleteSession(session)
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(jsonProcessor.formattedJSON, forType: .string)
        
        withAnimation(animationManager.bouncy) {
            showingCopyAlert = true
        }
    }
}

// MARK: - 简化的历史记录气泡组件
struct SimpleHistoryBubble: View {
    let session: JSONSession
    let index: Int
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text("记录 \(index + 1)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(session.content.prefix(30) + (session.content.count > 30 ? "..." : ""))
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(formatDate(session.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .frame(width: 100, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            .onHover { hovering in
                isHovered = hovering
            }
            .overlay(
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1.0 : 0.0),
                alignment: .topTrailing
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 最近文件按钮组件
struct RecentFileButton: View {
    let file: JSONFileManager.RecentFile
    let onSelect: (URL) -> Void
    let onRemove: (JSONFileManager.RecentFile) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            onSelect(file.url)
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: file.name.hasSuffix(".json") ? "doc.text.fill" : "doc.text")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(file.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Text(formatFileSize(file.fileSize))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(formatRelativeDate(file.accessDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .frame(width: 120, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(isHovered ? 0.15 : 0.1))
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            .onHover { hovering in
                isHovered = hovering
            }
            .overlay(
                Button(action: {
                    onRemove(file)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white, in: Circle())
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1.0 : 0.0),
                alignment: .topTrailing
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}