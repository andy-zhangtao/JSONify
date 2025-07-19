#!/bin/bash

# JSONify Release Script
# This script commits code, creates tag, builds DMG, and creates GitHub release

set -e

echo "🚀 Starting JSONify Release Process..."

# Step 1: Git operations
echo "📝 Step 1: Committing code..."
git add JSONify/SessionHistory.swift JSONify/ContentView.swift
git commit -m "feat: 添加会话历史功能

- 实现会话历史保存和管理
- 最多保存20个历史会话
- 支持点击恢复历史内容
- 支持删除单个或清空所有历史
- 数据持久化存储在UserDefaults中

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Step 2: Create tag
echo "🏷️  Step 2: Creating tag v1.1.0..."
git tag -a v1.1.0 -m "Release v1.1.0 - 会话历史功能"

# Step 3: Build DMG
echo "🔨 Step 3: Building DMG..."
chmod +x build_release.sh
./build_release.sh

# Step 4: Push to remote
echo "📤 Step 4: Pushing to remote repository..."
git push origin main
git push origin v1.1.0

# Step 5: Create GitHub release
echo "📦 Step 5: Creating GitHub release..."
gh release create v1.1.0 \
  --title "v1.1.0 - 会话历史功能" \
  --notes "## 新功能

### 🎉 会话历史
- 自动保存有效的JSON输入历史
- 最多保存20个历史会话
- 点击历史记录可快速恢复内容
- 支持删除单个历史记录
- 支持一键清空所有历史
- 数据持久化存储，关闭应用后仍然保留

## 改进
- 优化了用户界面布局
- 添加了延迟保存机制，避免频繁保存
- 改进了重复内容检测逻辑

## 下载
请下载下方的 JSONify.dmg 文件进行安装。" \
  JSONify.dmg

echo "✅ Release process completed successfully!"
echo "🎉 JSONify v1.1.0 has been released!"