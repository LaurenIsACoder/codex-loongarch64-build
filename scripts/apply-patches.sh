#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_cmd patch
require_cmd perl
ensure_dirs

STAMP_DIR="$WORK_ROOT/.stamps"
mkdir -p "$STAMP_DIR"

[[ -d "$CODEX_SRC_DIR" ]] || { echo "missing Codex source tree: $CODEX_SRC_DIR" >&2; exit 1; }
[[ -d "$RUSTY_V8_DIR" ]] || { echo "missing rusty_v8 source tree: $RUSTY_V8_DIR" >&2; exit 1; }
[[ -d "$SECCOMPILER_SRC_DIR" ]] || { echo "missing seccompiler source tree: $SECCOMPILER_SRC_DIR" >&2; exit 1; }

if [[ ! -f "$STAMP_DIR/codex.patch.applied" ]]; then
  log "Applying Codex patch"
  patch -d "$CODEX_SRC_DIR" -p1 < "$PATCH_CODEX"
  touch "$STAMP_DIR/codex.patch.applied"
fi

if [[ ! -f "$STAMP_DIR/seccompiler.patch.applied" ]]; then
  log "Applying seccompiler patch"
  patch -d "$SECCOMPILER_SRC_DIR" -p1 < "$PATCH_SECCOMPILER"
  touch "$STAMP_DIR/seccompiler.patch.applied"
fi

if [[ ! -f "$STAMP_DIR/rusty_v8.patch.applied" ]]; then
  log "Applying rusty_v8 patch"
  patch -d "$RUSTY_V8_DIR" -p1 < "$PATCH_RUSTY_V8"
  touch "$STAMP_DIR/rusty_v8.patch.applied"
fi

cargo_toml="$CODEX_SRC_DIR/codex-rs/Cargo.toml"
if ! grep -q '^seccompiler = { path = ' "$cargo_toml"; then
  log "Injecting local crate overrides into codex-rs/Cargo.toml"
  perl -0pi -e 's/\[patch\.crates-io\]\n/[patch.crates-io]\nseccompiler = { path = "'"$SECCOMPILER_SRC_DIR"'" }\nv8 = { path = "'"$RUSTY_V8_DIR"'" }\n/ unless /seccompiler = \{ path = /' "$cargo_toml"
fi

log "Patches applied"
