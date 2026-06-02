# 构建说明

## 适用范围

本文档记录的是 Codex CLI `0.135.0` 在 LoongArch64 上的可复现源码构建流程。

## 与官方 Linux 构建的区别

官方 Linux release 主要面向：

- `x86_64-unknown-linux-musl`
- `aarch64-unknown-linux-musl`

本仓库当前维护的是：

- `loongarch64-unknown-linux-gnu`

因此有两个关键差异：

- 运行时依赖的是 glibc，不是 musl
- V8 构建和最终链接都需要 LoongArch64 专门处理

## 前置依赖

最少需要：

- `git`
- `curl`
- `tar`
- `patch`
- `python3`
- `clang` / `clang++`
- `ld.lld`
- `ccache`（建议）
- `rg`
- `bwrap`
- Node.js 22+

本次成功构建所依赖的已知可用组合：

- 系统 clang 19
- 系统 lld 19
- 给 `rusty_v8` 使用的 nightly Rust sysroot
- 最终 Codex 二进制改用 `clang + lld` 进行链接

## 构建步骤

1. `scripts/fetch-sources.sh`
   - 下载上游 Codex release 源码 tarball
   - 克隆 `rusty_v8` Git 源码 `v147.4.0`
   - 下载 `seccompiler 0.5.0`
2. `scripts/apply-patches.sh`
   - 给上游 Codex 打 LoongArch 补丁
   - 给 `seccompiler` 打 `loongarch64` 支持补丁
   - 给 `rusty_v8` / Chromium 构建规则打兼容补丁
   - 往 `codex-rs/Cargo.toml` 注入本地 path override
3. `scripts/build-codex-loongarch64.sh`
   - 配置 V8 source build 环境
   - 以 release 模式构建 Codex CLI
   - 最终二进制链接改走 `clang + lld`

## 这个仓库已经替你处理掉的主要坑

- 上游 release 源码默认会把版本编成 `0.0.0`
- `seccompiler 0.5.0` 默认不支持 `loongarch64`
- `rusty_v8` 在 LoongArch64 上没有官方预编译产物
- crates.io 上的 `v8` 源码包不够完整，必须改用 Git checkout
- Chromium Rust / Clang 工具链对 LoongArch64 有额外假设，需要本地兼容补丁
- 最终 Codex 大二进制在 LoongArch64 上用 GNU `ld` 会遇到重定位溢出，因此必须改用 `lld`

## 期望输出

主要产物：

- `work/build/target-codex-0.135.0/release/codex`

脚本成功后会打印最终路径。
