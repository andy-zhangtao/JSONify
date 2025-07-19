//
//  MainTabView.swift
//  JSONify
//
//  Created by 张涛 on 7/19/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
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
        }
        .frame(minWidth: 1400, minHeight: 800)
    }
}

#Preview {
    MainTabView()
}