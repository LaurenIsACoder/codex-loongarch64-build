# Codex LoongArch64 编译仓库

这个仓库的目标不是只保存一个已经编好的二进制，而是把
LoongArch64 版本 Codex CLI 的**构建方法**和**分发方法**都沉淀下来。

项目仓库：

- https://github.com/LaurenIsACoder/codex-loongarch64-build

它主要解决两件事：

1. 让别人可以从上游源码稳定复现 LoongArch64 构建过程。
2. 让我们可以像官方其他架构那样，生成更正式的发布资产，而不是只发一个裸二进制。

## 当前目标版本

- 上游 release：`rust-v0.153.2`
- CLI 版本：`codex-cli 0.153.2`
- 目标架构：`loongarch64-unknown-linux-musl`
- V8 crate：`150.4.0`
- 代码模型：`medium`（`-C code-model=medium`）
- 最终链接策略：本地 `clang + lld`，静态 musl

Codex 主程序本身不直接链接 V8，但标准 package 必须附带
`codex-code-mode-host`，而这个 Code Mode 伴随程序依赖 `rusty_v8 150.4.0`。
构建脚本会把主程序和 host 作为一组编译；打包时也会验证两者，避免出现
普通 CLI 能启动、启用 Code Mode 才发现少了零件的情况。

## 仓库结构

- `docs/`
  构建说明、发行说明、LoongArch64 相关坑位说明。
- `patches/`
  给上游 Codex、`seccompiler`、`rusty_v8` 使用的补丁。
- `scripts/`
  下载源码、打补丁、执行构建、生成发布资产的脚本。
- `release/`
  GitHub Release 说明模板与上传检查清单。
- `artifacts/`
  生成后的发布资产目录。该目录默认不进入 git 历史。

## 快速开始

```bash
cd <your-clone-dir>/codex-loongarch64-build-repo
scripts/setup-local-toolchains.sh
scripts/fetch-sources.sh
scripts/apply-patches.sh
scripts/build-codex-loongarch64.sh
scripts/build-ripgrep-loongarch64.sh
scripts/package-release.sh
```

工具链初始化脚本只会在仓库内被 git 忽略的 `toolchains/` 目录下载、
解包和编译所需组件，包括 Clang、musl sysroot、Rust、Node.js、GN、
Ninja 和本地原生库；不会安装系统包或覆盖系统目录中的文件。V8 所需的
Chromium Rust 归档会先校验哈希，只取其中与架构无关的 vendored 标准库源码，
再配合仓库内原生 LoongArch64 Rust 编译器使用；归档里的 x86_64 程序不会执行。

## 一键系统级安装

安装最新发布版本：

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash
```

安装指定 tag：

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash -s -- --release v0.153.2-loongarch64-musl.1
```

## 计划生成的发布资产

本仓库会同时维护两类发行物：

1. 裸二进制发行物
2. 更接近官方形式的 package 发行物

面向 `0.153.2` 的目标资产：

- `codex-loongarch64-unknown-linux-musl`
- `codex-loongarch64-unknown-linux-musl.tar.gz`
- `codex-code-mode-host-loongarch64-unknown-linux-musl`
- `codex-code-mode-host-loongarch64-unknown-linux-musl.tar.gz`
- `codex-package-loongarch64-unknown-linux-musl.tar.gz`
- `codex-package_SHA256SUMS`
- `SHA256SUMS`
- `VERSION.txt`
- `ldd.txt`

其中：
- 裸二进制资产的命名风格尽量贴近官方 release
- package 资产使用标准目录布局：`bin/`、`codex-resources/`、`codex-path/`、`codex-package.json`
- `bin/` 同时包含 `codex` 与 `codex-code-mode-host`

## 为什么需要这个仓库

官方 Codex 目前会发布 `x86_64` 和 `aarch64` 的 Linux 资产，但不会发布
`loongarch64`。这导致我们在 LoongArch64 上至少要自己解决四类问题：

- 上游 `codex-rs` 默认版本号与 Linux sandbox 目标分支问题
- `seccompiler` 缺少 `loongarch64` 支持
- `rusty_v8` / Chromium Rust toolchain 的源码构建假设不适配 LoongArch64
- 在不使用系统 musl 的前提下，用本地 sysroot 和 `lld` 完成全静态 musl 链接

这些内容已经在本仓库里整理成脚本、补丁和说明，目标是让后续版本继续可维护。

## 当前状态

- `0.153.2` 的静态 musl Codex、Code Mode host、bubblewrap 和 ripgrep
  会在原生 LoongArch64 上成组构建和验证。
- 打包脚本会拒绝任何含 ELF interpreter 或动态 `NEEDED` 依赖的二进制，
  并在临时解包后执行 Code Mode IPC 与 JavaScript 冒烟测试。
- 版本与目标信息见 [VERSION.txt](./VERSION.txt)
- 构建方法见 [docs/build.zh-CN.md](./docs/build.zh-CN.md)
- 发行方法见 [docs/release.zh-CN.md](./docs/release.zh-CN.md)

英文说明见 [README.md](./README.md)。
