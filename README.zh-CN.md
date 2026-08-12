# Codex LoongArch64 编译仓库

这个仓库的目标不是只保存一个已经编好的二进制，而是把
LoongArch64 版本 Codex CLI 的**构建方法**和**分发方法**都沉淀下来。

项目仓库：

- https://github.com/LaurenIsACoder/codex-loongarch64-build

它主要解决两件事：

1. 让别人可以从上游源码稳定复现 LoongArch64 构建过程。
2. 让我们可以像官方其他架构那样，生成更正式的发布资产，而不是只发一个裸二进制。

## 当前目标版本

- 上游 release：`rust-v0.147.0`
- CLI 版本：`codex-cli 0.147.0`
- 目标架构：`loongarch64-unknown-linux-musl`
- V8 crate：`150.4.0`
- 代码模型：`medium`（`-C code-model=medium`）
- 最终链接策略：本地 `clang + lld`，静态 musl

Codex CLI `0.147.0` 并不链接工作区中独立的 `codex-v8-poc`
crate。本仓库仍保留 `rusty_v8 150.4.0` 源码和补丁，供这个可选
工作区组件使用；它不会进入默认 CLI 二进制。

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
Ninja 和本地原生库；不会安装系统包或覆盖系统目录中的文件。

## 一键系统级安装

安装最新发布版本：

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash
```

安装指定 tag：

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash -s -- --release v0.147.0-loongarch64-musl.1
```

## 计划生成的发布资产

本仓库会同时维护两类发行物：

1. 裸二进制发行物
2. 更接近官方形式的 package 发行物

面向 `0.147.0` 的目标资产：

- `codex-loongarch64-unknown-linux-musl`
- `codex-loongarch64-unknown-linux-musl.tar.gz`
- `codex-package-loongarch64-unknown-linux-musl.tar.gz`
- `codex-package_SHA256SUMS`
- `SHA256SUMS`
- `VERSION.txt`
- `ldd.txt`

其中：
- 裸二进制资产的命名风格尽量贴近官方 release
- package 资产使用标准目录布局：`bin/`、`codex-resources/`、`codex-path/`、`codex-package.json`

## 为什么需要这个仓库

官方 Codex 目前会发布 `x86_64` 和 `aarch64` 的 Linux 资产，但不会发布
`loongarch64`。这导致我们在 LoongArch64 上至少要自己解决四类问题：

- 上游 `codex-rs` 默认版本号与 Linux sandbox 目标分支问题
- `seccompiler` 缺少 `loongarch64` 支持
- `rusty_v8` / Chromium Rust toolchain 的源码构建假设不适配 LoongArch64
- 在不使用系统 musl 的前提下，用本地 sysroot 和 `lld` 完成全静态 musl 链接

这些内容已经在本仓库里整理成脚本、补丁和说明，目标是让后续版本继续可维护。

## 当前状态

- `0.147.0` 的静态 musl Codex、bubblewrap 和 ripgrep 已于 2026-08-12
  在原生 LoongArch64 上完成构建和运行验证。
- 打包脚本会先拒绝任何含 ELF interpreter 或动态 `NEEDED` 依赖的二进制。
- 版本与目标信息见 [VERSION.txt](./VERSION.txt)
- 构建方法见 [docs/build.zh-CN.md](./docs/build.zh-CN.md)
- 发行方法见 [docs/release.zh-CN.md](./docs/release.zh-CN.md)

英文说明见 [README.md](./README.md)。
