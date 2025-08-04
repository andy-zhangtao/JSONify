//
//  NewThemeSettingsView.swift
//  JSONify
//
//  Created by 张涛 on 7/20/25.
//

import SwiftUI

struct NewThemeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var openRouterManager = OpenRouterManager()
    @State private var showingColorCustomization = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 标题
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.accentColor)
                    Text("应用设置")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                // 主题选择
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("主题模式", systemImage: "circle.lefthalf.filled")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            ForEach(AppTheme.allCases) { theme in
                                ThemeButton(
                                    theme: theme,
                                    isSelected: themeManager.currentTheme == theme,
                                    action: {
                                        themeManager.currentTheme = theme
                                        themeManager.applyThemeToApp()
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                }
                
                // UI密度设置
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("界面密度", systemImage: "square.resize")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            ForEach(UIDensity.allCases) { density in
                                NewDensityButton(
                                    density: density,
                                    isSelected: themeManager.uiDensity == density,
                                    action: {
                                        themeManager.uiDensity = density
                                    }
                                )
                            }
                        }
                        
                        // 密度说明
                        VStack(alignment: .leading, spacing: 4) {
                            Text("当前设置：")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• 间距倍数: \(String(format: "%.1f", themeManager.uiDensity.spacingMultiplier))x")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• 字体倍数: \(String(format: "%.1f", themeManager.uiDensity.fontSizeMultiplier))x")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• 内边距倍数: \(String(format: "%.1f", themeManager.uiDensity.paddingMultiplier))x")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                
                // 语法高亮设置
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("语法高亮", systemImage: "highlighter")
                                .font(.headline)
                            
                            Spacer()
                            
                            Toggle("自定义颜色", isOn: $themeManager.useCustomColors)
                        }
                        
                        if themeManager.useCustomColors {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("浅色主题颜色")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                SyntaxColorGrid(
                                    colors: $themeManager.lightSyntaxColors,
                                    title: "浅色主题"
                                )
                                
                                Text("深色主题颜色")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.top)
                                
                                SyntaxColorGrid(
                                    colors: $themeManager.darkSyntaxColors,
                                    title: "深色主题"
                                )
                                
                                HStack {
                                    Button("重置为默认") {
                                        themeManager.resetToDefaults()
                                    }
                                    .buttonStyle(.borderless)
                                    
                                    Spacer()
                                }
                                .padding(.top)
                            }
                        }
                    }
                    .padding()
                }
                
                // OpenRouter AI 修复设置
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("AI JSON 修复", systemImage: "brain.head.profile")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("使用 OpenRouter API 自动修复损坏的 JSON")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Toggle("启用 AI 修复", isOn: $openRouterManager.isEnabled)
                                .toggleStyle(SwitchToggleStyle())
                            
                            if openRouterManager.isEnabled {
                                Divider()
                                OpenRouterConfigSection(manager: openRouterManager)
                            }
                        }
                    }
                    .padding()
                }
                
                // 预览
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("预览", systemImage: "eye")
                            .font(.headline)
                        
                        Text(sampleJSON)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .frame(height: 200)
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
    
    
    private let sampleJSON = """
{
  "name": "示例数据",
  "version": 1.0,
  "enabled": true,
  "config": null,
  "items": [
    "第一项",
    "第二项"
  ]
}
"""
}

