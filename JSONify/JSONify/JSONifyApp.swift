//
//  JSONifyApp.swift
//  JSONify
//
//  Created by 张涛 on 7/14/25.
//

import SwiftUI

@main
struct JSONifyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("清除输入") {
                    NotificationCenter.default.post(name: .clearInput, object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)
            }
            
            CommandGroup(after: .pasteboard) {
                Button("复制格式化结果") {
                    NotificationCenter.default.post(name: .copyFormatted, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                
                Button("粘贴到输入框") {
                    NotificationCenter.default.post(name: .pasteToInput, object: nil)
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .toolbar) {
                Button("切换视图模式") {
                    NotificationCenter.default.post(name: .toggleViewMode, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let clearInput = Notification.Name("clearInput")
    static let copyFormatted = Notification.Name("copyFormatted")
    static let pasteToInput = Notification.Name("pasteToInput")
    static let toggleViewMode = Notification.Name("toggleViewMode")
}
