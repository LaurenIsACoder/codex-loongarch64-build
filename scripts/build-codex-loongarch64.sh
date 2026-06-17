#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_cmd python3
require_cmd clang
require_cmd clang++
require_cmd ld.lld
require_cmd rg
require_cmd bwrap
require_cmd cargo
require_cmd rustc
ensure_dirs

nightly_sysroot="$(resolve_nightly_sysroot)"

"$REPO_ROOT/scripts/fetch-sources.sh"
"$REPO_ROOT/scripts/apply-patches.sh"

# ── Toolchain override symlinks ──────────────────────────────────────────────
mkdir -p "$TOOLCHAIN_OVERRIDE_DIR"
ln -sfn /usr/bin/clang "$TOOLCHAIN_OVERRIDE_DIR/loongarch64-unknown-linux-gnu-gcc"
ln -sfn /usr/bin/clang++ "$TOOLCHAIN_OVERRIDE_DIR/loongarch64-unknown-linux-gnu-g++"

if [[ -n "$NODE_BIN_DIR" ]]; then
  export PATH="$TOOLCHAIN_OVERRIDE_DIR:$NODE_BIN_DIR:$PATH"
else
  export PATH="$TOOLCHAIN_OVERRIDE_DIR:$PATH"
fi
export CARGO_HOME="$CARGO_HOME_DIR"
export CARGO_TARGET_DIR="$CARGO_TARGET_DIR_CUSTOM"
export RUSTUP_TOOLCHAIN=1.95.0
export V8_FROM_SOURCE=1
unset DISABLE_CLANG
export CLANG_BASE_PATH="$CLANG_BASE_PATH"
export LIBCLANG_PATH="$LIBCLANG_PATH"
export PYTHON=python3
export CCACHE=/usr/bin/ccache
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++
unset RUSTC_STABLE_COMPAT
require_cmd node

export GN_ARGS="rust_sysroot_absolute=\"$nightly_sysroot\" rustc_version=\"$(nightly_rustc_version_id)\""

# ── Replace x86_64 rust-toolchain with native LoongArch binaries ─────────────
log "Replacing x86_64 rust-toolchain binaries with native LoongArch64"
rusty_v8_tl_bin="${RUSTY_V8_DIR}/third_party/rust-toolchain/bin"
rusty_v8_tl_lib="${RUSTY_V8_DIR}/third_party/rust-toolchain/lib"
native_stable_root="${HOME}/.rustup/toolchains/${STABLE_TOOLCHAIN}-loongarch64-unknown-linux-gnu"

if [[ -d "$rusty_v8_tl_bin" ]] && [[ -d "$native_stable_root" ]]; then
  if ! file "$rusty_v8_tl_bin/rustc" 2>/dev/null | grep -q 'LoongArch'; then
    log "  copying native rustc, rustdoc, cargo, cargo-clippy, cargo-fmt, clippy-driver"
    for tool in rustc rustdoc cargo cargo-clippy cargo-fmt clippy-driver; do
      cp "$native_stable_root/bin/$tool" "$rusty_v8_tl_bin/$tool" 2>/dev/null || true
    done
    cp "$native_stable_root/bin/rustfmt" "$rusty_v8_tl_bin/rustfmt" 2>/dev/null || true
    command -v bindgen >/dev/null 2>&1 && cp "$(command -v bindgen)" "$rusty_v8_tl_bin/bindgen" 2>/dev/null || true

    log "  replacing libclang with native LoongArch64"
    rm -f "$rusty_v8_tl_lib"/libclang.so* "$rusty_v8_tl_lib"/libclang-cpp.so*
    cp -L "$LIBCLANG_PATH"/libclang.so* "$rusty_v8_tl_lib/" 2>/dev/null || true
    cp -L "$LIBCLANG_PATH"/libclang-cpp.so* "$rusty_v8_tl_lib/" 2>/dev/null || true

    log "  copying Rust runtime libraries"
    rm -f "$rusty_v8_tl_lib"/librustc_driver*.so
    cp -L "$native_stable_root/lib"/librustc_driver*.so "$rusty_v8_tl_lib/" 2>/dev/null || true
    cp -a "$native_stable_root/lib/rustlib" "$rusty_v8_tl_lib/" 2>/dev/null || true
    log "  toolchain replacement done"
  else
    log "  rust-toolchain already LoongArch native, skipping"
  fi
fi

export LD_LIBRARY_PATH="$rusty_v8_tl_lib:${LD_LIBRARY_PATH:-}"

# ── Medium code model (avoids B26 relocation overflow on LoongArch64) ────────
export RUSTFLAGS="-C code-model=medium"
export "CFLAGS_${TARGET_TRIPLE//-/_}"="-mcmodel=medium"

log "Building Codex CLI ${CODEX_VERSION} for ${TARGET_TRIPLE}"
log "Using rusty_v8 nightly sysroot: $nightly_sysroot"
log "Code model: medium (-C code-model=medium)"
log ""

cd "$CODEX_SRC_DIR/codex-rs"

# ── Step 1: direct cargo build ───────────────────────────────────────────────
log "Attempting direct cargo build..."
if cargo build --release -p codex-cli --bin codex; then
  binary="$(codex_binary_path)"
  if [[ -x "$binary" ]]; then
    log "Direct build succeeded"
    log "Build finished: $binary"
    "$binary" --version
    exit 0
  fi
fi

# ── Step 2: fallback — clang + lld linker override ───────────────────────────
log "Direct build failed (likely GNU ld relocation overflow), retrying with clang + lld..."
cargo rustc --release -p codex-cli --bin codex -- -C linker=/usr/bin/clang -C link-arg=-fuse-ld=lld

binary="$(codex_binary_path)"
log "Build finished: $binary"
"$binary" --version
