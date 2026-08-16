# Codex CLI 0.147.0 for LoongArch64 Linux (static musl)

- Upstream Codex tag: `rust-v0.147.0`
- Upstream commit: `be6e8eac029b183056b7e4402879f15d2c85f61b`
- Target: `loongarch64-unknown-linux-musl`

## Build highlights

- Built natively on LoongArch64 with repository-local Rust 1.95.0 for Codex,
  Rust 1.96.0 for the V8 host, Clang/LLD 20, musl 1.2.6, GN, Ninja, and
  Node.js toolchains.
- Codex, `codex-code-mode-host`, its bubblewrap resource, and bundled ripgrep
  are all static ELF executables with no interpreter and no dynamic `NEEDED`
  dependencies.
- The package contains a 16 KiB-page-compatible ripgrep/jemalloc build.
- No system package was installed and no system compiler, loader, sysroot, or
  library was replaced during the build.

This corrected release replaces the earlier assets published under the same
tag. The earlier package omitted `codex-code-mode-host`; use the assets and
checksums attached to this release instead.

## LoongArch64 changes

- Add the Codex landlock/seccomp architecture selection for LoongArch64.
- Add `seccompiler 0.5.0` LoongArch64 support.
- Use target-only static-musl Rust flags and a local Clang/LLD musl wrapper.
- Build and hash the static bubblewrap resource before compiling Codex.
- Build `codex` and `codex-code-mode-host` as one required release group, so
  the stable Code Mode feature no longer fails closed because its companion
  executable is missing.
- Patch `rusty_v8 150.4.0` for LoongArch64/musl and build it from the exact
  Chromium Rust source bundle paired with the vendored V8 revision.
- Reject release packages that omit the Code Mode host or contain a dynamically
  linked executable.

## Validation

- `codex --version` reports `codex-cli 0.147.0`.
- `codex --help`, `codex-code-mode-host --help`, `bwrap --version`,
  `rg --version`, and an `rg` search smoke test run successfully on the native
  LoongArch64 host.
- Three consecutive Code Mode protocol tests open a session, execute JavaScript,
  return `code-mode-smoke-ok`, and shut the host down cleanly.
- The packaged `codex sandbox /bin/true` path and a sandboxed command smoke
  test pass, exercising the packaged bubblewrap resource and embedded digest.
- `file`, `readelf`, and `ldd` independently report static executables for all
  four packaged programs.
- Negative packaging tests reject both a missing build-time host and a package
  archive from which the host has been removed.

---

# Codex CLI 0.147.0 LoongArch64 Linux 版（静态 musl）

- 上游 Codex tag：`rust-v0.147.0`
- 上游 commit：`be6e8eac029b183056b7e4402879f15d2c85f61b`
- 目标：`loongarch64-unknown-linux-musl`

## 构建要点

- 在原生 LoongArch64 上使用仓库内私有的 Rust 1.95.0 构建 Codex，
  使用 Rust 1.96.0 构建 V8 host，并配合 Clang/LLD 20、musl 1.2.6、
  GN、Ninja 和 Node.js 完成全部构建。
- Codex、`codex-code-mode-host`、bubblewrap 资源和内置 ripgrep 均为
  无 interpreter、无动态 `NEEDED` 依赖的静态 ELF。
- ripgrep/jemalloc 已按主机 16 KiB 页大小构建。
- 构建过程没有安装系统包，也没有替换系统编译器、加载器、
  sysroot 或库。

这是同一 tag 下的修正版发布，已经替换先前的错误资产。先前 package
遗漏了 `codex-code-mode-host`，请以本 release 当前附件及校验和为准。

## LoongArch64 修正

- 将 `codex` 与 `codex-code-mode-host` 作为一个不可拆分的发布组构建，
  修复稳定版 Code Mode 因找不到配套 host 而 fail closed 的问题。
- 为 `rusty_v8 150.4.0` 补齐 LoongArch64/musl 支持，并使用与 vendored V8
  版本严格配套的 Chromium Rust 源码包完成构建。
- release 打包现在会拒绝缺少 Code Mode host 或包含动态链接程序的产物。

## 验证

- `codex --version` 输出 `codex-cli 0.147.0`。
- `codex --help`、`codex-code-mode-host --help`、`bwrap --version`、
  `rg --version` 和 `rg` 搜索冒烟测试均已在原生 LoongArch64 主机运行通过。
- Code Mode 协议测试连续运行三次，均成功打开会话、执行 JavaScript、返回
  `code-mode-smoke-ok` 并干净关闭 host。
- package 中的 `codex sandbox /bin/true` 和沙箱命令冒烟测试均通过，
  实际覆盖了内置 bubblewrap 资源及其嵌入摘要验证。
- `file`、`readelf` 和 `ldd` 对四个打包程序的检查均证明其为静态可执行文件。
- 负向测试确认：构建阶段缺少 host，或从 package 中移除 host，均会被拒绝。
