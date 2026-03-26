# RippleClick

macOSで左クリック時にマウスポインタの位置に波紋（リップル）エフェクトを表示するメニューバー常駐型ユーティリティアプリ。

## 必要環境

- macOS 13 (Ventura) 以降
- Swift 5.9+

## ビルド・実行

### 開発時（swift run）

```bash
swift run
```

> `swift run` ではDockアイコンが表示される場合があります（Info.plistが読み込まれないため）。

### リリースビルド（.app バンドル）

```bash
bash scripts/bundle.sh
open RippleClick.app
```

## 機能

- 左クリック時に波紋エフェクトを表示
- メニューバーからエフェクトのON/OFF切り替え
- 設定画面でカスタマイズ可能:
  - エフェクトの色
  - 波紋の最大サイズ（30〜200px）
  - ログイン時の自動起動
