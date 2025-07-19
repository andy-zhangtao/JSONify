#!/bin/bash

# JSONify Release Build Script
# This script builds a release version of JSONify and creates a DMG file

set -e

echo "🔨 Building JSONify Release..."

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build/
rm -f JSONify.dmg

# Build the app for release
echo "Building Release configuration..."
xcodebuild -scheme JSONify -configuration Release -derivedDataPath build/DerivedData clean build

# Find the built app
APP_PATH="build/DerivedData/Build/Products/Release/JSONify.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Built app not found at $APP_PATH"
    exit 1
fi

echo "✅ App built successfully at: $APP_PATH"

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

# Clean up
rm -rf "$DMG_TEMP"

echo "✅ DMG created successfully: JSONify.dmg"

# Get file size
DMG_SIZE=$(ls -lh JSONify.dmg | awk '{print $5}')
echo "📦 DMG Size: $DMG_SIZE"

echo "🎉 Build complete!"