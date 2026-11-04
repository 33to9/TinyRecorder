<p align="center">
<img src="../img/tinyrecorder-header.png" alt="TinyRecorder" width="800">
</p>
<h3 align="center">macOS 用の軽量な画面収録アプリ（macOS 27 に対応）</h3>
<p align="center">
<a href="https://www.tinyrecorder.app/ja/"><b>公式サイト：www.tinyrecorder.app</b></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.zh-TW.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <b>日本語</b> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>
</p>

> **TinyRecorder** は、2025 年半ばから開発が止まっている [lihaoyun6](https://github.com/lihaoyun6) 氏の [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) のコミュニティフォークです。
> このフォークは、**最新の macOS リリースとの互換性**（macOS 27 /「Golden Gate」以降）を重視しています。

## このフォークでの修正点

- ✅ **macOS 27 でメニューバーの録画コントロール（停止／一時停止／カメラ）が反応しない問題** — アップストリームの Issue [#295](https://github.com/lihaoyun6/QuickRecorder/issues/295) / [#296](https://github.com/lihaoyun6/QuickRecorder/issues/296)。原因：macOS 27 では、実際のポインタの位置にかかわらず、`locationInWindow` が `NSStatusItem` のウインドウの中心として報告されます。そのため SwiftUI のヒットテストでは、常に中央のコントロールしか反応しませんでした。`NSEvent.mouseLocation` で取得した実際のポインタの位置を使ってマウスイベントを再構築することで修正しました。

## 録画できるもの

- 画面全体、選択した範囲、1 つまたは複数のウインドウ、1 つのアプリケーション
- システムオーディオのみ（マイクの音声の有無を選択可能）
- **接続した iPhone や iPad** — 下記を参照してください
- 録画中のカメラオーバーレイと発表者オーバーレイ（macOS 14 以降）

### iPhone / iPad の録画

TinyRecorder では、Mac に接続した iPhone や iPad の画面を録画できます。TinyRecorder は Mac で動作するアプリで、iOS アプリではありません。

1. USB ケーブルでデバイスを接続してロックを解除し、確認が表示されたら **信頼** をタップします。
2. TinyRecorder の録画ツールバーで **モバイルデバイス** をクリックします。接続されているデバイスが一覧表示されます。
3. 必要に応じて **消音** をオンにし、**プリセット**（画質）を選んでから、デバイス名をクリックして録画を開始します。

macOS はデバイスを外部カメラとして認識するため、（画面収録ではなく）**カメラ** の権限が必要です。デバイスが一覧に表示されない場合は、ケーブルを接続し直し、デバイスのロックが解除されていることを確認してください。

## 動作環境

- macOS 12.3 以降

## インストール

### 方法 1：1 行でインストール（おすすめ、Gatekeeper の警告なし）

「ターミナル」を開き、次のコマンドをペーストして return キーを押します：

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/TinyRecorder/main/install.sh | bash
```

このスクリプトは GitHub から最新リリースをダウンロードし、SHA-256 を確認したうえで「アプリケーション」フォルダにインストールして起動します。curl でダウンロードしたファイルには検疫属性が付かないため、初回起動時に macOS にブロックされません。スクリプトは短いので、先に[内容を確認](../install.sh)することもできます。

### 方法 2：Homebrew

```bash
brew install --cask 33to9/tap/tinyrecorder
```

### 方法 3：DMG

[リリースページ](https://github.com/33to9/TinyRecorder/releases/latest)から最新の `TinyRecorder_vX.Y.Z.dmg` をダウンロードして開き、TinyRecorder を「アプリケーション」フォルダにドラッグします。

このアプリは Apple の公証を受けていないため、初回起動時に一度だけ macOS にブロックされます：
- **macOS 15 以降**：アプリをダブルクリックし（警告が表示されます）、**「システム設定」→「プライバシーとセキュリティ」** を開いて下にスクロールし、**「このまま開く」** をクリックします
- **macOS 12〜14**：アプリを右クリック → **「開く」** を選択します

### アップデート

アプリの **アップデートを確認…** を使用してください。ご自身でダウンロードする必要はなく、Gatekeeper の警告も表示されず、権限もそのまま保持されます。

## 必要な権限

| 権限 | 用途 |
|---|---|
| 画面収録 | 画面／ウインドウ／アプリケーション／システムオーディオの録画 |
| マイク | 音声の録音 |
| カメラ | カメラオーバーレイ／発表者オーバーレイ／iPhone や iPad の録画 |

### 初回起動時の設定

初回起動時に、簡単なステップごとのガイドが表示されます：

1. **画面収録**：**権限を付与** をクリックし、**「システム設定」→「プライバシーとセキュリティ」→「画面とシステムオーディオの録音」** で **TinyRecorder** をオンにします。ガイドに緑のチェックマークが表示されると、3 秒後に TinyRecorder が自動的に再起動します（すぐに再起動することもできます）。
2. **マイク**（オプション）：ナレーションを入れる場合は、最初の録画がシステムの確認ダイアログで中断されないよう、ここで許可しておきます。
3. **デフォルトのフォーマット**：H.265 / H.264 と MP4 / MOV を選択します。あとから「設定」で変更できます。
4. **はじめる**：録画を開始する場所（メニューバーのアイコン／Dock）が表示され、録画ツールバーが開きます。

### アップデート後に権限のガイドが何度も表示される場合

バージョン 1.7.15 以降、アプリは固定の証明書で署名されているため、アプリ内でのアップデート後も権限が保持されます。通常これが起きるのは、古いバージョンからアップデートした場合のみです。

TinyRecorder のスイッチがすでにオンになっている、オンのままにならない、あるいはどのボタンを押しても権限のガイドが開く場合は、macOS に記録されている権限が古いビルドのものになっています（macOS は権限をアプリのコード署名に結び付けており、その署名が変更されたためです）。次のいずれかの方法で解決できます：

- 権限のガイドで **権限をリセットして再起動** をクリックし、もう一度権限を付与します。
- **「設定」→「一般」→「権限」→「画面収録の権限を修復」** を開きます。
- TinyRecorder を終了し、「ターミナル」で `tccutil reset ScreenCapture com.33to9.TinyRecorder` を実行してから、TinyRecorder をもう一度開いて権限を付与します。

## ソースからのビルド

必要なもの：macOS SDK を含む Xcode 15 以降。

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open QuickRecorder.xcodeproj
# QuickRecorder スキームを選択してビルド（⌘B / ⌘R）
```

CI では GitHub Actions（`.github/workflows/build.yml`）でビルドします。`v*` タグをプッシュすると リリースが公開されます。

## ライセンスとクレジット

このプロジェクトは **AGPL-3.0** のもとでライセンスされています（[LICENSE](../LICENSE) を参照）。

- オリジナルプロジェクト：[QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- 画面録画エンジンの一部は @Mnpn 氏の [Azayaka](https://github.com/Mnpn/Azayaka) をもとにしています
- フォークのメンテナンス：[33to9](https://github.com/33to9) — Copyright © 2026
