#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
local_bin=${LOCAL_BIN:-$repo_root/toolchains/bin}
musl_sysroot=${MUSL_SYSROOT:-$repo_root/toolchains/musl-sysroot}
target_triple=${TARGET_TRIPLE:-loongarch64-unknown-linux-musl}
gcc_runtime_dir=${GCC_RUNTIME_DIR:-$(dirname "$(gcc -print-libgcc-file-name)")}

driver=clang
if [[ "$(basename "$0")" == *++* ]]; then
  driver=clang++
fi

exec "$local_bin/$driver" \
  "--target=$target_triple" \
  "--sysroot=$musl_sysroot" \
  "-B$gcc_runtime_dir" \
  "-L$gcc_runtime_dir" \
  "$@"
