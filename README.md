# Codex LoongArch64 Build Repo

This repository is a maintainable build-and-release workspace for an unofficial
LoongArch64 Linux port of OpenAI Codex CLI.

Project repository:

- https://github.com/LaurenIsACoder/codex-loongarch64-build

It is designed to solve two separate problems:

1. Reproduce the LoongArch64 build from upstream source, including the V8 and
   linker issues that do not exist on officially released architectures.
2. Produce release assets that look and behave closer to official Codex
   platform releases, instead of shipping only a bare binary.

## Current target

- Upstream release: `rust-v0.147.0`
- CLI version: `codex-cli 0.147.0`
- Architecture: `loongarch64-unknown-linux-musl`
- V8 crate: `150.4.0`
- Code model: `medium` (`-C code-model=medium`)
- Final binary linker strategy: local `clang + lld`, static musl

The Codex entrypoint does not directly link V8, but the canonical package must
also ship `codex-code-mode-host`, whose runtime depends on `rusty_v8 150.4.0`.
The build and release checks treat the entrypoint and host as one group, so an
ordinary CLI smoke test cannot hide a missing Code Mode companion.

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
cd <your-clone-dir>/codex-loongarch64-build-repo
scripts/setup-local-toolchains.sh
scripts/fetch-sources.sh
scripts/apply-patches.sh
scripts/build-codex-loongarch64.sh
scripts/build-ripgrep-loongarch64.sh
scripts/package-release.sh
```

The setup script downloads and extracts its compiler, musl sysroot, Rust,
Node.js, GN, Ninja, and native libraries below this repository's ignored
`toolchains/` directory. It does not install packages or replace files in
system directories. For V8 it also verifies Chromium's pinned Rust archive,
uses only its architecture-independent vendored stdlib sources, and pairs them
with a repository-local native LoongArch64 Rust compiler; no x86_64 tool from
that archive is executed.

## One-click system install

Install the latest released package system-wide:

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash
```

Install a specific release tag system-wide:

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash -s -- --release v0.147.0-loongarch64-musl.1
```

## Previous releases

### v0.144.1

See [release/RELEASE_NOTES_v0.144.1-loongarch64.1.md](release/RELEASE_NOTES_v0.144.1-loongarch64.1.md).

### v0.142.4

### v0.142.2

### v0.142.0

See [release/RELEASE_NOTES_v0.142.0-loongarch64.1.md](release/RELEASE_NOTES_v0.142.0-loongarch64.1.md).

### v0.140.0

See [release/RELEASE_NOTES_v0.140.0-loongarch64.1.md](release/RELEASE_NOTES_v0.140.0-loongarch64.1.md).

### v0.135.0

See [release/RELEASE_NOTES_v0.135.0-loongarch64.1.md](release/RELEASE_NOTES_v0.135.0-loongarch64.1.md).

## Intended release assets

Expected assets for `0.147.0`:

- `codex-loongarch64-unknown-linux-musl`
- `codex-loongarch64-unknown-linux-musl.tar.gz`
- `codex-code-mode-host-loongarch64-unknown-linux-musl`
- `codex-code-mode-host-loongarch64-unknown-linux-musl.tar.gz`
- `codex-package-loongarch64-unknown-linux-musl.tar.gz`
- `codex-package_SHA256SUMS`
- `SHA256SUMS`
- `VERSION.txt`
- `ldd.txt`

The direct binary asset follows the naming style of official Codex releases.
The package archive follows the canonical Codex package directory layout with
`bin/`, `codex-resources/`, `codex-path/`, and `codex-package.json`;
`bin/` contains both `codex` and `codex-code-mode-host`.

## Why this repo exists

Official Codex releases currently ship Linux assets for `x86_64` and `aarch64`,
but not `loongarch64`. Building on LoongArch64 required custom work in four
places:

- upstream `codex-rs` version metadata and Linux sandbox target selection
- `seccompiler` support for `loongarch64`
- `rusty_v8` source-build path and Chromium Rust/toolchain assumptions
- fully static musl linking on LoongArch64 with a local sysroot and `lld`

Those changes are documented and packaged here so future builds are repeatable.

## Current status

The `0.147.0` static-musl Codex, Code Mode host, bubblewrap, and ripgrep are
built and verified as a release group on native LoongArch64. Packaging rejects
dynamic executables, then extracts the archive and runs a Code Mode IPC and
JavaScript smoke test.

See [VERSION.txt](./VERSION.txt) for the build target metadata and
[docs/build.md](./docs/build.md) plus [docs/release.md](./docs/release.md) for
full instructions.

Chinese documentation is available in [README.zh-CN.md](./README.zh-CN.md).
