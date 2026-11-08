<p align="center">
<img src="../img/tinyrecorder-header.png" alt="TinyRecorder" width="800">
</p>
<h3 align="center">轻量化、高性能的 macOS 录屏工具（支持 macOS 27）</h3>
<p align="center">
<a href="https://github.com/33to9/TinyRecorder/releases/latest"><img src="https://img.shields.io/github/v/release/33to9/TinyRecorder?style=flat" alt="Latest release"></a> <a href="https://github.com/33to9/TinyRecorder/releases"><img src="https://img.shields.io/github/downloads/33to9/TinyRecorder/total?style=flat" alt="Total downloads"></a> <a href="https://github.com/33to9/TinyRecorder/releases/latest"><img src="https://img.shields.io/github/downloads/33to9/TinyRecorder/latest/total?style=flat" alt="Downloads of the latest release"></a> <a href="https://github.com/33to9/TinyRecorder/blob/main/LICENSE"><img src="https://img.shields.io/github/license/33to9/TinyRecorder?style=flat" alt="License"></a>
</p>
<p align="center">
<a href="https://www.tinyrecorder.app/zh-Hans/"><b>官网：www.tinyrecorder.app</b></a> · <a href="https://www.tinyrecorder.app/zh-Hans/#video"><b>▶ 快速上手视频（英文）</b></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <b>简体中文</b> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>
</p>

