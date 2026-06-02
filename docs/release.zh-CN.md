# 发行说明

## 目标

让 LoongArch64 版本的 Codex 分发形式尽量接近官方 release，而不是只发一个裸二进制。

## 发行物分层

本仓库把发行物分成两层。

### 1. 裸二进制资产

计划资产名：

- `codex-loongarch64-unknown-linux-gnu`
- `codex-loongarch64-unknown-linux-gnu.tar.gz`

其中 `.tar.gz` 内建议只包含一个同名文件：
`codex-loongarch64-unknown-linux-gnu`。

### 2. 标准 package 资产

计划资产名：

- `codex-package-loongarch64-unknown-linux-gnu.tar.gz`
- `codex-package_SHA256SUMS`

标准包内容：

- `bin/codex`
- `codex-path/rg`
- `codex-resources/bwrap`
- `codex-package.json`

## 发布元数据文件

打包脚本还会生成：

- `VERSION.txt`
- `ldd.txt`
- `SHA256SUMS`

## 推荐 GitHub Release Tag 风格

由于这不是上游官方 release，不建议复用完全相同的 tag。

建议使用：

- `v0.135.0-loongarch64.1`
- `v0.135.0-loong64.1`

## 建议上传顺序

1. 裸二进制资产
2. 裸二进制 `.tar.gz`
3. package 归档
4. `codex-package_SHA256SUMS`
5. `SHA256SUMS`
6. 可选元数据文件（`VERSION.txt`、`ldd.txt`）

## 一键安装

推荐公开给用户的安装命令：

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash
```
