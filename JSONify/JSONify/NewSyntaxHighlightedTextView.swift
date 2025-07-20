//
//  NewSyntaxHighlightedTextView.swift
//  JSONify
//
//  Created by 张涛 on 7/20/25.
//

import SwiftUI
import AppKit

struct NewSyntaxHighlightedTextView: NSViewRepresentable {
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager
    
    let fontSize: CGFloat
    let isEditable: Bool
    let onTextChange: ((String) -> Void)?
    
    init(
        text: Binding<String>,
        fontSize: CGFloat = 14,
        isEditable: Bool = true,
        onTextChange: ((String) -> Void)? = nil
    ) {
        self._text = text
        self.fontSize = fontSize
        self.isEditable = isEditable
        self.onTextChange = onTextChange
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = JSONHighlightTextView(frame: .zero, textContainer: nil)
        
        // 配置文本视图
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = true
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        // 设置字体
        let adjustedFontSize = fontSize * themeManager.uiDensity.fontSizeMultiplier
        textView.font = NSFont.monospacedSystemFont(ofSize: adjustedFontSize, weight: .regular)
        
        // 配置滚动视图
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = false
        
        // 设置代理
        textView.delegate = context.coordinator
        textView.textStorage?.delegate = context.coordinator
        
        // 初始化内容
        textView.string = text
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // 更新文本内容（避免循环更新）
        if textView.string != text {
            textView.string = text
        }
        
        // 更新字体大小
        let adjustedFontSize = fontSize * themeManager.uiDensity.fontSizeMultiplier
        textView.font = NSFont.monospacedSystemFont(ofSize: adjustedFontSize, weight: .regular)
        
        // 更新主题色彩
        updateTextViewAppearance(textView)
        
        // 应用语法高亮
        if themeManager.useCustomColors {
            context.coordinator.applySyntaxHighlighting(to: textView.textStorage!)
        }
    }
    
    private func updateTextViewAppearance(_ textView: NSTextView) {
        let colors = themeManager.currentSyntaxColors
        
        // 设置背景色
        if let bgColor = Color(hex: colors.backgroundColor) {
            textView.backgroundColor = NSColor(bgColor)
        }
        
        // 设置文本色
        if let textColor = Color(hex: colors.textColor) {
            textView.textColor = NSColor(textColor)
        }
        
        // 设置插入点颜色
        textView.insertionPointColor = themeManager.effectiveColorScheme == .dark ? .white : .black
        
        // 设置选择背景色
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor.selectedTextBackgroundColor,
            .foregroundColor: NSColor.selectedTextColor
        ]
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        let parent: NewSyntaxHighlightedTextView
        
        init(_ parent: NewSyntaxHighlightedTextView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            DispatchQueue.main.async {
                self.parent.text = textView.string
                self.parent.onTextChange?(textView.string)
            }
        }
        
        func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
            guard editedMask.contains(.editedCharacters) else { return }
            
            if parent.themeManager.useCustomColors {
                // 延迟应用高亮，避免性能问题
                DispatchQueue.main.async {
                    self.applySyntaxHighlighting(to: textStorage)
                }
            }
        }
        
        func applySyntaxHighlighting(to textStorage: NSTextStorage) {
            let text = textStorage.string
            let range = NSRange(location: 0, length: text.count)
            let colors = parent.themeManager.currentSyntaxColors
            
            // 清除现有格式
            textStorage.removeAttribute(.foregroundColor, range: range)
            
            // 设置默认文本颜色
            if let defaultColor = Color(hex: colors.textColor) {
                textStorage.addAttribute(.foregroundColor, value: NSColor(defaultColor), range: range)
            }
            
            // 应用JSON语法高亮
            highlightJSONSyntax(in: textStorage, colors: colors)
        }
        
        private func highlightJSONSyntax(in textStorage: NSTextStorage, colors: SyntaxColors) {
            let text = textStorage.string
            
            // 字符串高亮 (双引号包围的内容)
            if let stringColor = Color(hex: colors.stringColor) {
                highlightPattern(
                    in: textStorage,
                    pattern: "\"([^\"\\\\]|\\\\.)*\"",
                    color: NSColor(stringColor)
                )
            }
            
            // 数字高亮
            if let numberColor = Color(hex: colors.numberColor) {
                highlightPattern(
                    in: textStorage,
                    pattern: "\\b-?\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b",
                    color: NSColor(numberColor)
                )
            }
            
            // 布尔值高亮
            if let booleanColor = Color(hex: colors.booleanColor) {
                highlightPattern(
                    in: textStorage,
                    pattern: "\\b(true|false)\\b",
                    color: NSColor(booleanColor)
                )
            }
            
            // null值高亮
            if let nullColor = Color(hex: colors.nullColor) {
                highlightPattern(
                    in: textStorage,
                    pattern: "\\bnull\\b",
                    color: NSColor(nullColor)
                )
            }
            
            // 键名高亮 (引号前面有冒号的字符串)
            if let keyColor = Color(hex: colors.keyColor) {
                highlightPattern(
                    in: textStorage,
                    pattern: "\"([^\"\\\\]|\\\\.)*\"(?=\\s*:)",
                    color: NSColor(keyColor)
                )
            }
            
            // 括号和分隔符
            if let bracketColor = Color(hex: colors.bracketColor) {
                highlightPattern(
                    in: textStorage,
                    pattern: "[\\[\\]{},:()]",
                    color: NSColor(bracketColor)
                )
            }
        }
        
        private func highlightPattern(in textStorage: NSTextStorage, pattern: String, color: NSColor) {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let text = textStorage.string
                let range = NSRange(location: 0, length: text.count)
                
                regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                    guard let matchRange = match?.range else { return }
                    textStorage.addAttribute(.foregroundColor, value: color, range: matchRange)
                }
            } catch {
                print("正则表达式错误: \\(error)")
            }
        }
    }
}

// 自定义NSTextView类
class JSONHighlightTextView: NSTextView {
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTextView()
    }
    
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        setupTextView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextView()
    }
    
    private func setupTextView() {
        // 禁用自动替换
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isContinuousSpellCheckingEnabled = false
        isGrammarCheckingEnabled = false
        smartInsertDeleteEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        
        // 启用富文本
        isRichText = true
        
        // 设置行间距
        defaultParagraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 2
            return style
        }()
    }
    
    // 支持制表符缩进
    override func insertTab(_ sender: Any?) {
        insertText("  ", replacementRange: selectedRange())
    }
    
    // 支持Shift+Tab减少缩进
    override func insertBacktab(_ sender: Any?) {
        let range = selectedRange()
        let text = string as NSString
        let lineRange = text.lineRange(for: range)
        let lineText = text.substring(with: lineRange)
        
        if lineText.hasPrefix("  ") {
            let newText = String(lineText.dropFirst(2))
            if shouldChangeText(in: lineRange, replacementString: newText) {
                textStorage?.replaceCharacters(in: lineRange, with: newText)
                didChangeText()
            }
        }
    }
}

// SwiftUI预览
struct NewSyntaxHighlightedTextView_Previews: PreviewProvider {
    @State static var sampleJSON = """
{
  "name": "JSONify App",
  "version": 2.0,
  "isActive": true,
  "description": null,
  "features": [
    "格式化",
    "比较",
    "语法高亮"
  ],
  "config": {
    "theme": "dark",
    "fontSize": 14
  }
}
"""
    
    static var previews: some View {
        NewSyntaxHighlightedTextView(
            text: $sampleJSON,
            fontSize: 14,
            isEditable: true
        )
        .environmentObject(ThemeManager())
        .frame(width: 500, height: 400)
        .padding()
    }
}