> **TinyRecorder** 是 [lihaoyun6](https://github.com/lihaoyun6) 的 [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) 的社区分支。QuickRecorder 是一款小巧、快速、真正好用的录屏工具，可惜自 2025 年年中起已停止更新，在 macOS 27 上，菜单栏里的停止、暂停和摄像头按钮都已失灵。
> 好的软件，不该因为停更就此消失。本分支接过接力棒，专注于**最新 macOS 版本的兼容性修复**（从 macOS 27 开始）。


https://github.com/user-attachments/assets/bf8c2512-a823-40e2-bb89-748e7202bd74

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

脚本会从 GitHub Releases 下载最新版、校验 SHA-256，然后安装到「应用程序」并打开。用 curl 下载的文件不带隔离标记，所以首次打开不会被 Gatekeeper 拦截。脚本很短，可以先[看一眼](../install.sh)再运行。

### 方式二：Homebrew

```bash
brew install --cask 33to9/tap/tinyrecorder
```

### 方式三：下载 DMG

从 [Releases](https://github.com/33to9/TinyRecorder/releases/latest) 下载最新的 `TinyRecorder_vX.Y.Z.dmg`，打开后拖入「应用程序」文件夹。

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
- **设置 → 一般设置 → 权限 → 屏幕录制权限 → 修复…**；或
- 退出 TinyRecorder，在终端执行 `tccutil reset ScreenCapture com.33to9.TinyRecorder`，再打开 TinyRecorder 重新授权。

## 隐私

录像只保存在你的 Mac 上，不会上传。为了改进应用，TinyRecorder 会通过 [TelemetryDeck](https://telemetrydeck.com/privacy/) 发送匿名使用统计：应用和 macOS 版本、语言、Mac 机型，以及每次录制的类型（全屏、窗口、区域、音频等）、格式、编码器、帧率、是否开启麦克风、时长、是否保存成功，录制失败时还有错误代码。每次录制会带一个随机 ID，用来关联这些数据，它与你本人和文件都无关。此外还会发送首次引导走到了哪一步、是否中途关闭，以及是否请求并获得了录屏和麦克风权限。每次录制还会记录是从哪里开始的（工具栏、菜单栏、快捷键或脚本），以及是不是第一次录制。绝不发送录像内容、文件名、文件夹、窗口或应用标题，也不发送错误信息原文。没有账户或用户 ID：应用会生成一个随机标识符，发送前经过哈希处理，TelemetryDeck 也不保存 IP 地址。如需关闭，请打开 偏好设置 › 一般设置 › 隐私，关闭“共享匿名使用数据”。

使用统计默认开启。详细说明：[隐私页](https://www.tinyrecorder.app/zh-Hans/privacy)。

## 自动化（AppleScript）

TinyRecorder 支持 AppleScript，可以在终端、快捷指令（**运行 AppleScript** 操作）、Raycast、Alfred、Keyboard Maestro 或你自己的脚本里开始和停止录制。

在终端里：

```bash
osascript -e 'tell application "TinyRecorder" to record screen numbered 1'
osascript -e 'tell application "TinyRecorder" to stop recording'
```

第一次运行时，macOS 会询问运行脚本的 App（比如“终端”）能否控制 TinyRecorder，点 **好**。以后可以在 **系统设置 → 隐私与安全性 → 自动化** 里修改。

| 命令 | 作用 |
|---|---|
| `record screen numbered 1` | 录制第 1 块屏幕（从 1 开始编号）。不带 `numbered` 时打开屏幕选择 |
| `record application named "Safari"` | 按名称录制某个 App。不带 `named` 时打开 App 选择 |
| `record window titled "标题" in application "Safari"` | 按完整标题录制一个窗口，`in application` 可省略。不带 `titled` 时打开窗口选择 |
| `record screen area` | 打开区域选择，用鼠标拖出要录的区域 |
| `record system audio` | 只录系统声音。加上 `microphone true` 时本次同时录麦克风 |
| `pause recording` / `resume recording` | 暂停 / 继续录制 |
| `stop recording` | 停止并保存 |
| `stop recording with waiting until saved` | 停止录制，等文件保存完成（包括混音或转换）后返回文件路径；保存失败时返回错误。 |
| `recording status` | 返回当前状态（idle、countdown、starting、recording 或 paused），录制中还会返回录制类型和已录秒数。 |
| `discard recording` | 停止录制，并把文件移到废纸篓 |
| `configure …` | 修改录制设置（见下表） |

`configure` 可以带下面任意参数。修改会被保存，和在设置里改是一样的；录制过程中不能使用。

| 参数 | 取值 |
|---|---|
| `fps` | 10、15、24、30、60、90、120、144 或 240 |
| `quality` | 1 = 低，2 = 中，3 = 高 |
| `hires` | `true` 为 Retina 分辨率 |
| `cursor` | 是否录制鼠标指针 |
| `sound` | 是否录制系统 / App 声音 |
| `microphone` | 是否录制麦克风 |
| `mic device` | 输入设备名称，或 `"default"` |
| `hdr` | HDR 录制（macOS 15 及以上） |
| `save folder` | 保存录制的文件夹，必须已存在，可以用 `~` |

示例：录制第 1 块屏幕 1 分钟。

```applescript
tell application "TinyRecorder"
    configure fps 30 quality 2 cursor true save folder "~/Movies"
    record screen numbered 1
end tell
delay 60
tell application "TinyRecorder" to stop recording
```

注意：
- 录制命令会立即返回。如果设置了 **开始录制前倒数**（设置 → 录制设置），录制会在倒数结束后才开始，`delay` 要把这段时间加上。
- 倒数期间发送 `stop recording` 或 `discard recording` 会取消这次录制；再发录制命令会被当作“已在录制”拒绝。
- 名称匹配到多个窗口，或者 App 的窗口分布在多块屏幕上时，TinyRecorder 会打开选择窗口让你手动选。此时命令会返回错误。
- 出错时（已经在录制、没有在录制、没有屏幕录制权限）会把错误返回给脚本，`osascript` 会以出错状态退出。屏幕编号无效、找不到应用或窗口时也一样，不会弹出对话框。
- 录制 iPhone / iPad 时不支持 `pause`、`resume` 和 `discard`，`stop recording` 可以用。

## 从源码构建

依赖：Xcode 15+（含 macOS SDK）。

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open TinyRecorder.xcodeproj
# 选择 TinyRecorder scheme 后构建（⌘B / ⌘R）
```

CI 通过 GitHub Actions 构建（`.github/workflows/build.yml`）——推送 `v*` 标签即可发布 Release。

## 许可证与致谢

本项目基于 **AGPL-3.0** 许可证（见 [LICENSE](../LICENSE)）。

- 原项目：[QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- 录屏引擎部分代码来自 [Azayaka](https://github.com/Mnpn/Azayaka)（@Mnpn）
- 分支维护：[33to9](https://github.com/33to9) — Copyright © 2026
