import SwiftUI

struct StatusBarView: View {
    let isValid: Bool
    let characterCount: Int
    let lineCount: Int
    let processingTime: TimeInterval?
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(isValid ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(isValid ? "有效" : "无效")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 12)
            
            HStack(spacing: 4) {
                Text("字符数:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(characterCount)")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            Divider()
                .frame(height: 12)
            
            HStack(spacing: 4) {
                Text("行数:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(lineCount)")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            if let time = processingTime {
                Divider()
                    .frame(height: 12)
                
                HStack(spacing: 4) {
                    Text("处理时间:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2fms", time * 1000))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    StatusBarView(isValid: true, characterCount: 1234, lineCount: 45, processingTime: 0.0023)
}