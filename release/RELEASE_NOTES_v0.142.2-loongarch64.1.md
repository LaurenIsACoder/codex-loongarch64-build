# Codex CLI LoongArch64 Community Build

Upstream Codex version: `0.142.2`  
Release tag: `v0.142.2-loongarch64.1`  
Target: `loongarch64-unknown-linux-gnu`

Project repository:

- https://github.com/LaurenIsACoder/codex-loongarch64-build

## English

This is an unofficial community build of Codex CLI for LoongArch64 Linux.

Built from upstream `openai/codex` release source:

- upstream release tag: `rust-v0.142.2`
- CLI version: `codex-cli 0.142.2`
- target: `loongarch64-unknown-linux-gnu`

### Highlights

- Upgraded to upstream `codex-cli 0.142.2`
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

### Runtime notes

This is a glibc-based Linux build.

Expected runtime libraries include:

- `libc.so.6`
- `libgcc_s.so.1`
- `libz.so.1`
- `libssl.so.3`
- `libcrypto.so.3`
- `libzstd.so.1`

### Disclaimer

This is a community-maintained LoongArch64 build and is not an official OpenAI release.

## 中文

这是一个面向 LoongArch64 Linux 的 Codex CLI 非官方社区构建版本。

构建所基于的上游版本：

- 上游 release tag：`rust-v0.142.2`
- CLI 版本：`codex-cli 0.142.2`
- 目标架构：`loongarch64-unknown-linux-gnu`

### 主要特点

- 升级至上游 `codex-cli 0.142.2`
- rusty_v8、seccompiler、龙芯补丁与 v0.140.0 相同
- 安装脚本自动检测用户代理设置

### 包含的资产

- `codex-loongarch64-unknown-linux-gnu`
- `codex-loongarch64-unknown-linux-gnu.tar.gz`
- `codex-package-loongarch64-unknown-linux-gnu.tar.gz`
- `codex-package_SHA256SUMS`
- `SHA256SUMS`
- `VERSION.txt`
- `ldd.txt`

### 运行时说明

这是一个基于 glibc 的 Linux 构建。

预期运行时依赖包括：

- `libc.so.6`
- `libgcc_s.so.1`
- `libz.so.1`
- `libssl.so.3`
- `libcrypto.so.3`
- `libzstd.so.1`

### 免责声明

这是一个面向 LoongArch64 的社区维护构建版本，不是 OpenAI 官方发布版本。

### Installation

Install the latest release system-wide:

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash
```

Install this exact release tag:

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash -s -- --release v0.142.2-loongarch64.1
```
