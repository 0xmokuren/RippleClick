#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:-dev}"

echo "Building RippleClick ${VERSION}..."
swift build -c release

echo "Creating app bundle..."
rm -rf RippleClick.app
mkdir -p RippleClick.app/Contents/MacOS
mkdir -p RippleClick.app/Contents/Resources

cp .build/release/RippleClick RippleClick.app/Contents/MacOS/
cp Resources/Info.plist RippleClick.app/Contents/
cp Resources/AppIcon.icns RippleClick.app/Contents/Resources/

# Set version in Info.plist
if [ "$VERSION" != "dev" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" RippleClick.app/Contents/Info.plist
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" RippleClick.app/Contents/Info.plist
fi

# Remove extended attributes and sign
xattr -cr RippleClick.app
echo "Signing..."
codesign --force --sign - RippleClick.app

echo "Done! Run with: open RippleClick.app"
