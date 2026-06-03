# RippleClick

[English](README.md) | 日本語 | [简体中文](README.zh-Hans.md) | [한국어](README.ko.md)

<p>
  <a href="https://github.com/0xmokuren/RippleClick/releases"><img src="https://img.shields.io/github/v/release/0xmokuren/RippleClick?label=release" alt="最新リリース"></a>
  <a href="https://github.com/0xmokuren/RippleClick/releases"><img src="https://img.shields.io/github/downloads/0xmokuren/RippleClick/total" alt="ダウンロード数"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-black?logo=apple" alt="macOS 13+">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/0xmokuren/RippleClick" alt="ライセンス"></a>
</p>

**すべてのクリックを“見える化”する。** RippleClick は、クリックした瞬間にマウスポインタの位置へ波紋（リップル）を描く軽量な macOS メニューバー常駐アプリです。任意で効果音も鳴らせます。画面録画・ライブデモ・プレゼン・チュートリアルなど、どこをクリックしたかを観客に正確に伝えたい場面に最適です。

![RippleClick Demo](ripple-click-demo.gif)

## 特長

- 🌊 **即座の視覚フィードバック** — クリックのたびにポインタ直下へ滑らかな波紋アニメーションを表示。
- 🖱️ **左・右・ダブルクリック対応** — クリック種別ごとに見た目が異なり、個別にON/OFFできます。
- 🎨 **自由にカスタマイズ** — 12色のプリセット、5段階のサイズ、速度・不透明度も調整可能。
- 🌗 **ライト / ダーク対応** — ライトモードとダークモードで別々の色を設定でき、自動で切り替わります。
- 🔊 **内蔵の効果音** — 合成音5種類。音量スライダーとプレビュー付き。
- 🪶 **超軽量** — メニューバーのみ・Dockアイコンなし・待機時のCPU負荷はごくわずか。
- 🌍 **4言語対応** — 英語・日本語・简体中文・한국어。

## 機能

### クリック種別

各クリック種別は個別にON/OFFでき、見た目も独立して設定できます。

| クリック     | 既定の見た目                       | 設定できる項目                       |
| ------------ | ---------------------------------- | ------------------------------------ |
| 左クリック   | 1重の波紋リング                    | 色（通常 / ライト / ダーク）         |
| 右クリック   | **2重の波紋リング**                | 有効化・外観ごとの色                 |
| ダブルクリック | **サイズ1.2倍・線幅2倍**          | 有効化・外観ごとの色                 |

### カスタマイズ

- **エフェクトの色** — 12色プリセット：シアン・ブルー・ネイビー・パープル・ピンク・レッド・オレンジ・イエロー・ライム・グリーン・ティール・ホワイト。
- **システムの外観に合わせる** — ライト/ダークで別々の色を指定でき、macOS の切り替えに追従して即座に入れ替わります。
- **波紋の最大サイズ** — 5段階（小 → 大）。
- **アニメーション速度** — 5段階（速い → 遅い）。
- **不透明度** — 5段階（控えめ → くっきり）。
- **ログイン時に自動起動** — サインイン時に自動で起動します。

### 効果音

効果音はアプリ内で合成しており（音声ファイルは同梱していません）、どの音量でもクリアに鳴ります：

| 効果音      | 雰囲気                   |
| ----------- | ------------------------ |
| Water Drop  | 柔らかな水滴のポチャッ音 |
| Pop         | 短く弾けるポップ音       |
| Sonar       | クリアなソナーのピン音   |
| Bubble      | まるい泡のブリップ音     |
| Soft Click  | やさしいメカニカル音     |

音量は5段階スライダーで調整でき、**プレビュー**で現在の音を試聴できます。

## インストール

### Homebrew（推奨）

```bash
brew tap 0xmokuren/tap
brew install --cask rippleclick
```

### 手動ダウンロード

[Releases](https://github.com/0xmokuren/RippleClick/releases) から最新の `.zip` をダウンロードし、解凍して `RippleClick.app` を Applications フォルダに移動してください。

> **初回起動時の注意:** 「システム設定」→「プライバシーとセキュリティ」→「このまま開く」で許可が必要です。また、システム全体のクリック検知のために **アクセシビリティ** 権限の許可を求められます。

## 使い方

1. RippleClick を起動すると、メニューバーに 💧 アイコンが表示されます。
2. アイコンをクリックしてエフェクトの **ON / OFF** 切り替え、または **設定** を開きます。
3. **設定** から色・サイズ・速度・不透明度・クリック種別・効果音を調整できます。

## 必要環境

- macOS 13 (Ventura) 以降

## プライバシー

RippleClick がアクセシビリティ権限を必要とするのは、波紋を描くために「いつ」「どこで」クリックされたかを知るためだけです。クリックや入力した内容を **記録・保存・送信することは一切ありません**。ネットワーク通信も解析も行いません。

## ビルド（開発者向け）

```bash
swift build              # デバッグビルド
swift run                # 開発実行
swift test               # テスト実行

bash scripts/bundle.sh   # リリースビルド（.app バンドル）
open RippleClick.app
```

> アクセシビリティ権限はバイナリごとに付与されるため、挙動確認は `swift run` よりも生成した `.app` で行うのが確実です。アーキテクチャや署名・リリース手順は [CLAUDE.md](CLAUDE.md) を参照してください。

## コントリビュート

Issue や Pull Request を歓迎します。PR を出す前に `swiftlint lint --strict` と `swift-format lint --strict --recursive Sources/ Tests/` を実行し、ユーザー向け文言を変更した場合は4言語の README を同期してください。

## ライセンス

[MIT License](LICENSE)
