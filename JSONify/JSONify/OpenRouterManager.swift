//
//  OpenRouterManager.swift
//  JSONify
//
//  Created by Claude on 8/4/25.
//

import Foundation
import SwiftUI

// OpenRouter配置管理器
class OpenRouterManager: ObservableObject {
    @Published var apiKey: String = ""
    @Published var modelName: String = "anthropic/claude-3.5-sonnet"
    @Published var isEnabled: Bool = false
    @Published var isValidated: Bool = false
    @Published var validationMessage: String = ""
    
    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainManager()
    @Published private var openRouterService = OpenRouterService()
    
    init() {
        loadSettings()
    }
    
    // 保存设置
    func saveSettings() {
        // API Key安全存储到Keychain
        if !apiKey.isEmpty {
            keychain.save(apiKey, forKey: "openrouter_api_key")
        } else {
            keychain.delete(forKey: "openrouter_api_key")
        }
        
        // 其他设置存储到UserDefaults
        userDefaults.set(modelName, forKey: "openrouter_model_name")
        userDefaults.set(isEnabled, forKey: "openrouter_enabled")
        userDefaults.set(isValidated, forKey: "openrouter_validated")
        
        // 当设置改变时，清除验证状态
        if !isValidated {
            validationMessage = ""
        }
    }
    
    // 加载设置
    private func loadSettings() {
        // 从Keychain加载API Key
        apiKey = keychain.load(forKey: "openrouter_api_key") ?? ""
        
        // 从UserDefaults加载其他设置
        modelName = userDefaults.string(forKey: "openrouter_model_name") ?? "anthropic/claude-3.5-sonnet"
        isEnabled = userDefaults.bool(forKey: "openrouter_enabled")
        isValidated = userDefaults.bool(forKey: "openrouter_validated")
    }
    
    // 验证配置是否完整
    var isConfigured: Bool {
        return !apiKey.isEmpty && !modelName.isEmpty && isEnabled
    }
    
    // 是否可以验证（有API Key和模型名称）
    var canValidate: Bool {
        return !apiKey.isEmpty && !modelName.isEmpty
    }
    
    // 验证配置
    func validateConfiguration() async {
        guard canValidate else {
            await MainActor.run {
                isValidated = false
                validationMessage = "请输入 API Key 和模型名称"
            }
            return
        }
        
        do {
            let isValid = try await openRouterService.pingAPI(using: self)
            await MainActor.run {
                isValidated = isValid
                validationMessage = isValid ? "配置验证成功" : "验证失败"
                saveSettings()
            }
        } catch {
            await MainActor.run {
                isValidated = false
                validationMessage = error.localizedDescription
                saveSettings()
            }
        }
    }
    
    // 获取验证服务的状态
    var isPinging: Bool {
        return openRouterService.isPinging
    }
    
    // 重置设置
    func resetSettings() {
        apiKey = ""
        modelName = "anthropic/claude-3.5-sonnet"
        isEnabled = false
        isValidated = false
        validationMessage = ""
        saveSettings()
    }
    
    // 清除验证状态（当配置改变时调用）
    func clearValidation() {
        isValidated = false
        validationMessage = ""
    }
}

// Keychain管理器 - 安全存储敏感信息
class KeychainManager {
    func save(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // 删除现有项目
        SecItemDelete(query as CFDictionary)
        
        // 添加新项目
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == noErr,
              let data = dataTypeRef as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}