//
//  FileManager.swift
//  JSONify
//
//  Created by Claude on 7/26/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

class JSONFileManager: ObservableObject {
    @Published var selectedFileURL: URL?
    @Published var selectedFileName: String = ""
    @Published var isFilePickerPresented = false
    @Published var fileError: FileError?
    @Published var isLoading = false
    @Published var recentFiles: [RecentFile] = []
    
    struct RecentFile: Identifiable, Codable {
        let id: UUID
        let url: URL
        let name: String
        let accessDate: Date
        let fileSize: Int64
        
        init(url: URL, name: String, fileSize: Int64) {
            self.id = UUID()
            self.url = url
            self.name = name
            self.accessDate = Date()
            self.fileSize = fileSize
        }
    }
    
    enum FileError: Error, LocalizedError, Equatable {
        case fileNotFound
        case fileReadPermissionDenied
        case fileFormatNotSupported
        case fileTooLarge(sizeInMB: Double)
        case fileContentInvalid
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "文件未找到"
            case .fileReadPermissionDenied:
                return "没有读取文件的权限"
            case .fileFormatNotSupported:
                return "不支持的文件格式"
            case .fileTooLarge(let sizeInMB):
                return "文件过大（\(String(format: "%.1f", sizeInMB))MB），建议小于50MB"
            case .fileContentInvalid:
                return "文件内容无效或包含非文本数据"
            }
        }
    }
    
    // 支持的文件类型
    static let supportedFileTypes: [UTType] = [
        .json,
        .plainText,
        .utf8PlainText,
        .text,
        UTType(filenameExtension: "jsonl") ?? .plainText,
        UTType(filenameExtension: "log") ?? .plainText
    ]
    
    private let maxRecentFiles = 10
    private let recentFilesKey = "JSONify.RecentFiles"
    
    init() {
        loadRecentFiles()
    }
    
    /// 打开文件选择器
    func presentFilePicker() {
        isFilePickerPresented = true
        fileError = nil
    }
    
    /// 读取选中的文件内容
    func readSelectedFile() async -> String? {
        guard let url = selectedFileURL else {
            await MainActor.run {
                fileError = .fileNotFound
            }
            return nil
        }
        
        await MainActor.run {
            isLoading = true
            fileError = nil
        }
        
        do {
            // 检查文件访问权限
            guard url.startAccessingSecurityScopedResource() else {
                await MainActor.run {
                    fileError = .fileReadPermissionDenied
                    isLoading = false
                }
                return nil
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            // 检查文件大小
            let fileAttributes = try Foundation.FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = fileAttributes[.size] as? Int64 {
                let sizeInMB = Double(fileSize) / (1024 * 1024)
                if sizeInMB > 50 {
                    await MainActor.run {
                        fileError = .fileTooLarge(sizeInMB: sizeInMB)
                        isLoading = false
                    }
                    return nil
                }
            }
            
            // 读取文件内容
            let content = try String(contentsOf: url, encoding: .utf8)
            
            await MainActor.run {
                selectedFileName = url.lastPathComponent
                isLoading = false
                
                // 添加到最近文件列表
                if let fileSize = fileAttributes[.size] as? Int64 {
                    addToRecentFiles(url: url, fileSize: fileSize)
                }
            }
            
            return content
            
        } catch CocoaError.fileReadNoPermission {
            await MainActor.run {
                fileError = .fileReadPermissionDenied
                isLoading = false
            }
            return nil
        } catch CocoaError.fileReadNoSuchFile {
            await MainActor.run {
                fileError = .fileNotFound
                isLoading = false
            }
            return nil
        } catch {
            await MainActor.run {
                fileError = .fileContentInvalid
                isLoading = false
            }
            return nil
        }
    }
    
    /// 清除文件选择
    func clearSelection() {
        selectedFileURL = nil
        selectedFileName = ""
        fileError = nil
    }
    
    /// 添加到最近文件列表
    private func addToRecentFiles(url: URL, fileSize: Int64) {
        let recentFile = RecentFile(url: url, name: url.lastPathComponent, fileSize: fileSize)
        
        // 移除已存在的相同文件
        recentFiles.removeAll { $0.url == url }
        
        // 添加到列表开头
        recentFiles.insert(recentFile, at: 0)
        
        // 限制最大数量
        if recentFiles.count > maxRecentFiles {
            recentFiles = Array(recentFiles.prefix(maxRecentFiles))
        }
        
        saveRecentFiles()
    }
    
    /// 从最近文件列表中移除
    func removeFromRecentFiles(_ file: RecentFile) {
        recentFiles.removeAll { $0.id == file.id }
        saveRecentFiles()
    }
    
    /// 清空最近文件列表
    func clearRecentFiles() {
        recentFiles.removeAll()
        saveRecentFiles()
    }
    
    /// 加载最近文件列表
    private func loadRecentFiles() {
        if let data = UserDefaults.standard.data(forKey: recentFilesKey),
           let files = try? JSONDecoder().decode([RecentFile].self, from: data) {
            recentFiles = files
        }
    }
    
    /// 保存最近文件列表
    private func saveRecentFiles() {
        if let data = try? JSONEncoder().encode(recentFiles) {
            UserDefaults.standard.set(data, forKey: recentFilesKey)
        }
    }
}

// MARK: - 文件选择器视图
struct FilePicker: NSViewRepresentable {
    @Binding var selectedURL: URL?
    @Binding var isPresented: Bool
    
    func makeNSView(context: Context) -> NSView {
        return NSView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented && !context.coordinator.isPresenting {
            context.coordinator.isPresenting = true
            DispatchQueue.main.async {
                self.presentFilePicker(coordinator: context.coordinator)
            }
        } else if !isPresented {
            context.coordinator.isPresenting = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var isPresenting = false
    }
    
    private func presentFilePicker(coordinator: Coordinator) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = JSONFileManager.supportedFileTypes
        panel.title = "选择JSON或文本文件"
        panel.message = "请选择要导入的JSON或文本文件"
        
        panel.begin { response in
            DispatchQueue.main.async {
                coordinator.isPresenting = false
                self.isPresented = false
                
                if response == .OK, let url = panel.url {
                    self.selectedURL = url
                }
            }
        }
    }
}