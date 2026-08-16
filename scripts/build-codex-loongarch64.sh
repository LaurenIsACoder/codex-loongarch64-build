#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

TOOLCHAIN_ROOT=${TOOLCHAIN_ROOT:-$REPO_ROOT/toolchains}
LOCAL_BIN=${LOCAL_BIN:-$TOOLCHAIN_ROOT/bin}
AOSC_ROOT=${AOSC_ROOT:-$TOOLCHAIN_ROOT/aosc-root}
MUSL_SYSROOT=${MUSL_SYSROOT:-$TOOLCHAIN_ROOT/musl-sysroot}
LIBCAP_PREFIX=${LIBCAP_PREFIX:-$TOOLCHAIN_ROOT/libcap-2.75/prefix}
RUSTUP_HOME=${RUSTUP_HOME:-$TOOLCHAIN_ROOT/rustup}
CARGO_HOME_DIR=${CARGO_HOME_DIR:-$TOOLCHAIN_ROOT/cargo}
export RUSTUP_HOME
export PATH="$CARGO_HOME_DIR/bin:$LOCAL_BIN:$PATH"
export LD_LIBRARY_PATH="$AOSC_ROOT/usr/lib:$AOSC_ROOT/usr/lib/llvm-20/lib:${LD_LIBRARY_PATH:-}"

require_cmd python3
require_cmd clang
require_cmd clang++
require_cmd ld.lld
require_cmd ninja
require_cmd gn
require_cmd pkg-config
require_cmd cargo
require_cmd rustc
ensure_dirs

GCC_RUNTIME_DIR=${GCC_RUNTIME_DIR:-$(dirname "$(gcc -print-libgcc-file-name)")}
[[ -f "$MUSL_SYSROOT/lib/libc.a" ]] || {
  echo "missing local musl sysroot: $MUSL_SYSROOT" >&2
  echo "run scripts/setup-local-toolchains.sh first" >&2
  exit 1
}
[[ -f "$LIBCAP_PREFIX/lib/libcap.a" ]] || {
  echo "missing local musl libcap: $LIBCAP_PREFIX/lib/libcap.a" >&2
  echo "run scripts/setup-local-toolchains.sh first" >&2
  exit 1
}

nightly_sysroot="$(resolve_nightly_sysroot)"
[[ -x "$RUSTY_V8_BINDGEN_ROOT/bin/bindgen" ]] || {
  echo "missing local V8 bindgen: $RUSTY_V8_BINDGEN_ROOT/bin/bindgen" >&2
  echo "run scripts/setup-local-toolchains.sh first" >&2
  exit 1
}
[[ -x "$RUSTY_V8_BINDGEN_ROOT/bin/rustfmt" ]] || {
  echo "missing local V8 rustfmt: $RUSTY_V8_BINDGEN_ROOT/bin/rustfmt" >&2
  echo "run scripts/setup-local-toolchains.sh first" >&2
  exit 1
}
[[ -e "$RUSTY_V8_BINDGEN_ROOT/lib/libclang.so" ]] || {
  echo "missing local V8 libclang: $RUSTY_V8_BINDGEN_ROOT/lib/libclang.so" >&2
  echo "run scripts/setup-local-toolchains.sh first" >&2
  exit 1
}

"$REPO_ROOT/scripts/fetch-sources.sh"
"$REPO_ROOT/scripts/apply-patches.sh"

# ── Toolchain override symlinks ──────────────────────────────────────────────
mkdir -p "$TOOLCHAIN_OVERRIDE_DIR"
ln -sfn "$(command -v clang)" "$TOOLCHAIN_OVERRIDE_DIR/loongarch64-unknown-linux-gnu-gcc"
ln -sfn "$(command -v clang++)" "$TOOLCHAIN_OVERRIDE_DIR/loongarch64-unknown-linux-gnu-g++"
ln -sfn "$REPO_ROOT/scripts/loongarch64-musl-clang.sh" "$TOOLCHAIN_OVERRIDE_DIR/musl-clang"
ln -sfn "$REPO_ROOT/scripts/loongarch64-musl-clang.sh" "$TOOLCHAIN_OVERRIDE_DIR/musl-clang++"

if [[ -n "$NODE_BIN_DIR" ]]; then
  export PATH="$TOOLCHAIN_OVERRIDE_DIR:$NODE_BIN_DIR:$PATH"
else
  export PATH="$TOOLCHAIN_OVERRIDE_DIR:$PATH"
fi
export CARGO_HOME="$CARGO_HOME_DIR"
export CARGO_TARGET_DIR="$CARGO_TARGET_DIR_CUSTOM"
export CARGO_NET_GIT_FETCH_WITH_CLI=true
export CARGO_NET_RETRY=10
export CARGO_HTTP_TIMEOUT=600
export RUSTUP_TOOLCHAIN=1.95.0
export V8_FROM_SOURCE=1
export RUSTY_V8_MUSL_SYSROOT="$MUSL_SYSROOT"
export RUSTY_V8_RUST_TOOLCHAIN_ROOT="$nightly_sysroot"
unset DISABLE_CLANG
export CLANG_BASE_PATH="$CLANG_BASE_PATH"
export LIBCLANG_PATH="$LIBCLANG_PATH"
export PYTHON=python3
export CCACHE="$(command -v ccache)"
export CC="$(command -v clang)"
export CXX="$(command -v clang++)"
export AR="$(command -v llvm-ar)"
export NM="$(command -v llvm-nm)"
export NINJA="$(command -v ninja)"
unset RUSTC_STABLE_COMPAT
require_cmd node

