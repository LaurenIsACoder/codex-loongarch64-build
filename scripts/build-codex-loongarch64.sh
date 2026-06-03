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

log "Building Codex CLI ${CODEX_VERSION} for ${TARGET_TRIPLE}"
log "Using rusty_v8 nightly sysroot: $nightly_sysroot"
log "Using final linker override: clang + lld"

cd "$CODEX_SRC_DIR/codex-rs"
cargo rustc --release -p codex-cli --bin codex -- -C linker=/usr/bin/clang -C link-arg=-fuse-ld=lld

binary="$(codex_binary_path)"
log "Build finished: $binary"
"$binary" --version
