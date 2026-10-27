#!/bin/bash
# The existing tap credential is step-scoped and never persisted in a remote URL.
set -euo pipefail
umask 077
VERSION="$1"
SHA="$2"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 2
[[ "$SHA" =~ ^[0-9a-f]{64}$ ]] || exit 2
: "${GH_TOKEN:?The existing HOMEBREW_TAP_TOKEN is required}"
WORK_DIR="$(mktemp -d "$RUNNER_TEMP/ripple-tap.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
cat > "$WORK_DIR/askpass.sh" <<'ASKPASS'
#!/bin/bash
case "$1" in
    *Username*) printf '%s\n' 'x-access-token' ;;
    *Password*) printf '%s\n' "$GH_TOKEN" ;;
    *) exit 1 ;;
esac
ASKPASS
chmod 700 "$WORK_DIR/askpass.sh"
export GIT_ASKPASS="$WORK_DIR/askpass.sh" GIT_TERMINAL_PROMPT=0
# Empty helper overrides prevent credential persistence. Auth failures stop here.
git -c credential.helper= clone https://github.com/0xmokuren/homebrew-tap.git "$WORK_DIR/repo"
cd "$WORK_DIR/repo"
python3 - "$VERSION" "$SHA" <<'PY'
import pathlib, re, sys
path = pathlib.Path('Casks/rippleclick.rb')
text = path.read_text()
for key, value in [('version', sys.argv[1]), ('sha256', sys.argv[2])]:
    text, count = re.subn(r'(?m)^(\s*' + key + r'\s+")[^"]*("\s*)$', lambda m: m[1] + value + m[2], text)
    if count != 1:
        raise SystemExit('Expected exactly one cask ' + key)
path.write_text(text)
PY
if git diff --quiet -- Casks/rippleclick.rb; then
    echo 'Homebrew cask is already current.'
    exit 0
fi
git config user.name 'github-actions[bot]'
git config user.email 'github-actions[bot]@users.noreply.github.com'
git add Casks/rippleclick.rb
git commit -m "Update RippleClick to v$VERSION"
git -c credential.helper= push
