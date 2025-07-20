#!/bin/bash

# JSONify Build and Test Script
# This script builds the project and checks for any compilation errors

set -e

echo "🔨 开始构建 JSONify..."
echo "================================"

# 清理之前的构建
echo "📦 清理之前的构建..."
xcodebuild clean -scheme JSONify -configuration Debug

# 构建项目
echo "🏗️  构建 Debug 版本..."
xcodebuild build \
    -scheme JSONify \
    -configuration Debug \
    -derivedDataPath build/DerivedData \
    | xcpretty --color || {
        echo "❌ 构建失败！"
        echo "请检查上面的错误信息"
        exit 1
    }

echo "✅ 构建成功！"
echo "================================"

# 显示构建产物位置
APP_PATH="build/DerivedData/Build/Products/Debug/JSONify.app"
if [ -d "$APP_PATH" ]; then
    echo "📍 应用位置: $APP_PATH"
    echo "📏 应用大小: $(du -sh "$APP_PATH" | awk '{print $1}')"
    
    # 可选：直接运行应用
    echo ""
    read -p "是否要运行应用？(y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🚀 启动 JSONify..."
        open "$APP_PATH"
    fi
else
    echo "⚠️  警告：找不到构建的应用"
fi

echo "🎉 完成！"