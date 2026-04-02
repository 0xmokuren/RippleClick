# RippleClick

English | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [한국어](README.ko.md)

A macOS menu bar utility that displays a ripple effect at the mouse pointer position on left click.

![RippleClick Demo](ripple-click-demo.gif)

## Install

### Homebrew (Recommended)

```bash
brew tap 0xmokuren/tap
brew install --cask rippleclick
```

### Manual Download

Download the latest `.zip` from [Releases](https://github.com/0xmokuren/RippleClick/releases), extract it, and move `RippleClick.app` to your Applications folder.

> **First launch note:** You need to allow the app via "System Settings" → "Privacy & Security" → "Open Anyway". You will also be prompted to grant Accessibility permission for click detection.

## Features

- Displays a ripple effect on left click
- Toggle the effect ON/OFF from the menu bar
- Customizable via the settings window:
  - Effect color (12 color presets)
  - Maximum ripple size (5 levels)
  - Launch at login
- Multilingual support (English, Japanese, Chinese, Korean)

## Requirements

- macOS 13 (Ventura) or later

## Build (For Developers)

```bash
# Development
swift run

# Release build (.app bundle)
bash scripts/bundle.sh
open RippleClick.app
```

## License

[MIT License](LICENSE)
