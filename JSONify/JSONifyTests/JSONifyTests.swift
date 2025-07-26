//
//  JSONifyTests.swift
//  JSONifyTests
//
//  Created by 张涛 on 7/14/25.
//

import Foundation
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

struct JSONProcessorEncodingConversionTests {
    
    @Test func testUnicodeToChineseBasic() async throws {
        let processor = JSONProcessor()
        
        // 测试基本Unicode转换
        processor.inputText = "\\u4e2d\\u6587"  // 中文
        processor.convertUnicodeToChineseCharactersSync()
        
        #expect(processor.inputText == "中文")
    }
    
    @Test func testUnicodeToChineseInJSON() async throws {
        let processor = JSONProcessor()
        
        // 测试在JSON中的Unicode转换
        processor.inputText = "{\"name\": \"\\u5f20\\u4e09\", \"city\": \"\\u5317\\u4eac\"}"  // 张三, 北京
        processor.convertUnicodeToChineseCharactersSync()
        
        #expect(processor.inputText.contains("张三"))
        #expect(processor.inputText.contains("北京"))
    }
    
    @Test func testUnicodeMixedWithRegularText() async throws {
        let processor = JSONProcessor()
        
        processor.inputText = "Hello \\u4e16\\u754c! Welcome to \\u4e2d\\u56fd"  // 世界, 中国
        processor.convertUnicodeToChineseCharactersSync()
        
        #expect(processor.inputText == "Hello 世界! Welcome to 中国")
    }
    
    @Test func testHTMLEntitiesBasic() async throws {
        let processor = JSONProcessor()
        
        processor.inputText = "&lt;div&gt;Hello &amp; World&lt;/div&gt;"
        processor.convertHTMLToChineseCharactersSync()
        
        #expect(processor.inputText == "<div>Hello & World</div>")
    }
    
    @Test func testHTMLNumericEntities() async throws {
        let processor = JSONProcessor()
        
        // 测试数字实体
        processor.inputText = "&#20013;&#25991; - &#72;&#101;&#108;&#108;&#111;"  // 中文 - Hello
        processor.convertHTMLToChineseCharactersSync()
        
        #expect(processor.inputText == "中文 - Hello")
    }
    
    @Test func testHTMLHexEntities() async throws {
        let processor = JSONProcessor()
        
        // 测试十六进制实体
        processor.inputText = "&#x4E2D;&#x6587;"  // 中文
        processor.convertHTMLToChineseCharactersSync()
        
        #expect(processor.inputText == "中文")
    }
    
    @Test func testHTMLMixedEntities() async throws {
        let processor = JSONProcessor()
        
        processor.inputText = "&quot;Hello&quot; &amp; &#20013;&#25991; &lt;test&gt;"
        processor.convertHTMLToChineseCharactersSync()
        
        #expect(processor.inputText == "\"Hello\" & 中文 <test>")
    }
    
    @Test func testURLDecodingBasic() async throws {
        let processor = JSONProcessor()
        
        processor.inputText = "Hello%20World%21"  // Hello World!
        processor.convertURLEncodingSync()
        
        #expect(processor.inputText == "Hello World!")
    }
    
    @Test func testURLDecodingChinese() async throws {
        let processor = JSONProcessor()
        
        // URL编码的中文
        processor.inputText = "%E4%B8%AD%E6%96%87%E6%B5%8B%E8%AF%95"  // 中文测试
        processor.convertURLEncodingSync()
        
        #expect(processor.inputText == "中文测试")
    }
    
    @Test func testURLDecodingJSON() async throws {
        let processor = JSONProcessor()
        
        processor.inputText = "{%22name%22%3A%22%E5%BC%A0%E4%B8%89%22%2C%22age%22%3A25}"
        processor.convertURLEncodingSync()
        
        #expect(processor.inputText.contains("张三"))
        #expect(processor.inputText.contains("\"name\""))
        #expect(processor.inputText.contains("\"age\""))
    }
    
    @Test func testComplexMixedEncoding() async throws {
        let processor = JSONProcessor()
        
        // 复杂混合编码：Unicode + HTML + URL编码
        let input = "{%22message%22%3A%22%5Cu4f60%5Cu597d%26amp%3B%26lt%3Bhello%26gt%3B%22}"
        processor.inputText = input
        
        // 先进行URL解码
        processor.convertURLEncodingSync()
        
        // 再进行Unicode转换
        processor.convertUnicodeToChineseCharactersSync()
        
        // 最后进行HTML转换
        processor.convertHTMLToChineseCharactersSync()
        
        #expect(processor.inputText.contains("你好"))
        #expect(processor.inputText.contains("&"))
        #expect(processor.inputText.contains("<hello>"))
    }
    
    @Test func testEncodingChain() async throws {
        let processor = JSONProcessor()
        
        // 测试编码链：先URL解码，再Unicode转换，最后HTML转换
        processor.inputText = "%7B%22user%22%3A%22%5Cu5f20%5Cu4e09%22%2C%22message%22%3A%22%26quot%3BHello%26quot%3B%22%7D"
        
        processor.convertURLEncodingSync()
        processor.convertUnicodeToChineseCharactersSync()
        processor.convertHTMLToChineseCharactersSync()
        
        // 验证最终结果是合法的JSON
        let resultData = processor.inputText.data(using: .utf8)!
        let jsonObject = try JSONSerialization.jsonObject(with: resultData)
        
        // 验证可以重新序列化
        let reSerializedData = try JSONSerialization.data(withJSONObject: jsonObject)
        let reSerializedString = String(data: reSerializedData, encoding: .utf8)!
        
        #expect(reSerializedString.contains("张三"))
        #expect(reSerializedString.contains("\"Hello\""))
    }
    
    @Test func testNoEncodingNeeded() async throws {
        let processor = JSONProcessor()
        
        // 测试不需要转换的文本
        let originalText = "{\"name\": \"张三\", \"message\": \"Hello World\"}"
        processor.inputText = originalText
        
        processor.convertUnicodeToChineseCharactersSync()
        processor.convertHTMLToChineseCharactersSync()
        processor.convertURLEncodingSync()
        
        #expect(processor.inputText == originalText)
    }
    
    @Test func testInvalidEncodingHandling() async throws {
        let processor = JSONProcessor()
        
        // 测试无效编码的处理
        processor.inputText = "\\uXXXX invalid unicode"
        processor.convertUnicodeToChineseCharactersSync()
        
        // 应该保持原样
        #expect(processor.inputText == "\\uXXXX invalid unicode")
        
        // 测试无效URL编码
        processor.inputText = "%ZZ invalid url encoding"
        processor.convertURLEncodingSync()
        
        // 应该保持原样
        #expect(processor.inputText == "%ZZ invalid url encoding")
    }
}
