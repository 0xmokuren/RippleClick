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
1. `ClickMonitor` が **入力監視（Input Monitoring）権限**で動く `CGEventTap`（`.cgSessionEventTap` / `.listenOnly`、左右の mouseDown のみ）でクリックを監視する。App Sandbox 下ではアクセシビリティ権限が使えず `NSEvent.addGlobalMonitorForEvents` に頼れないため、App Store 版と Developer ID 版の両方でこの方式に統一している。
   - CGEventTap は自アプリ宛てのクリックも受け取るので、**タップが張れている間はローカル監視を張らない**（張ると波紋が二重に出る）。
   - 権限が無い間は `addLocalMonitorForEvents` で代用し、設定ポップオーバー上のプレビューだけは動かす。同時に `CGRequestListenEventAccess` で権限を要求し、`accessPollInterval`（2 秒）ごとに `CGPreflightListenEventAccess` を確認して、許可されたらタップへ切り替えてローカル監視を外す。
   - 権限の確認と要求は `ListenEventAccess` に切り出してあり、テストでは差し替えて実際の TCC の状態に依存しないようにしている。
   - タップが `tapDisabledByTimeout` / `tapDisabledByUserInput` で止められたらコールバック内で有効に戻す。
2. 種別を判定（右クリック / `clickCount >= 2` のダブルクリック / 左クリック）し、各種別の有効フラグを確認してから `RippleWindowController.showRipple(at:clickType:)` を呼ぶ
3. `RippleWindowController` がクリック種別に応じてサイズ・色・リング数・線幅を決め、透明ボーダレスウィンドウを生成 → `RippleView`（CALayer アニメーション）が波紋を描画
4. `soundEnabled` なら `SoundPlayer.shared.playSound` で効果音を再生

クリック種別ごとの差: **右クリックは2重リング**、**ダブルクリックはサイズ1.2倍・線幅2倍**。色も種別ごとに独立して設定できる（通常/ライト/ダークの3系統）。

### 設定 UI（ポップオーバー）

Interface Builder は使わず、すべてコードで絶対座標配置している。関連ファイルは `SettingsViewController.swift`（骨組みとアクション）/ `SettingsViewController+Sections.swift`（各タブの中身と UI ヘルパー）/ `SettingsTab.swift`（タブ定義）。

- **開き方** — アイコン**左クリック**で `StatusBarController` が `NSPopover`（`.transient` / `animates = false`）をアイコン直下に出す。**右クリック**は従来のコンテキストメニュー（設定 / エフェクト切替 / About / 終了）。
- **構成** — 常時表示のヘッダー（波紋エフェクト ON/OFF）＋タブバー（`SettingsTab`: ripple / color / sound / general）＋スクロール領域。タブは `NSSegmentedControl` で、`segmentDistribution = .fillEqually` を外すとラベル幅のまま右端が切れる。
- **高さは定数ではなく実測** — `buildSections()` が y = 0 から下方向に積み、`alignSectionsToTop` がサブビューの占有範囲を実測して documentView 高を決める。**タブごとの高さ定数は持たない**ので、項目を増減しても定数調整は不要。
- **表示中は `view.frame` を書き換えない** — `NSPopover` は contentSize を view の実寸から見ているため、先に縮めると `popover.contentSize` の代入が同値扱いで無視され、ウィンドウだけ前のタブの高さに取り残されて上部に空き帯ができる。表示中（`rebuildContent()` 経由のタブ切替・外観トグル・リセット）は `popover.contentSize` だけを設定し、ウィンドウと view のリサイズは popover に任せる。
- **クロームの追従は `setFrameSize` から同期的に行う** — リサイズは frame 変更が先に走り `viewDidLayout` は次のレイアウトパスまで来ないため、そこに任せると1フレームだけヘッダーが旧位置に残る。ルートビュー `SettingsContainerView` の `setFrameSize` から `layoutChrome()` を呼んでいる。
- **アイコンクリックでの開閉** — transient ポップオーバーは mouseDown で自ら閉じるため、ボタンの action（mouseUp）時点では `isShown` が false になっている。`StatusBarController` は直近のクローズ時刻を見て再オープンを抑止している（この抑止を外すとアイコンクリックで閉じられなくなる）。
- 子ビューは**親の幅を確定させてから** addSubview する。幅0の親に足すと autoresizing の比例計算が崩れて幅が壊れる。

