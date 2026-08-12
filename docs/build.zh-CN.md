# 构建说明

## 适用范围

本文记录在原生 LoongArch64 Linux 主机上可复现构建 Codex CLI `0.147.0`
的方法，目标是完全静态的 `loongarch64-unknown-linux-musl`：

- Codex tag：`rust-v0.147.0`
- `rusty_v8` tag：`v150.4.0`
- `seccompiler` crate：`0.5.0`
- Rust：`1.95.0`

## 与主机系统隔离

请把仓库放在空间充足的普通用户目录中。下载的软件包、解包后的编译器、
Rust、sysroot、本地原生库、源码和构建产物全部位于本仓库的 `toolchains/`、
`work/` 和 `artifacts/` 下。初始化过程只使用 `apt-get download` 下载 deb，
再用 `dpkg-deb -x` 解包；不会执行 `sudo`，不会安装系统包，也不会修改
`/usr`、`/opt`、系统 Rust 或系统动态加载器。

初始化阶段只依赖主机上常见的下载、归档工具，以及 `gcc`、`make`、
`python3`、`dpkg-deb`。随后使用的 Clang/LLD 20、GN、Ninja、Node.js、
ccache、pkgconf、musl、libcap、Rust 和 Cargo 都来自仓库内的私有目录。

## 构建流程

```bash
scripts/setup-local-toolchains.sh
scripts/fetch-sources.sh
scripts/apply-patches.sh
scripts/build-codex-loongarch64.sh
scripts/build-ripgrep-loongarch64.sh
scripts/package-release.sh
```

各阶段完成以下工作：

1. 在 `toolchains/` 中准备隔离的静态 musl 编译环境和 sysroot。
2. 获取固定版本的 Codex、`rusty_v8`、`seccompiler` 及 Cargo Git 依赖。
3. 应用 LoongArch64 landlock/seccomp 补丁和 `rusty_v8` 源码构建补丁，
   并把 Cargo 依赖切换到本地路径。
4. 先构建静态 bubblewrap，把其 SHA-256 写入 Codex，再用仅作用于目标
   架构的 `+crt-static`、`-static`、medium code model 和 LLD 参数链接 Codex。
5. 构建静态 ripgrep，生成裸二进制和标准 package 两类发布资产。

## 为什么 `rusty_v8` 需要补丁

`rusty_v8` 没有发布 LoongArch64 预编译包。改为源码编译后还会遇到
Chromium 构建规则在 LoongArch64 上缺少可用 GN Clang toolchain 标签、
传入目标不支持的 Clang 参数、musl 目标选择不完整，以及假定存在 Chromium
预编译 Rust 工具链等问题。`patches/rusty_v8/150.4.0/` 中的补丁只处理这些
构建基础设施缺口。

`0.147.0` 的 `codex-cli` 依赖图不包含独立的 `codex-v8-poc`
工作区 crate，因此默认 CLI 构建并不会编译或链接 V8。这套补丁
是为该可选组件准备的，不应被视为 CLI 发布产物的验证前提。

## 期望输出

- 未裁剪构建二进制：
  `work/build/target-codex-0.147.0/loongarch64-unknown-linux-musl/release/codex`
- 静态 bubblewrap：同目录下的 `bwrap`
- 静态 ripgrep：`toolchains/ripgrep/bin/rg`
- 裁剪后的发布资产：`artifacts/v0.147.0/`

`scripts/package-release.sh` 会检查三个打包二进制；只要其中任何一个包含
ELF interpreter 或动态 `NEEDED` 依赖，打包就会中止。

## 可选覆盖项

可以通过环境变量覆盖主要版本和目录，例如 `TOOLCHAIN_ROOT`、`WORK_ROOT`、
`ARTIFACTS_ROOT`、`MUSL_SYSROOT`、`STABLE_TOOLCHAIN`、`NIGHTLY_SYSROOT`
和 `RIPGREP_VERSION`。默认值就是本文记录的仓库内固定配置。
