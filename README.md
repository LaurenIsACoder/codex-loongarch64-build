# Codex LoongArch64 Build Repo

This repository is a maintainable build-and-release workspace for an unofficial
LoongArch64 Linux port of OpenAI Codex CLI.

It is designed to solve two separate problems:

1. Reproduce the LoongArch64 build from upstream source, including the V8 and
   linker issues that do not exist on officially released architectures.
2. Produce release assets that look and behave closer to official Codex
   platform releases, instead of shipping only a bare binary.

## Current target

- Upstream release: `rust-v0.135.0`
- CLI version: `codex-cli 0.135.0`
- Architecture: `loongarch64-unknown-linux-gnu`
- V8 crate: `147.4.0`
- Final binary linker strategy: `clang + lld`

## Repository layout

- `docs/`
  Build notes, release notes, and LoongArch-specific pitfalls.
- `patches/`
  Reusable patch files for upstream Codex, `seccompiler`, and `rusty_v8`.
- `scripts/`
  Fetch, patch, build, and release automation.
- `release/`
  Release note templates and upload checklist.
- `artifacts/`
  Generated release assets ready for upload. This directory is intentionally
  kept out of git history except for its README.

## Quick start

```bash
cd ~/AI/codex-loongarch64-build-repo
scripts/fetch-sources.sh
scripts/apply-patches.sh
scripts/build-codex-loongarch64.sh
scripts/package-release.sh
```

## Intended release assets

Expected assets for `0.135.0`:

- `codex-loongarch64-unknown-linux-gnu`
- `codex-loongarch64-unknown-linux-gnu.tar.gz`
- `codex-package-loongarch64-unknown-linux-gnu.tar.gz`
- `codex-package_SHA256SUMS`
- `SHA256SUMS`
- `VERSION.txt`
- `ldd.txt`

The direct binary asset follows the naming style of official Codex releases.
The package archive follows the canonical Codex package directory layout with
`bin/`, `codex-resources/`, `codex-path/`, and `codex-package.json`.

## Why this repo exists

Official Codex releases currently ship Linux assets for `x86_64` and `aarch64`,
but not `loongarch64`. Building on LoongArch64 required custom work in four
places:

- upstream `codex-rs` version metadata and Linux sandbox target selection
- `seccompiler` support for `loongarch64`
- `rusty_v8` source-build path and Chromium Rust/toolchain assumptions
- final binary linking on LoongArch64, where GNU `ld` overflowed and `lld`
  became necessary

Those changes are documented and packaged here so future builds are repeatable.

## Current status

See [VERSION.txt](./VERSION.txt) for the build target metadata and
[docs/build.md](./docs/build.md) plus [docs/release.md](./docs/release.md) for
full instructions.

Chinese documentation is available in [README.zh-CN.md](./README.zh-CN.md).
