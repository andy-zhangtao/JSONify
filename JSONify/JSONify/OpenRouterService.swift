//
//  OpenRouterService.swift
//  JSONify
//
//  Created by Claude on 8/4/25.
//

import Foundation

// OpenRouter API服务
class OpenRouterService: ObservableObject {
    @Published var isLoading = false
    @Published var isPinging = false
    @Published var error: OpenRouterError?
    
    private let baseURL = "https://openrouter.ai/api/v1"
    private let session = URLSession.shared
    
    // 修复JSON的方法
    func healJSON(_ brokenJSON: String, using config: OpenRouterManager) async throws -> String {
        guard config.isConfigured else {
            throw OpenRouterError.notConfigured
        }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        let request = try createHealingRequest(brokenJSON: brokenJSON, config: config)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenRouterError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                break // 继续处理
            case 401:
                throw OpenRouterError.invalidAPIKey
            case 404:
                throw OpenRouterError.modelNotFound
            case 429:
                throw OpenRouterError.rateLimitExceeded
            default:
                throw OpenRouterError.httpError(httpResponse.statusCode)
            }
            
            let result = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
            
            guard let choice = result.choices.first else {
                throw OpenRouterError.noResponse
            }
            
            let content = choice.message.content
            
            // 尝试从响应中提取JSON
            let healedJSON = extractJSONFromResponse(content)
            return healedJSON
            
        } catch let error as OpenRouterError {
            await MainActor.run {
                self.error = error
            }
            throw error
        } catch {
            let openRouterError = OpenRouterError.networkError(error)
            await MainActor.run {
                self.error = openRouterError
            }
            throw openRouterError
        }
    }
    
    // Ping验证API配置
    func pingAPI(using config: OpenRouterManager) async throws -> Bool {
        guard !config.apiKey.isEmpty && !config.modelName.isEmpty else {
            throw OpenRouterError.notConfigured
        }
        
        await MainActor.run {
            isPinging = true
            error = nil
        }
        
        defer {
            Task { @MainActor in
                isPinging = false
            }
        }
        
        let request = try createPingRequest(config: config)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenRouterError.invalidResponse
            }
            
            // 检查HTTP状态码
            switch httpResponse.statusCode {
            case 200:
                // 验证响应是否包含有效的模型信息
                let result = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
                return !result.choices.isEmpty
            case 401:
                throw OpenRouterError.invalidAPIKey
            case 404:
                throw OpenRouterError.modelNotFound
            case 429:
                throw OpenRouterError.rateLimitExceeded
            default:
                throw OpenRouterError.httpError(httpResponse.statusCode)
            }
            
        } catch let error as OpenRouterError {
            await MainActor.run {
                self.error = error
            }
            throw error
        } catch {
            let openRouterError = OpenRouterError.networkError(error)
            await MainActor.run {
                self.error = openRouterError
            }
            throw openRouterError
        }
    }
    
    // 创建Ping请求 - 发送一个简单的测试消息
    private func createPingRequest(config: OpenRouterManager) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenRouterError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://github.com/andy-zhangtao/JSONify", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("JSONify", forHTTPHeaderField: "X-Title")
        
        // 简单的ping消息
        let requestBody = OpenRouterRequest(
            model: config.modelName,
            messages: [
                OpenRouterMessage(role: "user", content: "ping")
            ],
            temperature: 0.1,
            max_tokens: 10  // 只需要很少的token
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        return request
    }
    
    // 创建API请求
    private func createHealingRequest(brokenJSON: String, config: OpenRouterManager) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenRouterError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://github.com/andy-zhangtao/JSONify", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("JSONify", forHTTPHeaderField: "X-Title")
        
        let prompt = createHealingPrompt(brokenJSON: brokenJSON)
        
        let requestBody = OpenRouterRequest(
            model: config.modelName,
            messages: [
                OpenRouterMessage(role: "user", content: prompt)
            ],
            temperature: 0.1,
            max_tokens: 4000
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        return request
    }
    
    // 创建修复提示词
    private func createHealingPrompt(brokenJSON: String) -> String {
        return """
        你是一个JSON修复专家。请修复以下损坏的JSON数据，并返回有效的JSON格式。

        要求：
        1. 只返回修复后的JSON，不要任何解释或额外文本
        2. 保持原始数据的含义和结构
        3. 修复常见问题：缺少引号、多余逗号、括号不匹配等
        4. 如果数据无法修复，返回空的JSON对象 {}

        损坏的JSON：
        ```
        \(brokenJSON)
        ```

        修复后的JSON：
        """
    }
    
    // 从响应中提取JSON
    private func extractJSONFromResponse(_ response: String) -> String {
        // 移除可能的代码块标记
        let cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 尝试找到JSON内容
        if let jsonStart = cleanedResponse.firstIndex(of: "{") ?? cleanedResponse.firstIndex(of: "[") {
            let jsonContent = String(cleanedResponse[jsonStart...])
            return jsonContent.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleanedResponse
    }
}

// MARK: - 数据模型

struct OpenRouterRequest: Codable {
    let model: String
    let messages: [OpenRouterMessage]
    let temperature: Double
    let max_tokens: Int
}

struct OpenRouterMessage: Codable {
    let role: String
    let content: String
}

struct OpenRouterResponse: Codable {
    let choices: [OpenRouterChoice]
}

struct OpenRouterChoice: Codable {
    let message: OpenRouterMessage
}

// MARK: - 错误类型

enum OpenRouterError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noResponse
    case networkError(Error)
    case jsonParsingError
    case invalidAPIKey
    case modelNotFound
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "OpenRouter 未配置。请在设置中配置 API Key 和模型。"
        case .invalidURL:
            return "无效的 API URL"
        case .invalidResponse:
            return "服务器响应无效"
        case .httpError(let code):
            return "HTTP 错误: \(code)"
        case .noResponse:
            return "未收到有效响应"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .jsonParsingError:
            return "JSON 解析错误"
        case .invalidAPIKey:
            return "无效的 API Key。请检查您的 OpenRouter API Key 是否正确。"
        case .modelNotFound:
            return "模型不存在。请检查模型名称是否正确，或在 OpenRouter.ai 上确认该模型可用。"
        case .rateLimitExceeded:
            return "请求过于频繁，已超出API调用限制。请稍后再试，或检查您的OpenRouter账户余额和使用限制。"
        }
    }
}