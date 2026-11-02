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

从 [Releases](../../releases/latest) 下载最新的 `TinyRecorder_vX.Y.Z.dmg`。

> App 为 ad-hoc 签名（无 Developer ID / 公证），首次打开请**右键 → 打开**。

## 所需权限

| 权限 | 用途 |
|---|---|
| 屏幕录制 | 录制屏幕 / 窗口 / 应用 / 系统声音 |
| 麦克风 | 录制人声 |
| 摄像头 | 摄像头悬浮窗 / 演讲者前置 |

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
