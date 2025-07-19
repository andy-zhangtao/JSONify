//
//  SessionHistory.swift
//  JSONify
//
//  Created by 张涛 on 7/19/25.
//

import Foundation
import SwiftUI

// 会话历史数据模型
struct JSONSession: Identifiable, Codable, Equatable {
    let id = UUID()
    let content: String
    let timestamp: Date
    let preview: String
    
    init(content: String, timestamp: Date = Date()) {
        self.content = content
        self.timestamp = timestamp
        
        // 生成预览内容（前100个字符）
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 100 {
            self.preview = String(trimmed.prefix(100)) + "..."
        } else {
            self.preview = trimmed
        }
    }
}

// 会话历史管理器
class SessionHistoryManager: ObservableObject {
    @Published var sessions: [JSONSession] = []
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "jsonSessions"
    private let maxSessions = 20 // 最多保存20个会话
    
    init() {
        loadSessions()
    }
    
    func addSession(_ content: String) {
        // 避免保存空内容
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 检查所有会话中是否已存在相同内容
        if sessions.contains(where: { $0.content == content }) {
            return
        }
        
        let newSession = JSONSession(content: content)
        sessions.insert(newSession, at: 0)
        
        // 限制会话数量
        if sessions.count > maxSessions {
            sessions = Array(sessions.prefix(maxSessions))
        }
        
        saveSessions()
    }
    
    func deleteSession(_ session: JSONSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }
    
    func clearAllSessions() {
        sessions.removeAll()
        saveSessions()
    }
    
    private func loadSessions() {
        guard let data = userDefaults.data(forKey: sessionsKey),
              let decodedSessions = try? JSONDecoder().decode([JSONSession].self, from: data) else {
            return
        }
        sessions = decodedSessions
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: sessionsKey)
        }
    }
}

// 会话历史视图
struct SessionHistoryView: View {
    @ObservedObject var historyManager: SessionHistoryManager
    @Binding var selectedContent: String
    @State private var hoveredSession: JSONSession?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("会话历史")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !historyManager.sessions.isEmpty {
                    Button(action: {
                        historyManager.clearAllSessions()
                    }) {
                        Text("清除全部")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
            }
            
            if historyManager.sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("暂无会话历史")
                        .foregroundColor(.secondary)
                    Text("输入的JSON将自动保存到这里")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(historyManager.sessions) { session in
                            SessionRowView(
                                session: session,
                                isHovered: hoveredSession?.id == session.id,
                                dateFormatter: dateFormatter,
                                onSelect: {
                                    selectedContent = session.content
                                },
                                onDelete: {
                                    historyManager.deleteSession(session)
                                }
                            )
                            .onHover { isHovered in
                                hoveredSession = isHovered ? session : nil
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SessionRowView: View {
    let session: JSONSession
    let isHovered: Bool
    let dateFormatter: DateFormatter
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateFormatter.string(from: session.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(session.preview)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}