# Codex CLI LoongArch64 Community Build

Upstream Codex version: `0.140.0`  
Release tag: `v0.140.0-loongarch64.1`  
Target: `loongarch64-unknown-linux-gnu`

Project repository:

- https://github.com/LaurenIsACoder/codex-loongarch64-build

## English

This is an unofficial community build of Codex CLI for LoongArch64 Linux.

Built from upstream `openai/codex` release source:

- upstream release tag: `rust-v0.140.0`
- CLI version: `codex-cli 0.140.0`
- target: `loongarch64-unknown-linux-gnu`

### Changes from v0.135.0-loongarch64.1

| Item | v0.135.0 | v0.140.0 |
|------|----------|----------|
| Upstream Codex | 0.135.0 | 0.140.0 |
| rusty_v8 | 147.4.0 | 149.2.0 |
| Code model | default (small) | **medium** |
| Link strategy | clang + lld only | direct + clang/lld fallback |
| rusty_v8 toolchain | — | x86_64 → native LoongArch replacement |

### Highlights

- **Installer now supports `--proxy` for firewalled environments**
- Upgraded to upstream `codex-cli 0.140.0`
- `rusty_v8` upgraded to `v149.2.0` with updated LoongArch64 patches
- Medium code model (`-C code-model=medium`) avoids B26 relocation overflow
  without requiring explicit linker override in the common case
- x86_64 rust-toolchain binaries inside rusty_v8 are now auto-replaced with
  native LoongArch64 equivalents before the build
- `-fsanitize-ignore-for-ubsan-feature` flag is now gated behind loong64
  exclusion in sanitizers.gni (new for v149.2.0)
- `-fdiagnostics-show-inlining-chain` and `-fno-lifetime-dse` still excluded
  on loong64 in BUILD.gn

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

- 上游 release tag：`rust-v0.140.0`
- CLI 版本：`codex-cli 0.140.0`
- 目标架构：`loongarch64-unknown-linux-gnu`

### 相比 v0.135.0-loongarch64.1 的变化

| 项目 | v0.135.0 | v0.140.0 |
|------|----------|----------|
| 上游 Codex | 0.135.0 | 0.140.0 |
| rusty_v8 | 147.4.0 | 149.2.0 |
| 代码模型 | 默认（small） | **medium** |
| 链接策略 | 仅 clang + lld | 直接编译 + clang/lld 回退 |
| rusty_v8 工具链 | — | x86_64 → 原生 LoongArch 替换 |

### 主要特点

- 升级至上游 `codex-cli 0.140.0`
- `rusty_v8` 升级至 `v149.2.0`，同步更新龙芯兼容补丁
- 中型代码模型（`-C code-model=medium`）避免 B26 重定位溢出
- rusty_v8 内置的 x86_64 rust-toolchain 二进制现已自动替换为 LoongArch64 原生版本
- sanitizers.gni 新增 loong64 排除项（`-fsanitize-ignore-for-ubsan-feature`）
- BUILD.gn 中 loong64 排除项保持（`-fdiagnostics-show-inlining-chain`、`-fno-lifetime-dse`）

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

Install behind a proxy:

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo -E bash -s -- --proxy http://your-proxy:8080
```

Install this exact release tag:

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash -s -- --release v0.140.0-loongarch64.1
```
