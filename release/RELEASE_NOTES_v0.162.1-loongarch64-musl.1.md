# Codex CLI 0.162.1 for LoongArch64 Linux (static musl)

- Upstream tag: `rust-v0.162.1`
- Upstream commit: `092d3acd6bec3e3a14bdc7e7a2810ab628ab759d`
- Target: `loongarch64-unknown-linux-musl`
- V8: `150.4.0`; bundled ripgrep: `15.2.0`

## Changes

- Update Codex and the pinned crossterm fork to the 0.162.1 inputs. Preserve
  the exact upstream revisions of the MCP Rust SDK, HTTP/3, and MXC sources
  while using local checkouts for workspace resolution.
- Retain LoongArch64 seccomp support and the native `PROTOC` override.
- Fix the new daemon socket mount detection build failure on LoongArch64 musl:
  convert `BTRFS_SUPER_MAGIC` to `rustix::fs::FsWord` before comparing it with
  `statfs.f_type`, whose signedness differs between supported backends.
- Refresh the isolated AOSC toolchain packages and include local Git, CMake,
  jsoncpp, and rhash. Correct relocated CMake module lookup and select the
  explicit Rust toolchain when building bindgen on a fresh host.
- Build and package Codex and its Code Mode host together, with the bundled
  bubblewrap digest embedded in Codex. Keep ripgrep's 16 KiB page configuration.

## Validation

- Native AOSC LoongArch64 release build with Rust 1.95.0, the V8 Rust 1.96.0
  source toolchain, Clang/LLD 20.1.8, and musl 1.2.6 completed successfully.
- All four packaged executables are static LoongArch64 ELF files with no
  interpreter or dynamic `NEEDED` dependency.
- CLI version/help/features and app-server initialization passed.
- Code Mode IPC tests execute JavaScript and shut down successfully, both on
  the AOSC build host and after isolated offline installation on Debian.
- Packaged sandbox command execution and ripgrep searches passed on both hosts.
- The isolated daemon mount module test harness passed all 30 upstream cases
  plus one native `statfs`/mountinfo check: 31 passed, 0 failed.
- Offline user installation and repeat installation passed on Debian LoongArch64.
- All release checksums passed again after transferring the assets to the
  control machine.

Package SHA-256:

```text
a17cff6aea600ebbc4d9c754002cb4c3f7d6a49c88441f8a8c5ffa7f7c97f16f
```

---

# Codex CLI 0.162.1 LoongArch64 Linux 版（静态 musl）

基于上游 `rust-v0.162.1` 构建，保留完整的 Codex、Code Mode host、
bubblewrap 和 ripgrep。ripgrep 更新为 15.2.0，继续支持 16 KiB 页大小。

本次补齐新版沙箱挂载检测中的整数类型适配：将 Btrfs 文件系统常量转换为
rustix 使用的字段类型，修复 LoongArch64 musl 上 `u64` 与 `i64` 无法比较
导致的编译失败。继续使用原生 protoc，并固定上游 MCP Rust SDK、HTTP/3、
MXC 和 crossterm 依赖版本。

工具链在普通用户目录中独立搭建，没有安装或替换系统组件。原生 AOSC 构建、
四个静态 ELF 检查、Code Mode IPC/JavaScript、app-server 初始化和沙箱命令
验证均通过。挂载检测专项测试通过 31/31；在另一台 Debian LoongArch64 主机
上的离线安装、重复安装、Code Mode、ripgrep 和沙箱命令验证也均通过。
