# Codex CLI for LoongArch64 Linux

This is an unofficial community build of Codex CLI for LoongArch64 Linux.

## Build Information

- Package: Codex CLI
- Version: codex-cli 0.0.0
- Target: loongarch64-unknown-linux-gnu
- Build type: Unofficial community build
- Build contributor: Hanlu Li (@LaurenIsACoder)

## Contribution

This build was contributed as a LoongArch64 Linux community build.

The contributor completed the local LoongArch64 build of Codex CLI, including adapting the rusty_v8 / V8 v147.4.0 source build process and resolving toolchain issues involving Rust sysroot, bindgen, libclang, clang/lld, and LoongArch64 linker behavior.

Main contribution:

- Built Codex CLI on loongarch64 Linux
- Adapted rusty_v8 / V8 v147.4.0 source build for loongarch64
- Fixed build issues related to Rust sysroot and Chromium Rust toolchain assumptions
- Replaced incompatible prebuilt bindgen/libclang usage with local LoongArch64-compatible tooling
- Resolved clang/lld and LoongArch64 linker issues during final binary linking
- Produced a runnable Codex CLI binary for LoongArch64 Linux

## Package Contents

- `codex` - Codex CLI executable
- `README.md` - English documentation
- `README.zh-CN.md` - Chinese documentation
- `VERSION.txt` - Build and version metadata
- `ldd.txt` - Runtime dynamic library dependency list from the build machine
- `SHA256SUMS` - SHA256 checksums

## Runtime Dependencies

This package does not require Rust, Cargo, LLVM, Ninja, or a V8 build environment to run.

It requires a compatible LoongArch64 Linux runtime environment.

Expected runtime libraries:

- libc6
- libgcc-s1
- zlib1g
- libssl3
- libzstd1

On Debian/Loongnix-like systems, install dependencies with:

```bash
sudo apt install -y libc6 libgcc-s1 zlib1g libssl3 libzstd1
