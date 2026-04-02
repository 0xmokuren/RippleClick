# RippleClick

[English](README.md) | [日本語](README.ja.md) | 简体中文 | [한국어](README.ko.md)

一款 macOS 菜单栏常驻工具，在鼠标左键点击时于指针位置显示波纹特效。

![RippleClick Demo](ripple-click-demo.gif)

## 安装

### Homebrew（推荐）

```bash
brew tap 0xmokuren/tap
brew install --cask rippleclick
```

### 手动下载

从 [Releases](https://github.com/0xmokuren/RippleClick/releases) 下载最新的 `.zip` 文件，解压后将 `RippleClick.app` 移动到"应用程序"文件夹。

> **首次启动提示：** 需要在"系统设置"→"隐私与安全性"→"仍要打开"中允许运行。此外，为检测点击操作，系统会要求授予辅助功能权限。

## 功能

- 左键点击时显示波纹特效
- 从菜单栏开启/关闭特效
- 可通过设置窗口自定义：
  - 特效颜色（12 种预设颜色）
  - 波纹最大尺寸（5 个级别）
  - 登录时自动启动
- 多语言支持（英语、日语、中文、韩语）

## 系统要求

- macOS 13 (Ventura) 或更高版本

## 构建（面向开发者）

```bash
# 开发环境
swift run

# 发布构建（.app 应用包）
bash scripts/bundle.sh
open RippleClick.app
```

## 许可证

[MIT License](LICENSE)
