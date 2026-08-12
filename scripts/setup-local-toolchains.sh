#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

TOOLCHAIN_ROOT=${TOOLCHAIN_ROOT:-$REPO_ROOT/toolchains}
DOWNLOAD_ROOT=$TOOLCHAIN_ROOT/downloads
DEB_ROOT=$DOWNLOAD_ROOT/debs
AOSC_ROOT=$TOOLCHAIN_ROOT/aosc-root
MUSL_PACKAGE_ROOT=$TOOLCHAIN_ROOT/musl-package
MUSL_SYSROOT=${MUSL_SYSROOT:-$TOOLCHAIN_ROOT/musl-sysroot}
LOCAL_BIN=$TOOLCHAIN_ROOT/bin
RUSTUP_HOME=${RUSTUP_HOME:-$TOOLCHAIN_ROOT/rustup}
CARGO_HOME=${CARGO_HOME:-$TOOLCHAIN_ROOT/cargo}
RUSTUP_DIST_SERVER=${RUSTUP_DIST_SERVER:-https://rsproxy.cn}
RUSTUP_UPDATE_ROOT=${RUSTUP_UPDATE_ROOT:-https://rsproxy.cn/rustup}
RUSTUP_INIT=$DOWNLOAD_ROOT/rustup-init-loongarch64-unknown-linux-gnu
LIBCAP_VERSION=2.75
LIBCAP_ROOT=$TOOLCHAIN_ROOT/libcap-$LIBCAP_VERSION
LIBCAP_PREFIX=$LIBCAP_ROOT/prefix
LIBCAP_TARBALL=$DOWNLOAD_ROOT/libcap-$LIBCAP_VERSION.tar.xz
LIBCAP_URL=https://mirrors.edge.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-$LIBCAP_VERSION.tar.xz
LIBCAP_SHA256=de4e7e064c9ba451d5234dd46e897d7c71c96a9ebf9a0c445bc04f4742d83632

mkdir -p "$DEB_ROOT" "$AOSC_ROOT" "$MUSL_PACKAGE_ROOT" "$LOCAL_BIN" "$RUSTUP_HOME" "$CARGO_HOME"

download_deb() {
  local package_spec=$1 package_name=${1%%=*}
  if ! compgen -G "$DEB_ROOT/${package_name}_*.deb" >/dev/null; then
    (cd "$DEB_ROOT" && apt-get download "$package_spec")
  fi
}

download_deb llvm-20=20.1.8-10
download_deb llvm-runtime-20=20.1.8-10
download_deb musl=1.2.6
download_deb ninja=1.13.2
download_deb nodejs-26=26.5.1
download_deb ccache=4.12.2
download_deb pkgconf=3.0.5
download_deb gn=1:0+git20260521
download_deb ada=3.4.2
download_deb hdrhistogram-c=0.11.8

for deb in "$DEB_ROOT"/*.deb; do
  marker="$AOSC_ROOT/.extracted-$(basename "$deb")"
  if [[ ! -e "$marker" ]]; then
    dpkg-deb -x "$deb" "$AOSC_ROOT"
    touch "$marker"
  fi
done

if [[ ! -f "$MUSL_PACKAGE_ROOT/opt/musl/lib/libc.a" ]]; then
  musl_deb=$(compgen -G "$DEB_ROOT/musl_*.deb" | head -n 1)
  dpkg-deb -x "$musl_deb" "$MUSL_PACKAGE_ROOT"
fi

if [[ ! -f "$MUSL_SYSROOT/lib/libc.a" ]]; then
  mkdir -p "$MUSL_SYSROOT"
  cp -a "$MUSL_PACKAGE_ROOT/opt/musl/." "$MUSL_SYSROOT/"
fi

for header_dir in linux asm asm-generic; do
  if [[ ! -e "$MUSL_SYSROOT/include/$header_dir" ]]; then
    cp -aL "/usr/include/$header_dir" "$MUSL_SYSROOT/include/$header_dir"
  fi
done

for pair in \
  "clang:$AOSC_ROOT/usr/bin/clang-20" \
  "clang++:$AOSC_ROOT/usr/bin/clang++-20" \
  "ld.lld:$AOSC_ROOT/usr/bin/ld.lld-20" \
  "lld:$AOSC_ROOT/usr/bin/lld-20" \
  "llvm-ar:$AOSC_ROOT/usr/bin/llvm-ar-20" \
  "llvm-nm:$AOSC_ROOT/usr/bin/llvm-nm-20" \
  "llvm-ranlib:$AOSC_ROOT/usr/bin/llvm-ranlib-20" \
  "llvm-strip:$AOSC_ROOT/usr/bin/llvm-strip-20" \
  "ninja:$AOSC_ROOT/usr/bin/ninja" \
  "gn:$AOSC_ROOT/usr/bin/gn" \
  "node:$AOSC_ROOT/usr/lib/node-26/bin/node" \
  "ccache:$AOSC_ROOT/usr/bin/ccache" \
  "pkgconf:$AOSC_ROOT/usr/bin/pkgconf" \
  "pkg-config:$AOSC_ROOT/usr/bin/pkg-config"; do
  name=${pair%%:*}
  target=${pair#*:}
  [[ -x "$target" ]]
  ln -sfn "$target" "$LOCAL_BIN/$name"
done

if [[ ! -f "$LIBCAP_PREFIX/lib/libcap.a" ]]; then
  if [[ ! -f "$LIBCAP_TARBALL" ]]; then
    curl -fL --retry 5 "$LIBCAP_URL" -o "$LIBCAP_TARBALL"
  fi
  printf '%s  %s\n' "$LIBCAP_SHA256" "$LIBCAP_TARBALL" | sha256sum -c -
  mkdir -p "$LIBCAP_ROOT/src" "$LIBCAP_PREFIX/lib/pkgconfig" \
    "$LIBCAP_PREFIX/include/linux" "$LIBCAP_PREFIX/include/sys"
  tar -xJf "$LIBCAP_TARBALL" -C "$LIBCAP_ROOT/src"
  GCC_RUNTIME_DIR=${GCC_RUNTIME_DIR:-$(dirname "$(gcc -print-libgcc-file-name)")}
  export LOCAL_BIN MUSL_SYSROOT GCC_RUNTIME_DIR TARGET_TRIPLE
  make -C "$LIBCAP_ROOT/src/libcap-$LIBCAP_VERSION/libcap" clean
  make -C "$LIBCAP_ROOT/src/libcap-$LIBCAP_VERSION/libcap" -j"$(nproc)" \
    CC="$REPO_ROOT/scripts/loongarch64-musl-clang.sh" \
    BUILD_CC=gcc AR="$LOCAL_BIN/llvm-ar" RANLIB="$LOCAL_BIN/llvm-ranlib"
  cp "$LIBCAP_ROOT/src/libcap-$LIBCAP_VERSION/libcap/libcap.a" "$LIBCAP_PREFIX/lib/libcap.a"
  cp "$LIBCAP_ROOT/src/libcap-$LIBCAP_VERSION/libcap/include/uapi/linux/capability.h" \
    "$LIBCAP_PREFIX/include/linux/capability.h"
  cp "$LIBCAP_ROOT/src/libcap-$LIBCAP_VERSION/libcap/include/sys/capability.h" \
    "$LIBCAP_PREFIX/include/sys/capability.h"
  sed \
    -e "s|@PREFIX@|$LIBCAP_PREFIX|g" \
    "$REPO_ROOT/scripts/libcap.pc.in" > "$LIBCAP_PREFIX/lib/pkgconfig/libcap.pc"
fi

if [[ ! -x "$RUSTUP_INIT" ]]; then
  curl -fL --retry 5 \
    "$RUSTUP_UPDATE_ROOT/dist/loongarch64-unknown-linux-gnu/rustup-init" \
    -o "$RUSTUP_INIT"
  chmod +x "$RUSTUP_INIT"
fi

export RUSTUP_HOME CARGO_HOME RUSTUP_DIST_SERVER RUSTUP_UPDATE_ROOT
export PATH="$CARGO_HOME/bin:$LOCAL_BIN:$PATH"
export LD_LIBRARY_PATH="$AOSC_ROOT/usr/lib:$AOSC_ROOT/usr/lib/llvm-20/lib:${LD_LIBRARY_PATH:-}"
cp "$REPO_ROOT/scripts/cargo-config.toml" "$CARGO_HOME/config.toml"

if [[ ! -x "$CARGO_HOME/bin/rustup" ]]; then
  "$RUSTUP_INIT" -y --no-modify-path --profile minimal --default-toolchain none
fi

rustup set auto-self-update disable
rustup toolchain install 1.95.0 --profile minimal --component rust-src --no-self-update
rustup target add --toolchain 1.95.0 "$TARGET_TRIPLE"

log "Local toolchains ready under $TOOLCHAIN_ROOT"
clang --version | head -n 1
ld.lld --version | head -n 1
node --version
rustc +1.95.0 --version
