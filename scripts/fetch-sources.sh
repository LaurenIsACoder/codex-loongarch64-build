#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_cmd curl
require_cmd tar
require_cmd git
ensure_dirs

codex_tarball="$CACHE_ROOT/${CODEX_TAG}.tar.gz"
if [[ ! -f "$codex_tarball" ]]; then
  log "Downloading Codex source tarball: $CODEX_TARBALL_URL"
  curl -L "$CODEX_TARBALL_URL" -o "$codex_tarball"
fi

if [[ ! -d "$CODEX_SRC_DIR" ]]; then
  log "Extracting Codex source to $CODEX_SRC_DIR"
  mkdir -p "$CODEX_SRC_DIR"
  tar -xzf "$codex_tarball" --strip-components=1 -C "$CODEX_SRC_DIR"
fi

if [[ ! -d "$RUSTY_V8_DIR/.git" ]]; then
  log "Cloning rusty_v8 v${RUSTY_V8_VERSION}"
  git clone --branch "v${RUSTY_V8_VERSION}" --depth 1 "$RUSTY_V8_GIT_URL" "$RUSTY_V8_DIR"
fi

if [[ -d "$RUSTY_V8_DIR/.git" ]]; then
  log "Initialising rusty_v8 submodules"
  cd "$RUSTY_V8_DIR"
  local submodules=(
    build buildtools v8
    third_party/icu third_party/abseil-cpp
    third_party/libc++/src third_party/libc++abi/src third_party/libunwind/src
    third_party/fp16/src third_party/highway/src third_party/dragonbox/src
    third_party/fast_float/src third_party/simdutf third_party/rust
    third_party/jinja2 third_party/markupsafe third_party/partition_alloc
    third_party/llvm-libc/src
  )
  for sm in "${submodules[@]}"; do
    if [[ ! -f "$sm/.git" ]] && [[ ! -d "$sm/.git" ]]; then
      git submodule update --init --depth 1 "$sm" 2>/dev/null || true
    fi
  done
  cd "$REPO_ROOT"
fi

seccompiler_tarball="$CACHE_ROOT/seccompiler-${SECCOMPILER_VERSION}.tar.gz"
if [[ ! -f "$seccompiler_tarball" ]]; then
  log "Downloading seccompiler ${SECCOMPILER_VERSION} crate"
  curl -L "$SECCOMPILER_CRATE_URL" -o "$seccompiler_tarball"
fi

if [[ ! -d "$SECCOMPILER_SRC_DIR" ]]; then
  log "Extracting seccompiler to $SECCOMPILER_SRC_DIR"
  mkdir -p "$SECCOMPILER_SRC_DIR"
  tar -xzf "$seccompiler_tarball" --strip-components=1 -C "$SECCOMPILER_SRC_DIR"
fi

log "Sources ready"
log "  Codex:       $CODEX_SRC_DIR"
log "  rusty_v8:    $RUSTY_V8_DIR"
log "  seccompiler: $SECCOMPILER_SRC_DIR"
