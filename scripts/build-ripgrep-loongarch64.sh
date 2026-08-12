#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

RIPGREP_VERSION=${RIPGREP_VERSION:-14.1.1}
TOOLCHAIN_ROOT=${TOOLCHAIN_ROOT:-$REPO_ROOT/toolchains}
LOCAL_BIN=${LOCAL_BIN:-$TOOLCHAIN_ROOT/bin}
AOSC_ROOT=${AOSC_ROOT:-$TOOLCHAIN_ROOT/aosc-root}
MUSL_SYSROOT=${MUSL_SYSROOT:-$TOOLCHAIN_ROOT/musl-sysroot}
RUSTUP_HOME=${RUSTUP_HOME:-$TOOLCHAIN_ROOT/rustup}
CARGO_HOME=${CARGO_HOME:-$TOOLCHAIN_ROOT/cargo}
RIPGREP_ROOT=${RIPGREP_ROOT:-$TOOLCHAIN_ROOT/ripgrep}
RIPGREP_TARGET_DIR=${RIPGREP_TARGET_DIR:-$BUILD_ROOT/target-ripgrep-$RIPGREP_VERSION-$TARGET_TRIPLE-page14}

export RUSTUP_HOME CARGO_HOME MUSL_SYSROOT TARGET_TRIPLE LOCAL_BIN
export PATH="$CARGO_HOME/bin:$LOCAL_BIN:$PATH"
export LD_LIBRARY_PATH="$AOSC_ROOT/usr/lib:$AOSC_ROOT/usr/lib/llvm-20/lib:${LD_LIBRARY_PATH:-}"
export RUSTUP_TOOLCHAIN=${RUSTUP_TOOLCHAIN:-$STABLE_TOOLCHAIN}
export CARGO_TARGET_DIR="$RIPGREP_TARGET_DIR"
# The registry cache lives below this Git repository. Prevent ripgrep's build
# script from mistaking the build repository commit for ripgrep's own revision.
export GIT_CEILING_DIRECTORIES="$TOOLCHAIN_ROOT"

require_cmd cargo
require_cmd gcc
require_cmd llvm-strip
[[ -f "$MUSL_SYSROOT/lib/libc.a" ]] || {
  echo "missing local musl sysroot: $MUSL_SYSROOT" >&2
  echo "run scripts/setup-local-toolchains.sh first" >&2
  exit 1
}

GCC_RUNTIME_DIR=${GCC_RUNTIME_DIR:-$(dirname "$(gcc -print-libgcc-file-name)")}
export GCC_RUNTIME_DIR
target_env_suffix=${TARGET_TRIPLE//-/_}
cargo_target_prefix="CARGO_TARGET_${TARGET_TRIPLE^^}"
cargo_target_prefix=${cargo_target_prefix//-/_}
musl_cc="$REPO_ROOT/scripts/loongarch64-musl-clang.sh"
export "CC_${target_env_suffix}=$musl_cc"
export "CXX_${target_env_suffix}=$musl_cc"
export "AR_${target_env_suffix}=$LOCAL_BIN/llvm-ar"
export "CFLAGS_${target_env_suffix}=-mcmodel=medium -pthread"
export "CXXFLAGS_${target_env_suffix}=-mcmodel=medium -pthread"
export "${cargo_target_prefix}_LINKER=$REPO_ROOT/scripts/loongarch64-musl-clang.sh"
export "${cargo_target_prefix}_RUSTFLAGS=-C code-model=medium -C target-feature=+crt-static -C link-arg=-fuse-ld=lld -C link-arg=-static"
# The build host uses 16 KiB pages. ripgrep selects jemalloc on 64-bit musl targets, so
# configure it for the actual kernel page size instead of the 4 KiB default.
export JEMALLOC_SYS_WITH_LG_PAGE=${JEMALLOC_SYS_WITH_LG_PAGE:-14}

log "Building ripgrep ${RIPGREP_VERSION} for ${TARGET_TRIPLE}"
cargo install ripgrep \
  --version "$RIPGREP_VERSION" \
  --locked \
  --target "$TARGET_TRIPLE" \
  --root "$RIPGREP_ROOT" \
  --force

llvm-strip --strip-debug --strip-unneeded "$RIPGREP_ROOT/bin/rg"
"$RIPGREP_ROOT/bin/rg" --version | head -n 1
log "Static ripgrep ready: $RIPGREP_ROOT/bin/rg"
