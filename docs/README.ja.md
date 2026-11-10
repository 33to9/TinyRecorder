<p align="center">
<img src="../img/tinyrecorder-header.png" alt="TinyRecorder" width="800">
</p>
<h3 align="center">macOS 用の軽量な画面収録アプリ（macOS 27 に対応）</h3>
<p align="center">
<a href="https://github.com/33to9/TinyRecorder/releases/latest"><img src="https://img.shields.io/github/v/release/33to9/TinyRecorder?style=flat" alt="Latest release"></a> <a href="https://github.com/33to9/TinyRecorder/releases"><img src="https://img.shields.io/github/downloads/33to9/TinyRecorder/total?style=flat" alt="Total downloads"></a> <a href="https://github.com/33to9/TinyRecorder/releases/latest"><img src="https://img.shields.io/github/downloads/33to9/TinyRecorder/latest/total?style=flat" alt="Downloads of the latest release"></a> <a href="https://github.com/33to9/TinyRecorder/blob/main/LICENSE"><img src="https://img.shields.io/github/license/33to9/TinyRecorder?style=flat" alt="License"></a>
</p>
<p align="center">
<a href="https://www.tinyrecorder.app/ja/"><b>公式サイト：www.tinyrecorder.app</b></a> · <a href="https://www.tinyrecorder.app/ja/#video"><b>▶ クイックスタート動画（英語）</b></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <b>日本語</b> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>
</p>

