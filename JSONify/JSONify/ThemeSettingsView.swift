//
//  ThemeSettingsView.swift
//  JSONify
//
//  Created by 张涛 on 7/20/25.
//

import SwiftUI

struct ThemeSettingsView: View {
    @ObservedObject var themeManager: ThemeManager
    @State private var showingColorPicker = false
    @State private var selectedColorType: ColorType = .stringColor
    @State private var tempColor: Color = .red
    
    enum ColorType: String, CaseIterable {
        case stringColor = "字符串颜色"
        case numberColor = "数字颜色"
        case booleanColor = "布尔值颜色"
        case nullColor = "Null颜色"
        case keyColor = "键名颜色"
        case bracketColor = "括号颜色"
        case backgroundColor = "背景颜色"
        case textColor = "文本颜色"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 应用主题
                VStack(alignment: .leading, spacing: 12) {
                    Text("应用主题")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach(AppTheme.allCases) { theme in
                            ThemeOptionButton(
                                theme: theme,
                                isSelected: themeManager.currentTheme == theme,
                                action: {
                                    themeManager.currentTheme = theme
                                }
                            )
                        }
                    }
                }
                
                Divider()
                
                // UI密度
                VStack(alignment: .leading, spacing: 12) {
                    Text("界面密度")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach(UIDensity.allCases) { density in
                            DensityOptionButton(
                                density: density,
                                isSelected: themeManager.uiDensity == density,
                                action: {
                                    themeManager.uiDensity = density
                                }
                            )
                        }
                    }
                    
                    Text("调整界面元素的间距和大小")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // 语法高亮颜色
                VStack(alignment: .leading, spacing: 12) {
                    Text("语法高亮颜色")
                        .font(.headline)
                    
                    // 颜色预设
                    VStack(alignment: .leading, spacing: 8) {
                        Text("预设方案")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 8) {
                            ColorPresetButton(
                                name: "默认",
                                isSelected: !themeManager.useCustomColors,
                                action: {
                                    themeManager.useCustomColors = false
                                    themeManager.lightSyntaxColors = .defaultLight
                                    themeManager.darkSyntaxColors = .defaultDark
                                }
                            )
                            
                            ColorPresetButton(
                                name: "GitHub",
                                isSelected: false,
                                action: {
                                    themeManager.useCustomColors = false
                                    // 这里可以添加GitHub主题
                                }
                            )
                            
                            ColorPresetButton(
                                name: "VS Code",
                                isSelected: false,
                                action: {
                                    themeManager.useCustomColors = false
                                    // 这里可以添加VS Code主题
                                }
                            )
                        }
                    }
                    
                    // 自定义颜色
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("自定义颜色")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Toggle("", isOn: $themeManager.useCustomColors)
                                .toggleStyle(SwitchToggleStyle())
                        }
                        
                        if themeManager.useCustomColors {
                            ColorCustomizationGrid(
                                themeManager: themeManager,
                                showingColorPicker: $showingColorPicker,
                                selectedColorType: $selectedColorType,
                                tempColor: $tempColor
                            )
                        }
                    }
                    
                    // 预览区域
                    SyntaxPreviewView(themeManager: themeManager)
                }
                
                Divider()
                
                // 重置按钮
                HStack {
                    Spacer()
                    Button("重置为默认") {
                        themeManager.resetToDefaults()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(
                colorType: selectedColorType,
                currentColor: tempColor,
                themeManager: themeManager
            )
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

// 主题选项按钮
struct ThemeOptionButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: theme.icon)
                Text(theme.displayName)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// 密度选项按钮
struct DensityOptionButton: View {
    let density: UIDensity
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(density.displayName)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
                .foregroundColor(isSelected ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// 颜色预设按钮
struct ColorPresetButton: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// 颜色自定义网格
struct ColorCustomizationGrid: View {
    @ObservedObject var themeManager: ThemeManager
    @Binding var showingColorPicker: Bool
    @Binding var selectedColorType: ThemeSettingsView.ColorType
    @Binding var tempColor: Color
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
            ForEach(ThemeSettingsView.ColorType.allCases, id: \.rawValue) { colorType in
                ColorItemView(
                    colorType: colorType,
                    color: getColor(for: colorType),
                    action: {
                        selectedColorType = colorType
                        tempColor = getColor(for: colorType)
                        showingColorPicker = true
                    }
                )
            }
        }
    }
    
    private func getColor(for type: ThemeSettingsView.ColorType) -> Color {
        let colors = themeManager.effectiveColorScheme == .dark 
            ? themeManager.darkSyntaxColors 
            : themeManager.lightSyntaxColors
        
        switch type {
        case .stringColor: return Color(hex: colors.stringColor) ?? .red
        case .numberColor: return Color(hex: colors.numberColor) ?? .blue
        case .booleanColor: return Color(hex: colors.booleanColor) ?? .purple
        case .nullColor: return Color(hex: colors.nullColor) ?? .gray
        case .keyColor: return Color(hex: colors.keyColor) ?? .green
        case .bracketColor: return Color(hex: colors.bracketColor) ?? .black
        case .backgroundColor: return Color(hex: colors.backgroundColor) ?? .white
        case .textColor: return Color(hex: colors.textColor) ?? .black
        }
    }
}

// 颜色项视图
struct ColorItemView: View {
    let colorType: ThemeSettingsView.ColorType
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 20, height: 20)
                
                Text(colorType.rawValue)
                    .font(.caption)
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// 语法预览视图
struct SyntaxPreviewView: View {
    @ObservedObject var themeManager: ThemeManager
    
    private let sampleJSON = """
{
  "name": "JSONify",
  "version": 1.0,
  "active": true,
  "description": null,
  "features": [
    "格式化",
    "比较"
  ]
}
"""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("预览")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ScrollView {
                Text(sampleJSON)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(hex: themeManager.currentSyntaxColors.textColor))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 120)
            .background(Color(hex: themeManager.currentSyntaxColors.backgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// 颜色选择器弹窗
struct ColorPickerSheet: View {
    let colorType: ThemeSettingsView.ColorType
    @State var currentColor: Color
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("选择\(colorType.rawValue)")
                .font(.headline)
            
            ColorPicker("颜色", selection: $currentColor)
                .labelsHidden()
            
            HStack {
                Button("取消") {
                    dismiss()
                }
                
                Spacer()
                
                Button("确定") {
                    setColor(currentColor)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300, height: 200)
    }
    
    private func setColor(_ color: Color) {
        let hexColor = color.toHex()
        let isDark = themeManager.effectiveColorScheme == .dark
        
        if isDark {
            var colors = themeManager.darkSyntaxColors
            updateColors(&colors, colorType: colorType, hex: hexColor)
            themeManager.darkSyntaxColors = colors
        } else {
            var colors = themeManager.lightSyntaxColors
            updateColors(&colors, colorType: colorType, hex: hexColor)
            themeManager.lightSyntaxColors = colors
        }
    }
    
    private func updateColors(_ colors: inout SyntaxColors, colorType: ThemeSettingsView.ColorType, hex: String) {
        switch colorType {
        case .stringColor: colors.stringColor = hex
        case .numberColor: colors.numberColor = hex
        case .booleanColor: colors.booleanColor = hex
        case .nullColor: colors.nullColor = hex
        case .keyColor: colors.keyColor = hex
        case .bracketColor: colors.bracketColor = hex
        case .backgroundColor: colors.backgroundColor = hex
        case .textColor: colors.textColor = hex
        }
    }
}


#Preview {
    ThemeSettingsView(themeManager: ThemeManager())
}