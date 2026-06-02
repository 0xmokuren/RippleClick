# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

RippleClick は macOS メニューバー常駐型ユーティリティアプリ。クリック時にマウスポインタ位置に波紋エフェクトを表示し、任意で効果音を鳴らす。左クリック・右クリック・ダブルクリックに対応。macOS 13+ 対応、Swift Package Manager ベース。

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

同等のショートカットとして `Makefile`（`make build` / `run` / `test` / `lint` / `format` / `bundle`）もある。CI（`.github/workflows/ci.yml`）は main への push / PR で build+test・lint・format の3ジョブを `macos-15` 上で実行する。

## アーキテクチャ

Swift Package は2つのターゲットに分離されている:

- **RippleClickLib** (`Sources/RippleClick/`) — アプリ本体のロジック全体。テストはこのライブラリに対して書く（`@testable import RippleClickLib`）
- **RippleClick** (`Sources/RippleClickApp/main.swift`) — エントリポイントのみ。NSApplication を手動で起動する薄いラッパー

### 主要コンポーネントの連携

`AppDelegate` が起動時に `NSApp.setActivationPolicy(.accessory)` を設定し、`SettingsStore.shared` を生成して `StatusBarController`（メニューバーUI）と `ClickMonitor`（グローバルクリック監視）に注入する。さらに `effectiveAppearance` を KVO 監視し、ライト/ダーク切替時に `appearanceAwareColor` が有効なら `.rippleColorChanged` を post する。

クリック検知フロー:
1. `ClickMonitor` が `NSEvent.addGlobalMonitorForEvents([.leftMouseDown, .rightMouseDown])` で監視
2. 種別を判定（右クリック / `clickCount >= 2` のダブルクリック / 左クリック）し、各種別の有効フラグを確認してから `RippleWindowController.showRipple(at:clickType:)` を呼ぶ
3. `RippleWindowController` がクリック種別に応じてサイズ・色・リング数・線幅を決め、透明ボーダレスウィンドウを生成 → `RippleView`（CALayer アニメーション）が波紋を描画
4. `soundEnabled` なら `SoundPlayer.shared.playSound` で効果音を再生

クリック種別ごとの差: **右クリックは2重リング**、**ダブルクリックはサイズ1.2倍・線幅2倍**。色も種別ごとに独立して設定できる（通常/ライト/ダークの3系統）。

### 押さえるべき設計上のポイント

- **`SettingsStore`** — UserDefaults ラッパー（`@MainActor` シングルトン）で全設定の唯一の真実源。色変更系の setter は `.rippleColorChanged` を post する。数値はすべてクランプされる（maxRippleSize 10–500、rippleOpacity 0.1–1.0、animationDuration 0.1–2.0、soundVolume 0–1）。イニシャライザが2つあり、`private init()` は `UserDefaults.standard`（本番シングルトン）、`init(defaults:)` はテスト用の注入口。
- **ウィンドウのプール再利用** — `RippleWindowController` は `NSWindow` と `RippleView` を毎回生成・破棄せず `windowPool` で再利用する。同時表示は最大 `maxConcurrentWindows = 10`（超過時は最古をリサイクル）。表示後 `animationDuration + 0.05` 秒でリサイクルに回す。`RippleView.reset()` で再利用、`clearLayers()` でサブレイヤを破棄する。
- **効果音はファイルではなくプログラム合成** — `SoundPlayer`（`@MainActor` シングルトン）が5種類（`SoundType`: waterDrop / pop / sonar / bubble / softClick）を sin 波＋エンベロープで波形合成し、`AVAudioEngine` で再生する。生成したバッファは種別ごとにキャッシュする。音声リソースファイルは存在しない。
- **ログイン項目** — `LoginItemManager` が `SMAppService.mainApp` で登録/解除する。**実際の .app バンドル（bundle identifier が必要）でのみ動作**し、`swift run` では機能しない。

## アクセシビリティ権限とコード署名（動作確認に必須）

- グローバルクリック監視には**アクセシビリティ権限が必須**。未許可だと監視が動かない（`ClickMonitor.start()` が起動時に `AXIsProcessTrustedWithOptions` で要求する）。`swift run` で動かす実行バイナリにも個別に権限付与が必要なので、挙動確認は基本的に `bundle.sh` で生成した `.app` で行う。
- `bundle.sh` の署名は `SIGNING_IDENTITY` 環境変数で切り替わる:
  - 既定は **ad-hoc 署名**（`"-"`）。この場合、アプリ更新のたびに TCC（アクセシビリティ）権限がリセットされる。
  - `SIGNING_IDENTITY` に Developer ID か自己署名証明書を指定すると、hardened runtime + `Resources/RippleClick.entitlements` で署名され、**TCC 権限が更新をまたいで保持される**。
  - 自己署名証明書は `bash scripts/create-signing-cert.sh` で作成し、`SIGNING_IDENTITY="RippleClick Development" bash scripts/bundle.sh` でビルドする。

## コードスタイル

- インデント: スペース4つ
- 行長上限: 120（warning）/ 150（error）。その他の閾値は `.swiftlint.yml` 参照
- SwiftLint で `force_unwrapping` / `implicitly_unwrapped_optional` を opt-in 有効化しているため、強制アンラップは原則禁止（必要箇所は `// swiftlint:disable:next` で明示）
- ローカライゼーション文字列はリソースバンドルではなくコード内に埋め込み（`Localization.swift`）
- ユーザー向け文言を変更したら **4言語の README（`README.md` / `README.ja.md` / `README.ko.md` / `README.zh-Hans.md`）を同期**する

## テスト

テストでは `SettingsStore(defaults:)` イニシャライザに `UserDefaults(suiteName:)` で作った専用 suite を渡し、テスト間の状態を分離する（`RippleWindowControllerTests` の `makeSettingsStore()` が好例）。AppKit/UI に依存するクラスも `@MainActor` テストで直接インスタンス化して検証している。

## リリース

タグを push すると `.github/workflows/release.yml` が自動でリリースを作成する（ビルド → ZIP → GitHub Release → Homebrew Cask 更新）。バージョンはタグ名から導出される（`v0.0.X` → `0.0.X`）ので、コード側にバージョンを書く必要はない。

リリース手順:
```bash
git tag v0.0.X
git push origin v0.0.X
# あとは CI が自動処理する
```

**注意点:**

- **手動で `gh release create` しないこと。** CI の Release ワークフローと競合し、アセット上書きエラー（"Cannot delete asset from an immutable release"）が発生する。
- **このリポジトリは immutable releases が有効。** 一度タグを push してリリースが発行されると、そのバージョン名は**恒久的にロックされ二度と再利用できない**（リリースを削除しても、リポジトリオーナーでもそのタグの再作成は拒否される）。リリースが途中で失敗した場合は、同じタグを使い回さず**次のバージョン番号に上げて**やり直す。
- immutable リリースでも、リリースノート本文（`gh release edit --notes`）は後から編集できる（アセット・タグは変更不可）。
