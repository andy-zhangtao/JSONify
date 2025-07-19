//
//  JSONDiffEngine.swift
//  JSONify
//
//  Created by 张涛 on 7/19/25.
//

import Foundation

// 差异类型
enum DiffType {
    case added      // 新增
    case removed    // 删除
    case modified   // 修改
    case unchanged  // 未改变
}

// 差异项
struct DiffItem: Identifiable {
    let id = UUID()
    let path: String
    let type: DiffType
    let leftValue: Any?
    let rightValue: Any?
    let description: String
}

// 比较选项
struct CompareOptions {
    var ignoreWhitespace: Bool = true
    var ignoreArrayOrder: Bool = false
    var ignoreCase: Bool = false
    var compareOnlyStructure: Bool = false
}

class JSONDiffEngine: ObservableObject {
    @Published var differences: [DiffItem] = []
    @Published var isComparing = false
    @Published var error: Error?
    
    private var options = CompareOptions()
    
    func setOptions(_ options: CompareOptions) {
        self.options = options
    }
    
    func compareJSON(_ leftString: String, _ rightString: String) {
        isComparing = true
        differences = []
        error = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let leftData = leftString.data(using: .utf8) ?? Data()
                let rightData = rightString.data(using: .utf8) ?? Data()
                
                let leftJSON = try JSONSerialization.jsonObject(with: leftData, options: [])
                let rightJSON = try JSONSerialization.jsonObject(with: rightData, options: [])
                
                let diffs = self?.compareValues(leftJSON, rightJSON, path: "$") ?? []
                
                DispatchQueue.main.async {
                    self?.differences = diffs
                    self?.isComparing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self?.error = error
                    self?.isComparing = false
                }
            }
        }
    }
    
    private func compareValues(_ left: Any?, _ right: Any?, path: String) -> [DiffItem] {
        var diffs: [DiffItem] = []
        
        // 处理nil情况
        if left == nil && right == nil {
            return []
        }
        
        if left == nil {
            diffs.append(DiffItem(
                path: path,
                type: .added,
                leftValue: nil,
                rightValue: right,
                description: "新增: \(path)"
            ))
            return diffs
        }
        
        if right == nil {
            diffs.append(DiffItem(
                path: path,
                type: .removed,
                leftValue: left,
                rightValue: nil,
                description: "删除: \(path)"
            ))
            return diffs
        }
        
        // 比较不同类型的值
        if type(of: left!) != type(of: right!) {
            diffs.append(DiffItem(
                path: path,
                type: .modified,
                leftValue: left,
                rightValue: right,
                description: "类型改变: \(path)"
            ))
            return diffs
        }
        
        // 比较字典
        if let leftDict = left as? [String: Any],
           let rightDict = right as? [String: Any] {
            diffs.append(contentsOf: compareDictionaries(leftDict, rightDict, path: path))
        }
        // 比较数组
        else if let leftArray = left as? [Any],
                let rightArray = right as? [Any] {
            diffs.append(contentsOf: compareArrays(leftArray, rightArray, path: path))
        }
        // 比较基本类型
        else if !areEqual(left, right) {
            diffs.append(DiffItem(
                path: path,
                type: .modified,
                leftValue: left,
                rightValue: right,
                description: "值改变: \(path)"
            ))
        }
        
        return diffs
    }
    
    private func compareDictionaries(_ left: [String: Any], _ right: [String: Any], path: String) -> [DiffItem] {
        var diffs: [DiffItem] = []
        let allKeys = Set(left.keys).union(Set(right.keys))
        
        for key in allKeys.sorted() {
            let keyPath = "\(path).\(key)"
            let leftValue = left[key]
            let rightValue = right[key]
            
            diffs.append(contentsOf: compareValues(leftValue, rightValue, path: keyPath))
        }
        
        return diffs
    }
    
    private func compareArrays(_ left: [Any], _ right: [Any], path: String) -> [DiffItem] {
        var diffs: [DiffItem] = []
        
        if options.ignoreArrayOrder {
            // 忽略顺序的比较逻辑（较复杂，这里简化处理）
            if left.count != right.count {
                diffs.append(DiffItem(
                    path: path,
                    type: .modified,
                    leftValue: left,
                    rightValue: right,
                    description: "数组长度不同: \(path) (\(left.count) vs \(right.count))"
                ))
            }
        } else {
            // 按顺序比较
            let maxCount = max(left.count, right.count)
            for i in 0..<maxCount {
                let indexPath = "\(path)[\(i)]"
                let leftValue = i < left.count ? left[i] : nil
                let rightValue = i < right.count ? right[i] : nil
                
                diffs.append(contentsOf: compareValues(leftValue, rightValue, path: indexPath))
            }
        }
        
        return diffs
    }
    
    private func areEqual(_ left: Any, _ right: Any) -> Bool {
        if options.compareOnlyStructure {
            return true // 只比较结构时，值总是相等的
        }
        
        // 字符串比较
        if let leftStr = left as? String, let rightStr = right as? String {
            if options.ignoreCase {
                return leftStr.lowercased() == rightStr.lowercased()
            }
            if options.ignoreWhitespace {
                return leftStr.trimmingCharacters(in: .whitespacesAndNewlines) ==
                       rightStr.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return leftStr == rightStr
        }
        
        // 数字比较
        if let leftNum = left as? NSNumber, let rightNum = right as? NSNumber {
            return leftNum == rightNum
        }
        
        // 布尔比较
        if let leftBool = left as? Bool, let rightBool = right as? Bool {
            return leftBool == rightBool
        }
        
        return false
    }
}

// 格式化值为字符串用于显示
extension JSONDiffEngine {
    static func formatValue(_ value: Any?) -> String {
        guard let value = value else { return "null" }
        
        if let string = value as? String {
            return "\"\(string)\""
        } else if let number = value as? NSNumber {
            return "\(number)"
        } else if let bool = value as? Bool {
            return "\(bool)"
        } else if let array = value as? [Any] {
            return "Array[\(array.count)]"
        } else if let dict = value as? [String: Any] {
            return "Object{\(dict.count)}"
        }
        
        return String(describing: value)
    }
}