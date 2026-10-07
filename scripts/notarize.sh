#!/bin/bash
# Notarize and staple a Developer ID signed RippleClick.app.
#
# Usage: bash scripts/notarize.sh [path/to/RippleClick.app]
#
# Requires an App Store Connect API key:
#   NOTARY_API_KEY_PATH  Path to the AuthKey_XXXXXXXXXX.p8 file
#   NOTARY_API_KEY_ID    Key ID (e.g. "ABC123DEFG")
#   NOTARY_API_ISSUER_ID Issuer ID (UUID)

set -euo pipefail

cd "$(dirname "$0")/.."

APP_PATH="${1:-RippleClick.app}"
: "${NOTARY_API_KEY_PATH:?NOTARY_API_KEY_PATH is required}"
: "${NOTARY_API_KEY_ID:?NOTARY_API_KEY_ID is required}"
: "${NOTARY_API_ISSUER_ID:?NOTARY_API_ISSUER_ID is required}"

# notarytool はバンドルを直接受け付けないため、ZIP にして提出します。
SUBMIT_ZIP="$(mktemp -d)/RippleClick-notarize.zip"
ditto -c -k --keepParent "$APP_PATH" "$SUBMIT_ZIP"

echo "Submitting ${APP_PATH} for notarization..."
xcrun notarytool submit "$SUBMIT_ZIP" \
    --key "$NOTARY_API_KEY_PATH" \
    --key-id "$NOTARY_API_KEY_ID" \
    --issuer "$NOTARY_API_ISSUER_ID" \
    --wait \
    --timeout 2h \
    --output-format json | tee "${SUBMIT_ZIP%.zip}.json"

STATUS=$(/usr/bin/plutil -extract status raw "${SUBMIT_ZIP%.zip}.json")
if [ "$STATUS" != "Accepted" ]; then
    SUBMISSION_ID=$(/usr/bin/plutil -extract id raw "${SUBMIT_ZIP%.zip}.json")
    echo "Notarization failed with status: ${STATUS}"
    xcrun notarytool log "$SUBMISSION_ID" \
        --key "$NOTARY_API_KEY_PATH" \
        --key-id "$NOTARY_API_KEY_ID" \
        --issuer "$NOTARY_API_ISSUER_ID"
    exit 1
fi

echo "Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"

# Gatekeeper が公証済みとして受け入れるかを確認します。
spctl --assess --type execute --verbose=2 "$APP_PATH"
echo "Notarization complete."
