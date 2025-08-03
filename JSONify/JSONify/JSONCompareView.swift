//
//  JSONCompareView.swift
//  JSONify
//
//  Created by 张涛 on 7/19/25.
//

import SwiftUI

struct JSONCompareView: View {
    @StateObject private var leftProcessor = JSONProcessor()
    @StateObject private var rightProcessor = JSONProcessor()
    @StateObject private var diffEngine = JSONDiffEngine()
    @StateObject private var animationManager = AnimationManager.shared
    
    @State private var compareOptions = CompareOptions()
    @State private var showingOptions = false
    @State private var isComparing = false
    @State private var showComparisonResult = false
    @AppStorage("compareFontSize") private var fontSize = 14.0
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 增强的工具栏
            EnhancedCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("JSON 比较工具")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        StatusIndicator(status: currentCompareStatus)
                            .pageTransition(isActive: true)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // 比较选项
                        CompactIconButton(
                            icon: "gear",
                            tooltip: "比较选项",
                            variant: .secondary,
                            action: { 
                                withAnimation(animationManager.spring) {
                                    showingOptions.toggle()
                                }
                            }
                        )
                        .animatedScale(trigger: showingOptions)
                        .popover(isPresented: $showingOptions) {
                            CompareOptionsView(options: $compareOptions)
                                .padding()
                                .frame(width: 320)
                        }
                        
                        // 比较按钮
                        if isComparing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("比较中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            IconButton(
                                icon: "arrow.triangle.2.circlepath",
                                tooltip: "开始比较 JSON",
                                variant: .primary,
                                action: performComparison
                            )
                            .disabled(leftProcessor.inputText.isEmpty || rightProcessor.inputText.isEmpty || isComparing)
                            .animatedScale(trigger: !leftProcessor.inputText.isEmpty && !rightProcessor.inputText.isEmpty)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
            
            // 主要内容区域
            GeometryReader { geometry in
                HStack(spacing: 1) {
                    // 左侧JSON输入
                    EnhancedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("JSON A")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    StatusIndicator(status: leftJSONStatus)
                                        .pageTransition(isActive: true)
                                }
                                
                                Spacer()
                                
                                if leftProcessor.isValid {
                                    InfoBubble(text: "格式正确", type: .success)
                                        .pageTransition(isActive: leftProcessor.isValid)
                                }
                            }
                            
                            EnhancedTextEditor(
                                text: $leftProcessor.inputText,
                                placeholder: "在此输入左侧待比较的 JSON...\n\n支持：\n• 标准 JSON\n• 压缩或格式化的 JSON",
                                isValid: leftProcessor.isValid
                            )
                            .frame(minHeight: 300)
                            .onChange(of: leftProcessor.inputText) { _ in
                                withAnimation(animationManager.quick) {
                                    leftProcessor.processJSON(sortKeys: false)
                                }
                            }
                            
                            if let error = leftProcessor.validationError {
                                InfoBubble(text: error.localizedDescription, type: .error)
                                    .pageTransition(isActive: leftProcessor.validationError != nil)
                            }
                        }
                    }
                    .frame(width: geometry.size.width * 0.35)
                    .animatedScale(trigger: leftProcessor.isValid, scale: 1.01)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 1)
                    
                    // 右侧JSON输入
                    EnhancedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("JSON B")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    StatusIndicator(status: rightJSONStatus)
                                        .pageTransition(isActive: true)
                                }
                                
                                Spacer()
                                
                                if rightProcessor.isValid {
                                    InfoBubble(text: "格式正确", type: .success)
                                        .pageTransition(isActive: rightProcessor.isValid)
                                }
                            }
                            
                            EnhancedTextEditor(
                                text: $rightProcessor.inputText,
                                placeholder: "在此输入右侧待比较的 JSON...\n\n支持：\n• 标准 JSON\n• 压缩或格式化的 JSON",
                                isValid: rightProcessor.isValid
                            )
                            .frame(minHeight: 300)
                            .onChange(of: rightProcessor.inputText) { _ in
                                withAnimation(animationManager.quick) {
                                    rightProcessor.processJSON(sortKeys: false)
                                }
                            }
                            
                            if let error = rightProcessor.validationError {
                                InfoBubble(text: error.localizedDescription, type: .error)
                                    .pageTransition(isActive: rightProcessor.validationError != nil)
                            }
                        }
                    }
                    .frame(width: geometry.size.width * 0.35)
                    .animatedScale(trigger: rightProcessor.isValid, scale: 1.01)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 1)
                    
                    // 差异结果视图
                    EnhancedCard {
                        DiffResultView(
                            differences: diffEngine.differences,
                            isComparing: diffEngine.isComparing,
                            error: diffEngine.error
                        )
                    }
                    .frame(width: geometry.size.width * 0.3)
                    .pageTransition(isActive: showComparisonResult)
                }
                .padding()
            }
        }
    }
    
    private func performComparison() {
        withAnimation(animationManager.spring) {
            isComparing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            diffEngine.setOptions(compareOptions)
            diffEngine.compareJSON(leftProcessor.inputText, rightProcessor.inputText)
            
            withAnimation(animationManager.spring) {
                isComparing = false
                showComparisonResult = true
            }
        }
    }
    
    // MARK: - 辅助属性
    
    private var currentCompareStatus: StatusIndicator.Status {
        if isComparing {
            return .processing
        } else if leftProcessor.isValid && rightProcessor.isValid {
            return .valid
        } else {
            return .idle
        }
    }
    
    private var leftJSONStatus: StatusIndicator.Status {
        if leftProcessor.inputText.isEmpty {
            return .idle
        } else if leftProcessor.isValid {
            return .valid
        } else {
            return .invalid
        }
    }
    
    private var rightJSONStatus: StatusIndicator.Status {
        if rightProcessor.inputText.isEmpty {
            return .idle
        } else if rightProcessor.isValid {
            return .valid
        } else {
            return .invalid
        }
    }
}


// 比较选项视图
struct CompareOptionsView: View {
    @Binding var options: CompareOptions
    @StateObject private var animationManager = AnimationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("比较选项")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("自定义JSON比较行为")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .pageTransition(isActive: true)
            
            VStack(alignment: .leading, spacing: 12) {
                OptionToggle(
                    title: "忽略空格",
                    description: "忽略字符串值的前后空格",
                    isOn: $options.ignoreWhitespace
                )
                
                OptionToggle(
                    title: "忽略数组顺序",
                    description: "不考虑数组元素的顺序",
                    isOn: $options.ignoreArrayOrder
                )
                
                OptionToggle(
                    title: "忽略大小写",
                    description: "字符串比较时忽略大小写",
                    isOn: $options.ignoreCase
                )
                
                OptionToggle(
                    title: "仅比较结构",
                    description: "只比较JSON结构，不比较具体值",
                    isOn: $options.compareOnlyStructure
                )
            }
            .pageTransition(isActive: true)
            
            Divider()
                .opacity(0.5)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("提示")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Text("选择合适的选项可以让比较结果更符合您的需求。处理包含特殊格式或顺序要求的JSON时特别有用。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .pageTransition(isActive: true)
        }
    }
}

// 选项开关组件
struct OptionToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    @StateObject private var animationManager = AnimationManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
                .scaleEffect(0.8)
                .animatedScale(trigger: isOn)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(animationManager.spring) {
                isOn.toggle()
            }
        }
    }
}

#Preview {
    JSONCompareView()
}