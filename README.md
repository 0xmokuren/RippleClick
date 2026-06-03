# RippleClick

English | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [한국어](README.ko.md)

<p>
  <a href="https://github.com/0xmokuren/RippleClick/releases"><img src="https://img.shields.io/github/v/release/0xmokuren/RippleClick?label=release" alt="Latest release"></a>
  <a href="https://github.com/0xmokuren/RippleClick/releases"><img src="https://img.shields.io/github/downloads/0xmokuren/RippleClick/total" alt="Downloads"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-black?logo=apple" alt="macOS 13+">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/0xmokuren/RippleClick" alt="License"></a>
</p>

**Make every click visible.** RippleClick is a lightweight macOS menu bar utility that paints a ripple at your mouse pointer the moment you click — with an optional click sound. Perfect for screen recordings, live demos, presentations, and tutorials where your audience needs to see exactly where you clicked.

![RippleClick Demo](ripple-click-demo.gif)

## Highlights

- 🌊 **Instant visual feedback** — a clean, animated ripple appears right under the pointer on every click.
- 🖱️ **Left, right & double click** — each click type has its own look and can be toggled independently.
- 🎨 **Fully customizable** — 12 color presets, 5 size levels, adjustable speed and opacity.
- 🌗 **Light / Dark aware** — set separate colors for Light and Dark mode and they switch automatically.
- 🔊 **Built-in click sounds** — 5 synthesized sound effects with a volume slider and live preview.
- 🪶 **Featherweight** — menu bar only, no Dock icon, negligible CPU when idle.
- 🌍 **4 languages** — English, 日本語, 简体中文, 한국어.

## Features

### Click types

Each click type can be turned on or off and styled independently.

| Click        | Default behavior                          | Configurable                  |
| ------------ | ----------------------------------------- | ----------------------------- |
| Left click   | Single ripple ring                        | Color (normal / light / dark) |
| Right click  | **Double ripple ring**                    | Enable, color per appearance  |
| Double click | **1.2× size, 2× line width**              | Enable, color per appearance  |

### Customization

- **Effect color** — 12 presets: cyan, blue, navy, purple, pink, red, orange, yellow, lime, green, teal, white.
- **Match system appearance** — pick distinct colors for Light and Dark mode; RippleClick swaps them on the fly when macOS switches.
- **Ripple size** — 5 levels (small → large).
- **Animation speed** — 5 levels (fast → slow).
- **Opacity** — 5 levels (subtle → bold).
- **Launch at login** — start automatically when you sign in.

### Click sounds

Sounds are synthesized in-app (no audio files bundled), so they stay crisp at any volume:

| Sound      | Vibe                    |
| ---------- | ----------------------- |
| Water Drop | soft, watery plink      |
| Pop        | short bubbly pop        |
| Sonar      | clean sonar ping        |
| Bubble     | rounded bubble blip     |
| Soft Click | gentle mechanical click |

Adjust the volume with a 5-step slider and tap **Preview** to hear the current selection.

## Install

### Homebrew (Recommended)

```bash
brew tap 0xmokuren/tap
brew install --cask rippleclick
```

### Manual Download

Download the latest `.zip` from [Releases](https://github.com/0xmokuren/RippleClick/releases), extract it, and move `RippleClick.app` to your Applications folder.

> **First launch note:** Allow the app via "System Settings" → "Privacy & Security" → "Open Anyway". You will also be prompted to grant **Accessibility** permission, which is required to detect clicks system-wide.

## Usage

1. Launch RippleClick — a 💧 icon appears in the menu bar.
2. Click the icon to toggle the effect **ON / OFF** or open **Settings**.
3. Open **Settings** to tune colors, size, speed, opacity, click types, and sounds.

## Requirements

- macOS 13 (Ventura) or later

## Privacy

RippleClick needs Accessibility permission solely to know *when* and *where* a click happens so it can draw the ripple. It does **not** record, store, or transmit anything you click or type. There is no network access and no analytics.

## Build (For Developers)

```bash
swift build              # Debug build
swift run                # Run in development
swift test               # Run the test suite

bash scripts/bundle.sh   # Release build (.app bundle)
open RippleClick.app
```

> Accessibility permission is granted per binary, so behavior is best verified with the bundled `.app` rather than `swift run`. See [CLAUDE.md](CLAUDE.md) for architecture notes and the signing/release workflow.

## Contributing

Issues and pull requests are welcome. Please run `swiftlint lint --strict` and `swift-format lint --strict --recursive Sources/ Tests/` before opening a PR, and keep the four README translations in sync when you change user-facing text.

## License

[MIT License](LICENSE)
