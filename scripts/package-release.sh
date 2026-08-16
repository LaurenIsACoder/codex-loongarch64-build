#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_cmd tar
require_cmd sha256sum
require_cmd ldd
require_cmd file
require_cmd readelf
ensure_dirs

TOOLCHAIN_ROOT=${TOOLCHAIN_ROOT:-$REPO_ROOT/toolchains}
CODEX_BIN=${CODEX_BIN:-$(codex_binary_path)}
CODE_MODE_HOST_BIN=${CODE_MODE_HOST_BIN:-$CARGO_TARGET_DIR_CUSTOM/$TARGET_TRIPLE/release/codex-code-mode-host}
RG_BIN=${RG_BIN:-$TOOLCHAIN_ROOT/ripgrep/bin/rg}
BWRAP_BIN=${BWRAP_BIN:-$CARGO_TARGET_DIR_CUSTOM/$TARGET_TRIPLE/release/bwrap}
STRIP_BIN=${STRIP_BIN:-$TOOLCHAIN_ROOT/bin/llvm-strip}
TARGET_NAME="codex-${TARGET_TRIPLE}"
HOST_TARGET_NAME="codex-code-mode-host-${TARGET_TRIPLE}"
PACKAGE_NAME="codex-package-${TARGET_TRIPLE}"
RELEASE_DIR="$ARTIFACTS_ROOT"
PACKAGE_DIR="$RELEASE_DIR/$PACKAGE_NAME"

[[ -x "$CODEX_BIN" ]] || { echo "missing built codex binary: $CODEX_BIN" >&2; exit 1; }
[[ -x "$CODE_MODE_HOST_BIN" ]] || {
  echo "missing built Code Mode host: $CODE_MODE_HOST_BIN" >&2
  echo "run scripts/build-codex-loongarch64.sh first" >&2
  exit 1
}
[[ -x "$RG_BIN" ]] || {
  echo "missing static rg binary: $RG_BIN" >&2
  echo "run scripts/build-ripgrep-loongarch64.sh first" >&2
  exit 1
}
[[ -x "$BWRAP_BIN" ]] || { echo "missing bwrap binary: $BWRAP_BIN" >&2; exit 1; }
[[ -x "$STRIP_BIN" ]] || { echo "missing llvm-strip: $STRIP_BIN" >&2; exit 1; }

verify_static_elf() {
  local binary=$1
  file "$binary" | grep -q 'statically linked' || {
    echo "expected a statically linked ELF binary: $binary" >&2
    file "$binary" >&2
    exit 1
  }
  if readelf -lW "$binary" | grep -q ' INTERP '; then
    echo "unexpected ELF interpreter in $binary" >&2
    exit 1
  fi
  if readelf -dW "$binary" 2>/dev/null | grep -q '(NEEDED)'; then
    echo "unexpected dynamic dependency in $binary" >&2
    exit 1
  fi
}

verify_static_elf "$CODEX_BIN"
verify_static_elf "$CODE_MODE_HOST_BIN"
verify_static_elf "$RG_BIN"
verify_static_elf "$BWRAP_BIN"

rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

version="$($CODEX_BIN --version | awk '{print $2}')"
raw_binary="$RELEASE_DIR/$TARGET_NAME"
cp "$CODEX_BIN" "$raw_binary"
chmod +x "$raw_binary"
"$STRIP_BIN" --strip-debug --strip-unneeded "$raw_binary"

raw_host_binary="$RELEASE_DIR/$HOST_TARGET_NAME"
cp "$CODE_MODE_HOST_BIN" "$raw_host_binary"
chmod +x "$raw_host_binary"
"$STRIP_BIN" --strip-debug --strip-unneeded "$raw_host_binary"

tar --owner=0 --group=0 --numeric-owner \
  -C "$RELEASE_DIR" -czf "$RELEASE_DIR/${TARGET_NAME}.tar.gz" "$TARGET_NAME"
tar --owner=0 --group=0 --numeric-owner \
  -C "$RELEASE_DIR" -czf "$RELEASE_DIR/${HOST_TARGET_NAME}.tar.gz" "$HOST_TARGET_NAME"

mkdir -p "$PACKAGE_DIR/bin" "$PACKAGE_DIR/codex-resources" "$PACKAGE_DIR/codex-path"
cp "$raw_binary" "$PACKAGE_DIR/bin/codex"
cp "$raw_host_binary" "$PACKAGE_DIR/bin/codex-code-mode-host"
cp "$RG_BIN" "$PACKAGE_DIR/codex-path/rg"
cp "$BWRAP_BIN" "$PACKAGE_DIR/codex-resources/bwrap"
chmod +x \
  "$PACKAGE_DIR/bin/codex" \
  "$PACKAGE_DIR/bin/codex-code-mode-host" \
  "$PACKAGE_DIR/codex-path/rg" \
  "$PACKAGE_DIR/codex-resources/bwrap"
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

tar --owner=0 --group=0 --numeric-owner \
  -C "$PACKAGE_DIR" -czf "$RELEASE_DIR/${PACKAGE_NAME}.tar.gz" \
  bin codex-resources codex-path codex-package.json
"$REPO_ROOT/scripts/verify-release.sh" "$RELEASE_DIR/${PACKAGE_NAME}.tar.gz"

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

ldd "$CODEX_BIN" > "$RELEASE_DIR/ldd.txt" 2>&1 || true
cp "$REPO_ROOT/README.md" "$RELEASE_DIR/README.md"
cp "$REPO_ROOT/README.zh-CN.md" "$RELEASE_DIR/README.zh-CN.md"
cp "$REPO_ROOT/scripts/install-system.sh" "$RELEASE_DIR/install-system.sh"
chmod +x "$RELEASE_DIR/install-system.sh"

(
  cd "$RELEASE_DIR"
  sha256sum     "$TARGET_NAME"     "${TARGET_NAME}.tar.gz"     "$HOST_TARGET_NAME"     "${HOST_TARGET_NAME}.tar.gz"     "${PACKAGE_NAME}.tar.gz"     README.md README.zh-CN.md VERSION.txt ldd.txt install-system.sh     > SHA256SUMS
  sha256sum "${PACKAGE_NAME}.tar.gz" > codex-package_SHA256SUMS
)

log "Release assets written to $RELEASE_DIR"
log "  $raw_binary"
log "  $raw_host_binary"
log "  $RELEASE_DIR/${HOST_TARGET_NAME}.tar.gz"
log "  $RELEASE_DIR/${TARGET_NAME}.tar.gz"
log "  $RELEASE_DIR/${PACKAGE_NAME}.tar.gz"
log "  $RELEASE_DIR/SHA256SUMS"
log "  $RELEASE_DIR/codex-package_SHA256SUMS"
