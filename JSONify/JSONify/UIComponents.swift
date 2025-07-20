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
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
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
                .onFocusChange { focused in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = focused
                    }
                }
            
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
                    .opacity(isFocused ? 0.5 : 0.7)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return isValid ? .green : .blue
        } else {
            return isValid ? .green : (text.isEmpty ? .gray : .red)
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