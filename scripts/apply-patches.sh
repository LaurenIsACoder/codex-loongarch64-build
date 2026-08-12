#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_cmd patch
require_cmd perl
ensure_dirs

STAMP_DIR="$WORK_ROOT/.stamps/${CODEX_VERSION}-${TARGET_TRIPLE}"
mkdir -p "$STAMP_DIR"

[[ -d "$CODEX_SRC_DIR" ]] || { echo "missing Codex source tree: $CODEX_SRC_DIR" >&2; exit 1; }
[[ -d "$RUSTY_V8_DIR" ]] || { echo "missing rusty_v8 source tree: $RUSTY_V8_DIR" >&2; exit 1; }
[[ -d "$SECCOMPILER_SRC_DIR" ]] || { echo "missing seccompiler source tree: $SECCOMPILER_SRC_DIR" >&2; exit 1; }

# ── select patch files by version ────────────────────────────────────────────
if [[ "$CODEX_VERSION" == "0.135.0" ]]; then
  CODEX_PATCH="$PATCH_CODEX"
  RUSTY_V8_PATCH="$PATCH_RUSTY_V8"
elif [[ "$CODEX_VERSION" == "0.147.0" ]]; then
  CODEX_PATCH="$PATCH_CODEX_0147"
  RUSTY_V8_PATCH="$PATCH_RUSTY_V8_0150"
else
  CODEX_PATCH="$PATCH_CODEX_0140"
  RUSTY_V8_PATCH="$PATCH_RUSTY_V8_0149"
fi

if [[ ! -f "$STAMP_DIR/codex.patch.applied" ]]; then
  log "Applying Codex patch"
  patch -d "$CODEX_SRC_DIR" -p1 < "$CODEX_PATCH"
  touch "$STAMP_DIR/codex.patch.applied"
fi

if [[ ! -f "$STAMP_DIR/seccompiler.patch.applied" ]]; then
  log "Applying seccompiler patch"
  patch -d "$SECCOMPILER_SRC_DIR" -p1 < "$PATCH_SECCOMPILER"
  touch "$STAMP_DIR/seccompiler.patch.applied"
fi

if [[ ! -f "$STAMP_DIR/rusty_v8.patch.applied" ]]; then
  log "Applying rusty_v8 patch"
  patch -d "$RUSTY_V8_DIR" -p1 < "$RUSTY_V8_PATCH"
  touch "$STAMP_DIR/rusty_v8.patch.applied"
fi

cargo_toml="$CODEX_SRC_DIR/codex-rs/Cargo.toml"
if ! grep -q '^seccompiler = { path = ' "$cargo_toml"; then
  log "Injecting local crate overrides into codex-rs/Cargo.toml"
  if [[ "$CODEX_VERSION" != "0.135.0" ]]; then
    # 0.140.0+ upstream already has crossterm, ratatui, tokio-tungstenite, tungstenite
    # Only need to add seccompiler and v8 local paths
    perl -0pi -e 's/\nv8 = \{ path.*\n//s' "$cargo_toml" 2>/dev/null || true
    SECCOMPILER_SRC_DIR="$SECCOMPILER_SRC_DIR" RUSTY_V8_DIR="$RUSTY_V8_DIR" perl -0pi -e '
      my $insert = "[patch.crates-io]\nseccompiler = { path = \"$ENV{SECCOMPILER_SRC_DIR}\" }\nv8 = { path = \"$ENV{RUSTY_V8_DIR}\" }\n";
      s/\[patch\.crates-io\]\n/$insert/ unless /seccompiler = \{ path = /;
    ' "$cargo_toml"
  else
    SECCOMPILER_SRC_DIR="$SECCOMPILER_SRC_DIR" RUSTY_V8_DIR="$RUSTY_V8_DIR" perl -0pi -e '
      my $insert = "[patch.crates-io]\nseccompiler = { path = \"$ENV{SECCOMPILER_SRC_DIR}\" }\nv8 = { path = \"$ENV{RUSTY_V8_DIR}\" }\n";
      s/\[patch\.crates-io\]\n/$insert/ unless /seccompiler = \{ path = /;
    ' "$cargo_toml"
  fi
fi

if [[ "$TARGET_TRIPLE" == *-musl ]]; then
  cargo_core_toml="$CODEX_SRC_DIR/codex-rs/core/Cargo.toml"
  if ! grep -q "target\.$TARGET_TRIPLE\.dependencies" "$cargo_core_toml"; then
    log "Adding vendored OpenSSL for $TARGET_TRIPLE"
    perl -0pi -e 's/(\[target\.aarch64-unknown-linux-musl\.dependencies\]\nopenssl-sys = \{ workspace = true, features = \["vendored"\] \}\n)/$1\n# Build OpenSSL from source for musl builds.\n[target.loongarch64-unknown-linux-musl.dependencies]\nopenssl-sys = { workspace = true, features = ["vendored"] }\n/' "$cargo_core_toml"
  fi
fi

if ! grep -Fq "crossterm = { path = \"$CROSSTERM_SRC_DIR\" }" "$cargo_toml"; then
  log "Replacing pinned Git dependencies with local checkouts"
  CROSSTERM_SRC_DIR="$CROSSTERM_SRC_DIR" \
  NUCLEO_SRC_DIR="$NUCLEO_SRC_DIR" \
  RULES_RUST_SRC_DIR="$RULES_RUST_SRC_DIR" \
  TOKIO_TUNGSTENITE_SRC_DIR="$TOKIO_TUNGSTENITE_SRC_DIR" \
  TUNGSTENITE_SRC_DIR="$TUNGSTENITE_SRC_DIR" perl -0pi -e '
    s{nucleo = \{ git = "[^"]+", rev = "[^"]+" \}}{nucleo = { path = "$ENV{NUCLEO_SRC_DIR}" }}g;
    s{runfiles = \{ git = "[^"]+", rev = "[^"]+" \}}{runfiles = { path = "$ENV{RULES_RUST_SRC_DIR}/rust/runfiles" }}g;
    s{crossterm = \{ git = "[^"]+", rev = "[^"]+" \}}{crossterm = { path = "$ENV{CROSSTERM_SRC_DIR}" }}g;
    s{tokio-tungstenite = \{ git = "[^"]+", rev = "[^"]+" \}}{tokio-tungstenite = { path = "$ENV{TOKIO_TUNGSTENITE_SRC_DIR}" }}g;
    s{tungstenite = \{ git = "[^"]+", rev = "[^"]+" \}}{tungstenite = { path = "$ENV{TUNGSTENITE_SRC_DIR}" }}g;
  ' "$cargo_toml"
fi

tokio_tungstenite_toml="$TOKIO_TUNGSTENITE_SRC_DIR/Cargo.toml"
if ! grep -Fq "path = \"$TUNGSTENITE_SRC_DIR\"" "$tokio_tungstenite_toml"; then
  log "Pointing tokio-tungstenite at the matching local tungstenite checkout"
  TUNGSTENITE_SRC_DIR="$TUNGSTENITE_SRC_DIR" perl -0pi -e '
    s{git = "https://github\.com/openai-oss-forks/tungstenite-rs"\nrev = "[^"]+"}{path = "$ENV{TUNGSTENITE_SRC_DIR}"}g;
  ' "$tokio_tungstenite_toml"
fi

log "Patches applied"
