#!/bin/bash

# JSONify 依赖测试脚本
# 测试本地JSONHealer依赖是否正常工作

set -e

echo "🧪 测试JSONHealer本地依赖..."
echo "================================"

# 检查JSONHealer目录是否存在
if [ -d "./JSONHealer" ]; then
    echo "✅ JSONHealer目录存在"
else
    echo "❌ 错误：找不到JSONHealer目录"
    exit 1
fi

# 检查JSONHealer的Package.swift
if [ -f "./JSONHealer/Package.swift" ]; then
    echo "✅ JSONHealer Package.swift存在"
else
    echo "❌ 错误：找不到JSONHealer Package.swift"
    exit 1
fi

# 清理依赖缓存
echo "🧹 清理Xcode缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/JSONify-*

# 尝试构建项目以测试依赖
echo "🔨 测试构建项目..."
xcodebuild \
    -scheme JSONify \
    -configuration Debug \
    -destination "platform=macOS" \
    -derivedDataPath ./build/DependencyTest \
    clean build | head -50

# 检查构建结果
BUILD_SUCCESS=$?
if [ $BUILD_SUCCESS -eq 0 ]; then
    echo ""
    echo "✅ 依赖测试成功！"
    echo "📦 本地JSONHealer依赖工作正常"
    
    # 显示一些统计信息
    echo ""
    echo "📊 统计信息："
    echo "   - JSONHealer源文件：$(find ./JSONHealer/Sources -name "*.swift" | wc -l) 个"
    echo "   - JSONHealer测试文件：$(find ./JSONHealer/Tests -name "*.swift" | wc -l) 个"
else
    echo ""
    echo "❌ 依赖测试失败！"
    echo "请检查JSONHealer路径配置或依赖设置"
    exit 1
fi

echo ""
echo "🎉 测试完成！本地依赖配置正确。"