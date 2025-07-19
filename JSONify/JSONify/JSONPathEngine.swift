//
//  JSONPathEngine.swift
//  JSONify
//
//  Created by 张涛 on 7/19/25.
//

import Foundation

// JSONPath查询结果
struct JSONPathResult: Identifiable {
    let id = UUID()
    let path: String
    let value: Any
    let parentPath: String
    let key: String
    
    var formattedValue: String {
        JSONPathEngine.formatValue(value)
    }
}

// JSONPath解析错误
enum JSONPathError: LocalizedError {
    case invalidPath(String)
    case parseError(String)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidPath(let path):
            return "无效的JSONPath: \(path)"
        case .parseError(let message):
            return "解析错误: \(message)"
        case .notFound:
            return "未找到匹配的元素"
        }
    }
}

// JSONPath查询引擎
class JSONPathEngine: ObservableObject {
    @Published var results: [JSONPathResult] = []
    @Published var error: Error?
    @Published var isSearching = false
    
    // 执行JSONPath查询
    func query(_ jsonString: String, path: String) {
        isSearching = true
        error = nil
        results = []
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                // 解析JSON
                guard let data = jsonString.data(using: .utf8) else {
                    throw JSONPathError.parseError("无法将字符串转换为数据")
                }
                
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                // 执行查询
                let queryResults = try self?.performQuery(json, path: path) ?? []
                
                DispatchQueue.main.async {
                    self?.results = queryResults
                    self?.isSearching = false
                }
            } catch {
                DispatchQueue.main.async {
                    self?.error = error
                    self?.isSearching = false
                }
            }
        }
    }
    
    // 执行查询的核心逻辑
    private func performQuery(_ json: Any, path: String) throws -> [JSONPathResult] {
        var results: [JSONPathResult] = []
        
        // 规范化路径
        let normalizedPath = path.trimmingCharacters(in: .whitespaces)
        
        // 解析路径组件
        let components = try parsePath(normalizedPath)
        
        // 执行查询
        queryRecursive(json, components: components, currentPath: "$", results: &results)
        
        if results.isEmpty {
            throw JSONPathError.notFound
        }
        
        return results
    }
    
    // 解析JSONPath路径
    private func parsePath(_ path: String) throws -> [PathComponent] {
        var components: [PathComponent] = []
        var currentIndex = path.startIndex
        
        // 必须以 $ 开头
        guard path.hasPrefix("$") else {
            throw JSONPathError.invalidPath("路径必须以 $ 开头")
        }
        
        currentIndex = path.index(after: currentIndex)
        
        while currentIndex < path.endIndex {
            let char = path[currentIndex]
            
            switch char {
            case ".":
                // 处理点号导航
                currentIndex = path.index(after: currentIndex)
                
                if currentIndex < path.endIndex && path[currentIndex] == "." {
                    // 递归下降 ..
                    components.append(.recursiveDescent)
                    currentIndex = path.index(after: currentIndex)
                } else {
                    // 普通属性访问
                    let (property, nextIndex) = parseProperty(path, from: currentIndex)
                    if !property.isEmpty {
                        components.append(.property(property))
                    }
                    currentIndex = nextIndex
                }
                
            case "[":
                // 处理方括号
                let (component, nextIndex) = try parseBracket(path, from: currentIndex)
                components.append(component)
                currentIndex = nextIndex
                
            case "*":
                // 通配符
                components.append(.wildcard)
                currentIndex = path.index(after: currentIndex)
                
            default:
                throw JSONPathError.invalidPath("意外的字符: \(char)")
            }
        }
        
        return components
    }
    
    // 解析属性名
    private func parseProperty(_ path: String, from index: String.Index) -> (String, String.Index) {
        var currentIndex = index
        var property = ""
        
        while currentIndex < path.endIndex {
            let char = path[currentIndex]
            if char == "." || char == "[" {
                break
            }
            property.append(char)
            currentIndex = path.index(after: currentIndex)
        }
        
        return (property, currentIndex)
    }
    
    // 解析方括号内容
    private func parseBracket(_ path: String, from index: String.Index) throws -> (PathComponent, String.Index) {
        var currentIndex = path.index(after: index) // 跳过 [
        var content = ""
        
        while currentIndex < path.endIndex && path[currentIndex] != "]" {
            content.append(path[currentIndex])
            currentIndex = path.index(after: currentIndex)
        }
        
        guard currentIndex < path.endIndex else {
            throw JSONPathError.invalidPath("未闭合的方括号")
        }
        
        currentIndex = path.index(after: currentIndex) // 跳过 ]
        
        // 解析内容
        let trimmed = content.trimmingCharacters(in: .whitespaces)
        
        if trimmed == "*" {
            return (.wildcard, currentIndex)
        } else if let index = Int(trimmed) {
            return (.index(index), currentIndex)
        } else if trimmed.hasPrefix("'") && trimmed.hasSuffix("'") {
            let property = String(trimmed.dropFirst().dropLast())
            return (.property(property), currentIndex)
        } else if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
            let property = String(trimmed.dropFirst().dropLast())
            return (.property(property), currentIndex)
        } else if trimmed.contains(":") {
            // 切片语法 [start:end]
            let parts = trimmed.split(separator: ":", omittingEmptySubsequences: false)
            let start = parts.count > 0 && !parts[0].isEmpty ? Int(parts[0]) : nil
            let end = parts.count > 1 && !parts[1].isEmpty ? Int(parts[1]) : nil
            return (.slice(start, end), currentIndex)
        } else {
            // 假设是属性名
            return (.property(trimmed), currentIndex)
        }
    }
    
    // 递归查询
    private func queryRecursive(_ value: Any, components: [PathComponent], currentPath: String, results: inout [JSONPathResult]) {
        guard !components.isEmpty else {
            // 到达路径末尾，添加结果
            let pathParts = currentPath.split(separator: ".")
            let parentPath = pathParts.dropLast().joined(separator: ".")
            let key = String(pathParts.last ?? "")
            
            results.append(JSONPathResult(
                path: currentPath,
                value: value,
                parentPath: parentPath.isEmpty ? "$" : parentPath,
                key: key
            ))
            return
        }
        
        var remainingComponents = components
        let component = remainingComponents.removeFirst()
        
        switch component {
        case .property(let name):
            if let dict = value as? [String: Any], let nextValue = dict[name] {
                let nextPath = currentPath == "$" ? "$.\(name)" : "\(currentPath).\(name)"
                queryRecursive(nextValue, components: remainingComponents, currentPath: nextPath, results: &results)
            }
            
        case .index(let index):
            if let array = value as? [Any], index >= 0 && index < array.count {
                let nextPath = "\(currentPath)[\(index)]"
                queryRecursive(array[index], components: remainingComponents, currentPath: nextPath, results: &results)
            }
            
        case .wildcard:
            if let dict = value as? [String: Any] {
                for (key, nextValue) in dict {
                    let nextPath = currentPath == "$" ? "$.\(key)" : "\(currentPath).\(key)"
                    queryRecursive(nextValue, components: remainingComponents, currentPath: nextPath, results: &results)
                }
            } else if let array = value as? [Any] {
                for (index, nextValue) in array.enumerated() {
                    let nextPath = "\(currentPath)[\(index)]"
                    queryRecursive(nextValue, components: remainingComponents, currentPath: nextPath, results: &results)
                }
            }
            
        case .recursiveDescent:
            // 先在当前级别继续查询
            queryRecursive(value, components: remainingComponents, currentPath: currentPath, results: &results)
            
            // 然后递归到所有子级
            if let dict = value as? [String: Any] {
                for (key, nextValue) in dict {
                    let nextPath = currentPath == "$" ? "$.\(key)" : "\(currentPath).\(key)"
                    queryRecursive(nextValue, components: components, currentPath: nextPath, results: &results)
                }
            } else if let array = value as? [Any] {
                for (index, nextValue) in array.enumerated() {
                    let nextPath = "\(currentPath)[\(index)]"
                    queryRecursive(nextValue, components: components, currentPath: nextPath, results: &results)
                }
            }
            
        case .slice(let start, let end):
            if let array = value as? [Any] {
                let startIndex = start ?? 0
                let endIndex = end ?? array.count
                
                for index in startIndex..<min(endIndex, array.count) {
                    if index >= 0 {
                        let nextPath = "\(currentPath)[\(index)]"
                        queryRecursive(array[index], components: remainingComponents, currentPath: nextPath, results: &results)
                    }
                }
            }
        }
    }
    
    // 路径组件类型
    private enum PathComponent {
        case property(String)
        case index(Int)
        case wildcard
        case recursiveDescent
        case slice(Int?, Int?)
    }
    
    // 格式化值用于显示
    static func formatValue(_ value: Any) -> String {
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
        } else if value is NSNull {
            return "null"
        }
        
        return String(describing: value)
    }
    
    // 获取值的详细JSON表示
    static func getDetailedJSON(_ value: Any) -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted])
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

// JSONPath语法示例
struct JSONPathExample {
    let syntax: String
    let description: String
    
    static let examples = [
        JSONPathExample(syntax: "$", description: "根元素"),
        JSONPathExample(syntax: "$.property", description: "访问属性"),
        JSONPathExample(syntax: "$['property']", description: "使用方括号访问属性"),
        JSONPathExample(syntax: "$.array[0]", description: "访问数组第一个元素"),
        JSONPathExample(syntax: "$.array[*]", description: "访问数组所有元素"),
        JSONPathExample(syntax: "$..property", description: "递归搜索所有property"),
        JSONPathExample(syntax: "$.array[0:3]", description: "数组切片（索引0到2）"),
        JSONPathExample(syntax: "$.*", description: "所有直接子元素"),
        JSONPathExample(syntax: "$.users[*].name", description: "所有用户的名字")
    ]
}