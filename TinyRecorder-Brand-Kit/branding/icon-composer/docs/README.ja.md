# Icon Composer 用レイヤー素材

<a href="../README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.zh-TW.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <b>日本語</b> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>

これらは読み込み用の SVG ソース素材で、**コンパイル・検証済みの `.icon` プロジェクトではありません**。
プロジェクトには従来互換の AppIcon がすでに組み込まれているので、この作業を先に済ませる必要はありません。

1. Mac で Xcode に付属の Icon Composer を開き、キャンバス 1024 × 1024 の macOS アイコンを新規作成します。
2. Background を不透明な単色 `#F3F5FA` に設定します。ダークの外観には `#242C3D` を使います。背景の SVG は色見本で、全面の背景として読み込むこともできます。
3. 下から順に `layers/monitor-light.svg`、`layers/record-dot.svg` を読み込みます。どちらのレイヤーも元のキャンバス上の位置とサイズのままにし、見えている部分を先に切り抜かないでください。
4. ダークの外観では、ディスプレイのレイヤーを `monitor-dark.svg` に置き換えます。`mono` のファイルは単色の参考です。tinted / clear でのシステムの処理結果を Composer でプレビューしてください。
5. Composer のマテリアル、ライティング、ガラスの設定で効果を調整します。これらのソースには影・角丸・ハイライトを焼き込んでいません。形と効果はシステムが処理します。
6. default / dark / clear / tinted と小さいサイズのプレビューを確認し、`AppIcon.icon` を保存します。Xcode のアプリのターゲットにドラッグし、メインのアイコンがそれを指していることを確認します。
7. `.icon` は現在のメインの appiconset に置き換わります。リリース手順を変える前に、Mac でビルドして Dock、Finder、メニューバー、古い macOS での動作を確認してください。

`flat-square-reference.png` は平面の構図の参考にすぎず、Icon Composer で処理した Liquid Glass の効果ではありません。

Apple の公式説明：https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer
