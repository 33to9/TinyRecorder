<p align="center">
<img src="../img/tinyrecorder-header.png" alt="TinyRecorder" width="800">
</p>
<h3 align="center">macOS 用の軽量な画面収録アプリ（macOS 27 に対応）</h3>
<p align="center">
<a href="https://www.tinyrecorder.app/ja/"><b>公式サイト：www.tinyrecorder.app</b></a> · <a href="https://www.tinyrecorder.app/ja/#video"><b>▶ クイックスタート動画（英語）</b></a>
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
- **「設定」→「一般」→「権限」→「画面収録の権限」→「修復…」** を開きます。
- TinyRecorder を終了し、「ターミナル」で `tccutil reset ScreenCapture com.33to9.TinyRecorder` を実行してから、TinyRecorder をもう一度開いて権限を付与します。

## 自動化（AppleScript）

TinyRecorder は AppleScript で操作できます。ターミナル、ショートカット（「**AppleScript を実行**」アクション）、Raycast、Alfred、Keyboard Maestro、自作のスクリプトから録画を開始・停止できます。

ターミナルから：

```bash
osascript -e 'tell application "TinyRecorder" to record screen numbered 1'
osascript -e 'tell application "TinyRecorder" to stop recording'
```

初回は、スクリプトを実行する App（例：ターミナル）が TinyRecorder を制御してよいか macOS が確認します。「**OK**」をクリックしてください。あとから「**システム設定**」→「**プライバシーとセキュリティ**」→「**オートメーション**」で変更できます。

| コマンド | 動作 |
|---|---|
| `record screen numbered 1` | ディスプレイ 1 を録画（番号は 1 から）。`numbered` を省略すると画面の選択を開きます |
| `record application named "Safari"` | App を名前で指定して録画。`named` を省略すると App の選択を開きます |
| `record window titled "タイトル" in application "Safari"` | ウインドウを正確なタイトルで指定して録画。`in application` は省略可。`titled` を省略するとウインドウの選択を開きます |
| `record screen area` | 範囲選択を開き、マウスで範囲をドラッグします |
| `record system audio` | システムオーディオのみ録音。`microphone true` を付けると今回はマイクも録音します |
| `pause recording` / `resume recording` | 録画を一時停止 / 再開 |
| `stop recording` | 録画を停止して保存 |
| `discard recording` | 録画を停止し、ファイルをゴミ箱に移動 |
| `configure …` | 録画設定を変更（下の表を参照） |

`configure` には次のパラメータを自由に組み合わせて指定できます。変更は環境設定で変えた場合と同じく保存されます。録画中は使えません。

| パラメータ | 値 |
|---|---|
| `fps` | 10、15、24、30、60、90、120、144、240 のいずれか |
| `quality` | 1 = 低、2 = 中、3 = 高 |
| `hires` | `true` で Retina 解像度 |
| `cursor` | マウスポインタを録画するか |
| `sound` | システム / App のサウンドを録音するか |
| `microphone` | マイクを録音するか |
| `mic device` | 入力デバイス名、または `"default"` |
| `hdr` | HDR で録画（macOS 15 以降） |
| `save folder` | 録画の保存先フォルダ。既存のフォルダである必要があり、`~` も使えます |

例：ディスプレイ 1 を 1 分間録画する。

```applescript
tell application "TinyRecorder"
    configure fps 30 quality 2 cursor true save folder "~/Movies"
    record screen numbered 1
end tell
delay 60
tell application "TinyRecorder" to stop recording
```

補足：
- 録画コマンドはすぐに戻ります。「**録画開始までの待ち時間**」（環境設定 → 録画）を設定している場合、録画はカウントダウン後に始まるので、その分を `delay` に足してください。
- カウントダウン中に `stop recording` または `discard recording` を送ると、録画は開始前に取り消されます。別の録画コマンドは「録画中」として拒否されます。
- 名前が複数のウインドウに一致する場合や、App のウインドウが複数の画面にある場合は、選択画面が開くので手動で選んでください。
- エラー（すでに録画中、録画していない、画面収録の権限がない）はスクリプトに返され、`osascript` はエラーで終了します。
- iPhone / iPad の録画では `pause`、`resume`、`discard` は使えません。`stop recording` は使えます。

## ソースからのビルド

必要なもの：macOS SDK を含む Xcode 15 以降。

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open TinyRecorder.xcodeproj
# TinyRecorder スキームを選択してビルド（⌘B / ⌘R）
```

CI では GitHub Actions（`.github/workflows/build.yml`）でビルドします。`v*` タグをプッシュすると リリースが公開されます。

## ライセンスとクレジット

このプロジェクトは **AGPL-3.0** のもとでライセンスされています（[LICENSE](../LICENSE) を参照）。

- オリジナルプロジェクト：[QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- 画面録画エンジンの一部は @Mnpn 氏の [Azayaka](https://github.com/Mnpn/Azayaka) をもとにしています
- フォークのメンテナンス：[33to9](https://github.com/33to9) — Copyright © 2026
