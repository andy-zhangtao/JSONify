//
//  JSONifyTests.swift
//  JSONifyTests
//
//  Created by 张涛 on 7/14/25.
//

import Testing
@testable import JSONify

struct JSONifyTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

struct JSONProcessorUnescapeTests {
    
    @Test func testBasicUnescape() async throws {
        let processor = JSONProcessor()
        
        // 测试基本转义
        processor.inputText = "\"Hello\\nWorld\""
        processor.unescapeJSONString()
        
        #expect(processor.inputText == "Hello\nWorld")
    }
    
    @Test func testComplexJSONStringUnescape() async throws {
        let processor = JSONProcessor()
        
        // 用户提供的复杂测试用例
        let input = "{\\\"name\\\":\\\"张三\\\",\\\"message\\\":\\\"Hello\\\\nWorld!\\\",\\\"path\\\":\\\"C:\\\\\\\\Users\\\\\\\\Documents\\\",\\\"description\\\":\\\"这是一个\\\\\\\"示例\\\\\\\"字符串\\\\t包含特殊字符\\\",\\\"data\\\":{\\\"value\\\":123,\\\"active\\\":true,\\\"items\\\":[\\\"item1\\\",\\\"item2\\\"]},\\\"newline\\\":\\\"第一行\\\\n第二行\\\\r\\\\n第三行\\\"}"
        
        processor.inputText = "\"\(input)\""
        processor.unescapeJSONString()
        
        // 验证反转义后是合法的JSON
        let resultData = processor.inputText.data(using: .utf8)!
        let jsonObject = try JSONSerialization.jsonObject(with: resultData)
        
        // 验证可以重新序列化
        let reSerializedData = try JSONSerialization.data(withJSONObject: jsonObject)
        let reSerializedString = String(data: reSerializedData, encoding: .utf8)!
        
        #expect(reSerializedString.contains("张三"))
        #expect(reSerializedString.contains("Hello\\nWorld!"))
    }
    
    @Test func testStandardEscapeSequences() async throws {
        let processor = JSONProcessor()
        
        // 测试所有标准转义序列
        processor.inputText = "\"Quote: \\\" Backslash: \\\\\\\\ Tab: \\\\t Newline: \\\\n Return: \\\\r\""
        processor.unescapeJSONString()
        
        let expected = "Quote: \" Backslash: \\\\ Tab: \\t Newline: \\n Return: \\r"
        #expect(processor.inputText == expected)
    }
    
    @Test func testUnicodeEscape() async throws {
        let processor = JSONProcessor()
        
        processor.inputText = "\"\\\\u4E2D\\\\u6587\""  // 中文
        processor.unescapeJSONString()
        
        #expect(processor.inputText == "中文")
    }
    
    @Test func testNoOuterQuotes() async throws {
        let processor = JSONProcessor()
        
        // 测试没有外层引号的情况
        processor.inputText = "Hello\\\\nWorld"
        processor.unescapeJSONString()
        
        #expect(processor.inputText == "Hello\\nWorld")
    }
}
