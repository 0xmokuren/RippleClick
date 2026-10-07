#!/bin/bash
# Build a Mac App Store package (.pkg) of RippleClick.
#
# Usage: bash scripts/bundle-appstore.sh <version> [build-number]
#
# Environment variables:
#   APP_SIGNING_IDENTITY        App signing identity
#                               (default: "Apple Distribution: satoshi hara (56C5MDSJD6)")
#   INSTALLER_SIGNING_IDENTITY  Installer signing identity
#                               (default: "3rd Party Mac Developer Installer: satoshi hara (56C5MDSJD6)")
#   PROVISIONING_PROFILE        Path to the Mac App Store provisioning profile (.provisionprofile)
#   OUT_DIR                     Output directory (default: a temporary directory)
#
# The output directory defaults to a temporary directory on purpose: when the repository lives in an
# iCloud-synced folder (e.g. ~/Documents), File Provider re-adds com.apple.FinderInfo to the bundle and
# the signature fails strict verification.

set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:?Usage: bash scripts/bundle-appstore.sh <version> [build-number]}"
BUILD_NUMBER="${2:-$VERSION}"
APP_SIGNING_IDENTITY="${APP_SIGNING_IDENTITY:-Apple Distribution: satoshi hara (56C5MDSJD6)}"
INSTALLER_SIGNING_IDENTITY="${INSTALLER_SIGNING_IDENTITY:-3rd Party Mac Developer Installer: satoshi hara (56C5MDSJD6)}"
: "${PROVISIONING_PROFILE:?PROVISIONING_PROFILE is required (path to .provisionprofile)}"
OUT_DIR="${OUT_DIR:-$(mktemp -d)/rippleclick-appstore}"

APP_PATH="${OUT_DIR}/RippleClick.app"
PKG_PATH="${OUT_DIR}/RippleClick-${VERSION}-appstore.pkg"
ENTITLEMENTS="Resources/RippleClick-AppStore.entitlements"

echo "Building RippleClick ${VERSION} (${BUILD_NUMBER}) for the Mac App Store..."
# macOS 13 以上を必須にしているアプリは arm64 だけで提出できます。
swift build -c release --arch arm64

echo "Creating app bundle in ${OUT_DIR}..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
cp .build/arm64-apple-macosx/release/RippleClick "$APP_PATH/Contents/MacOS/"
cp Resources/Info.plist "$APP_PATH/Contents/"
cp Resources/AppIcon.icns "$APP_PATH/Contents/Resources/"
cp "$PROVISIONING_PROFILE" "$APP_PATH/Contents/embedded.provisionprofile"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" "$APP_PATH/Contents/Info.plist"

xattr -cr "$APP_PATH"
echo "Signing app with identity: ${APP_SIGNING_IDENTITY}"
codesign --force --options runtime --timestamp \
    --sign "$APP_SIGNING_IDENTITY" \
    --entitlements "$ENTITLEMENTS" \
    "$APP_PATH"
codesign --verify --strict --verbose=2 "$APP_PATH"

echo "Building installer package with identity: ${INSTALLER_SIGNING_IDENTITY}"
productbuild --component "$APP_PATH" /Applications \
    --sign "$INSTALLER_SIGNING_IDENTITY" \
    "$PKG_PATH"

echo "Done! Upload with Transporter: ${PKG_PATH}"
