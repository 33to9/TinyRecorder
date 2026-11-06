# TinyRecorder · macOS 图标与品牌素材

<a href="../README.md">English</a> · <b>简体中文</b> · <a href="README.zh-TW.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>

以用户提供的「显示器 + 录制圆点」参考图重新绘制全部矢量几何，去除参考拼图的噪点、残边和装饰文件标记。浅色为项目默认主图标，深色为可选替代。所有 PNG 附带 sRGB 配置；SVG 可无限缩放，品牌字标已转轮廓。

## 已接入当前项目

- `TinyRecorder/Assets.xcassets/AppIcon.appiconset/`：传统 macOS 全套 10 张 PNG，16 / 32 / 128 / 256 / 512 pt，每档 1×、2×。
- `TinyRecorder/Assets.xcassets/TinyRecorderMenuBar.imageset/`：18 pt 黑色透明模板，macOS 1× / 2×。SwiftUI 在未录制状态使用 `.template` 渲染，随菜单栏外观着色。18 pt 是本项目的设计尺寸，不是 Apple 强制尺寸；`menubar/` 另附 54 px 导出。
- `img/tinyrecorder-header.png`：已接入各语言 README 顶部。

## 目录与用途

| 目录 | 内容 |
| --- | --- |
| `macos/` | 浅色、深色 `.icns` 及完整 `.iconset`，适用于传统 macOS / Finder / Dock |
| `xcode/` | 可直接导入的 AppIcon、AppIconDark 和菜单栏资产目录 |
| `source/` | 1024 矢量母版及 16/32 pt 的光学校正版 |
| `png/` | 浅深应用图标 1024、2048 px，外围透明 |
| `logo/` | 彩色、反白、深色单色、白色单色；独立标志、横版、竖版及纯字标；SVG + 透明 PNG |
| `menubar/` | 菜单栏模板及一个暂停状态备选 SVG |
| `icon-composer/` | 新版分层 SVG、满幅背景色参考和 Mac 上的导入步骤 |
| `documents/` | 可选 QMA 文件图标：SVG / PNG / iconset / icns；未替换现有文件类型声明 |
| `web/` | 可选网站 favicon SVG / ICO、180/192/512 PNG、apple-touch-icon 和 manifest |
| `marketing/` | GitHub README 1600×480 横幅、GitHub Social Preview 1280×640、660×400 DMG 安装背景及 2× 版本 |
| `preview/` | 全套素材总览 SVG / PNG |

## 浅色和深色的使用

传统 macOS appiconset 不会因为把两套文件放在目录中就自动切换。默认接入 `AppIcon`。如果要全局改用深色，将 `xcode/AppIconDark.appiconset/` 放入项目，修改 target 的 App Icon Set Name 为 `AppIconDark`，或用深色 iconset 对应 PNG 替换原默认文件。

新的外观与系统玻璃效果请使用 `icon-composer/` 的分层稿。背景应满幅不透明，前景保持透明，圆角由系统施加。这里提供的是导入源文件，尚未在 Mac 上创建或验证 `.icon` 工程，不能将传统预渲染图标称为原生 Liquid Glass 图标。

## 设计规则

- 颜色：Ink `#293248`，Record `#FF435C`，Canvas `#F3F5FA`。
- Logo 四周至少留出一个录制圆点直径的空白；不要拉伸、改变圆点相对位置或加文字进应用图标。
- 小号应用图标单独加粗边框、支架及圆点，按逻辑 pt 档选择源稿；16pt@2x 与 32pt@1x 虽然都是 32 px，仍按用途导出。
- 菜单栏只使用黑色 + 透明并设为 Template；品牌红色不烘焙进菜单栏模板。
- 参考图右下角的 “SVG” 文件样式不代表应用真实文件类型。本包额外制作 QMA 文件图标，作为可选接入素材。

## 重新生成与验证

在 `TinyRecorder-Brand-Kit` 目录下运行：

```sh
python -m pip install -r scripts/requirements-branding.txt
python scripts/generate_brand_assets.py
python scripts/validate_brand_assets.py
```

生成器从 SVG 几何渲染，不依赖上传的 PNG。`scripts/brand-fonts/Manrope.ttf` 来自 Google Fonts，使用 SIL OFL；许可证随附于同目录。品牌字标导出为轮廓，不要求使用者安装字体。

生成器按原 QuickRecorder 项目的目录结构编写：除 `branding/` 外，它还会在本目录下写出 `QuickRecorder/Assets.xcassets/`、`img/` 和 `.github/assets/`，并重新生成旧的中文 README 文件。项目用到的文件请手动复制到对应位置，重新生成的 README 文件直接删除即可。

ICNS 使用 PNG 数据块保存全部标准尺寸。可在 Mac 上用系统工具重新生成并检查（`iconutil` 在本目录运行，`xcodebuild` 在仓库根目录运行）：

```sh
iconutil -c icns branding/macos/TinyRecorder.iconset -o /tmp/TinyRecorder.icns
xcodebuild -project TinyRecorder.xcodeproj -scheme TinyRecorder -configuration Release -destination 'generic/platform=macOS' CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build
```

本次制作环境为 Windows：已检查尺寸、透明通道、ICNS 结构、SVG、模板着色及接入引用；没有运行 Xcode、actool、Icon Composer 或 Finder/Dock 实机验证。

## Apple 官方依据

- [App icons / HIG](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [配置 App Icon 资产目录](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
- [Icon Composer 工作流](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
- [传统 macOS 高分辨率图标尺寸与 iconutil](https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Optimizing/Optimizing.html)
- [菜单栏 HIG](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [NSImage.isTemplate](https://developer.apple.com/documentation/appkit/nsimage/istemplate)
