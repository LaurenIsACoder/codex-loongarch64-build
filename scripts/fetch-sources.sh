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
  submodules=(
    build buildtools v8 tools/clang
    third_party/icu third_party/abseil-cpp
    third_party/libc++/src third_party/libc++abi/src third_party/libunwind/src
    third_party/fp16/src third_party/highway/src third_party/dragonbox/src
    third_party/fast_float/src third_party/simdutf third_party/rust
    third_party/jinja2 third_party/markupsafe third_party/partition_alloc
    third_party/llvm-libc/src
  )
  for sm in "${submodules[@]}"; do
    if [[ ! -e "$sm/.codex-source-ready" ]] && \
       [[ ! -f "$sm/.git" ]] && [[ ! -d "$sm/.git" ]]; then
      if ! git submodule update --init --depth 1 "$sm"; then
        log "Retrying full submodule fetch: $sm"
        git submodule update --init "$sm"
      fi
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

ensure_git_dependency() {
  local path=$1 url=$2 revision=$3
  local marker="$path/.codex-source-ready"
  if [[ -f "$marker" ]] && grep -Fxq "$revision" "$marker"; then
    return
  fi

  # Older build caches used an unversioned marker after stripping .git. Keep
  # that snapshot as a rollback aid, but never silently reuse it for a newer
  # pinned revision.
  if [[ -e "$path" && ! -d "$path/.git" ]]; then
    local stale_path="${path}.stale.$(date -u +%Y%m%dT%H%M%SZ)"
    log "Preserving stale dependency snapshot: $path -> $stale_path"
    mv "$path" "$stale_path"
  fi

  if [[ ! -d "$path/.git" ]]; then
    git clone --filter=blob:none --no-checkout "$url" "$path"
  fi
  if [[ -n "$(git -C "$path" status --porcelain)" ]]; then
    echo "refusing to replace modified dependency checkout: $path" >&2
    exit 1
  fi
  if ! git -C "$path" checkout --detach "$revision"; then
    git -C "$path" fetch --depth 1 origin "$revision"
    git -C "$path" checkout --detach FETCH_HEAD
  fi
  printf '%s\n' "$revision" > "$marker"
}

ensure_git_dependency "$CROSSTERM_SRC_DIR" \
  https://github.com/openai-oss-forks/crossterm \
  45fecb9508105988f42fe6ff0441783ed3717f92
ensure_git_dependency "$NUCLEO_SRC_DIR" \
  https://github.com/helix-editor/nucleo.git \
  4253de9faabb4e5c6d81d946a5e35a90f87347ee
ensure_git_dependency "$RULES_RUST_SRC_DIR" \
  https://github.com/dzbarsky/rules_rust \
  b56cbaa8465e74127f1ea216f813cd377295ad81
ensure_git_dependency "$TOKIO_TUNGSTENITE_SRC_DIR" \
  https://github.com/openai-oss-forks/tokio-tungstenite \
  0e5b2d73aa18dd9f0a50ee9ff199d5aef7594186
ensure_git_dependency "$TUNGSTENITE_SRC_DIR" \
  https://github.com/openai-oss-forks/tungstenite-rs \
  4fffad30fe373adbdcffab9545e9e9bf4f2fc19f

log "Sources ready"
log "  Codex:       $CODEX_SRC_DIR"
log "  rusty_v8:    $RUSTY_V8_DIR"
log "  seccompiler: $SECCOMPILER_SRC_DIR"
log "  git deps:    $GIT_DEPS_ROOT"
