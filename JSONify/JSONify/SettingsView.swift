import SwiftUI

struct SettingsView: View {
    @AppStorage("autoFormat") private var autoFormat = true
    @AppStorage("sortKeys") private var sortKeys = true
    @AppStorage("indentSize") private var indentSize = 2
    @AppStorage("fontSize") private var fontSize = 14.0
    @AppStorage("showLineNumbers") private var showLineNumbers = false
    @AppStorage("theme") private var theme = "system"
    
    let themes = ["system", "light", "dark"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("JSONify 设置")
                .font(.title2)
                .fontWeight(.bold)
            
            GroupBox("格式化选项") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("自动格式化", isOn: $autoFormat)
                    
                    Toggle("排序键名", isOn: $sortKeys)
                    
                    HStack {
                        Text("缩进大小：")
                        Picker("缩进大小", selection: $indentSize) {
                            ForEach(1...8, id: \.self) { size in
                                Text("\(size) 空格").tag(size)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                }
                .padding(.vertical, 8)
            }
            
            GroupBox("显示选项") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("字体大小：")
                        Slider(value: $fontSize, in: 10...24, step: 1)
                        Text("\(Int(fontSize))pt")
                            .frame(width: 40)
                    }
                    
                    Toggle("显示行号", isOn: $showLineNumbers)
                    
                    HStack {
                        Text("主题：")
                        Picker("主题", selection: $theme) {
                            Text("跟随系统").tag("system")
                            Text("浅色").tag("light")
                            Text("深色").tag("dark")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            HStack {
                Button("重置为默认") {
                    autoFormat = true
                    sortKeys = true
                    indentSize = 2
                    fontSize = 14.0
                    showLineNumbers = false
                    theme = "system"
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("关闭") {
                    NSApp.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}

#Preview {
    SettingsView()
}