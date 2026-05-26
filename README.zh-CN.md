# LoongArch64 Linux 版 Codex CLI

这是一个面向 LoongArch64 Linux 的 Codex CLI 非官方社区构建版本。

## 构建信息

- 软件包：Codex CLI
- 版本：codex-cli 0.0.0
- 目标架构：loongarch64-unknown-linux-gnu
- 构建类型：非官方社区构建
- 编译贡献者：Hanlu Li (@LaurenIsACoder)

## 贡献说明

该构建版本作为 LoongArch64 Linux 社区构建版本提供。

编译贡献者完成了 Codex CLI 在 LoongArch64 Linux 环境下的本地构建，包括适配 rusty_v8 / V8 v147.4.0 源码构建流程，并修复 Rust sysroot、bindgen、libclang、clang/lld、LoongArch64 链接器行为等相关构建问题。

主要贡献：

- 在 loongarch64 Linux 环境下完成 Codex CLI 构建
- 适配 rusty_v8 / V8 v147.4.0 在 loongarch64 上的源码构建流程
- 修复 Rust sysroot 与 Chromium Rust toolchain 假设不匹配的问题
- 将不兼容的预编译 bindgen/libclang 替换为本地 LoongArch64 可用工具链
- 修复 clang/lld 与 LoongArch64 最终链接阶段相关问题
- 产出可运行的 LoongArch64 Linux Codex CLI 二进制文件

## 包内容

- `codex` - Codex CLI 可执行文件
- `README.md` - 英文说明文档
- `README.zh-CN.md` - 中文说明文档
- `VERSION.txt` - 构建与版本信息
- `ldd.txt` - 构建机上的运行时动态库依赖列表
- `SHA256SUMS` - SHA256 校验文件

## 运行时依赖

运行本包不需要安装 Rust、Cargo、LLVM、Ninja 或 V8 编译环境。

但需要兼容的 LoongArch64 Linux 运行时环境。

预期运行时依赖：

- libc6
- libgcc-s1
- zlib1g
- libssl3
- libzstd1

在 Debian / Loongnix 类系统上，可以尝试安装：

```bash
sudo apt install -y libc6 libgcc-s1 zlib1g libssl3 libzstd1