> **TinyRecorder** は、[lihaoyun6](https://github.com/lihaoyun6) 氏の [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) のコミュニティフォークです。QuickRecorder は軽くて速い、本当に良い録画アプリですが、2025 年半ばから開発が止まり、macOS 27 ではメニューバーの停止・一時停止・カメラボタンが反応しなくなりました。
> 更新が止まったというだけで、良いアプリが消えてしまうのはあまりに惜しい。このフォークはそのバトンを受け継ぎ、**最新の macOS リリースとの互換性**（macOS 27 /「Golden Gate」以降）を重視して保守しています。


https://github.com/user-attachments/assets/bf8c2512-a823-40e2-bb89-748e7202bd74

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

## プライバシー

録画はお使いの Mac から外に出ることはありません。アプリの改善のため、TinyRecorder は [TelemetryDeck](https://telemetrydeck.com/privacy/) を通じて匿名の使用状況データを送信します。内容は、アプリと macOS のバージョン、言語、Mac の機種、そして収録ごとの種類（画面、ウインドウ、範囲、オーディオなど）、形式、エンコーダ、フレームレート、マイクのオン／オフ、長さ、保存できたかどうか、失敗した場合はエラーコードです。これらを結び付けるため収録ごとにランダムな ID を付けますが、あなたやファイルとは関連付けられません。また、初回セットアップのどのステップまで進んだか（または閉じたか）と、画面収録とマイクへのアクセスを求めたか・許可されたかも送信します。収録ごとに、どこから開始したか（ツールバー、メニューバー、ショートカット、スクリプト、コマンドラインツール）と、初めての収録かどうかも送信します。録画内容、ファイル名、フォルダ、ウインドウやアプリのタイトル、エラーメッセージは一切送信しません。アカウントやユーザ ID はありません。アプリが生成したランダムな識別子は送信前にハッシュ化され、TelemetryDeck は IP アドレスを保存しません。オフにするには「設定」›「一般」›「プライバシー」で「匿名の使用状況データを共有」をオフにしてください。

使用状況データの送信は初期設定でオンになっています。詳しくは[プライバシーページ](https://www.tinyrecorder.app/ja/privacy)をご覧ください。

## コマンドラインツール

TinyRecorder には `tinyrecorder` コマンドが付属しています。Homebrew でインストールすると自動で使えるようになり、ワンライナーのインストーラもパスワードが不要な場合はリンクを作成します。それ以外の場合は、**TinyRecorder › コマンドラインツールをインストール…**（バージョン 1.8.22 以降。設定 › 一般 にもあります）を選ぶか、次のコマンドを一度実行してください：

```bash
sudo mkdir -p /usr/local/bin && sudo ln -sf /Applications/TinyRecorder.app/Contents/Resources/tinyrecorder /usr/local/bin/tinyrecorder
```

使い方の例：

```bash
tinyrecorder record screen 1 --duration 10
tinyrecorder list windows --app TextEdit          # ウインドウの ID、タイトル、サイズ
tinyrecorder record window --id 1234 --output ~/Desktop/demo.mp4
tinyrecorder status
tinyrecorder stop
tinyrecorder record area 0,0,1280,720 --duration 5 --quiet
tinyrecorder frames ~/Desktop/demo.mp4 --sheet    # 収録内容がわかる 1 枚の画像
tinyrecorder screenshot window --id 1234 --output shot.png
tinyrecorder doctor                               # 権限と保存先フォルダを確認
```

`record` は収録が実際に始まるまで待ってから戻り、`stop` はファイルの保存が終わるまで待ってからパスを表示します。`--json` を付けると、各コマンドが JSON オブジェクトを 1 つ出力します。

- `list displays`、`list windows`、`list apps` で、収録できる対象をディスプレイ番号やウインドウ ID とともに表示します。
- `record area X,Y,WIDTH,HEIGHT` は、ディスプレイの左上からのポイント単位で指定した範囲を、ドラッグせずに収録します（別のディスプレイは `--display N`）。
- `screenshot` はディスプレイ、ウインドウ、範囲の PNG を保存し、そのパスを表示します。TinyRecorder の画面収録の権限を使うので、ターミナルに権限を与える必要はありません。
- `--output PATH` で収録をその名前で保存します。`config --format mp4|mov --codec h264|h265` でファイル形式とコーデックを設定します。
- `--quiet` を付けるとすぐに収録を始め、終了後もプレビューを表示しないので、収録や次のスクリーンショットの邪魔になりません（`--no-countdown` と `--no-preview` はそれぞれ片方だけを行います）。
- `frames FILE` は収録から静止画を保存します（`--every 2`、`--count 8`、または時刻付きのコンタクトシートを 1 枚作る `--sheet`）。エージェントは動画を再生せずに、収録内容を確認できます。
- `doctor` は必要なものがそろっているかを確認します：画面収録の権限、TinyRecorder を操作する権限、PATH 上のコマンド、保存先フォルダ。`config --show` は現在の設定を表示します。

すべてのコマンドとオプションは `tinyrecorder help` で確認できます。`list`、`screenshot`、`record area X,Y,WIDTH,HEIGHT`、`--id`、`--output`、`--format`、`--codec` にはバージョン 1.8.25 以降が必要です。`doctor`、`frames`、`config --show`、`--quiet`、`--no-countdown`、`--no-preview` には 1.8.26 以降が必要です。

### AI エージェントから使う

Claude Code、Codex、Cursor などのコーディングエージェントはターミナルのコマンドを実行できるので、`tinyrecorder` で画面を収録できます。たとえば再現したバグや、作ったばかりの機能のデモを収録できます。プロジェクトの `CLAUDE.md` または `AGENTS.md` に次の内容を追加すると、エージェントが使い方を把握できます：

```markdown
## 画面収録
この Mac には TinyRecorder がインストールされています。`tinyrecorder` コマンドで画面を収録できます：
- コマンドが失敗したら、`tinyrecorder doctor` を実行して、その結果を教えてください。
- `tinyrecorder record screen 1 --duration 15 --quiet --json`：メインディスプレイを 15 秒収録し、{"file": "<パス>"} を出力します。
- `tinyrecorder frames <パス> --sheet --json`：収録から取り出したフレームを 1 枚の画像に保存します。その画像を見て、収録内容を確認してください。
- `tinyrecorder list windows --json`：ウインドウを ID 付きで一覧表示します。`tinyrecorder record window --id <ID>` でそのウインドウの収録を開始し、`tinyrecorder stop --json` で停止してファイルのパスを出力します。
- `tinyrecorder screenshot window --id <ID> --json`（または `screenshot screen 1`）：PNG を保存し、{"file": "<パス>"} を出力します。
- `--output <パス>`：`record` に付けると、収録の保存先を指定できます。
- `tinyrecorder status --json`：収録中かどうかを確認します。
エラーは stderr に出力され、終了ステータスは 0 以外になります。すべてのオプションは `tinyrecorder help` で確認できます。
```

macOS は画面収録の許可と、ターミナルが TinyRecorder を操作する許可を一度だけ求めます。収録中はメニューバーに表示されるので、知らないうちに収録されることはありません。

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
| `record window identified by 1234` | 指定した ID のウインドウを録画（ID は `list targets` で確認） |
| `record screen area` | 範囲選択を開き、マウスで範囲をドラッグします |
| `record screen area rectangle "0,0,1280,720"` | 指定した範囲を録画。x、y、幅、高さをディスプレイの左上からのポイント単位で指定します。別のディスプレイは `display number 2` を追加 |
| `record system audio` | システムオーディオのみ録音。`microphone true` を付けると今回はマイクも録音します |
| `pause recording` / `resume recording` | 録画を一時停止 / 再開 |
| `stop recording` | 録画を停止して保存 |
| `stop recording with waiting until saved` | 録画を停止し、ファイルの保存（音声のミックスや変換を含む）が終わるまで待ってからパスを返します。保存に失敗した場合はエラーを返します。 |
| `recording status` | 現在の状態（idle、countdown、starting、recording、paused）を返します。収録中は収録の種類と経過秒数も返します。 |
| `discard recording` | 録画を停止し、ファイルをゴミ箱に移動 |
| `list targets showing "windows"` | 録画できるウインドウを ID 付きで 1 行に 1 つずつ返します。`"displays"` と `"apps"` も指定可。`in application "Safari"` で絞り込み、`json true` で JSON を返します |
| `diagnose` | 画面収録とマイクの権限、保存先フォルダを確認し、設定を一覧表示します。1 項目につき 1 行（種類、状態、名前、値）、`json true` で JSON を返します |
| `extract frames from file "/path/demo.mp4"` | 録画から静止画を保存し、そのパスを返します。`interval 2`、`frame count 8`、`contact sheet true`、`maximum width 640`、`saving to "/folder"` を追加できます |
| `take screenshot` | ディスプレイ 1 の PNG を保存し、そのパスを返します。`display number 2`、`window identified by 1234`、`window titled "タイトル"`、`rectangle "x,y,w,h"` や、`saving to "~/shot.png"` を追加できます |
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
| `file format` | `"mp4"` または `"mov"` |
| `video codec` | `"h264"` または `"h265"` |
| `countdown` | 録画開始までの待ち時間（秒、0〜99） |
| `show preview` | 保存後にプレビューのサムネールを表示するか |

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
- 録画コマンドはすべて（選択画面を開くものを除く）`countdown 0` と `showing preview false` を受け付けます。`countdown 0` ですぐに開始し、`showing preview false` で終了後のプレビュー、トリミング画面、通知を表示しません。どちらもその録画にだけ適用されます。
- 録画コマンドはすべて（選択画面を開くものを除く）`saving to "/path/name"` を受け付けます。録画はその場所に、現在の形式の拡張子を付けて保存されます。フォルダは既存である必要があり、既存のファイルが置き換えられることはありません。
- タイトルが複数のウインドウに一致する場合、コマンドはエラーを返します。代わりにウインドウの ID を使ってください。App のウインドウが複数の画面にある場合は、選択画面が開くので手動で選んでください。このときもコマンドはエラーを返します。
- エラー（すでに録画中、録画していない、画面収録の権限がない）はスクリプトに返され、`osascript` はエラーで終了します。画面番号が無効な場合や、アプリやウインドウが見つからない場合も同様で、ダイアログは表示されません。
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
