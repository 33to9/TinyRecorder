# TinyRecorder · macOS 圖示與品牌素材

<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <b>繁體中文</b> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>

依據使用者提供的「顯示器 + 錄製圓點」參考圖重新繪製全部向量幾何，去除參考拼圖中的雜點、殘邊和裝飾用的檔案標記。淺色為專案預設主圖示，深色為可選替代。所有 PNG 皆附 sRGB 描述檔；SVG 可無限縮放，品牌字標已轉為外框。

## 已接入目前專案

- `TinyRecorder/Assets.xcassets/AppIcon.appiconset/`：傳統 macOS 全套 10 張 PNG，16 / 32 / 128 / 256 / 512 pt，每檔 1×、2×。
- `TinyRecorder/Assets.xcassets/TinyRecorderMenuBar.imageset/`：18 pt 黑色透明範本，macOS 1× / 2×。未錄製時 SwiftUI 以 `.template` 算繪，隨選單列外觀著色。18 pt 是本專案的設計尺寸，並非 Apple 強制尺寸；`menubar/` 另附 54 px 匯出。
- `img/tinyrecorder-header.png`：已用於各語言 README 頂部。

## 目錄與用途

| 目錄 | 內容 |
| --- | --- |
| `macos/` | 淺色、深色 `.icns` 及完整 `.iconset`，適用於傳統 macOS / Finder / Dock |
| `xcode/` | 可直接匯入的 AppIcon、AppIconDark 和選單列資源目錄 |
| `source/` | 1024 向量母版及 16/32 pt 的光學校正版 |
| `png/` | 淺色、深色 App 圖示 1024、2048 px，外圍透明 |
| `logo/` | 彩色、反白、深色單色、白色單色；獨立標誌、橫式、直式及純字標；SVG + 透明 PNG |
| `menubar/` | 選單列範本及一個暫停狀態的備選 SVG |
| `icon-composer/` | 新版分層 SVG、滿版背景色參考和在 Mac 上的匯入步驟 |
| `documents/` | 可選 QMA 檔案圖示：SVG / PNG / iconset / icns；未替換現有的檔案類型宣告 |
| `web/` | 可選網站 favicon SVG / ICO、180/192/512 PNG、apple-touch-icon 和 manifest |
| `marketing/` | GitHub README 1600×480 橫幅、GitHub Social Preview 1280×640、660×400 DMG 安裝背景及 2× 版本 |
| `preview/` | 全套素材總覽 SVG / PNG |

## 淺色與深色的使用

傳統 macOS appiconset 不會因為兩套檔案都放在目錄中就自動切換。預設使用 `AppIcon`。若要全面改用深色，請將 `xcode/AppIconDark.appiconset/` 加入專案，並把 target 的 App Icon Set Name 改為 `AppIconDark`，或以深色 iconset 中對應的 PNG 取代原預設檔案。

新的外觀與系統玻璃效果請使用 `icon-composer/` 的分層稿。背景應滿版且不透明，前景保持透明，圓角由系統套用。這裡提供的是匯入用的原始檔，尚未在 Mac 上建立或驗證 `.icon` 專案，不能把傳統預先算繪的圖示稱為原生 Liquid Glass 圖示。

## 設計規則

- 顏色：Ink `#293248`，Record `#FF435C`，Canvas `#F3F5FA`。
- Logo 四周至少留出一個錄製圓點直徑的空白；不要拉伸、不要改變圓點的相對位置，也不要在 App 圖示中加入文字。
- 小尺寸 App 圖示單獨加粗邊框、支架及圓點，請依邏輯 pt 檔位選擇原始稿；16pt@2x 與 32pt@1x 雖然都是 32 px，仍依用途分別匯出。
- 選單列只使用黑色 + 透明並設為 Template；品牌紅色不烘焙進選單列範本。
- 參考圖右下角的「SVG」檔案樣式不代表 App 實際的檔案類型。本素材包另外製作了 QMA 檔案圖示，作為可選素材。

## 重新產生與驗證

在 `TinyRecorder-Brand-Kit` 目錄下執行：

```sh
python -m pip install -r scripts/requirements-branding.txt
python scripts/generate_brand_assets.py
python scripts/validate_brand_assets.py
```

產生器從 SVG 幾何算繪，不依賴上傳的 PNG。`scripts/brand-fonts/Manrope.ttf` 來自 Google Fonts，採用 SIL OFL 授權；授權檔附在同一目錄。品牌字標以外框匯出，使用者不需安裝字型。

產生器是依原 QuickRecorder 專案的目錄結構撰寫的：除了 `branding/`，它還會在本目錄下寫出 `QuickRecorder/Assets.xcassets/`、`img/` 和 `.github/assets/`，並重新產生舊的中文 README 檔案。專案用到的檔案請手動複製到對應位置，重新產生的 README 檔案直接刪除即可。

ICNS 以 PNG 資料區塊儲存全部標準尺寸。可在 Mac 上用系統工具重新產生並檢查（`iconutil` 在本目錄執行，`xcodebuild` 在儲存庫根目錄執行）：

```sh
iconutil -c icns branding/macos/TinyRecorder.iconset -o /tmp/TinyRecorder.icns
xcodebuild -project TinyRecorder.xcodeproj -scheme TinyRecorder -configuration Release -destination 'generic/platform=macOS' CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build
```

本次製作環境為 Windows：已檢查尺寸、透明通道、ICNS 結構、SVG、範本著色及接入引用；沒有執行 Xcode、actool、Icon Composer，也沒有在 Finder/Dock 實機驗證。

## Apple 官方依據

- [App 圖示（HIG）](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [設定 App 圖示資源目錄](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
- [使用 Icon Composer 製作 App 圖示](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
- [傳統 macOS 高解析度圖示尺寸與 iconutil](https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Optimizing/Optimizing.html)
- [選單列（HIG）](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [NSImage.isTemplate](https://developer.apple.com/documentation/appkit/nsimage/istemplate)
