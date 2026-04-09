#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:-dev}"
# Set SIGNING_IDENTITY to use a Developer ID or self-signed certificate.
# Default: ad-hoc signing ("-")
#   Developer ID example: "Developer ID Application: Name (TEAMID)"
#   Self-signed example:  "RippleClick Development"
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"

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
echo "Signing with identity: ${SIGNING_IDENTITY}"

if [ "$SIGNING_IDENTITY" = "-" ]; then
    # Ad-hoc signing (no stable identity — TCC permissions may reset on update)
    codesign --force --sign - RippleClick.app
else
    # Identity-based signing with hardened runtime and entitlements
    # TCC will remember accessibility permissions across updates
    codesign --force --options runtime \
        --sign "$SIGNING_IDENTITY" \
        --entitlements Resources/RippleClick.entitlements \
        RippleClick.app
fi

echo "Done! Run with: open RippleClick.app"
