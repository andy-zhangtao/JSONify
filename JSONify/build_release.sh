#!/bin/bash

# JSONify Release Build Script
# This script builds a release version of JSONify and creates a DMG file with code signing and notarization

set -e

echo "🔨 Building JSONify Release..."

# Configuration
TEAM_ID="XLNMYUAC2D"  # 你的Team ID
DEVELOPER_ID_CERT="Developer ID Application: Zhangtao zhang ($TEAM_ID)"
DEVELOPER_ID_INSTALLER="Developer ID Installer: Zhangtao zhang ($TEAM_ID)"
BUNDLE_ID="com.zhangtao.JSONify"

# 检查是否有必要的证书
echo "🔍 Checking for Developer ID certificates..."
if ! security find-identity -v | grep -q "Developer ID Application"; then
    echo "⚠️  Warning: No Developer ID Application certificate found"
    echo "   You need to create and download a 'Developer ID Application' certificate from:"
    echo "   https://developer.apple.com/account/resources/certificates/list"
    echo ""
    echo "   For now, building without notarization..."
    SKIP_NOTARIZATION=true
else
    echo "✅ Developer ID Application certificate found"
    SKIP_NOTARIZATION=false
fi

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build/
rm -f JSONify.dmg

# Build the app for release
echo "Building Release configuration..."
if [ "$SKIP_NOTARIZATION" = true ]; then
    # 使用开发证书构建（不公证）
    xcodebuild -scheme JSONify -configuration Release -derivedDataPath build/DerivedData clean build
else
    # 使用分发证书构建（准备公证）
    xcodebuild -scheme JSONify -configuration Release \
        -derivedDataPath build/DerivedData \
        CODE_SIGN_IDENTITY="$DEVELOPER_ID_CERT" \
        PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
        clean build
fi

# Find the built app
APP_PATH="build/DerivedData/Build/Products/Release/JSONify.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Built app not found at $APP_PATH"
    exit 1
fi

echo "✅ App built successfully at: $APP_PATH"

# 代码签名和公证
if [ "$SKIP_NOTARIZATION" = false ]; then
    echo "🔐 Code signing the app..."
    
    # 深度签名应用程序
    codesign --force --deep --sign "$DEVELOPER_ID_CERT" \
        --options runtime \
        --entitlements JSONify/JSONify.entitlements \
        "$APP_PATH"
    
    # 验证签名
    echo "🔍 Verifying code signature..."
    codesign --verify --deep --strict "$APP_PATH"
    
    echo "✅ Code signing completed"
    
    # 创建压缩包准备公证
    echo "📦 Creating ZIP for notarization..."
    NOTARIZATION_ZIP="build/JSONify-notarization.zip"
    ditto -c -k --keepParent "$APP_PATH" "$NOTARIZATION_ZIP"
    
    # 公证应用程序
    echo "📋 Submitting for notarization..."
    echo "   This may take several minutes..."
    
    # 使用notarytool进行公证（需要App Store Connect API密钥或Apple ID）
    if [ -z "$NOTARYTOOL_PROFILE" ]; then
        echo "⚠️  NOTARYTOOL_PROFILE environment variable not set"
        echo "   You need to set up notarytool first:"
        echo "   xcrun notarytool store-credentials --apple-id your-apple-id --team-id $TEAM_ID"
        echo ""
        echo "   Skipping notarization for now..."
    else
        xcrun notarytool submit "$NOTARIZATION_ZIP" \
            --keychain-profile "$NOTARYTOOL_PROFILE" \
            --wait
        
        # 装订公证票据
        echo "📎 Stapling notarization ticket..."
        xcrun stapler staple "$APP_PATH"
        
        echo "✅ Notarization completed"
    fi
    
    # 清理公证临时文件
    rm -f "$NOTARIZATION_ZIP"
fi

# Create a temporary directory for DMG contents
echo "Creating DMG contents..."
DMG_TEMP="build/dmg_temp"
mkdir -p "$DMG_TEMP"

# Copy the app to the temporary directory
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create a symbolic link to Applications folder
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG
echo "Creating DMG file..."
hdiutil create -volname "JSONify" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "JSONify.dmg"

# 签名DMG文件
if [ "$SKIP_NOTARIZATION" = false ]; then
    echo "🔐 Signing DMG file..."
    codesign --force --sign "$DEVELOPER_ID_CERT" "JSONify.dmg"
    
    # 验证DMG签名
    echo "🔍 Verifying DMG signature..."
    codesign --verify "JSONify.dmg"
    
    echo "✅ DMG signed successfully"
fi

# Clean up
rm -rf "$DMG_TEMP"

echo "✅ DMG created successfully: JSONify.dmg"

# Get file size
DMG_SIZE=$(ls -lh JSONify.dmg | awk '{print $5}')
echo "📦 DMG Size: $DMG_SIZE"

echo "🎉 Build complete!"