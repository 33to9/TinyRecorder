# TinyRecorder · macOS アイコンとブランド素材

<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <b>日本語</b> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>

提供された「ディスプレイ + 録画ドット」の参考画像をもとに、すべてのベクター形状を描き直しました。参考コラージュにあったノイズ、エッジの残り、装飾用のファイルバッジは取り除いています。ライトはプロジェクトの既定のアプリアイコン、ダークは任意の代替です。すべての PNG に sRGB プロファイルが付いています。SVG はいくらでも拡大でき、ブランドのワードマークはアウトライン化済みです。

## プロジェクトに組み込み済みのもの

- `TinyRecorder/Assets.xcassets/AppIcon.appiconset/`：従来の macOS 用の PNG 10 枚一式。16 / 32 / 128 / 256 / 512 pt、それぞれ 1× と 2×。
- `TinyRecorder/Assets.xcassets/TinyRecorderMenuBar.imageset/`：18 pt の黒・透明のテンプレート、macOS 1× / 2×。録画していないときは SwiftUI が `.template` でレンダリングし、メニューバーの外観に合わせて色が付きます。18 pt はこのプロジェクトのデザインサイズで、Apple が求めるサイズではありません。`menubar/` には 54 px の書き出しもあります。
- `img/tinyrecorder-header.png`：各言語の README の冒頭で使用しています。

## フォルダと用途

| フォルダ | 内容 |
| --- | --- |
| `macos/` | ライトとダークの `.icns` と完全な `.iconset`。従来の macOS / Finder / Dock 用 |
| `xcode/` | そのまま読み込める AppIcon、AppIconDark、メニューバーのアセットカタログ |
| `source/` | 1024 のベクターマスターと、16/32 pt 用に視覚補正した版 |
| `png/` | ライトとダークのアプリアイコン 1024 px と 2048 px、周囲は透明 |
| `logo/` | カラー、反転、ダークのモノクロ、白のモノクロ。シンボル単体、横組み、縦組み、ワードマークのみ。SVG + 透過 PNG |
| `menubar/` | メニューバーのテンプレートと、一時停止状態の代替 SVG |
| `icon-composer/` | 新しいレイヤー SVG、全面背景色の参考、Mac での読み込み手順 |
| `documents/` | 任意の QMA ファイルアイコン：SVG / PNG / iconset / icns。既存のファイルタイプ宣言は変更していません |
| `web/` | 任意の Web サイト用 favicon SVG / ICO、180/192/512 PNG、apple-touch-icon と manifest |
| `marketing/` | GitHub README 用バナー 1600×480、GitHub ソーシャルプレビュー 1280×640、DMG インストーラ背景 660×400 とその 2× 版 |
| `preview/` | 全素材の一覧 SVG / PNG |

## ライトとダークの使い分け

従来の macOS の appiconset は、2 組のファイルをフォルダに置くだけでは自動で切り替わりません。既定では `AppIcon` を使用します。すべてダークにしたい場合は、`xcode/AppIconDark.appiconset/` をプロジェクトに追加してターゲットの App Icon Set Name を `AppIconDark` に変えるか、既定の PNG をダークの iconset の対応する PNG に置き換えてください。

新しい外観とシステムのガラス効果には、`icon-composer/` のレイヤー素材を使います。背景は全面かつ不透明、前景は透明のままにし、角丸はシステムが付けます。ここにあるのは読み込み用のソースファイルです。`.icon` プロジェクトはまだ Mac 上で作成も検証もしていないため、従来のレンダリング済みアイコンをネイティブの Liquid Glass アイコンと呼んではいけません。

## デザインルール

- 色：Ink `#293248`、Record `#FF435C`、Canvas `#F3F5FA`。
- ロゴの周囲には、録画ドットの直径以上の余白を取ってください。引き伸ばしたり、ドットの位置を変えたり、アプリアイコンに文字を加えたりしないでください。
- 小さいアプリアイコンは、枠・スタンド・ドットを個別に太くしています。論理 pt サイズに合わせて元データを選んでください。16pt@2x と 32pt@1x はどちらも 32 px ですが、用途ごとに書き出しています。
- メニューバーのアイコンは黒と透明だけを使い、Template に設定します。ブランドの赤はメニューバーのテンプレートに焼き込みません。
- 参考画像の右下にある「SVG」のファイルバッジは、アプリの実際のファイルタイプを表すものではありません。このキットでは任意の素材として QMA ファイルアイコンを追加しています。

## 再生成と検証

`TinyRecorder-Brand-Kit` フォルダで実行します：

```sh
python -m pip install -r scripts/requirements-branding.txt
python scripts/generate_brand_assets.py
python scripts/validate_brand_assets.py
```

ジェネレータは SVG の形状からレンダリングするため、アップロードされた PNG には依存しません。`scripts/brand-fonts/Manrope.ttf` は Google Fonts のもので、SIL OFL ライセンスです。ライセンスファイルは同じフォルダにあります。ワードマークはアウトラインで書き出すため、フォントのインストールは不要です。

ジェネレータは `branding/` のほか、TinyRecorder リポジトリ内でアプリが使うコピー（`TinyRecorder/Assets.xcassets/`、`img/tinyrecorder-header.png`、`.github/assets/` の DMG 背景）も更新し、キットの zip を `deliverables/` に書き出します。README ファイルは手作業で管理しているため、変更しません。

ICNS はすべての標準サイズを PNG データとして格納しています。Mac ではシステムのツールで再生成と確認ができます（`iconutil` はこのフォルダで、`xcodebuild` はリポジトリのルートで実行）：

```sh
iconutil -c icns branding/macos/TinyRecorder.iconset -o /tmp/TinyRecorder.icns
xcodebuild -project TinyRecorder.xcodeproj -scheme TinyRecorder -configuration Release -destination 'generic/platform=macOS' CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build
```

これらの素材は Windows で作成しました。サイズ、アルファチャンネル、ICNS の構造、SVG、テンプレートの着色、プロジェクトからの参照は確認済みです。Xcode、actool、Icon Composer の実行や、Finder/Dock での実機確認は行っていません。

## Apple の公式資料

- [App icons（HIG）](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [App アイコンのアセットカタログの設定](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
- [Icon Composer で App アイコンを作成する](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
- [従来の macOS の高解像度アイコンサイズと iconutil](https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Optimizing/Optimizing.html)
- [メニューバー（HIG）](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [NSImage.isTemplate](https://developer.apple.com/documentation/appkit/nsimage/istemplate)
