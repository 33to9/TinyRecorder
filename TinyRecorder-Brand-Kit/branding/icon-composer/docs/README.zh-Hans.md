# Icon Composer 分层素材

<a href="../README.md">English</a> · <b>简体中文</b> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>

这些文件是可导入的 SVG 源素材，**不是已编译、已验证的 `.icon` 工程**。
现有项目已经接入传统兼容 AppIcon，无需先完成本步骤。

1. 在 Mac 上打开 Xcode 附带的 Icon Composer，新建 macOS 图标，画布 1024 × 1024。
2. 将 Background 设为不透明纯色 `#F3F5FA`；深色外观使用 `#242C3D`。背景 SVG 是色板参考，也可作为满幅背景导入。
3. 按从下到上顺序导入 `layers/monitor-light.svg`、`layers/record-dot.svg`，两层均保留原画布位置和尺寸；不要先裁切可见内容。
4. 为深色外观把显示器层替换为 `monitor-dark.svg`。`mono` 文件是单色参考，请在 Composer 中预览 tinted/clear 的系统处理结果。
5. 用 Composer 的材料、照明和玻璃控制调节效果；本次源稿不含预烘焙阴影、圆角或高光，由系统处理外形和效果。
6. 检查 default / dark / clear / tinted 以及小尺寸预览，保存 `AppIcon.icon`。拖入 Xcode 应用 target，确认主图标指向它。
7. `.icon` 将取代现有主 appiconset。先在 Mac 构建并检查 Dock、Finder、菜单栏和旧版 macOS 兼容行为，再替换发布流程。

`flat-square-reference.png` 只是平面构图参考，不是经过 Icon Composer 处理的 Liquid Glass 效果。

官方说明：https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer
