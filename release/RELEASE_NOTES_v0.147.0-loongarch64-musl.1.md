# Codex CLI 0.147.0 for LoongArch64 Linux (static musl)

- Upstream Codex tag: `rust-v0.147.0`
- Upstream commit: `be6e8eac029b183056b7e4402879f15d2c85f61b`
- Target: `loongarch64-unknown-linux-musl`

## Build highlights

- Built natively on LoongArch64 with repository-local Rust 1.95.0,
  Clang/LLD 20, musl 1.2.6, GN, Ninja, and Node.js toolchains.
- Codex, its bubblewrap resource, and bundled ripgrep are all static ELF
  executables with no interpreter and no dynamic `NEEDED` dependencies.
- The package contains a 16 KiB-page-compatible ripgrep/jemalloc build.
- No system package was installed and no system compiler, loader, sysroot, or
  library was replaced during the build.

## LoongArch64 changes

- Add the Codex landlock/seccomp architecture selection for LoongArch64.
- Add `seccompiler 0.5.0` LoongArch64 support.
- Use target-only static-musl Rust flags and a local Clang/LLD musl wrapper.
- Build and hash the static bubblewrap resource before compiling Codex.
- Stage a `rusty_v8 150.4.0` LoongArch64/musl patch for the optional
  `codex-v8-poc` workspace component. Codex CLI `0.147.0` itself does not
  depend on or link that component.

## Validation

- `codex --version` reports `codex-cli 0.147.0`.
- `codex --help`, `bwrap --version`, `rg --version`, and an `rg` search smoke
  test run successfully on the native LoongArch64 host.
- The packaged `codex sandbox /bin/true` path and a sandboxed command smoke
  test pass, exercising the packaged bubblewrap resource and embedded digest.
- `file`, `readelf`, and `ldd` independently report static executables for all
  three packaged programs.

---

# Codex CLI 0.147.0 LoongArch64 Linux 版（静态 musl）

- 上游 Codex tag：`rust-v0.147.0`
- 上游 commit：`be6e8eac029b183056b7e4402879f15d2c85f61b`
- 目标：`loongarch64-unknown-linux-musl`

## 构建要点

- 在原生 LoongArch64 上使用仓库内私有的 Rust 1.95.0、
  Clang/LLD 20、musl 1.2.6、GN、Ninja 和 Node.js 完成构建。
- Codex、bubblewrap 资源和内置 ripgrep 均为无 interpreter、
  无动态 `NEEDED` 依赖的静态 ELF。
- ripgrep/jemalloc 已按主机 16 KiB 页大小构建。
- 构建过程没有安装系统包，也没有替换系统编译器、加载器、
  sysroot 或库。

## 验证

- `codex --version` 输出 `codex-cli 0.147.0`。
- `codex --help`、`bwrap --version`、`rg --version` 和 `rg` 搜索冒烟测试
  均已在原生 LoongArch64 主机运行通过。
- package 中的 `codex sandbox /bin/true` 和沙箱命令冒烟测试均通过，
  实际覆盖了内置 bubblewrap 资源及其嵌入摘要验证。
- `file`、`readelf` 和 `ldd` 对三个打包程序的检查均证明其为静态可执行文件。
