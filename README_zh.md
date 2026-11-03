<p align="center">
<h1 align="center">TinyRecorder</h1>
<h3 align="center">轻量化、高性能的 macOS 录屏工具（支持 macOS 27）<br><a href="README.md">[English Version]</a>
</p>

> **TinyRecorder** 是 [lihaoyun6](https://github.com/lihaoyun6) 的 [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) 的社区分支（原项目自 2025 年中起停止维护）。
> 本分支专注于**最新 macOS 版本的兼容性修复**（从 macOS 27 开始）。

## 本分支修复的问题

- ✅ **macOS 27 下菜单栏录制控制按钮（停止/暂停/摄像头）无法点击** — 上游 issue [#295](https://github.com/lihaoyun6/QuickRecorder/issues/295) / [#296](https://github.com/lihaoyun6/QuickRecorder/issues/296)。根因：macOS 27 起 `NSStatusItem` 窗口内鼠标事件的 `locationInWindow` 一律返回窗口中心点，SwiftUI 命中测试只命中中心控件。已通过 `NSEvent.mouseLocation` 重建事件坐标修复。

## 系统要求

- macOS 12.3 及更高版本

## 安装

从 [Releases](../../releases/latest) 下载最新的 `TinyRecorder_vX.Y.Z.dmg`，打开后拖入「应用程序」文件夹。

> App 未使用 Apple Developer ID 签名，也未经公证，首次打开：
> - **macOS 15 及以上**：双击一次（会弹出拦截提示），然后打开 **系统设置 → 隐私与安全性**，下拉点击 **仍要打开**；或在终端执行 `xattr -cr /Applications/TinyRecorder.app`
> - 旧版 macOS：**右键 → 打开**

## 所需权限

| 权限 | 用途 |
|---|---|
| 屏幕录制 | 录制屏幕 / 窗口 / 应用 / 系统声音 |
| 麦克风 | 录制人声 |
| 摄像头 | 摄像头悬浮窗 / 演讲者前置 |

### 授予屏幕录制权限

1. 打开 TinyRecorder，在引导窗中点击 **开始授权**。
2. 在 **系统设置 → 隐私与安全性 → 录屏与系统录音** 中打开 **TinyRecorder** 的开关。
3. 引导窗出现绿色对勾后，点击 **立即重启 TinyRecorder**。

### 升级后一直弹出授权窗口

如果 TinyRecorder 的开关已经打开、打不开，或者点任何功能键都弹出授权引导窗，说明系统里的权限记录属于旧版本（macOS 按应用的代码签名记录权限，而签名已经变了）。任选一种方法修复：

- 在授权引导窗中点击 **重置授权并重启**，然后重新授权；或
- **设置 → 一般设置 → 权限 → 修复屏幕录制权限**；或
- 退出 TinyRecorder，在终端执行 `tccutil reset ScreenCapture com.33to9.TinyRecorder`，再打开 TinyRecorder 重新授权。

提示：以后请在应用内 **检查程序更新…** 升级，不要重新下载 DMG，可以避免首次打开时被 Gatekeeper 拦截。

## 从源码构建

依赖：Xcode 15+（含 macOS SDK）。

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open QuickRecorder.xcodeproj
# 选择 QuickRecorder scheme 后构建（⌘B / ⌘R）
```

CI 通过 GitHub Actions 构建（`.github/workflows/build.yml`）——推送 `v*` 标签即可发布 Release。

## 许可证与致谢

本项目基于 **AGPL-3.0** 许可证（见 [LICENSE](LICENSE)）。

- 原项目：[QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- 录屏引擎部分代码来自 [Azayaka](https://github.com/Mnpn/Azayaka)（@Mnpn）
- 分支维护：[33to9](https://github.com/33to9) — Copyright © 2026
