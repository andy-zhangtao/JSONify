//
//  MainTabView.swift
//  JSONify
//
//  Created by 张涛 on 7/19/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("格式化", systemImage: "doc.text")
                }
                .tag(0)
            
            JSONCompareView()
                .tabItem {
                    Label("比较", systemImage: "doc.on.doc")
                }
                .tag(1)
            
            JSONPathQueryView()
                .tabItem {
                    Label("查找", systemImage: "magnifyingglass")
                }
                .tag(2)
            
            NewThemeSettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .frame(minWidth: 1400, minHeight: 800)
        .environmentObject(themeManager)
        .environment(\.colorScheme, themeManager.effectiveColorScheme)
        .background(Color(hex: themeManager.currentSyntaxColors.backgroundColor))
        .preferredColorScheme(themeManager.effectiveColorScheme)
        .onChange(of: themeManager.currentTheme) { _ in
            themeManager.applyThemeToApp()
        }
        .onAppear {
            themeManager.applyThemeToApp()
        }
    }
}

#Preview {
    MainTabView()
}