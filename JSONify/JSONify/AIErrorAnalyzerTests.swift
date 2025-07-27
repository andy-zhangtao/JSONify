//
//  AIErrorAnalyzerTests.swift
//  JSONify
//
//  Created by Claude on 7/27/25.
//

import Foundation

/// AI错误分析器测试用例
struct AIErrorAnalyzerTestCases {
    
    /// 测试用例集合
    static let testCases: [TestCase] = [
        // 1. 大括号不匹配
        TestCase(
            name: "大括号不匹配",
            input: """
            {
                "name": "张三",
                "age": 30,
                "city": "北京"
            """,
            expectedErrors: ["大括号不匹配", "缺少闭合大括号"]
        ),
        
        // 2. 引号问题
        TestCase(
            name: "单引号问题",
            input: """
            {
                'name': '张三',
                'age': 30
            }
            """,
            expectedErrors: ["单引号", "双引号"]
        ),
        
        // 3. 多余逗号
        TestCase(
            name: "多余逗号",
            input: """
            {
                "name": "张三",
                "age": 30,
            }
            """,
            expectedErrors: ["多余逗号", "trailing comma"]
        ),
        
        // 4. 重复键名
        TestCase(
            name: "重复键名",
            input: """
            {
                "name": "张三",
                "age": 30,
                "name": "李四"
            }
            """,
            expectedErrors: ["重复键名", "duplicate key"]
        ),
        
        // 5. 布尔值大写
        TestCase(
            name: "布尔值大写",
            input: """
            {
                "name": "张三",
                "isActive": True,
                "isAdmin": FALSE
            }
            """,
            expectedErrors: ["布尔值", "小写", "true", "false"]
        ),
        
        // 6. 空值错误
        TestCase(
            name: "空值错误",
            input: """
            {
                "name": "张三",
                "address": nil,
                "phone": NULL
            }
            """,
            expectedErrors: ["null", "nil", "NULL"]
        ),
        
        // 7. 未引用的字符串
        TestCase(
            name: "未引用的字符串",
            input: """
            {
                name: "张三",
                "age": 30
            }
            """,
            expectedErrors: ["键名", "引号", "name"]
        ),
        
        // 8. 复杂嵌套错误
        TestCase(
            name: "复杂嵌套错误",
            input: """
            {
                "users": [
                    {
                        "name": "张三",
                        "details": {
                            "age": 30,
                            "hobbies": ["读书", "游泳",]
                        }
                    }
                ]
            }
            """,
            expectedErrors: ["多余逗号", "数组", "trailing comma"]
        ),
        
        // 9. 数字格式错误
        TestCase(
            name: "数字格式错误",
            input: """
            {
                "name": "张三",
                "age": 030,
                "salary": 5000.
            }
            """,
            expectedErrors: ["数字格式", "leading zero", "decimal"]
        ),
        
        // 10. 特殊字符问题
        TestCase(
            name: "特殊字符问题",
            input: """
            {
                "name": "张三",
                "comment": "这是一段"注释"内容"
            }
            """,
            expectedErrors: ["转义", "引号", "特殊字符"]
        )
    ]
    
    /// 单个测试用例
    struct TestCase {
        let name: String
        let input: String
        let expectedErrors: [String]
        
        /// 验证AI分析结果是否包含期望的错误提示
        func validate(aiSuggestion: String?) -> Bool {
            guard let suggestion = aiSuggestion?.lowercased() else {
                return false
            }
            
            // 检查是否至少包含一个期望的错误提示
            return expectedErrors.contains { keyword in
                suggestion.contains(keyword.lowercased())
            }
        }
    }
    
    /// 运行所有测试用例
    @available(macOS 15.0, *)
    static func runAllTests() async -> TestResult {
        let analyzer = AIErrorAnalyzer()
        var passedTests = 0
        var failedTests: [String] = []
        
        print("🧪 开始AI错误分析器测试...")
        
        for testCase in testCases {
            print("📝 测试: \(testCase.name)")
            
            // 创建JSON错误
            let error = JSONValidationError.invalidJSON(
                message: "测试错误",
                line: nil,
                column: nil
            )
            
            // 执行AI分析
            let suggestion = await analyzer.performAnalysis(
                jsonInput: testCase.input,
                error: error
            )
            
            // 验证结果
            if testCase.validate(aiSuggestion: suggestion) {
                print("✅ 通过")
                passedTests += 1
            } else {
                print("❌ 失败")
                print("   期望包含: \(testCase.expectedErrors)")
                print("   实际结果: \(suggestion ?? "nil")")
                failedTests.append(testCase.name)
            }
            
            print("")
        }
        
        let totalTests = testCases.count
        let successRate = Double(passedTests) / Double(totalTests) * 100
        
        print("📊 测试完成!")
        print("总测试数: \(totalTests)")
        print("通过: \(passedTests)")
        print("失败: \(failedTests.count)")
        print("成功率: \(String(format: "%.1f", successRate))%")
        
        if !failedTests.isEmpty {
            print("失败的测试: \(failedTests.joined(separator: ", "))")
        }
        
        return TestResult(
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            successRate: successRate
        )
    }
    
    /// 测试结果
    struct TestResult {
        let totalTests: Int
        let passedTests: Int
        let failedTests: [String]
        let successRate: Double
        
        var isPassing: Bool {
            return successRate >= 80.0 // 80%以上通过率视为合格
        }
    }
}

// MARK: - AI分析器测试扩展
@available(macOS 15.0, *)
extension AIErrorAnalyzer {
    /// 测试专用的分析方法
    func performAnalysis(jsonInput: String, error: JSONValidationError) async -> String? {
        return await withCheckedContinuation { continuation in
            analyzeJSONError(jsonInput: jsonInput, error: error) { suggestion in
                continuation.resume(returning: suggestion)
            }
        }
    }
}