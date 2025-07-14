import SwiftUI

struct JSONTreeNode: Identifiable {
    let id = UUID()
    let key: String?
    let value: Any
    let level: Int
    var isExpanded: Bool = true
    var children: [JSONTreeNode] = []
    
    var displayValue: String {
        if let dict = value as? [String: Any] {
            return "{\(dict.count) items}"
        } else if let array = value as? [Any] {
            return "[\(array.count) items]"
        } else if let string = value as? String {
            return "\"\(string)\""
        } else if let number = value as? NSNumber {
            return "\(number)"
        } else if value is NSNull {
            return "null"
        } else {
            return "\(value)"
        }
    }
    
    var isCollapsible: Bool {
        return value is [String: Any] || value is [Any]
    }
}

class JSONTreeViewModel: ObservableObject {
    @Published var nodes: [JSONTreeNode] = []
    
    func buildTree(from jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            nodes = []
            return
        }
        
        nodes = createNodes(from: jsonObject, key: nil, level: 0)
    }
    
    private func createNodes(from value: Any, key: String?, level: Int) -> [JSONTreeNode] {
        var node = JSONTreeNode(key: key, value: value, level: level)
        
        if let dict = value as? [String: Any] {
            node.children = dict.sorted { $0.key < $1.key }.flatMap { key, value in
                createNodes(from: value, key: key, level: level + 1)
            }
        } else if let array = value as? [Any] {
            node.children = array.enumerated().flatMap { index, value in
                createNodes(from: value, key: "[\(index)]", level: level + 1)
            }
        }
        
        return [node]
    }
    
    func toggleExpansion(for nodeId: UUID) {
        toggleNodeExpansion(in: &nodes, nodeId: nodeId)
    }
    
    private func toggleNodeExpansion(in nodes: inout [JSONTreeNode], nodeId: UUID) {
        for i in 0..<nodes.count {
            if nodes[i].id == nodeId {
                nodes[i].isExpanded.toggle()
                return
            }
            toggleNodeExpansion(in: &nodes[i].children, nodeId: nodeId)
        }
    }
    
    func flattenedNodes() -> [JSONTreeNode] {
        return flattenNodes(nodes)
    }
    
    private func flattenNodes(_ nodes: [JSONTreeNode]) -> [JSONTreeNode] {
        var result: [JSONTreeNode] = []
        
        for node in nodes {
            result.append(node)
            if node.isExpanded {
                result.append(contentsOf: flattenNodes(node.children))
            }
        }
        
        return result
    }
}

struct JSONTreeView: View {
    @StateObject private var viewModel = JSONTreeViewModel()
    let jsonString: String
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(viewModel.flattenedNodes()) { node in
                    JSONTreeNodeView(node: node) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.toggleExpansion(for: node.id)
                        }
                    }
                    .transition(.asymmetric(insertion: .opacity.combined(with: .slide), 
                                           removal: .opacity.combined(with: .slide)))
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.buildTree(from: jsonString)
            }
        }
        .onChange(of: jsonString) { newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.buildTree(from: newValue)
            }
        }
    }
}

struct JSONTreeNodeView: View {
    let node: JSONTreeNode
    let onToggle: () -> Void
    @State private var isHovered = false
    
    private var indentWidth: CGFloat {
        CGFloat(node.level * 20)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // 缩进
            Rectangle()
                .fill(Color.clear)
                .frame(width: indentWidth, height: 1)
            
            // 展开/折叠按钮
            if node.isCollapsible {
                Button(action: onToggle) {
                    Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 12, height: 12)
            }
            
            // 键名
            if let key = node.key {
                Text(key)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue)
                Text(":")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            // 值
            Text(node.displayValue)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(valueColor(for: node.value))
            
            Spacer()
        }
        .padding(.vertical, 1)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
    
    private func valueColor(for value: Any) -> Color {
        if value is String {
            return .green
        } else if value is NSNumber {
            return .orange
        } else if value is NSNull {
            return .red
        } else if value is [String: Any] || value is [Any] {
            return .secondary
        } else {
            return .primary
        }
    }
}

#Preview {
    JSONTreeView(jsonString: """
    {
        "name": "John Doe",
        "age": 30,
        "address": {
            "street": "123 Main St",
            "city": "New York",
            "zipcode": "10001"
        },
        "hobbies": ["reading", "swimming", "coding"],
        "married": true,
        "children": null
    }
    """)
}