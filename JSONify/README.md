# JSONify

<div align="center">

![JSONify Icon](Assets/icon.png)

**专业的 macOS JSON 处理工具套件**

[![macOS](https://img.shields.io/badge/macOS-12.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-v1.3.0-purple.svg)](https://github.com/andy-zhangtao/JSONify/releases)

[下载最新版本](https://github.com/andy-zhangtao/JSONify/releases/latest) | [功能演示](#功能特性) | [使用指南](#使用指南)

</div>

---

## 📖 简介

**JSONify** 是一款功能强大的原生 macOS JSON 处理工具，专为开发者和数据分析师设计。它集成了 JSON 格式化、比较和 JSONPath 查询三大核心功能，为你的 JSON 数据处理工作提供一站式解决方案。

### 🎯 设计理念

- **原生体验** - 完全使用 SwiftUI 构建，完美融入 macOS 生态
- **高效处理** - 异步处理大型 JSON 文件，保持界面响应
- **用户友好** - 直观的 Tab 导航，清晰的视觉反馈
- **功能专业** - 涵盖日常 JSON 处理的所有需求场景

---

## ✨ 功能特性

### 🎨 JSON 格式化
- **智能格式化** - 一键美化 JSON 结构，支持自定义缩进
- **语法验证** - 实时检测 JSON 格式错误，精确定位问题
- **树形展示** - 层次化显示 JSON 结构，支持折叠/展开
- **快捷操作** - 支持键盘快捷键，提升操作效率
- **历史记录** - 自动保存处理历史，方便回溯查看

### 🔍 JSON 比较
- **双面板对比** - 并排显示两个 JSON，直观对比差异
- **智能差异检测** - 深度递归算法，检测所有层级变化
- **灵活比较选项**：
  - 🔸 忽略空格 - 忽略字符串前后空格差异
  - 🔸 忽略数组顺序 - 支持数组元素顺序无关比较
  - 🔸 忽略大小写 - 字符串比较时忽略大小写
  - 🔸 仅比较结构 - 专注于 JSON 结构差异
- **差异统计** - 实时统计新增、删除、修改的项目数量
- **精确定位** - 显示差异的完整 JSONPath 路径
- **结果筛选** - 点击统计徽章快速过滤特定类型差异

### 🔎 JSONPath 查询
- **完整语法支持** - 支持标准 JSONPath 规范的所有语法
- **实时查询** - 输入即查询，立即显示匹配结果
- **语法高亮** - JSONPath 表达式语法着色显示
- **结果详览** - 支持展开查看复杂对象的完整内容
- **语法帮助** - 内置语法参考和示例，快速上手

#### 支持的 JSONPath 语法
```javascript
$                    // 根元素
$.property          // 访问属性
$['property']       // 方括号访问属性
$[0]               // 数组索引访问
$[*]               // 所有数组元素
$.*                // 所有直接子元素
$..property        // 递归搜索属性
$[0:3]             // 数组切片（索引0到2）
$.users[*].name    // 复合路径查询
```

---

## 🛠 技术架构

### 核心技术栈
- **SwiftUI** - 现代化声明式 UI 框架
- **Combine** - 响应式编程支持
- **Core Data** - 数据持久化存储
- **JSONSerialization** - 高性能 JSON 处理

### 关键模块

#### 📁 项目结构
```
JSONify/
├── JSONifyApp.swift          # 应用入口
├── MainTabView.swift         # 主 Tab 导航
├── ContentView.swift         # JSON 格式化界面
├── JSONCompareView.swift     # JSON 比较界面
├── JSONPathQueryView.swift   # JSONPath 查询界面
├── JSONProcessor.swift       # JSON 处理引擎
├── JSONDiffEngine.swift      # 差异检测引擎
├── JSONPathEngine.swift      # JSONPath 查询引擎
├── DiffResultView.swift      # 差异结果展示
├── JSONTreeView.swift        # 树形结构展示
├── SessionHistory.swift      # 会话历史管理
├── SettingsView.swift        # 设置界面
└── Assets.xcassets/          # 应用资源
```

#### 🔧 性能优化
- **异步处理** - 使用 GCD 进行后台 JSON 处理，避免界面卡顿
- **延迟加载** - LazyVStack 优化大量数据的显示性能
- **内存管理** - 智能的对象生命周期管理，避免内存泄漏
- **并发安全** - 线程安全的数据处理流程

---

## 💻 系统要求

- **操作系统**: macOS 12.0 (Monterey) 或更高版本
- **架构**: Apple Silicon (M1/M2/M3) 和 Intel 处理器
- **内存**: 建议 8GB 以上（处理大型 JSON 文件时）
- **存储**: 50MB 可用空间

---

## 📥 安装指南

### 方式一：GitHub Releases（推荐）
1. 前往 [Releases 页面](https://github.com/andy-zhangtao/JSONify/releases/latest)
2. 下载最新的 `JSONify.dmg` 文件
3. 双击打开 DMG 文件
4. 将 JSONify 拖拽到 Applications 文件夹
5. 首次运行时，可能需要在系统偏好设置 → 安全性与隐私中允许运行

### 方式二：从源代码构建
```bash
# 克隆仓库
git clone https://github.com/andy-zhangtao/JSONify.git
cd JSONify

# 使用 Xcode 打开项目
open JSONify.xcodeproj

# 或使用命令行构建
./build_release.sh
```

---

## 🚀 使用指南

### JSON 格式化
1. 启动 JSONify，默认进入"格式化"标签页
2. 在左侧文本区域粘贴或输入 JSON 数据
3. 应用会自动验证格式并在右侧显示格式化结果
4. 使用工具栏按钮进行排序、压缩等操作
5. ⌘K 快速清除输入内容

### JSON 比较
1. 切换到"比较"标签页
2. 在左右两个面板分别输入需要比较的 JSON
3. 配置比较选项（忽略空格、数组顺序等）
4. 点击"比较"按钮查看差异结果
5. 使用统计徽章筛选特定类型的差异

### JSONPath 查询
1. 切换到"查询"标签页
2. 在左侧输入 JSON 数据
3. 在查询框中输入 JSONPath 表达式
4. 实时查看匹配结果
5. 点击结果项查看详细内容
6. 使用"?"按钮查看语法帮助

---

## 🎨 界面预览

### 主界面 - Tab 导航
<div align="center">
  <img src="Screenshots/main-interface.png" alt="主界面" width="800">
</div>

### JSON 格式化
<div align="center">
  <img src="Screenshots/json-formatter.png" alt="JSON格式化" width="800">
</div>

### JSON 比较
<div align="center">
  <img src="Screenshots/json-compare.png" alt="JSON比较" width="800">
</div>

### JSONPath 查询
<div align="center">
  <img src="Screenshots/jsonpath-query.png" alt="JSONPath查询" width="800">
</div>

---

## ⚡ 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌘K` | 清除输入内容 |
| `⌘1` | 切换到格式化标签页 |
| `⌘2` | 切换到比较标签页 |
| `⌘3` | 切换到查询标签页 |
| `⌘+` | 增大字体 |
| `⌘-` | 减小字体 |
| `⌘0` | 重置字体大小 |
| `⌘,` | 打开设置 |

---

## 📝 更新日志

### v1.3.0 (2025-07-19)
#### 🚀 新功能
- ✨ **JSONPath 查询工具** - 强大的路径表达式查询功能
- 🔍 **完整语法支持** - 支持所有标准 JSONPath 语法
- 💡 **语法帮助** - 内置语法参考和示例
- 🎯 **实时查询** - 输入即查询，立即显示结果
- 📋 **结果详览** - 支持展开查看复杂对象内容

#### 🔧 改进
- ⚡ 优化 Tab 导航体验
- 🚄 提升整体性能表现

### v1.2.0 (2025-07-18)
#### 🚀 新功能
- 🔄 **JSON 比较功能** - 并排对比两个 JSON
- 📊 **差异统计** - 实时统计新增、删除、修改项目
- ⚙️ **灵活选项** - 多种比较模式配置
- 🎯 **精确定位** - 显示完整的差异路径

### v1.1.0 (2025-07-16)
#### 🚀 新功能
- 🌳 **树形展示** - 层次化显示 JSON 结构
- 📚 **历史记录** - 自动保存处理历史
- ⚙️ **设置选项** - 可配置的应用设置

### v1.0.0 (2025-07-14)
#### 🎉 首个版本
- 🎨 **JSON 格式化** - 基础的 JSON 美化功能
- ✅ **格式验证** - 实时 JSON 语法检查
- 💫 **现代 UI** - SwiftUI 构建的原生界面

---

## 🤝 贡献指南

欢迎为 JSONify 项目做出贡献！无论是 Bug 报告、功能建议还是代码提交，我们都非常欢迎。

### 如何贡献
1. **Fork** 本仓库
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建一个 **Pull Request**

### 开发环境设置
```bash
# 克隆你的 fork
git clone https://github.com/YourUsername/JSONify.git
cd JSONify

# 安装依赖（如果有）
# 本项目使用原生 SwiftUI，无需额外依赖

# 使用 Xcode 打开
open JSONify.xcodeproj
```

### 代码规范
- 使用 Swift 5.0+ 语法
- 遵循 SwiftUI 最佳实践
- 添加适当的注释和文档
- 确保代码通过所有测试

---

## 🐛 问题反馈

遇到问题？有改进建议？请通过以下方式联系我们：

- **GitHub Issues**: [提交 Issue](https://github.com/andy-zhangtao/JSONify/issues/new)
- **功能请求**: [Feature Request](https://github.com/andy-zhangtao/JSONify/issues/new?template=feature_request.md)
- **Bug 报告**: [Bug Report](https://github.com/andy-zhangtao/JSONify/issues/new?template=bug_report.md)

提交 Issue 时，请包含以下信息：
- macOS 版本
- JSONify 版本
- 详细的问题描述
- 复现步骤
- 相关截图（如果适用）

---

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

## 🙏 致谢

感谢以下开源项目和社区的支持：

- **Apple** - 提供优秀的 SwiftUI 框架
- **Swift Community** - 持续推动 Swift 语言发展
- **GitHub** - 优秀的代码托管和协作平台
- **所有贡献者** - 感谢每一位为项目做出贡献的开发者

---

## 🔗 相关链接

- [Apple SwiftUI 文档](https://developer.apple.com/documentation/swiftui/)
- [JSONPath 规范](https://goessner.net/articles/JsonPath/)
- [JSON 官方规范](https://www.json.org/)
- [macOS 开发指南](https://developer.apple.com/macos/)

---

<div align="center">

**如果 JSONify 对你有帮助，请给个 ⭐️ Star 支持一下！**

Made with ❤️ by [andy-zhangtao](https://github.com/andy-zhangtao)

</div>
