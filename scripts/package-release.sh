#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_cmd tar
require_cmd sha256sum
require_cmd ldd
require_cmd rg
require_cmd bwrap
ensure_dirs

CODEX_BIN=${CODEX_BIN:-$(codex_binary_path)}
RG_BIN=${RG_BIN:-$(command -v rg)}
BWRAP_BIN=${BWRAP_BIN:-$(command -v bwrap)}
TARGET_NAME="codex-${TARGET_TRIPLE}"
PACKAGE_NAME="codex-package-${TARGET_TRIPLE}"
RELEASE_DIR="$ARTIFACTS_ROOT"
PACKAGE_DIR="$RELEASE_DIR/$PACKAGE_NAME"

[[ -x "$CODEX_BIN" ]] || { echo "missing built codex binary: $CODEX_BIN" >&2; exit 1; }
[[ -x "$RG_BIN" ]] || { echo "missing rg binary: $RG_BIN" >&2; exit 1; }
[[ -x "$BWRAP_BIN" ]] || { echo "missing bwrap binary: $BWRAP_BIN" >&2; exit 1; }

rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

version="$($CODEX_BIN --version | awk '{print $2}')"
raw_binary="$RELEASE_DIR/$TARGET_NAME"
cp "$CODEX_BIN" "$raw_binary"
chmod +x "$raw_binary"

tar -C "$RELEASE_DIR" -czf "$RELEASE_DIR/${TARGET_NAME}.tar.gz" "$TARGET_NAME"

mkdir -p "$PACKAGE_DIR/bin" "$PACKAGE_DIR/codex-resources" "$PACKAGE_DIR/codex-path"
cp "$CODEX_BIN" "$PACKAGE_DIR/bin/codex"
cp "$RG_BIN" "$PACKAGE_DIR/codex-path/rg"
cp "$BWRAP_BIN" "$PACKAGE_DIR/codex-resources/bwrap"
chmod +x "$PACKAGE_DIR/bin/codex" "$PACKAGE_DIR/codex-path/rg" "$PACKAGE_DIR/codex-resources/bwrap"
cat > "$PACKAGE_DIR/codex-package.json" <<JSON
{
  "layoutVersion": 1,
  "version": "$version",
  "target": "$TARGET_TRIPLE",
  "variant": "codex",
  "entrypoint": "bin/codex",
  "resourcesDir": "codex-resources",
  "pathDir": "codex-path"
}
JSON

tar -C "$PACKAGE_DIR" -czf "$RELEASE_DIR/${PACKAGE_NAME}.tar.gz" bin codex-resources codex-path codex-package.json

cat > "$RELEASE_DIR/VERSION.txt" <<EOF2
codex version:
$($CODEX_BIN --version)

target:
$TARGET_TRIPLE

build date:
$(date -u '+%Y-%m-%dT%H:%M:%SZ')

binary:
$TARGET_NAME
EOF2

ldd "$CODEX_BIN" > "$RELEASE_DIR/ldd.txt"
cp "$REPO_ROOT/README.md" "$RELEASE_DIR/README.md"
cp "$REPO_ROOT/README.zh-CN.md" "$RELEASE_DIR/README.zh-CN.md"
cp "$REPO_ROOT/scripts/install-system.sh" "$RELEASE_DIR/install-system.sh"
chmod +x "$RELEASE_DIR/install-system.sh"

(
  cd "$RELEASE_DIR"
  sha256sum     "$TARGET_NAME"     "${TARGET_NAME}.tar.gz"     "${PACKAGE_NAME}.tar.gz"     README.md README.zh-CN.md VERSION.txt ldd.txt install-system.sh     > SHA256SUMS
  sha256sum "${PACKAGE_NAME}.tar.gz" > codex-package_SHA256SUMS
)

log "Release assets written to $RELEASE_DIR"
log "  $raw_binary"
log "  $RELEASE_DIR/${TARGET_NAME}.tar.gz"
log "  $RELEASE_DIR/${PACKAGE_NAME}.tar.gz"
log "  $RELEASE_DIR/SHA256SUMS"
log "  $RELEASE_DIR/codex-package_SHA256SUMS"
