# Codex CLI 0.153.2 for LoongArch64 Linux (static musl)

- Upstream Codex tag: `rust-v0.153.2`
- Upstream commit: `657a993cbee87acf52d14b758ce49dbd46d1b8eb`
- Target: `loongarch64-unknown-linux-musl`

## Build highlights

- Built natively on LoongArch64 with repository-local Rust 1.95.0 for Codex,
  Rust 1.96.0 for the V8 host, Clang/LLD 20, musl 1.2.6, GN, Ninja, and
  Node.js toolchains.
- Codex, `codex-code-mode-host`, its bubblewrap resource, and bundled ripgrep
  are packaged as static ELF executables with no interpreter or dynamic
  `NEEDED` dependencies.
- No system package, compiler, loader, sysroot, or library is replaced by the
  build workflow.

## LoongArch64 changes

- Add the Codex landlock/seccomp architecture selection for LoongArch64.
- Add `seccompiler 0.5.0` LoongArch64 support.
- Use the host `PROTOC` because `protoc-bin-vendored 3.2.0` has no
  LoongArch64 payload.
- Use target-only static-musl Rust flags and a local Clang/LLD musl wrapper.
- Build and hash the static bubblewrap resource before compiling Codex.
- Build `codex` and `codex-code-mode-host` as one required release group.
- Reuse the `rusty_v8 150.4.0` LoongArch64/musl source-build patch and exact
  Chromium Rust source bundle retained by Codex 0.153.2.
- Update the pinned crossterm fork revision to the one used by Codex 0.153.2.

## Validation

- `codex --version` reports `codex-cli 0.153.2`.
- `codex --help`, `codex features list`, `codex-code-mode-host --help`,
  `bwrap --version`, `rg --version`, and an `rg` search smoke test pass on a
  native LoongArch64 host.
- Three consecutive Code Mode protocol tests open a session, execute
  JavaScript, return `code-mode-smoke-ok`, and shut the host down cleanly.
- A command executed through the packaged `codex sandbox` path succeeds,
  exercising the packaged bubblewrap resource and embedded digest.
- `file`, `readelf`, and `ldd` independently confirm that all four packaged
  programs are static executables with no ELF interpreter or dynamic
  `NEEDED` entry.
- Re-running the complete Codex/Code Mode host build preserves the hashes of
  the Codex, host, and bubblewrap build outputs.
- A negative package test confirms that removing `codex-code-mode-host` is
  rejected by release verification.
- Package SHA-256:
  `021de2f4c7f37795b7779f560c7f29e5874706f6268d8b894585c88114a6231a`.

These results cover the native build, package layout, Code Mode runtime, and a
packaged sandbox smoke test. No system-wide installation was performed during
validation.

---

# Codex CLI 0.153.2 LoongArch64 Linux 版（静态 musl）

- 上游 Codex tag：`rust-v0.153.2`
- 上游 commit：`657a993cbee87acf52d14b758ce49dbd46d1b8eb`
- 目标：`loongarch64-unknown-linux-musl`

## 构建要点

- 在原生 LoongArch64 上使用仓库内私有工具链构建，不安装或替换系统组件。
- Codex、`codex-code-mode-host`、bubblewrap 和 ripgrep 作为完整 package
  一起打包，并要求都是无 interpreter、无动态 `NEEDED` 依赖的静态 ELF。
- 0.153.2 仍使用 `rusty_v8 150.4.0`、Rust 1.95.0 和配套的 V8 Rust 1.96.0，
  因此可以复用上一版本已经验证的隔离工具链与 V8 构建方案。

## LoongArch64 修正

- 补齐 Codex landlock/seccomp 的 LoongArch64 架构选择。
- 补齐 `seccompiler 0.5.0` 的 LoongArch64 支持。
- `protoc-bin-vendored 3.2.0` 没有 LoongArch64 载荷，构建时改用主机
  `PROTOC`。
- 使用只作用于目标架构的静态 musl、medium code model 和 LLD 参数。
- 先构建并写入 bubblewrap 摘要，再把 Codex 与 Code Mode host 作为一个发布组编译。
- 把 crossterm fork固定到 Codex 0.153.2 实际使用的 revision。

## 验证

- `codex --version` 输出 `codex-cli 0.153.2`。
- `codex --help`、`codex features list`、Code Mode host、bubblewrap、ripgrep
  的启动与搜索冒烟测试均在原生 LoongArch64 主机通过。
- Code Mode 协议测试连续运行三次，均成功打开会话、执行 JavaScript、返回
  `code-mode-smoke-ok` 并干净关闭 host。
- package 中的 `codex sandbox` 命令执行通过，实际覆盖了内置 bubblewrap
  资源及其嵌入摘要。
- `file`、`readelf`、`ldd` 确认四个打包程序都没有 ELF interpreter 或动态
  `NEEDED` 依赖。
- 完整重跑构建后，Codex、Code Mode host 和 bubblewrap 的构建产物哈希不变。
- 从 package 中移除 Code Mode host 后，发行校验会按预期拒绝该归档。
- package SHA-256：
  `021de2f4c7f37795b7779f560c7f29e5874706f6268d8b894585c88114a6231a`。

以上验证覆盖原生构建、package 布局、Code Mode runtime 和沙箱冒烟测试；
验证过程没有执行系统级安装。
