# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

RippleClick は macOS メニューバー常駐型ユーティリティアプリ。左クリック時にマウスポインタ位置に波紋エフェクトを表示する。macOS 13+ 対応、Swift Package Manager ベース。

## ビルド・テスト・Lint コマンド

```bash
swift build              # デバッグビルド
swift run                # 開発実行
swift test               # 全テスト実行
swift test --filter SettingsStoreTests/testIsEnabledDefaultsToTrue  # 単一テスト実行

# Lint / Format（CI と同じ）
swiftlint lint --strict
swift-format lint --strict --recursive Sources/ Tests/

# リリースビルド（.app バンドル生成）
bash scripts/bundle.sh
```

## アーキテクチャ

Swift Package は2つのターゲットに分離されている:

- **RippleClickLib** (`Sources/RippleClick/`) — アプリ本体のロジック全体。テストはこのライブラリに対して書く（`@testable import RippleClickLib`）
- **RippleClick** (`Sources/RippleClickApp/main.swift`) — エントリポイントのみ。NSApplication を手動で起動する薄いラッパー

### 主要コンポーネントの連携

`AppDelegate` が起動時に `SettingsStore`（UserDefaults ラッパー、シングルトン）を生成し、`StatusBarController`（メニューバーUI）と `ClickMonitor`（グローバルクリック監視）に注入する。

クリック検知フロー: `ClickMonitor` が `NSEvent.addGlobalMonitorForEvents` で左クリックを監視 → `RippleWindowController` がクリック位置に透明ウィンドウを生成 → `RippleView`（CALayer アニメーション）が波紋を描画 → 0.55秒後にウィンドウを破棄。同時表示は最大20個に制限。

設定変更は `SettingsStore` 経由で UserDefaults に永続化。色変更時は `Notification.Name.rippleColorChanged` で通知。

## コードスタイル

- インデント: スペース4つ
- 行長上限: 120（warning）/ 150（error）
- SwiftLint と swift-format の設定は `.swiftlint.yml` / `.swift-format` を参照
- ローカライゼーション文字列はリソースバンドルではなくコード内に埋め込み（`Localization.swift`）
- アプリは `NSApp.setActivationPolicy(.accessory)` でDockに表示しない

## テスト

テストでは `SettingsStore(defaults:)` イニシャライザで専用の UserDefaults suite を使い、テスト間の状態を分離する。
