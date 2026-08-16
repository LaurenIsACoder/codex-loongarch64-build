#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

CODEX_VERSION=${CODEX_VERSION:-0.147.0}
CODEX_TAG=${CODEX_TAG:-rust-v${CODEX_VERSION}}
RUSTY_V8_VERSION=${RUSTY_V8_VERSION:-150.4.0}
SECCOMPILER_VERSION=${SECCOMPILER_VERSION:-0.5.0}
BINDGEN_CLI_VERSION=${BINDGEN_CLI_VERSION:-0.72.1}
TARGET_TRIPLE=${TARGET_TRIPLE:-loongarch64-unknown-linux-musl}

CODEX_TARBALL_URL=${CODEX_TARBALL_URL:-https://github.com/openai/codex/archive/refs/tags/${CODEX_TAG}.tar.gz}
RUSTY_V8_GIT_URL=${RUSTY_V8_GIT_URL:-https://github.com/denoland/rusty_v8.git}
SECCOMPILER_CRATE_URL=${SECCOMPILER_CRATE_URL:-https://static.crates.io/crates/seccompiler/seccompiler-${SECCOMPILER_VERSION}.crate}

WORK_ROOT=${WORK_ROOT:-$REPO_ROOT/work}
SRC_ROOT=${SRC_ROOT:-$WORK_ROOT/src}
CACHE_ROOT=${CACHE_ROOT:-$WORK_ROOT/cache}
BUILD_ROOT=${BUILD_ROOT:-$WORK_ROOT/build}
ARTIFACTS_ROOT=${ARTIFACTS_ROOT:-$REPO_ROOT/artifacts/v${CODEX_VERSION}}

CODEX_SRC_DIR=${CODEX_SRC_DIR:-$SRC_ROOT/codex-${CODEX_TAG}}
RUSTY_V8_DIR=${RUSTY_V8_DIR:-$SRC_ROOT/rusty_v8-v${RUSTY_V8_VERSION}}
SECCOMPILER_SRC_DIR=${SECCOMPILER_SRC_DIR:-$SRC_ROOT/seccompiler-${SECCOMPILER_VERSION}}
GIT_DEPS_ROOT=${GIT_DEPS_ROOT:-$SRC_ROOT/git-deps}
CROSSTERM_SRC_DIR=${CROSSTERM_SRC_DIR:-$GIT_DEPS_ROOT/crossterm}
NUCLEO_SRC_DIR=${NUCLEO_SRC_DIR:-$GIT_DEPS_ROOT/nucleo}
RULES_RUST_SRC_DIR=${RULES_RUST_SRC_DIR:-$GIT_DEPS_ROOT/rules_rust}
TOKIO_TUNGSTENITE_SRC_DIR=${TOKIO_TUNGSTENITE_SRC_DIR:-$GIT_DEPS_ROOT/tokio_tungstenite}
TUNGSTENITE_SRC_DIR=${TUNGSTENITE_SRC_DIR:-$GIT_DEPS_ROOT/tungstenite}

PATCH_CODEX=$REPO_ROOT/patches/openai-codex/0.135.0/0001-codex-0.135.0-version-and-loongarch-linux-sandbox.patch
PATCH_CODEX_0140=$REPO_ROOT/patches/openai-codex/0.140.0/0001-codex-0.140.0-add-loongarch64-and-riscv64-landlock.patch
PATCH_SECCOMPILER=$REPO_ROOT/patches/seccompiler/0.5.0/0001-seccompiler-0.5.0-add-loongarch64.patch
PATCH_RUSTY_V8=$REPO_ROOT/patches/rusty_v8/147.4.0/0001-rusty-v8-147.4.0-loongarch-clang19-compat.patch
PATCH_RUSTY_V8_0149=$REPO_ROOT/patches/rusty_v8/149.2.0/0001-rusty-v8-149.2.0-loongarch64-clang19-compat.patch
PATCH_CODEX_0147=$REPO_ROOT/patches/openai-codex/0.147.0/0001-codex-0.147.0-add-loongarch64-musl-support.patch
PATCH_RUSTY_V8_0150=$REPO_ROOT/patches/rusty_v8/150.4.0/0001-rusty-v8-150.4.0-loongarch64-musl.patch

NODE_BIN_DIR=${NODE_BIN_DIR:-}
STABLE_TOOLCHAIN=${STABLE_TOOLCHAIN:-1.95.0}
V8_RUST_TOOLCHAIN=${V8_RUST_TOOLCHAIN:-1.96.0}
CHROMIUM_RUST_REVISION=${CHROMIUM_RUST_REVISION:-4c4205163abcbd08948b3efab796c543ba1ea687}
CHROMIUM_RUST_SUB_REVISION=${CHROMIUM_RUST_SUB_REVISION:-4}
CHROMIUM_RUST_LLVM_REVISION=${CHROMIUM_RUST_LLVM_REVISION:-llvmorg-23-init-10931-g20b6ec66}
V8_RUST_SYSROOT=${V8_RUST_SYSROOT:-$REPO_ROOT/toolchains/rusty-v8-rust-sysroot-${V8_RUST_TOOLCHAIN}-${CHROMIUM_RUST_REVISION}-${CHROMIUM_RUST_SUB_REVISION}}
NIGHTLY_TOOLCHAIN=${NIGHTLY_TOOLCHAIN:-$V8_RUST_TOOLCHAIN}
NIGHTLY_SYSROOT=${NIGHTLY_SYSROOT:-}
LIBCLANG_PATH=${LIBCLANG_PATH:-$REPO_ROOT/toolchains/aosc-root/usr/lib/llvm-20/lib}
CLANG_BASE_PATH=${CLANG_BASE_PATH:-$REPO_ROOT/toolchains/aosc-root/usr/lib/llvm-20}
RUSTY_V8_TOOLCHAIN_BIN=$RUSTY_V8_DIR/third_party/rust-toolchain/bin
RUSTY_V8_TOOLCHAIN_LIB=$RUSTY_V8_DIR/third_party/rust-toolchain/lib
TOOLCHAIN_OVERRIDE_DIR=${TOOLCHAIN_OVERRIDE_DIR:-$WORK_ROOT/toolchain-overrides/bin}
CARGO_HOME_DIR=${CARGO_HOME_DIR:-$REPO_ROOT/toolchains/cargo}
CARGO_TARGET_DIR_CUSTOM=${CARGO_TARGET_DIR_CUSTOM:-$BUILD_ROOT/target-codex-${CODEX_VERSION}}
RUSTY_V8_BINDGEN_ROOT=${RUSTY_V8_BINDGEN_ROOT:-$REPO_ROOT/toolchains/rust-bindgen}

log() {
  printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

ensure_dirs() {
  mkdir -p "$SRC_ROOT" "$CACHE_ROOT" "$BUILD_ROOT" "$ARTIFACTS_ROOT" "$TOOLCHAIN_OVERRIDE_DIR"
}

resolve_nightly_sysroot() {
  if [[ -n "${NIGHTLY_SYSROOT:-}" ]]; then
    printf '%s\n' "$NIGHTLY_SYSROOT"
    return
  fi

  [[ -x "$V8_RUST_SYSROOT/bin/rustc" ]] || {
    echo "missing repository-local V8 Rust compiler: $V8_RUST_SYSROOT/bin/rustc" >&2
    echo "run scripts/setup-local-toolchains.sh first" >&2
    exit 1
  }
  [[ -d "$V8_RUST_SYSROOT/lib/rustlib/src/rust/library/vendor" ]] || {
    echo "missing Chromium-matched vendored Rust stdlib sources under: $V8_RUST_SYSROOT" >&2
    echo "run scripts/setup-local-toolchains.sh first" >&2
    exit 1
  }
  printf '%s\n' "$V8_RUST_SYSROOT"
}

nightly_rustc_version_id() {
  local sysroot ver hash
  sysroot="$(resolve_nightly_sysroot)"
  ver="$($sysroot/bin/rustc --version | awk 'NR==1{print $2}')"
  hash="$($sysroot/bin/rustc --version | awk 'NR==1{gsub(/[()]/, "", $3); print $3}')"
  printf '%s-%s\n' "$ver" "$hash"
}

codex_binary_path() {
  printf '%s/%s/release/codex\n' "$CARGO_TARGET_DIR_CUSTOM" "$TARGET_TRIPLE"
}
