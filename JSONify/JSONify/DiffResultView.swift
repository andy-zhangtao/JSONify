//
//  DiffResultView.swift
//  JSONify
//
//  Created by 张涛 on 7/19/25.
//

import SwiftUI

struct DiffResultView: View {
    let differences: [DiffItem]
    let isComparing: Bool
    let error: Error?
    
    @State private var selectedDiff: DiffItem?
    @State private var filterType: DiffType?
    
    var filteredDifferences: [DiffItem] {
        if let filterType = filterType {
            return differences.filter { $0.type == filterType }
        }
        return differences
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题栏
            HStack {
                Text("差异结果")
                    .font(.headline)
                
                Spacer()
                
                if !differences.isEmpty {
                    // 统计信息
                    HStack(spacing: 16) {
                        DiffStatBadge(
                            type: .added,
                            count: differences.filter { $0.type == .added }.count,
                            isSelected: filterType == .added,
                            action: { toggleFilter(.added) }
                        )
                        
                        DiffStatBadge(
                            type: .removed,
                            count: differences.filter { $0.type == .removed }.count,
                            isSelected: filterType == .removed,
                            action: { toggleFilter(.removed) }
                        )
                        
                        DiffStatBadge(
                            type: .modified,
                            count: differences.filter { $0.type == .modified }.count,
                            isSelected: filterType == .modified,
                            action: { toggleFilter(.modified) }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider()
            
            // 内容区域
            if isComparing {
                VStack {
                    ProgressView("正在比较...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("请稍候...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("比较失败")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if differences.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "equal.circle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("没有差异")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("两个JSON完全相同")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(filteredDifferences) { diff in
                            DiffItemRow(
                                item: diff,
                                isSelected: selectedDiff?.id == diff.id,
                                onSelect: { selectedDiff = diff }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            VStack {
                Divider()
                    .padding(.top, 47)
                Spacer()
            }
        )
    }
    
    private func toggleFilter(_ type: DiffType) {
        if filterType == type {
            filterType = nil
        } else {
            filterType = type
        }
    }
}

// 差异统计徽章
struct DiffStatBadge: View {
    let type: DiffType
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    private var color: Color {
        switch type {
        case .added:
            return .green
        case .removed:
            return .red
        case .modified:
            return .orange
        case .unchanged:
            return .gray
        }
    }
    
    private var icon: String {
        switch type {
        case .added:
            return "plus.circle.fill"
        case .removed:
            return "minus.circle.fill"
        case .modified:
            return "pencil.circle.fill"
        case .unchanged:
            return "equal.circle.fill"
        }
    }
    
    private var label: String {
        switch type {
        case .added:
            return "新增"
        case .removed:
            return "删除"
        case .modified:
            return "修改"
        case .unchanged:
            return "未变"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(label): \(count)")
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// 差异项行
struct DiffItemRow: View {
    let item: DiffItem
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var icon: String {
        switch item.type {
        case .added:
            return "plus.circle.fill"
        case .removed:
            return "minus.circle.fill"
        case .modified:
            return "pencil.circle.fill"
        case .unchanged:
            return "equal.circle.fill"
        }
    }
    
    private var color: Color {
        switch item.type {
        case .added:
            return .green
        case .removed:
            return .red
        case .modified:
            return .orange
        case .unchanged:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 路径和类型
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(item.path)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
                Spacer()
            }
            
            // 值对比
            if item.type == .modified {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("原值:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(JSONDiffEngine.formatValue(item.leftValue))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.red)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("新值:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(JSONDiffEngine.formatValue(item.rightValue))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Text(JSONDiffEngine.formatValue(item.type == .added ? item.rightValue : item.leftValue))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(color)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? color.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? color : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

#Preview {
    DiffResultView(
        differences: [
            DiffItem(
                path: "$.name",
                type: .modified,
                leftValue: "John",
                rightValue: "Jane",
                description: "名称改变"
            ),
            DiffItem(
                path: "$.age",
                type: .added,
                leftValue: nil,
                rightValue: 30,
                description: "新增年龄"
            ),
            DiffItem(
                path: "$.email",
                type: .removed,
                leftValue: "john@example.com",
                rightValue: nil,
                description: "删除邮箱"
            )
        ],
        isComparing: false,
        error: nil
    )
    .frame(width: 400, height: 600)
}