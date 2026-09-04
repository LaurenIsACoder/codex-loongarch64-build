# 构建说明

## 适用范围

本文记录在原生 LoongArch64 Linux 主机上可复现构建 Codex CLI `0.153.2`
的方法，目标是完全静态的 `loongarch64-unknown-linux-musl`：

- Codex tag：`rust-v0.153.2`
- `rusty_v8` tag：`v150.4.0`
- `seccompiler` crate：`0.5.0`
- Codex Rust：`1.95.0`
- V8 原生 Rust 编译器：`1.96.0`，配套 Chromium 精确锁定的 vendored
  标准库源码快照 `4c4205163abcbd08948b3efab796c543ba1ea687-4`

## 与主机系统隔离

请把仓库放在空间充足的普通用户目录中。下载的软件包、解包后的编译器、
Rust、sysroot、本地原生库、源码和构建产物全部位于本仓库的 `toolchains/`、
`work/` 和 `artifacts/` 下。初始化过程只使用 `apt-get download` 下载 deb，
再用 `dpkg-deb -x` 解包；不会执行 `sudo`，不会安装系统包，也不会修改
`/usr`、`/opt`、系统 Rust 或系统动态加载器。

初始化阶段只依赖主机上常见的下载、归档工具，以及 `gcc`、`make`、
`python3`、`protoc`、`dpkg-deb`。随后使用的 Clang/LLD 20、GN、Ninja、Node.js、
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
3. 应用 LoongArch64 landlock/seccomp 补丁；当 vendored protoc crate 没有
   LoongArch64 载荷时使用主机 `PROTOC`；再应用 `rusty_v8` 源码构建补丁，
   并把 Cargo 依赖切换到本地路径。
4. 先构建静态 bubblewrap，把其 SHA-256 写入 Codex，再在同一次 Cargo
   调用中构建 `codex` 与必需的 `codex-code-mode-host`；两者都使用仅作用于
   目标架构的 `+crt-static`、`-static`、medium code model 和 LLD 参数。
5. 构建静态 ripgrep，生成裸二进制和标准 package 两类发布资产。

## 为什么 `rusty_v8` 需要补丁

`rusty_v8` 没有发布 LoongArch64 预编译包。改为源码编译后还会遇到
Chromium 构建规则在 LoongArch64 上缺少可用 GN Clang toolchain 标签、
传入目标不支持的 Clang 参数、musl 目标选择不完整，以及假定存在 Chromium
预编译 Rust 工具链等问题。Chromium 生成的 GN 规则还精确引用了它所锁定的
vendored Rust 标准库文件，普通 `rust-src` 组件不能直接替代。初始化脚本会
校验 Chromium Linux 工具链归档的 SHA-256，只从中提取与架构无关的标准库
源码，再与仓库内原生 LoongArch64 Rust 1.96 编译器组合；归档中的 x86_64
程序不会被执行。`patches/rusty_v8/150.4.0/` 中的补丁只处理这些构建基础设施
缺口。

`codex` 主程序本身不直接链接 V8，但 `0.153.2` 的完整标准 package 还必须
包含 `codex-code-mode-host`，而这个伴随程序通过 Code Mode runtime 依赖
`rusty_v8`。因此，只编出 `codex` 可以通过普通 CLI 冒烟测试，却会在开启
Code Mode 时因缺少 host 而失败。发布构建必须把二者作为一组编译、打包和验证。

## 期望输出

- 未裁剪构建二进制：
  `work/build/target-codex-0.153.2/loongarch64-unknown-linux-musl/release/codex`
- 未裁剪 Code Mode host：同目录下的 `codex-code-mode-host`
- 静态 bubblewrap：同目录下的 `bwrap`
- 静态 ripgrep：`toolchains/ripgrep/bin/rg`
- 裁剪后的发布资产：`artifacts/v0.153.2/`

`scripts/package-release.sh` 会检查 `codex`、Code Mode host、ripgrep 和
bubblewrap 四个打包二进制；只要其中任何一个包含 ELF interpreter 或动态
`NEEDED` 依赖，打包就会中止。归档完成后还会在临时目录解包，核对标准布局，
并通过真实 IPC 握手、创建 session、执行 JavaScript 和关闭 session 来验证
Code Mode host，而不只检查文件是否存在。

## 可选覆盖项

可以通过环境变量覆盖主要版本和目录，例如 `TOOLCHAIN_ROOT`、`WORK_ROOT`、
`ARTIFACTS_ROOT`、`MUSL_SYSROOT`、`STABLE_TOOLCHAIN`、
`V8_RUST_TOOLCHAIN`、`V8_RUST_SYSROOT`、`NIGHTLY_SYSROOT` 和
`RIPGREP_VERSION`。默认值就是本文记录的仓库内固定配置。
