//
//  ThemeAwareModifiers.swift
//  JSONify
//
//  Created by 张涛 on 7/20/25.
//

import SwiftUI

// 主题感知的内边距修饰符
struct ThemeAwarePadding: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    let edges: Edge.Set
    let length: CGFloat?
    
    func body(content: Content) -> some View {
        let multiplier = themeManager.uiDensity.paddingMultiplier
        if let length = length {
            content.padding(edges, length * multiplier)
        } else {
            content.padding(edges)
        }
    }
}

// 主题感知的字体修饰符
struct ThemeAwareFont: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    let font: Font
    let size: CGFloat?
    
    func body(content: Content) -> some View {
        let multiplier = themeManager.uiDensity.fontSizeMultiplier
        if let size = size {
            content.font(.system(size: size * multiplier, design: .default))
        } else {
            content.font(font)
        }
    }
}

// 主题感知的等宽字体修饰符
struct ThemeAwareMonospacedFont: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    let size: CGFloat
    
    func body(content: Content) -> some View {
        let multiplier = themeManager.uiDensity.fontSizeMultiplier
        content.font(.system(size: size * multiplier, design: .monospaced))
    }
}

// 主题感知的间距修饰符
struct ThemeAwareSpacing: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    let spacing: CGFloat
    
    func body(content: Content) -> some View {
        let multiplier = themeManager.uiDensity.spacingMultiplier
        content
    }
}

// 语法高亮文本修饰符
struct SyntaxHighlightedText: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    let text: String
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color(hex: themeManager.currentSyntaxColors.textColor))
            .background(Color(hex: themeManager.currentSyntaxColors.backgroundColor))
    }
}

// View扩展
extension View {
    func themeAwarePadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
        modifier(ThemeAwarePadding(edges: edges, length: length))
    }
    
    func themeAwareFont(_ font: Font, size: CGFloat? = nil) -> some View {
        modifier(ThemeAwareFont(font: font, size: size))
    }
    
    func themeAwareMonospacedFont(size: CGFloat) -> some View {
        modifier(ThemeAwareMonospacedFont(size: size))
    }
    
    func syntaxHighlighted(_ text: String) -> some View {
        modifier(SyntaxHighlightedText(text: text))
    }
}

// 主题容器修饰符
struct ThemeAwareContainer<Content: View>: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environment(\.colorScheme, themeManager.effectiveColorScheme)
            .background(Color(hex: themeManager.currentSyntaxColors.backgroundColor))
            .foregroundColor(Color(hex: themeManager.currentSyntaxColors.textColor))
    }
}