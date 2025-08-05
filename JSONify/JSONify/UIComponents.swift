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
                PlainTextEditor(text: $displayText, isFocused: $isFocused, borderColor: borderColor)
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
            let isLarge = newValue.count > 500000
            
            // 更新大文件状态
            if isLarge != isLargeFile {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLargeFile = isLarge
                }
            }
            
            // 同步显示文本，大文件立即截断避免UI冻结
            if newValue != displayText {
                // 对大文件立即截断，避免UI冻结
                if isLarge && newValue.count > 100000 {
                    let truncatedContent = String(newValue.prefix(100000)) + "\n\n... (文件内容过长，已截断显示前100KB，但完整内容已加载用于处理)"
                    displayText = truncatedContent
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

// MARK: - 图标按钮组件（带tooltip）
struct IconButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    let variant: EnhancedButtonStyle.ButtonVariant
    let size: CGFloat
    
    @State private var isHovered = false
    @State private var showTooltip = false
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(
        icon: String,
        tooltip: String,
        variant: EnhancedButtonStyle.ButtonVariant = .primary,
        size: CGFloat = 16,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.tooltip = tooltip
        self.action = action
        self.variant = variant
        self.size = size
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                        .shadow(
                            color: shadowColor,
                            radius: isHovered ? 4 : 2,
                            x: 0,
                            y: isHovered ? 2 : 1
                        )
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tooltip)
        .accessibilityHint("")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
            if hovering {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if isHovered {
                        showTooltip = true
                    }
                }
            } else {
                showTooltip = false
            }
        }
        .overlay(
            tooltipView,
            alignment: .top
        )
    }
    
    @ViewBuilder
    private var tooltipView: some View {
        if showTooltip {
            Text(tooltip)
                .font(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                )
                .offset(y: -50)
                .zIndex(1002)
                .allowsHitTesting(false)
        }
    }
    
    private var iconColor: Color {
        Color(hex: variant.colors.text) ?? .white
    }
    
    private var backgroundColor: Color {
        Color(hex: variant.colors.background) ?? .blue
    }
    
    private var shadowColor: Color {
        Color.black.opacity(themeManager.effectiveColorScheme == .dark ? 0.3 : 0.15)
    }
}

// MARK: - 紧凑图标按钮组件（用于工具栏）
struct CompactIconButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    let variant: EnhancedButtonStyle.ButtonVariant
    
    @State private var isHovered = false
    @State private var showTooltip = false
    
    init(
        icon: String,
        tooltip: String,
        variant: EnhancedButtonStyle.ButtonVariant = .secondary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.tooltip = tooltip
        self.action = action
        self.variant = variant
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(backgroundColor.opacity(isHovered ? 1.0 : 0.8))
                )
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tooltip)
        .accessibilityHint("")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
            if hovering {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if isHovered {
                        showTooltip = true
                    }
                }
            } else {
                showTooltip = false
            }
        }
        .overlay(
            tooltipView,
            alignment: .top
        )
    }
    
    @ViewBuilder
    private var tooltipView: some View {
        if showTooltip {
            Text(tooltip)
                .font(.caption2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                )
                .offset(y: -40)
                .zIndex(1002)
                .allowsHitTesting(false)
        }
    }
    
    private var iconColor: Color {
        Color(hex: variant.colors.text) ?? .white
    }
    
    private var backgroundColor: Color {
        Color(hex: variant.colors.background) ?? .gray
    }
}

// MARK: - 简化图标按钮组件（主要使用原生tooltip）
struct SimpleIconButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    let variant: EnhancedButtonStyle.ButtonVariant
    let size: CGFloat
    
    @State private var isHovered = false
    @State private var showTooltip = false
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(
        icon: String,
        tooltip: String,
        variant: EnhancedButtonStyle.ButtonVariant = .primary,
        size: CGFloat = 16,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.tooltip = tooltip
        self.action = action
        self.variant = variant
        self.size = size
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                        .shadow(
                            color: shadowColor,
                            radius: isHovered ? 4 : 2,
                            x: 0,
                            y: isHovered ? 2 : 1
                        )
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tooltip)
        .accessibilityHint("")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
            if hovering {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if isHovered {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showTooltip = true
                        }
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showTooltip = false
                }
            }
        }
        .overlay(
            tooltipView,
            alignment: .top
        )
    }
    
    @ViewBuilder
    private var tooltipView: some View {
        if showTooltip {
            Text(tooltip)
                .font(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                )
                .offset(y: -45)
                .zIndex(1002)
                .allowsHitTesting(false)
        }
    }
    
    private var iconColor: Color {
        Color(hex: variant.colors.text) ?? .white
    }
    
    private var backgroundColor: Color {
        Color(hex: variant.colors.background) ?? .blue
    }
    
    private var shadowColor: Color {
        Color.black.opacity(themeManager.effectiveColorScheme == .dark ? 0.3 : 0.15)
    }
}