// 主题按钮
struct ThemeButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: theme.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(theme.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// 密度按钮
struct NewDensityButton: View {
    let density: UIDensity
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // 密度可视化
                VStack(spacing: density == .compact ? 2 : density == .regular ? 4 : 6) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(isSelected ? Color.white : Color.primary)
                            .frame(height: 2)
                    }
                }
                .frame(width: 30, height: 20)
                
                Text(density.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// 语法颜色网格
struct SyntaxColorGrid: View {
    @Binding var colors: SyntaxColors
    let title: String
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
            ColorPicker("字符串", selection: Binding(
                get: { Color(hex: colors.stringColor) ?? .red },
                set: { colors.stringColor = $0.toHex() }
            ))
            .labelsHidden()
            
            ColorPicker("数字", selection: Binding(
                get: { Color(hex: colors.numberColor) ?? .blue },
                set: { colors.numberColor = $0.toHex() }
            ))
            .labelsHidden()
            
            ColorPicker("布尔值", selection: Binding(
                get: { Color(hex: colors.booleanColor) ?? .purple },
                set: { colors.booleanColor = $0.toHex() }
            ))
            .labelsHidden()
            
            ColorPicker("空值", selection: Binding(
                get: { Color(hex: colors.nullColor) ?? .gray },
                set: { colors.nullColor = $0.toHex() }
            ))
            .labelsHidden()
            
            ColorPicker("键名", selection: Binding(
                get: { Color(hex: colors.keyColor) ?? .green },
                set: { colors.keyColor = $0.toHex() }
            ))
            .labelsHidden()
            
            ColorPicker("括号", selection: Binding(
                get: { Color(hex: colors.bracketColor) ?? .primary },
                set: { colors.bracketColor = $0.toHex() }
            ))
            .labelsHidden()
        }
    }
}

// 颜色扩展
extension Color {
    init?(hex: String) {
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
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let uiColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}


// OpenRouter 配置组件
struct OpenRouterConfigSection: View {
    @ObservedObject var manager: OpenRouterManager
    @State private var showingAPIKey = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // API Key 配置
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    if showingAPIKey {
                        SecureField("输入 OpenRouter API Key", text: $manager.apiKey)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: manager.apiKey) { _, _ in
                                manager.clearValidation()
                            }
                    } else {
                        HStack {
                            Text(manager.apiKey.isEmpty ? "未设置" : "••••••••")
                                .foregroundColor(manager.apiKey.isEmpty ? .secondary : .primary)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    Button(showingAPIKey ? "隐藏" : "编辑") {
                        showingAPIKey.toggle()
                    }
                    .buttonStyle(.bordered)
                }
                
                if manager.apiKey.isEmpty {
                    Text("请在 OpenRouter.ai 获取 API Key")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // 模型输入
            VStack(alignment: .leading, spacing: 8) {
                Text("AI 模型")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("输入模型名称", text: $manager.modelName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: manager.modelName) { _, _ in
                        manager.clearValidation()
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("推荐模型示例：")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• anthropic/claude-3.5-sonnet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                    
                    Text("• openai/gpt-4o")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                    
                    Text("• meta-llama/llama-3.1-8b-instruct")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                    
                    Text("更多模型请查看 OpenRouter.ai")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // 验证按钮和状态
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button(action: {
                        Task {
                            await manager.validateConfiguration()
                        }
                    }) {
                        HStack {
                            if manager.isPinging {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "network")
                            }
                            Text(manager.isPinging ? "验证中..." : "验证配置")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!manager.canValidate || manager.isPinging)
                    
                    Spacer()
                }
                
                // 验证状态显示
                if !manager.validationMessage.isEmpty {
                    HStack {
                        Image(systemName: manager.isValidated ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(manager.isValidated ? .green : .red)
                        
                        Text(manager.validationMessage)
                            .font(.caption)
                            .foregroundColor(manager.isValidated ? .green : .red)
                        
                        Spacer()
                    }
                } else if manager.canValidate && !manager.isValidated {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        
                        Text("点击验证按钮检查配置是否正确")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                }
            }
        }
        .onChange(of: manager.apiKey) { _, _ in
            manager.saveSettings()
        }
        .onChange(of: manager.modelName) { _, _ in
            manager.saveSettings()
        }
        .onChange(of: manager.isEnabled) { _, _ in
            manager.saveSettings()
        }
    }
}

#Preview {
    NewThemeSettingsView()
        .environmentObject(ThemeManager())
        .frame(width: 600, height: 800)
}