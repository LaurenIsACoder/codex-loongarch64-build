# Release Guide

## Goal

Publish LoongArch64 Codex in a way that feels closer to official Codex release
assets.

## Release asset strategy

This repo produces two release layers.

### 1. Direct binary assets

Planned asset names:

- `codex-loongarch64-unknown-linux-musl`
- `codex-loongarch64-unknown-linux-musl.tar.gz`
- `codex-code-mode-host-loongarch64-unknown-linux-musl`
- `codex-code-mode-host-loongarch64-unknown-linux-musl.tar.gz`

The `.tar.gz` archive should contain a single file named
`codex-loongarch64-unknown-linux-musl`.

### 2. Package archive assets

Planned asset names:

- `codex-package-loongarch64-unknown-linux-musl.tar.gz`
- `codex-package_SHA256SUMS`

Canonical package contents:

- `bin/codex`
- `bin/codex-code-mode-host`
- `codex-path/rg`
- `codex-resources/bwrap`
- `codex-package.json`

## Release metadata files

The packaging script also generates:

- `VERSION.txt`
- `ldd.txt`
- `SHA256SUMS`

## Recommended GitHub release tag style

Because this is not an official upstream release, avoid reusing the exact
upstream tag name.

Recommended patterns:

- `v0.153.2-loongarch64-musl.1`
- `v0.153.2-loong64-musl.1`

## Upload order

1. raw binary asset
2. raw binary `.tar.gz`
3. Code Mode host binary and its `.tar.gz`
4. package archive
5. `codex-package_SHA256SUMS`
6. `SHA256SUMS`
7. optional supporting metadata files (`VERSION.txt`, `ldd.txt`)

## One-click install

Recommended public install command:

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash
```
