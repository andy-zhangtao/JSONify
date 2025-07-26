//
//  UIComponents.swift
//  JSONify
//
//  Created by 张涛 on 7/20/25.
//

import SwiftUI

// MARK: - 改进的卡片容器
struct EnhancedCard<Content: View>: View {
    let content: Content
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isHovered = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: themeManager.currentSyntaxColors.backgroundColor) ?? .clear)
                    .shadow(
                        color: Color.black.opacity(themeManager.effectiveColorScheme == .dark ? 0.3 : 0.1),
                        radius: isHovered ? 8 : 4,
                        x: 0,
                        y: isHovered ? 4 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color(hex: themeManager.currentSyntaxColors.bracketColor)?
                            .opacity(isHovered ? 0.3 : 0.1) ?? Color.gray.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - 改进的按钮样式
struct EnhancedButtonStyle: ButtonStyle {
    @EnvironmentObject private var themeManager: ThemeManager
    let variant: ButtonVariant
    
    enum ButtonVariant {
        case primary
        case secondary
        case success
        case danger
        
        var colors: (background: String, text: String) {
            switch self {
            case .primary:
                return ("#007AFF", "#FFFFFF")
            case .secondary:
                return ("#8E8E93", "#FFFFFF")
            case .success:
                return ("#34C759", "#FFFFFF")
            case .danger:
                return ("#FF3B30", "#FFFFFF")
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: variant.colors.background) ?? .blue)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .foregroundColor(Color(hex: variant.colors.text) ?? .white)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 状态指示器
struct StatusIndicator: View {
    let status: Status
    @State private var isAnimating = false
    
    enum Status {
        case valid
        case invalid
        case processing
        case idle
        
        var color: Color {
            switch self {
            case .valid: return .green
            case .invalid: return .red
            case .processing: return .orange
            case .idle: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .valid: return "checkmark.circle.fill"
            case .invalid: return "exclamationmark.triangle.fill"
            case .processing: return "arrow.triangle.2.circlepath.circle.fill"
            case .idle: return "circle"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .rotationEffect(.degrees(status == .processing && isAnimating ? 360 : 0))
                .animation(
                    status == .processing ? 
                        .linear(duration: 1.0).repeatForever(autoreverses: false) : 
                        .easeInOut(duration: 0.3),
                    value: isAnimating
                )
                .onAppear {
                    if status == .processing {
                        isAnimating = true
                    }
                }
                .onChange(of: status) { _, newStatus in
                    isAnimating = newStatus == .processing
                }
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(status.color)
        }
    }
    
    private var statusText: String {
        switch status {
        case .valid: return "有效"
        case .invalid: return "无效"
        case .processing: return "处理中"
        case .idle: return "就绪"
        }
    }
}

// MARK: - 改进的文本编辑器
struct EnhancedTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let isValid: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isFocused = false
    @State private var displayText: String = ""
    @State private var isLargeFile = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if isLargeFile {
                // 大文件只读模式，提高性能
                ScrollView {
                    Group {
                        if displayText.isEmpty {
                            Text("正在加载大文件...")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // displayText 已经在同步时被截断，直接使用
                            Text(displayText)
                                .themeAwareMonospacedFont(size: 14 * themeManager.uiDensity.fontSizeMultiplier)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .background(Color(hex: themeManager.currentSyntaxColors.backgroundColor) ?? .clear)
                                .foregroundColor(Color(hex: themeManager.currentSyntaxColors.textColor) ?? .primary)
                        }
                    }
                    .padding(12)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: 1)
                )
                .cornerRadius(10)
                .overlay(
                    // 大文件只读模式提示和控制
                    VStack {
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("大文件只读模式")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(4)
                                
                                // 为大文件提供格式化按钮
                                Button(action: {
                                    // 触发格式化处理
                                    NotificationCenter.default.post(name: .formatLargeFile, object: nil)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "play.fill")
                                            .font(.caption2)
                                        Text("格式化")
                                            .font(.caption2)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Spacer()
                    }
                    .padding(8),
                    alignment: .topTrailing
                )
            } else {
                TextEditor(text: $displayText)
                    .themeAwareMonospacedFont(size: 14 * themeManager.uiDensity.fontSizeMultiplier)
                    .padding(12)
                    .background(Color(hex: themeManager.currentSyntaxColors.backgroundColor) ?? .clear)
                    .foregroundColor(Color(hex: themeManager.currentSyntaxColors.textColor) ?? .primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
                            .animation(.easeInOut(duration: 0.2), value: isFocused)
                    )
                    .cornerRadius(10)
                    .onReceive(NotificationCenter.default.publisher(for: NSTextView.didBeginEditingNotification)) { _ in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isFocused = true
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSTextView.didEndEditingNotification)) { _ in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isFocused = false
                        }
                    }
                    .onChange(of: displayText) { _, newValue in
                        // 双向绑定，但避免循环更新
                        if newValue != text {
                            text = newValue
                        }
                    }
            }
            
            if displayText.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
                    .opacity(isFocused ? 0.5 : 0.7)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
        }
        .onChange(of: text) { _, newValue in
            print("📝 EnhancedTextEditor text 改变: \(newValue.count)字符")
            let isLarge = newValue.count > 500000
            
            // 更新大文件状态
            if isLarge != isLargeFile {
                print("🔄 切换文件模式: 大文件=\(isLarge)")
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLargeFile = isLarge
                }
            }
            
            // 同步显示文本，大文件立即截断避免UI冻结
            if newValue != displayText {
                print("🔄 同步显示文本: \(newValue.count)字符")
                
                // 对大文件立即截断，避免UI冻结
                if isLarge && newValue.count > 100000 {
                    let truncatedContent = String(newValue.prefix(100000)) + "\n\n... (文件内容过长，已截断显示前100KB，但完整内容已加载用于处理)"
                    displayText = truncatedContent
                    print("📏 文本已截断到: \(truncatedContent.count)字符")
                } else {
                    displayText = newValue
                }
            }
        }
        .onAppear {
            let isLarge = text.count > 500000
            isLargeFile = isLarge
            
            // 初始化时也要截断大文件
            if isLarge && text.count > 100000 {
                displayText = String(text.prefix(100000)) + "\n\n... (文件内容过长，已截断显示前100KB，但完整内容已加载用于处理)"
                print("📏 初始化时文本已截断到: \(displayText.count)字符")
            } else {
                displayText = text
            }
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return isValid ? .green : .blue
        } else {
            return isValid ? .green : (displayText.isEmpty ? .gray : .red)
        }
    }
}

