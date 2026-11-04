<p align="center">
<h1 align="center">TinyRecorder</h1>
<h3 align="center">轻量化、高性能的 macOS 录屏工具（支持 macOS 27）<br><a href="README.md">[English Version]</a>
</p>

> **TinyRecorder** 是 [lihaoyun6](https://github.com/lihaoyun6) 的 [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) 的社区分支（原项目自 2025 年中起停止维护）。
> 本分支专注于**最新 macOS 版本的兼容性修复**（从 macOS 27 开始）。

## 本分支修复的问题

- ✅ **macOS 27 下菜单栏录制控制按钮（停止/暂停/摄像头）无法点击** — 上游 issue [#295](https://github.com/lihaoyun6/QuickRecorder/issues/295) / [#296](https://github.com/lihaoyun6/QuickRecorder/issues/296)。根因：macOS 27 起 `NSStatusItem` 窗口内鼠标事件的 `locationInWindow` 一律返回窗口中心点，SwiftUI 命中测试只命中中心控件。已通过 `NSEvent.mouseLocation` 重建事件坐标修复。

## 能录什么

- 全屏、选定区域、一个或多个窗口、单个应用
- 只录系统声音，可同时录麦克风
- **连接到 Mac 的 iPhone 或 iPad**，见下文
- 录制时显示摄像头悬浮窗、演讲者前置（macOS 14 及以上）

### 录制 iPhone / iPad

TinyRecorder 可以录制连接到 Mac 的 iPhone 或 iPad 的屏幕。它运行在 Mac 上，不是 iOS App。

1. 用 USB 数据线连接设备，解锁设备；如果弹出提示，点 **信任**。
2. 在 TinyRecorder 的录制工具栏中点 **录制移动设备**，会列出已连接的设备。
3. 按需打开 **静音**、在 **预设** 中选择画质，然后点设备名开始录制。

macOS 把设备当成一个外接摄像头，所以需要的是 **摄像头** 权限，而不是屏幕录制权限。如果列表里没有设备，请重新插拔数据线，并确认设备已解锁。

## 系统要求

- macOS 12.3 及更高版本

## 安装

### 方式一：一行命令安装（推荐，不会被系统拦截）

打开「终端」，粘贴并回车：

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/TinyRecorder/main/install.sh | bash
```

脚本会从 GitHub Releases 下载最新版、校验 SHA-256，然后安装到「应用程序」并打开。用 curl 下载的文件不带隔离标记，所以首次打开不会被 Gatekeeper 拦截。脚本很短，可以先[看一眼](install.sh)再运行。

### 方式二：Homebrew

```bash
brew install --cask 33to9/tap/tinyrecorder
```

### 方式三：下载 DMG

从 [Releases](../../releases/latest) 下载最新的 `TinyRecorder_vX.Y.Z.dmg`，打开后拖入「应用程序」文件夹。

App 未经 Apple 公证，第一次打开会被拦截一次：
- **macOS 15 及以上**：双击一次（会弹出提示），然后打开 **系统设置 → 隐私与安全性**，往下滚动，点 **仍要打开**
- **macOS 12–14**：**右键点击 App → 打开**

### 以后怎么升级

在应用内点 **检查程序更新…** 即可：不用重新下载，不会被拦截，权限也会保留。

## 所需权限

| 权限 | 用途 |
|---|---|
| 屏幕录制 | 录制屏幕 / 窗口 / 应用 / 系统声音 |
| 麦克风 | 录制人声 |
| 摄像头 | 摄像头悬浮窗 / 演讲者前置 / 录制 iPhone、iPad |

### 首次使用引导

第一次打开时，会出现一个分步引导窗：

1. **屏幕录制权限**：点 **开始授权**，在 **系统设置 → 隐私与安全性 → 录屏与系统录音** 中打开 **TinyRecorder** 的开关。引导窗出现绿色对勾后，3 秒内自动重启（也可以立即重启）。
2. **麦克风**（可跳过）：需要边录边讲解的话现在允许，第一次录制时就不会被弹窗打断。
3. **默认格式**：H.265 / H.264、MP4 / MOV，之后可在偏好设置里修改。
4. **开始使用**：告诉你在哪里开始录制（菜单栏图标 / 程序坞），然后打开录制工具栏。

### 升级后一直弹出授权窗口

从 v1.7.15 起，App 使用固定证书签名，应用内升级会保留权限。一般只有从更早的版本升级时，才会遇到这个问题。

如果 TinyRecorder 的开关已经打开、打不开，或者点任何功能键都弹出授权引导窗，说明系统里的权限记录属于旧版本（macOS 按应用的代码签名记录权限，而签名已经变了）。任选一种方法修复：

- 在授权引导窗中点击 **重置授权并重启**，然后重新授权；或
- **设置 → 一般设置 → 权限 → 修复屏幕录制权限**；或
- 退出 TinyRecorder，在终端执行 `tccutil reset ScreenCapture com.33to9.TinyRecorder`，再打开 TinyRecorder 重新授权。

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
