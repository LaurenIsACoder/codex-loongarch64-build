# Release Guide

## Goal

Publish LoongArch64 Codex in a way that feels closer to official Codex release
assets.

## Release asset strategy

This repo produces two release layers.

### 1. Direct binary assets

Planned asset names:

- `codex-loongarch64-unknown-linux-gnu`
- `codex-loongarch64-unknown-linux-gnu.tar.gz`

The `.tar.gz` archive should contain a single file named
`codex-loongarch64-unknown-linux-gnu`.

### 2. Package archive assets

Planned asset names:

- `codex-package-loongarch64-unknown-linux-gnu.tar.gz`
- `codex-package_SHA256SUMS`

Canonical package contents:

- `bin/codex`
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

- `v0.135.0-loongarch64.1`
- `v0.135.0-loong64.1`

## Upload order

1. raw binary asset
2. raw binary `.tar.gz`
3. package archive
4. `codex-package_SHA256SUMS`
5. `SHA256SUMS`
6. optional supporting metadata files (`VERSION.txt`, `ldd.txt`)