// MARK: - 滑动切换控件
struct SlidingSegmentedControl: View {
    @Binding var selection: Int
    let options: [String]
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var backgroundOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<options.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = index
                        updateBackgroundOffset(for: index)
                    }
                }) {
                    Text(options[index])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selection == index ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue)
                .frame(width: backgroundWidth)
                .offset(x: backgroundOffset)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: backgroundOffset)
        )
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: themeManager.currentSyntaxColors.backgroundColor) ?? .clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            updateBackgroundOffset(for: selection)
        }
    }
    
    private var backgroundWidth: CGFloat {
        return 200 / CGFloat(options.count) // 假设总宽度为200
    }
    
    private func updateBackgroundOffset(for index: Int) {
        backgroundOffset = (backgroundWidth * CGFloat(index)) - (backgroundWidth * CGFloat(options.count - 1) / 2)
    }
}

// MARK: - 信息提示气泡
struct InfoBubble: View {
    let text: String
    let type: BubbleType
    @State private var isVisible = false
    
    enum BubbleType {
        case info, success, warning, error
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(type.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isVisible = true
            }
        }
    }
}

// MARK: - 扩展：焦点状态检测
extension View {
    func onFocusChange(_ action: @escaping (Bool) -> Void) -> some View {
        self.background(
            FocusDetector(onFocusChange: action)
        )
    }
}

private struct FocusDetector: NSViewRepresentable {
    let onFocusChange: (Bool) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}