// MARK: - 简化紧凑图标按钮组件
struct SimpleCompactIconButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    let variant: EnhancedButtonStyle.ButtonVariant
    
    @State private var isHovered = false
    @State private var showTooltip = false
    
    init(
        icon: String,
        tooltip: String,
        variant: EnhancedButtonStyle.ButtonVariant = .secondary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.tooltip = tooltip
        self.action = action
        self.variant = variant
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(backgroundColor.opacity(isHovered ? 1.0 : 0.8))
                )
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tooltip)
        .accessibilityHint("")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
            if hovering {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if isHovered {
                        showTooltip = true
                    }
                }
            } else {
                showTooltip = false
            }
        }
        .overlay(
            tooltipView,
            alignment: .top
        )
    }
    
    @ViewBuilder
    private var tooltipView: some View {
        if showTooltip {
            Text(tooltip)
                .font(.caption2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                )
                .offset(y: -40)
                .zIndex(1002)
                .allowsHitTesting(false)
        }
    }
    
    private var iconColor: Color {
        Color(hex: variant.colors.text) ?? .white
    }
    
    private var backgroundColor: Color {
        Color(hex: variant.colors.background) ?? .gray
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

// MARK: - 纯文本编辑器（禁用智能替换）
struct PlainTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let borderColor: Color
    @EnvironmentObject private var themeManager: ThemeManager
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSView {
        // 创建容器视图
        let containerView = NSView()
        
        // 创建滚动视图和文本视图
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // 基本配置
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        
        // 关键：禁用智能引号和其他自动替换功能
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        
        // 文本容器配置 - 关键修复
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.lineFragmentPadding = 0
        
        // 确保文本容器有正确的宽度
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        
        // 强制设置文本视图的frame
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        // 滚动视图配置
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        // 设置初始文本
        textView.string = text
        
        // 强制设置一些测试文本来验证显示
        if text.isEmpty {
            textView.string = "测试文本 - 如果你看到这个，说明文本显示正常"
        }
        
        print("PlainTextEditor makeNSView - 初始文本: '\(text)'")
        print("PlainTextEditor makeNSView - textView.string: '\(textView.string)'")
        print("PlainTextEditor makeNSView - textView bounds: \(textView.bounds)")
        print("PlainTextEditor makeNSView - scrollView bounds: \(scrollView.bounds)")
        
        // 应用主题和样式
        updateTheme(textView: textView, scrollView: scrollView)
        
        // 布局配置 - 关键修复：内置padding和边框
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(scrollView)
        
        // 设置容器视图的最小尺寸
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        containerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            // 设置最小尺寸约束
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
        
        // 设置边框和圆角
        scrollView.wantsLayer = true
        scrollView.layer?.cornerRadius = 10
        scrollView.layer?.borderWidth = isFocused ? 2 : 1
        scrollView.layer?.borderColor = NSColor.from(borderColor)?.cgColor ?? NSColor.controlAccentColor.cgColor
        
        print("PlainTextEditor makeNSView - 初始文本: '\(text)'")
        print("PlainTextEditor makeNSView - textView.string: '\(textView.string)'")
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let scrollView = nsView.subviews.first as? NSScrollView,
              let textView = scrollView.documentView as? NSTextView else { return }
        
        // 只在文本真正不同时才更新，避免循环
        if textView.string != text {
            print("PlainTextEditor updateNSView - 更新文本: '\(text)'")
            textView.string = text
            textView.needsDisplay = true
        }
        
        // 强制更新文本容器尺寸
        if scrollView.bounds.width > 0 {
            let containerWidth = scrollView.bounds.width - 24 // 减去padding
            textView.textContainer?.containerSize = NSSize(width: containerWidth, height: CGFloat.greatestFiniteMagnitude)
            
            // 强制textView重新布局
            textView.frame = NSRect(x: 0, y: 0, width: containerWidth, height: textView.frame.height)
            textView.sizeToFit()
            textView.needsLayout = true
            textView.layoutSubtreeIfNeeded()
            textView.setNeedsDisplay(textView.bounds)
        }
        
        // 调试尺寸信息
        print("PlainTextEditor updateNSView - textView bounds: \(textView.bounds)")
        print("PlainTextEditor updateNSView - scrollView bounds: \(scrollView.bounds)")
        print("PlainTextEditor updateNSView - containerView bounds: \(nsView.bounds)")
        print("PlainTextEditor updateNSView - textContainer size: \(textView.textContainer?.containerSize.width ?? -1)")
        
        // 更新边框颜色（响应焦点变化）
        scrollView.layer?.borderWidth = isFocused ? 2 : 1
        scrollView.layer?.borderColor = NSColor.from(borderColor)?.cgColor ?? NSColor.controlAccentColor.cgColor
        
        // 更新主题
        updateTheme(textView: textView, scrollView: scrollView)
    }
    
    private func updateTheme(textView: NSTextView, scrollView: NSScrollView) {
        let fontSize = 14 * themeManager.uiDensity.fontSizeMultiplier
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        // 使用强对比度颜色确保可见性
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.labelColor
        
        // 设置滚动视图背景
        scrollView.backgroundColor = NSColor.textBackgroundColor
        
        // 强制重绘
        textView.needsDisplay = true
        scrollView.needsDisplay = true
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: PlainTextEditor
        
        init(_ parent: PlainTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // 立即更新绑定的文本
            parent.text = textView.string
        }
        
        func textDidBeginEditing(_ notification: Notification) {
            parent.isFocused = true
        }
        
        func textDidEndEditing(_ notification: Notification) {
            parent.isFocused = false
        }
    }
}

// MARK: - NSColor 扩展
extension NSColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            srgbRed: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
    
    static func from(_ color: Color) -> NSColor? {
        // 简单的Color到NSColor转换
        // 这是一个近似转换，对于边框颜色足够使用
        if #available(macOS 11.0, *) {
            return NSColor(color)
        } else {
            return nil
        }
    }
}