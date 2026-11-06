# Icon Composer 分層素材

<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <b>繁體中文</b> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>

這些檔案是可匯入的 SVG 原始素材，**不是已編譯、已驗證的 `.icon` 專案**。
目前專案已經使用傳統相容的 AppIcon，不必先完成這些步驟。

1. 在 Mac 上開啟 Xcode 附帶的 Icon Composer，新增 macOS 圖示，畫布 1024 × 1024。
2. 將 Background 設為不透明純色 `#F3F5FA`；深色外觀使用 `#242C3D`。背景 SVG 是色票參考，也可作為滿版背景匯入。
3. 由下而上依序匯入 `layers/monitor-light.svg`、`layers/record-dot.svg`，兩層都保留原畫布位置和尺寸；不要先裁切可見內容。
4. 深色外觀請把顯示器圖層換成 `monitor-dark.svg`。`mono` 檔案是單色參考，請在 Composer 中預覽系統的 tinted/clear 處理結果。
5. 用 Composer 的材質、光照和玻璃控制項調整效果；這些原始稿不含預先烘焙的陰影、圓角或高光，外形和效果由系統處理。
6. 檢查 default / dark / clear / tinted 以及小尺寸預覽，儲存 `AppIcon.icon`。拖進 Xcode 的 App target，確認主圖示指向它。
7. `.icon` 會取代現有的主 appiconset。請先在 Mac 上建置並檢查 Dock、Finder、選單列和舊版 macOS 的相容行為，再更換發佈流程。

`flat-square-reference.png` 只是平面構圖參考，不是經過 Icon Composer 處理的 Liquid Glass 效果。

官方說明：https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer
