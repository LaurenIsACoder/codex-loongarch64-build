# Codex CLI LoongArch64 Community Build

Upstream Codex version: `0.135.0`
Target: `loongarch64-unknown-linux-gnu`

Project repository:

- https://github.com/LaurenIsACoder/codex-loongarch64-build

## Highlights

- Community build for LoongArch64 Linux
- Built from upstream `openai/codex` release source
- `rusty_v8` compiled from source for LoongArch64
- Final Codex binary linked with `clang + lld` to avoid LoongArch GNU `ld` relocation overflow

## Included assets

- `codex-loongarch64-unknown-linux-gnu`
- `codex-loongarch64-unknown-linux-gnu.tar.gz`
- `codex-package-loongarch64-unknown-linux-gnu.tar.gz`
- `codex-package_SHA256SUMS`
- `SHA256SUMS`

## Runtime notes

This is a glibc-based Linux build.

Expected runtime libraries include:

- `libc.so.6`
- `libgcc_s.so.1`
- `libz.so.1`
- `libssl.so.3`
- `libcrypto.so.3`
- `libzstd.so.1`

## Disclaimer

This is an unofficial community-maintained build and is not an upstream OpenAI release.


## Installation

Install the latest release system-wide:

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash
```
