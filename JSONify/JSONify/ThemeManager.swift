//
//  ThemeManager.swift
//  JSONify
//
//  Created by 张涛 on 7/20/25.
//

import SwiftUI
import Combine

// 主题类型
enum AppTheme: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light: return "浅色"
        case .dark: return "深色"
        case .auto: return "跟随系统"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .auto: return "circle.lefthalf.filled"
        }
    }
}

// UI密度
enum UIDensity: String, CaseIterable, Identifiable {
    case compact = "compact"
    case regular = "regular"
    case relaxed = "relaxed"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .compact: return "紧凑"
        case .regular: return "标准"
        case .relaxed: return "宽松"
        }
    }
    
    var spacingMultiplier: CGFloat {
        switch self {
        case .compact: return 0.75
        case .regular: return 1.0
        case .relaxed: return 1.25
        }
    }
    
    var fontSizeMultiplier: CGFloat {
        switch self {
        case .compact: return 0.9
        case .regular: return 1.0
        case .relaxed: return 1.1
        }
    }
    
    var paddingMultiplier: CGFloat {
        switch self {
        case .compact: return 0.8
        case .regular: return 1.0
        case .relaxed: return 1.2
        }
    }
}

// 语法高亮颜色方案
struct SyntaxColors: Codable, Equatable {
    var stringColor: String = "#D73A49"
    var numberColor: String = "#005CC5"
    var booleanColor: String = "#6F42C1"
    var nullColor: String = "#6A737D"
    var keyColor: String = "#22863A"
    var bracketColor: String = "#24292E"
    var backgroundColor: String = "#FFFFFF"
    var textColor: String = "#24292E"
    
    static let defaultLight = SyntaxColors()
    
    static let defaultDark = SyntaxColors(
        stringColor: "#F97583",
        numberColor: "#79B8FF",
        booleanColor: "#B392F0",
        nullColor: "#959DA5",
        keyColor: "#85E89D",
        bracketColor: "#E1E4E8",
        backgroundColor: "#0D1117",
        textColor: "#E1E4E8"
    )
}

// 主题管理器
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .auto
    @Published var uiDensity: UIDensity = .regular
    @Published var lightSyntaxColors: SyntaxColors = .defaultLight
    @Published var darkSyntaxColors: SyntaxColors = .defaultDark
    @Published var useCustomColors: Bool = false
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
    }
    
    var currentSyntaxColors: SyntaxColors {
        let isDark = effectiveColorScheme == .dark
        return isDark ? darkSyntaxColors : lightSyntaxColors
    }
    
    var effectiveColorScheme: ColorScheme {
        switch currentTheme {
        case .light: return .light
        case .dark: return .dark
        case .auto: return NSApp.effectiveAppearance.name == .darkAqua ? .dark : .light
        }
    }
    
    func resetToDefaults() {
        lightSyntaxColors = .defaultLight
        darkSyntaxColors = .defaultDark
        useCustomColors = false
        saveSettings()
    }
    
    func applyThemeToApp() {
        DispatchQueue.main.async {
            switch self.currentTheme {
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            case .auto:
                NSApp.appearance = nil
            }
        }
    }
    
    private func saveSettings() {
        userDefaults.set(currentTheme.rawValue, forKey: "appTheme")
        userDefaults.set(uiDensity.rawValue, forKey: "uiDensity")
        userDefaults.set(useCustomColors, forKey: "useCustomColors")
        
        if let lightData = try? JSONEncoder().encode(lightSyntaxColors) {
            userDefaults.set(lightData, forKey: "lightSyntaxColors")
        }
        if let darkData = try? JSONEncoder().encode(darkSyntaxColors) {
            userDefaults.set(darkData, forKey: "darkSyntaxColors")
        }
    }
    
    private func loadSettings() {
        if let themeString = userDefaults.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: themeString) {
            currentTheme = theme
        }
        
        if let densityString = userDefaults.string(forKey: "uiDensity"),
           let density = UIDensity(rawValue: densityString) {
            uiDensity = density
        }
        
        useCustomColors = userDefaults.bool(forKey: "useCustomColors")
        
        if let lightData = userDefaults.data(forKey: "lightSyntaxColors"),
           let colors = try? JSONDecoder().decode(SyntaxColors.self, from: lightData) {
            lightSyntaxColors = colors
        }
        
        if let darkData = userDefaults.data(forKey: "darkSyntaxColors"),
           let colors = try? JSONDecoder().decode(SyntaxColors.self, from: darkData) {
            darkSyntaxColors = colors
        }
    }
}