clang_resource_version="$(basename "$(clang --print-resource-dir)")"
export GN_ARGS="rust_sysroot_absolute=\"$nightly_sysroot\" rustc_version=\"$(nightly_rustc_version_id)\" rust_bindgen_root=\"$RUSTY_V8_BINDGEN_ROOT\" clang_version=\"$clang_resource_version\" use_sysroot=false chrome_pgo_phase=0 fatal_linker_warnings=false treat_warnings_as_errors=false"

# Cargo ignores target-specific rustflags when the global RUSTFLAGS variable is
# set. Keep the global variable unset for musl so the target-only static-link
# flags below are actually applied (without applying them to host proc-macros).
if [[ "$TARGET_TRIPLE" == *-musl ]]; then
  unset RUSTFLAGS
  target_env_suffix=${TARGET_TRIPLE//-/_}
  cargo_target_prefix="CARGO_TARGET_${TARGET_TRIPLE^^}"
  cargo_target_prefix=${cargo_target_prefix//-/_}
  musl_cc="$TOOLCHAIN_OVERRIDE_DIR/musl-clang"
  musl_cxx="$TOOLCHAIN_OVERRIDE_DIR/musl-clang++"
  export MUSL_SYSROOT GCC_RUNTIME_DIR TARGET_TRIPLE LOCAL_BIN
  export "CC_${target_env_suffix}=$musl_cc"
  export "CXX_${target_env_suffix}=$musl_cxx"
  export "AR_${target_env_suffix}=$AR"
  export "CFLAGS_${target_env_suffix}=-mcmodel=medium -pthread"
  export "CXXFLAGS_${target_env_suffix}=-mcmodel=medium -pthread"
  export TARGET_CC="$musl_cc"
  export TARGET_CXX="$musl_cxx"
  export CMAKE_C_COMPILER="$musl_cc"
  export CMAKE_CXX_COMPILER="$musl_cxx"
  export CMAKE_ARGS="-DCMAKE_HAVE_THREADS_LIBRARY=1 -DCMAKE_USE_PTHREADS_INIT=1 -DCMAKE_THREAD_LIBS_INIT=-pthread -DTHREADS_PREFER_PTHREAD_FLAG=ON"
  export "${cargo_target_prefix}_LINKER=$musl_cc"
  export "${cargo_target_prefix}_RUSTFLAGS=-C code-model=medium -C target-feature=+crt-static -C link-arg=-fuse-ld=lld -C link-arg=-static"
  export PKG_CONFIG_ALLOW_CROSS=1
  export PKG_CONFIG_SYSROOT_DIR=/
  export PKG_CONFIG_PATH="$LIBCAP_PREFIX/lib/pkgconfig"
  export PKG_CONFIG_LIBDIR="$LIBCAP_PREFIX/lib/pkgconfig"
  export "PKG_CONFIG_PATH_${target_env_suffix}=$LIBCAP_PREFIX/lib/pkgconfig"
  export "PKG_CONFIG_LIBDIR_${target_env_suffix}=$LIBCAP_PREFIX/lib/pkgconfig"
  export "PKG_CONFIG_SYSROOT_DIR_${target_env_suffix}=/"
  export AWS_LC_SYS_NO_JITTER_ENTROPY=1
  export "AWS_LC_SYS_NO_JITTER_ENTROPY_${target_env_suffix}=1"
else
  # Medium code model avoids B26 relocation overflow on LoongArch64.
  export RUSTFLAGS="-C code-model=medium"
fi

log "Building Codex CLI ${CODEX_VERSION} for ${TARGET_TRIPLE}"
log "Using Chromium-matched rusty_v8 sysroot: $nightly_sysroot"
log "Code model: medium (-C code-model=medium)"
log ""

cd "$CODEX_SRC_DIR/codex-rs"

# Build and finalize the bundled bubblewrap first. Codex embeds this exact
# binary's digest and verifies it before use.
log "Building musl bubblewrap resource"
cargo build --release --target "$TARGET_TRIPLE" --bin bwrap
bwrap_binary="$CARGO_TARGET_DIR/$TARGET_TRIPLE/release/bwrap"
"$LOCAL_BIN/llvm-strip" --strip-debug --strip-unneeded "$bwrap_binary"
export CODEX_BWRAP_SHA256
CODEX_BWRAP_SHA256=$(sha256sum "$bwrap_binary" | awk '{print $1}')
log "Bundled bwrap sha256: $CODEX_BWRAP_SHA256"

# Build the entrypoint and its required Code Mode host in one Cargo invocation,
# matching upstream's package builder. The grouped graph also enables the
# vendored OpenSSL feature needed by fully static musl builds.
# Chromium's V8 build graph deliberately uses unstable rustc flags even with
# its stable-versioned toolchain. The official bundled compiler enables these;
# our local LoongArch compiler needs the equivalent scoped bootstrap switch.
export RUSTC_BOOTSTRAP=1
log "Building Codex CLI and codex-code-mode-host as one release group..."
cargo build --release --target "$TARGET_TRIPLE" \
  -p codex-cli --bin codex \
  -p codex-code-mode-host --bin codex-code-mode-host

binary="$(codex_binary_path)"
host_binary="$CARGO_TARGET_DIR/$TARGET_TRIPLE/release/codex-code-mode-host"
[[ -x "$binary" ]] || { echo "missing built codex binary: $binary" >&2; exit 1; }
[[ -x "$host_binary" ]] || {
  echo "missing built Code Mode host: $host_binary" >&2
  exit 1
}

log "Build finished: $binary"
log "Build finished: $host_binary"
"$binary" --version
"$host_binary" --help >/dev/null
