#!/bin/bash
# Create a self-signed certificate for code signing RippleClick.
# This allows macOS TCC to remember accessibility permissions across updates.
#
# Usage: bash scripts/create-signing-cert.sh
#
# After running, build with:
#   SIGNING_IDENTITY="RippleClick Development" bash scripts/bundle.sh

set -euo pipefail

CERT_NAME="RippleClick Development"
KEYCHAIN="login.keychain-db"

# Check if the certificate already exists
if security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
    echo "Certificate '$CERT_NAME' already exists."
    echo "To rebuild: bash scripts/bundle.sh with SIGNING_IDENTITY='$CERT_NAME'"
    exit 0
fi

# Create a temporary config for the certificate
TMPDIR_CERT=$(mktemp -d)
CERT_CONFIG="$TMPDIR_CERT/cert.cfg"
KEY_FILE="$TMPDIR_CERT/key.pem"
CERT_FILE="$TMPDIR_CERT/cert.pem"
P12_FILE="$TMPDIR_CERT/cert.p12"

cat > "$CERT_CONFIG" <<CFG
[req]
distinguished_name = req_dn
prompt = no

[req_dn]
CN = $CERT_NAME
O = RippleClick Development

[codesign]
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
CFG

echo "Creating self-signed code signing certificate: $CERT_NAME"

# Generate key + certificate (valid for 10 years)
openssl req -x509 -newkey rsa:2048 -noenc \
    -keyout "$KEY_FILE" -out "$CERT_FILE" \
    -days 3650 -config "$CERT_CONFIG" -extensions codesign 2>/dev/null

# Use macOS built-in LibreSSL for PKCS12 export (Homebrew OpenSSL 3.x
# generates PKCS12 with algorithms that macOS Keychain cannot import)
/usr/bin/openssl pkcs12 -export -inkey "$KEY_FILE" -in "$CERT_FILE" \
    -out "$P12_FILE" -passout pass:tmppass -name "$CERT_NAME"

security import "$P12_FILE" -k "$KEYCHAIN" -T /usr/bin/codesign -P "tmppass" -A

# Trust the self-signed certificate for code signing
security add-trusted-cert -p codeSign -k "$KEYCHAIN" "$CERT_FILE"

# Clean up temp files
rm -rf "$TMPDIR_CERT"

# Verify
echo ""
if security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
    echo "Done! Certificate '$CERT_NAME' is ready."
    echo ""
    echo "Build with:"
    echo "  SIGNING_IDENTITY='$CERT_NAME' bash scripts/bundle.sh"
else
    echo "ERROR: Certificate was not found after import."
    echo "Try creating it manually via Keychain Access > Certificate Assistant."
    exit 1
fi
