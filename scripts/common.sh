#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

CODEX_VERSION=${CODEX_VERSION:-0.144.1}
CODEX_TAG=${CODEX_TAG:-rust-v${CODEX_VERSION}}
RUSTY_V8_VERSION=${RUSTY_V8_VERSION:-149.2.0}
SECCOMPILER_VERSION=${SECCOMPILER_VERSION:-0.5.0}
TARGET_TRIPLE=${TARGET_TRIPLE:-loongarch64-unknown-linux-gnu}

CODEX_TARBALL_URL=${CODEX_TARBALL_URL:-https://github.com/openai/codex/archive/refs/tags/${CODEX_TAG}.tar.gz}
RUSTY_V8_GIT_URL=${RUSTY_V8_GIT_URL:-https://github.com/denoland/rusty_v8.git}
SECCOMPILER_CRATE_URL=${SECCOMPILER_CRATE_URL:-https://crates.io/api/v1/crates/seccompiler/${SECCOMPILER_VERSION}/download}

WORK_ROOT=${WORK_ROOT:-$REPO_ROOT/work}
SRC_ROOT=${SRC_ROOT:-$WORK_ROOT/src}
CACHE_ROOT=${CACHE_ROOT:-$WORK_ROOT/cache}
BUILD_ROOT=${BUILD_ROOT:-$WORK_ROOT/build}
ARTIFACTS_ROOT=${ARTIFACTS_ROOT:-$REPO_ROOT/artifacts/v${CODEX_VERSION}}

CODEX_SRC_DIR=${CODEX_SRC_DIR:-$SRC_ROOT/codex-${CODEX_TAG}}
RUSTY_V8_DIR=${RUSTY_V8_DIR:-$SRC_ROOT/rusty_v8-v${RUSTY_V8_VERSION}}
SECCOMPILER_SRC_DIR=${SECCOMPILER_SRC_DIR:-$SRC_ROOT/seccompiler-${SECCOMPILER_VERSION}}

PATCH_CODEX=$REPO_ROOT/patches/openai-codex/0.135.0/0001-codex-0.135.0-version-and-loongarch-linux-sandbox.patch
PATCH_CODEX_0140=$REPO_ROOT/patches/openai-codex/0.140.0/0001-codex-0.140.0-add-loongarch64-and-riscv64-landlock.patch
PATCH_SECCOMPILER=$REPO_ROOT/patches/seccompiler/0.5.0/0001-seccompiler-0.5.0-add-loongarch64.patch
PATCH_RUSTY_V8=$REPO_ROOT/patches/rusty_v8/147.4.0/0001-rusty-v8-147.4.0-loongarch-clang19-compat.patch
PATCH_RUSTY_V8_0149=$REPO_ROOT/patches/rusty_v8/149.2.0/0001-rusty-v8-149.2.0-loongarch64-clang19-compat.patch

NODE_BIN_DIR=${NODE_BIN_DIR:-}
NIGHTLY_TOOLCHAIN=${NIGHTLY_TOOLCHAIN:-nightly-2026-05-06-loongarch64-unknown-linux-gnu}
STABLE_TOOLCHAIN=${STABLE_TOOLCHAIN:-1.95.0}
NIGHTLY_SYSROOT=${NIGHTLY_SYSROOT:-}
LIBCLANG_PATH=${LIBCLANG_PATH:-/usr/lib/llvm-19/lib}
CLANG_BASE_PATH=${CLANG_BASE_PATH:-/usr}
RUSTY_V8_TOOLCHAIN_BIN=$RUSTY_V8_DIR/third_party/rust-toolchain/bin
RUSTY_V8_TOOLCHAIN_LIB=$RUSTY_V8_DIR/third_party/rust-toolchain/lib
TOOLCHAIN_OVERRIDE_DIR=${TOOLCHAIN_OVERRIDE_DIR:-$WORK_ROOT/toolchain-overrides/bin}
CARGO_HOME_DIR=${CARGO_HOME_DIR:-$WORK_ROOT/.cargo-home}
CARGO_TARGET_DIR_CUSTOM=${CARGO_TARGET_DIR_CUSTOM:-$BUILD_ROOT/target-codex-${CODEX_VERSION}}

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

  require_cmd rustup
  local rustc_path
  rustc_path="$(rustup which --toolchain "$NIGHTLY_TOOLCHAIN" rustc 2>/dev/null || true)"
  [[ -n "$rustc_path" ]] || {
    echo "unable to resolve nightly rust toolchain: $NIGHTLY_TOOLCHAIN" >&2
    echo "set NIGHTLY_SYSROOT explicitly or install the toolchain with rustup" >&2
    exit 1
  }
  printf '%s\n' "$(cd "$(dirname "$rustc_path")/.." && pwd)"
}

nightly_rustc_version_id() {
  local sysroot ver hash
  sysroot="$(resolve_nightly_sysroot)"
  ver="$($sysroot/bin/rustc --version | awk 'NR==1{print $2}')"
  hash="$($sysroot/bin/rustc --version | awk 'NR==1{gsub(/[()]/, "", $3); print $3}')"
  printf '%s-%s\n' "$ver" "$hash"
}

codex_binary_path() {
  printf '%s/release/codex\n' "$CARGO_TARGET_DIR_CUSTOM"
}