### 押さえるべき設計上のポイント

- **`SettingsStore`** — UserDefaults ラッパー（`@MainActor` シングルトン）で全設定の唯一の真実源。色変更系の setter は `.rippleColorChanged` を post する。数値はすべてクランプされる（maxRippleSize 10–500、rippleOpacity 0.1–1.0、animationDuration 0.1–2.0、soundVolume 0–1）。イニシャライザが2つあり、`private init()` は `UserDefaults.standard`（本番シングルトン）、`init(defaults:)` はテスト用の注入口。
- **ウィンドウのプール再利用** — `RippleWindowController` は `NSWindow` と `RippleView` を毎回生成・破棄せず `windowPool` で再利用する。同時表示は最大 `maxConcurrentWindows = 10`（超過時は最古をリサイクル）。表示後 `animationDuration + 0.05` 秒でリサイクルに回す。`RippleView.reset()` で再利用、`clearLayers()` でサブレイヤを破棄する。
- **効果音はファイルではなくプログラム合成** — `SoundPlayer`（`@MainActor` シングルトン）が5種類（`SoundType`: waterDrop / pop / sonar / bubble / softClick）を sin 波＋エンベロープで波形合成し、`AVAudioEngine` で再生する。生成したバッファは種別ごとにキャッシュする。音声リソースファイルは存在しない。
- **ログイン項目** — `LoginItemManager` が `SMAppService.mainApp` で登録/解除する。**実際の .app バンドル（bundle identifier が必要）でのみ動作**し、`swift run` では機能しない。

## 入力監視権限とコード署名（動作確認に必須）

- グローバルクリック監視には**入力監視権限が必須**。未許可の間は設定画面上のプレビューしか動かない（`ClickMonitor.start()` が起動時に `CGRequestListenEventAccess` で要求する）。`swift run` で動かす実行バイナリにも個別に権限付与が必要なので、挙動確認は基本的に `bundle.sh` で生成した `.app` で行う。
- `bundle.sh` の署名は `SIGNING_IDENTITY` 環境変数で切り替わる:
  - 既定は **ad-hoc 署名**（`"-"`）。この場合、アプリ更新のたびに TCC（入力監視）権限がリセットされる。
  - `SIGNING_IDENTITY` に Developer ID か自己署名証明書を指定すると、hardened runtime + `Resources/RippleClick.entitlements` で署名され、**TCC 権限が更新をまたいで保持される**。
  - 自己署名証明書は `bash scripts/create-signing-cert.sh` で作成し、`SIGNING_IDENTITY="RippleClick Development" bash scripts/bundle.sh` でビルドする。
  - `SIGNING_IDENTITY` が `Developer ID Application` で始まるときだけ `--timestamp` を付ける（公証に必須。自己署名証明書では付けない）。
- 公証は `scripts/notarize.sh` が行う。App Store Connect API キー（`NOTARY_API_KEY_PATH` / `NOTARY_API_KEY_ID` / `NOTARY_API_ISSUER_ID`）で `notarytool submit --wait` → `stapler staple` → `spctl --assess` まで実行し、不合格ならログを出して失敗する。

## Mac App Store 版

- `scripts/bundle-appstore.sh <version> [build-number]` が App Store 提出用の `.pkg` を作る。arm64 のみでビルドし、`embedded.provisionprofile` を同梱して `Resources/RippleClick-AppStore.entitlements`（App Sandbox）で署名し、`productbuild` でインストーラー署名付きの pkg にする。アップロードは Transporter で行う。
- 必要なもの: `PROVISIONING_PROFILE`（App ID `com.0xmokuren.RippleClick` の Mac App Store 用プロファイル）、アプリ署名用の Apple Distribution 証明書、インストーラー署名用の Mac Installer Distribution 証明書。署名 ID は `APP_SIGNING_IDENTITY` / `INSTALLER_SIGNING_IDENTITY` で上書きできる。
- 出力先の既定は一時ディレクトリ。リポジトリが iCloud 同期下（`~/Documents` 等）にあると File Provider が `com.apple.FinderInfo` を付け直し、`codesign --verify --strict` が失敗するため。同じ理由で、手元の `swift test` がテストバンドルの署名で失敗する場合は `--scratch-path` で同期対象外に出力する。
- App Store に提出する同じバージョンを再アップロードするときは `build-number` を上げる（`CFBundleVersion` は提出のたびに増やす必要がある）。
- Info.plist の `LSApplicationCategoryType`（App Store 提出に必須）と `ITSAppUsesNonExemptEncryption = false`（暗号の輸出規制の質問を省く）は Developer ID 版にもそのまま入っていて問題ない。

