# RippleClick

[English](README.md) | [日本語](README.ja.md) | 简体中文 | [한국어](README.ko.md)

<p>
  <a href="https://github.com/0xmokuren/RippleClick/releases"><img src="https://img.shields.io/github/v/release/0xmokuren/RippleClick?label=release" alt="最新版本"></a>
  <a href="https://github.com/0xmokuren/RippleClick/releases"><img src="https://img.shields.io/github/downloads/0xmokuren/RippleClick/total" alt="下载量"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-black?logo=apple" alt="macOS 13+">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/0xmokuren/RippleClick" alt="许可证"></a>
</p>

**让每一次点击都看得见。** RippleClick 是一款轻量级的 macOS 菜单栏常驻工具，在你点击的瞬间于鼠标指针位置绘制波纹特效，并可选地播放点击音效。非常适合屏幕录制、现场演示、演讲和教程等需要让观众清楚看到点击位置的场景。

![RippleClick Demo](ripple-click-demo.gif)

## 亮点

- 🌊 **即时视觉反馈** — 每次点击都会在指针正下方显示流畅的波纹动画。
- 🖱️ **支持左键、右键与双击** — 每种点击类型外观各异，可单独开关。
- 🎨 **完全可自定义** — 12 种预设颜色、5 档尺寸，速度与不透明度均可调节。
- 🌗 **适配浅色 / 深色模式** — 可为浅色和深色模式分别设置颜色，并自动切换。
- 🔊 **内置点击音效** — 5 种合成音效，配有音量滑块与试听功能。
- 🪶 **极致轻量** — 仅驻留菜单栏、无 Dock 图标、空闲时几乎不占用 CPU。
- 🌍 **支持 4 种语言** — 英语、日语、简体中文、韩语。

## 功能

### 点击类型

每种点击类型均可单独开关，外观也可独立设置。

| 点击     | 默认外观                  | 可配置项                     |
| -------- | ------------------------- | ---------------------------- |
| 左键点击 | 单层波纹环                | 颜色（普通 / 浅色 / 深色）   |
| 右键点击 | **双层波纹环**            | 启用、按外观分别设色         |
| 双击     | **尺寸 1.2 倍、线宽 2 倍**| 启用、按外观分别设色         |

### 自定义

- **特效颜色** — 12 种预设：青色、蓝色、藏青、紫色、粉色、红色、橙色、黄色、青柠、绿色、蓝绿、白色。
- **跟随系统外观** — 为浅色和深色模式分别指定颜色，macOS 切换时即时互换。
- **波纹最大尺寸** — 5 档（小 → 大）。
- **动画速度** — 5 档（快 → 慢）。
- **不透明度** — 5 档（淡 → 浓）。
- **登录时自动启动** — 登录系统时自动运行。

### 点击音效

音效在应用内合成（不附带任何音频文件），因此在任意音量下都清晰悦耳：

| 音效       | 风格               |
| ---------- | ------------------ |
| Water Drop | 柔和的水滴声       |
| Pop        | 短促的弹出声       |
| Sonar      | 干净的声呐 ping 声 |
| Bubble     | 圆润的气泡声       |
| Soft Click | 轻柔的机械点击声   |

可用 5 档滑块调节音量，点击 **试听** 即可预览当前音效。

## 安装

### Homebrew（推荐）

```bash
brew tap 0xmokuren/tap
brew install --cask rippleclick
```

### 手动下载

从 [Releases](https://github.com/0xmokuren/RippleClick/releases) 下载最新的 `.zip` 文件，解压后将 `RippleClick.app` 移动到“应用程序”文件夹。

> **首次启动提示：** 需要在“系统设置”→“隐私与安全性”→“仍要打开”中允许运行。此外，为在系统范围内检测点击操作，系统会要求授予 **辅助功能** 权限。

## 使用方法

1. 启动 RippleClick，菜单栏会出现一个 💧 图标。
2. 点击图标可切换特效 **开 / 关**，或打开 **设置**。
3. 在 **设置** 中调整颜色、尺寸、速度、不透明度、点击类型与音效。

## 系统要求

- macOS 13 (Ventura) 或更高版本

## 隐私

RippleClick 申请辅助功能权限，仅用于知晓点击发生的“时间”与“位置”，以便绘制波纹。它 **不会** 记录、存储或上传你的任何点击或输入内容，也没有任何网络访问与统计分析。

## 构建（面向开发者）

```bash
swift build              # 调试构建
swift run                # 开发运行
swift test               # 运行测试

bash scripts/bundle.sh   # 发布构建（.app 应用包）
open RippleClick.app
```

> 辅助功能权限是按二进制文件授予的，因此建议用生成的 `.app` 而非 `swift run` 来验证行为。架构说明与签名/发布流程详见 [CLAUDE.md](CLAUDE.md)。

## 参与贡献

欢迎提交 Issue 和 Pull Request。提交 PR 前请运行 `swiftlint lint --strict` 与 `swift-format lint --strict --recursive Sources/ Tests/`；若修改了面向用户的文案，请同步更新四种语言的 README。

## 许可证

[MIT License](LICENSE)
