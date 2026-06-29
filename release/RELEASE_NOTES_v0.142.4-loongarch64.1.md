# Codex CLI LoongArch64 Community Build

Upstream Codex version: `0.142.4`  
Release tag: `v0.142.4-loongarch64.1`  
Target: `loongarch64-unknown-linux-gnu`

Project repository:

- https://github.com/LaurenIsACoder/codex-loongarch64-build

## English

This is an unofficial community build of Codex CLI for LoongArch64 Linux.

Built from upstream `openai/codex` release source:

- upstream release tag: `rust-v0.142.4`
- CLI version: `codex-cli 0.142.4`
- target: `loongarch64-unknown-linux-gnu`

### Highlights

- Upgraded to upstream `codex-cli 0.142.4`
- rusty_v8, seccompiler, and loongarch64 patches unchanged from v0.140.0
- Installer auto-detects proxy settings from user shell

### Included assets

- `codex-loongarch64-unknown-linux-gnu`
- `codex-loongarch64-unknown-linux-gnu.tar.gz`
- `codex-package-loongarch64-unknown-linux-gnu.tar.gz`
- `codex-package_SHA256SUMS`
- `SHA256SUMS`
- `VERSION.txt`
- `ldd.txt`

### Disclaimer

This is a community-maintained LoongArch64 build and is not an official OpenAI release.

## 中文

这是一个面向 LoongArch64 Linux 的 Codex CLI 非官方社区构建版本。

构建所基于的上游版本：

- 上游 release tag：`rust-v0.142.4`
- CLI 版本：`codex-cli 0.142.4`
- 目标架构：`loongarch64-unknown-linux-gnu`

### 免责声明

这是一个面向 LoongArch64 的社区维护构建版本，不是 OpenAI 官方发布版本。

### Installation

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash
```

Install this exact release tag:

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash -s -- --release v0.142.4-loongarch64.1
```