## コードスタイル

- インデント: スペース4つ
- 行長上限: 120（warning）/ 150（error）。その他の閾値は `.swiftlint.yml` 参照
- SwiftLint で `force_unwrapping` / `implicitly_unwrapped_optional` を opt-in 有効化しているため、強制アンラップは原則禁止（必要箇所は `// swiftlint:disable:next` で明示）
- ローカライゼーション文字列はリソースバンドルではなくコード内に埋め込み（`Localization.swift`）
- ユーザー向け文言を変更したら **4言語の README（`README.md` / `README.ja.md` / `README.ko.md` / `README.zh-Hans.md`）を同期**する

## テスト

テストでは `SettingsStore(defaults:)` イニシャライザに `UserDefaults(suiteName:)` で作った専用 suite を渡し、テスト間の状態を分離する（`RippleWindowControllerTests` の `makeSettingsStore()` が好例）。AppKit/UI に依存するクラスも `@MainActor` テストで直接インスタンス化して検証している。

`LivePopoverTests` だけは例外で、実際に `NSPopover` を表示してタブを往復させ、view 高・ヘッダー位置・ウィンドウ高との差分が一定であることを検証する（ポップオーバー主導のリサイズは実ウィンドウがないと再現できないため）。ポップオーバーを表示できない環境では `XCTSkipUnless` で skip する。高さは実測値なので、UI の行間や項目を変えると期待値も変わる — 落ちたら `swift test --filter LivePopoverTests` の出力で実測値を確認する。

## リリース

タグを push すると `.github/workflows/release.yml` が自動でリリースを作成する（ビルド → ZIP → GitHub Release → Homebrew Cask 更新）。バージョンはタグ名から導出される（`v0.0.X` → `0.0.X`）ので、コード側にバージョンを書く必要はない。

リリース手順:
```bash
git tag v0.0.X
git push origin v0.0.X
# あとは CI が自動処理する
```

Release ワークフローは Developer ID 署名と公証を必須にしている。次の Secrets が1つでも欠けているとリリース作成前に失敗する。

| Secret | 内容 |
| --- | --- |
| `SIGNING_IDENTITY` | `Developer ID Application: 氏名 (TEAMID)` |
| `DEVELOPER_ID_CERT_P12_BASE64` | Developer ID Application 証明書（秘密鍵込みの .p12）を base64 にしたもの |
| `DEVELOPER_ID_CERT_PASSWORD` | .p12 のパスワード |
| `NOTARY_API_KEY_P8_BASE64` | App Store Connect API キー（.p8）を base64 にしたもの |
| `NOTARY_API_KEY_ID` | API キーの Key ID |
| `NOTARY_API_ISSUER_ID` | API キーの Issuer ID |

**注意点:**

- **手動で `gh release create` しないこと。** CI の Release ワークフローと競合し、アセット上書きエラー（"Cannot delete asset from an immutable release"）が発生する。
- **このリポジトリは immutable releases が有効。** 一度タグを push してリリースが発行されると、そのバージョン名は**恒久的にロックされ二度と再利用できない**（リリースを削除しても、リポジトリオーナーでもそのタグの再作成は拒否される）。リリースが途中で失敗した場合は、同じタグを使い回さず**次のバージョン番号に上げて**やり直す。
- immutable リリースでも、リリースノート本文（`gh release edit --notes`）は後から編集できる（アセット・タグは変更不可）。
