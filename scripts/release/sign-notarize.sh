#!/bin/bash
# CI only: sign a built app with existing credentials; never build source with secrets.
set -euo pipefail
umask 077

INPUT_DIR="$1"
OUTPUT_DIR="$2"
VERSION="$3"
EXPECTED_SHA="$4"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 2
[[ "$EXPECTED_SHA" =~ ^[0-9a-f]{64}$ ]] || exit 2
printf '%s  %s\n' "$EXPECTED_SHA" "$INPUT_DIR/unsigned-app.zip" | shasum -a 256 -c -

for name in DEVELOPER_ID_CERT_P12_BASE64 DEVELOPER_ID_CERT_PASSWORD SIGNING_IDENTITY \
    NOTARY_API_KEY_P8_BASE64 NOTARY_API_KEY_ID NOTARY_API_ISSUER_ID; do
    if [ -z "${!name:-}" ]; then
        echo "::error::Required signing input is missing: $name" >&2
        exit 2
    fi
done
[[ "$SIGNING_IDENTITY" == "Developer ID Application:"* ]] || exit 2

WORK_DIR="$(mktemp -d "$RUNNER_TEMP/ripple-sign.XXXXXX")"
KEYCHAIN_PATH="$WORK_DIR/signing.keychain-db"
cleanup() {
    security delete-keychain "$KEYCHAIN_PATH" >/dev/null 2>&1 || true
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Validate before extraction. This app currently contains no framework symlinks.
python3 - "$INPUT_DIR" "$VERSION" <<'PY'
import pathlib, plistlib, stat, sys, zipfile
root = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(root / 'unsigned-app.zip') as archive:
    for entry in archive.infolist():
        parts = pathlib.PurePosixPath(entry.filename).parts
        if not parts or parts[0] != 'RippleClick.app' or '..' in parts or stat.S_ISLNK(entry.external_attr >> 16):
            raise SystemExit('Unexpected unsigned app archive entry')
    info = plistlib.loads(archive.read('RippleClick.app/Contents/Info.plist'))
    if info.get('CFBundleIdentifier') != 'com.0xmokuren.RippleClick' or any(
        info.get(key) != sys.argv[2] for key in ['CFBundleVersion', 'CFBundleShortVersionString']
    ):
        raise SystemExit('Unexpected app identity or version')
if plistlib.loads((root / 'signing-entitlements.plist').read_bytes()) != {}:
    raise SystemExit('Entitlement changes require a separate signing review')
PY

ditto -x -k "$INPUT_DIR/unsigned-app.zip" "$WORK_DIR/app"
KEYCHAIN_PASSWORD="$(uuidgen)"
printf '%s' "$DEVELOPER_ID_CERT_P12_BASE64" | base64 --decode > "$WORK_DIR/certificate.p12"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$WORK_DIR/certificate.p12" -P "$DEVELOPER_ID_CERT_PASSWORD" \
    -T /usr/bin/codesign -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
rm -f "$WORK_DIR/certificate.p12"
# Select this temporary keychain explicitly; do not change the search list.
codesign --force --options runtime --timestamp --keychain "$KEYCHAIN_PATH" \
    --sign "$SIGNING_IDENTITY" --entitlements "$INPUT_DIR/signing-entitlements.plist" \
    "$WORK_DIR/app/RippleClick.app"
codesign --verify --strict "$WORK_DIR/app/RippleClick.app"
printf '%s' "$NOTARY_API_KEY_P8_BASE64" | base64 --decode > "$WORK_DIR/notary.p8"
export NOTARY_API_KEY_PATH="$WORK_DIR/notary.p8"
unset DEVELOPER_ID_CERT_P12_BASE64 DEVELOPER_ID_CERT_PASSWORD NOTARY_API_KEY_P8_BASE64
bash "$(dirname "$0")/../notarize.sh" "$WORK_DIR/app/RippleClick.app"
codesign --verify --strict "$WORK_DIR/app/RippleClick.app"
mkdir -p "$OUTPUT_DIR"
ditto -c -k --keepParent "$WORK_DIR/app/RippleClick.app" "$OUTPUT_DIR/RippleClick-$VERSION.zip"
cp "$INPUT_DIR/release-notes.md" "$OUTPUT_DIR/release-notes.md"
SHA="$(shasum -a 256 "$OUTPUT_DIR/RippleClick-$VERSION.zip" | awk '{print $1}')"
printf 'sha256=%s\n' "$SHA" >> "$GITHUB_OUTPUT"
