# Build Guide

## Scope

This guide documents the reproducible LoongArch64 source build for Codex CLI
`0.135.0`.

## What is different from official Linux builds

Official Linux release assets are built for:

- `x86_64-unknown-linux-musl`
- `aarch64-unknown-linux-musl`

The LoongArch64 build here is currently based on:

- `loongarch64-unknown-linux-gnu`

That means two important differences:

- it uses a glibc runtime, not musl
- the V8 and final-link paths need LoongArch64-specific handling

## Prerequisites

Minimum required host tools:

- `git`
- `curl`
- `tar`
- `patch`
- `python3`
- `clang` / `clang++`
- `ld.lld`
- `ccache` (recommended)
- `rg`
- `bwrap`
- Node.js 22 or newer

Known-good local assumptions used during the successful build:

- system clang 19
- system lld 19
- local nightly Rust sysroot for `rusty_v8`
- final Codex link performed with `clang + lld`

## Build flow

1. `scripts/fetch-sources.sh`
   - downloads upstream Codex release source tarball
   - clones `rusty_v8` Git source at `v147.4.0`
   - downloads `seccompiler 0.5.0`
2. `scripts/apply-patches.sh`
   - applies upstream Codex LoongArch patches
   - applies `seccompiler` LoongArch support patch
   - applies `rusty_v8` / Chromium compatibility patch set
   - injects local path overrides into `codex-rs/Cargo.toml`
3. `scripts/build-codex-loongarch64.sh`
   - configures V8 source build environment
   - builds Codex CLI in release mode
   - uses `clang + lld` for the final binary link

## Key pitfalls that this repo handles

- Upstream release source defaults to `0.0.0` unless the workspace version is
  patched.
- `seccompiler 0.5.0` does not support `loongarch64` out of the box.
- `rusty_v8` prebuilt artifacts for LoongArch64 are unavailable.
- crates.io `v8` source tarball is insufficient for this source-build path;
  the Git checkout is required.
- Chromium Rust and Clang assumptions require local compatibility adjustments.
- The final Codex binary can overflow GNU `ld` relocations on LoongArch64.
  This repo therefore uses `clang` with `-fuse-ld=lld` for the final link.

## Expected build output

Primary output:

- `work/build/target-codex-0.135.0/release/codex`

The script prints the final path after a successful build.
