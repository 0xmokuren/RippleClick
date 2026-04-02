# RippleClick

[English](README.md) | 日本語 | [简体中文](README.zh-Hans.md) | [한국어](README.ko.md)

macOSで左クリック時にマウスポインタの位置に波紋（リップル）エフェクトを表示するメニューバー常駐型ユーティリティアプリ。

![RippleClick Demo](ripple-click-demo.gif)

## インストール

### Homebrew（推奨）

```bash
brew tap 0xmokuren/tap
brew install --cask rippleclick
```

### 手動ダウンロード

[Releases](https://github.com/0xmokuren/RippleClick/releases) から最新の `.zip` をダウンロードし、解凍して `RippleClick.app` を Applications フォルダに移動してください。

> **初回起動時の注意:** 「システム設定」→「プライバシーとセキュリティ」→「このまま開く」で許可が必要です。また、クリック検知のためにアクセシビリティ権限の許可を求められます。

## 機能

- 左クリック時に波紋エフェクトを表示
- メニューバーからエフェクトのON/OFF切り替え
- 設定画面でカスタマイズ可能:
  - エフェクトの色（12色プリセット）
  - 波紋の最大サイズ（5段階）
  - ログイン時の自動起動
- 多言語対応（英語・日本語・中国語・韓国語）

## 必要環境

- macOS 13 (Ventura) 以降

## ビルド（開発者向け）

```bash
# 開発時
swift run

# リリースビルド（.app バンドル）
bash scripts/bundle.sh
open RippleClick.app
```

## ライセンス

[MIT License](LICENSE)
