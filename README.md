<p align="center">
<h1 align="center">TinyRecorder</h1>
<h3 align="center">A lightweight screen recorder for macOS, with macOS 27 support<br>轻量化多功能 macOS 录屏工具（支持 macOS 27）<br><a href="README_zh.md">[中文版本]</a>
</p>

> **TinyRecorder** is a community fork of [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) by [lihaoyun6](https://github.com/lihaoyun6), which has been inactive since mid-2025.
> The fork focuses on **compatibility with the latest macOS releases** (starting with macOS 27 / "Golden Gate").

## What's fixed in this fork

- ✅ **Menu bar recording controls (stop / pause / camera) not responding on macOS 27** — upstream issue [#295](https://github.com/lihaoyun6/QuickRecorder/issues/295) / [#296](https://github.com/lihaoyun6/QuickRecorder/issues/296). Root cause: macOS 27 reports `locationInWindow` as the centre of an `NSStatusItem`'s window regardless of the real pointer position; SwiftUI hit-testing then only ever fires the centred control. Fixed by rebuilding mouse events with the real pointer position via `NSEvent.mouseLocation`.

## System Requirements

- macOS 12.3 and later

## Install

Download the latest `TinyRecorder_vX.Y.Z.dmg` from [Releases](../../releases/latest), open it and drag TinyRecorder into your Applications folder.

> The app is not signed with an Apple Developer ID and is not notarized. On first launch:
> - **macOS 15 and later**: double-click once (a warning appears), then open **System Settings → Privacy & Security**, scroll down and click **Open Anyway** — or run `xattr -cr /Applications/TinyRecorder.app` in Terminal
> - Older macOS: right-click the app → **Open**

## Required permissions

| Permission | Needed for |
|---|---|
| Screen Recording (屏幕录制) | Recording screen / window / app / system audio |
| Microphone (麦克风) | Recording your voice |
| Camera (摄像头) | Camera overlay / Presenter Overlay |

### Granting Screen Recording

1. Launch TinyRecorder and click **Grant Permission** in the guide window.
2. In **System Settings → Privacy & Security → Screen & System Audio Recording**, turn on **TinyRecorder**.
3. When the guide shows a green checkmark, click **Restart TinyRecorder Now**.

### The permission guide keeps appearing after an update

If TinyRecorder's toggle is already on, won't stay on, or every button still opens the permission guide, the permission record in macOS belongs to an older build (macOS ties the permission to the app's code signature, and that signature changed). Fix it in any one of these ways:

- In the permission guide, click **Reset Permission & Relaunch**, then grant the permission again; or
- **Settings → General → Permissions → Repair Screen Recording Permission**; or
- Quit TinyRecorder, run `tccutil reset ScreenCapture com.33to9.TinyRecorder` in Terminal, reopen TinyRecorder and grant the permission again.

Tip: update from inside the app (**Check for Updates…**) instead of downloading the DMG again — this avoids the first-launch Gatekeeper warning.

## Building from source

Requirements: Xcode 15+ with macOS SDK.

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open QuickRecorder.xcodeproj
# Select the QuickRecorder scheme, then build (⌘B / ⌘R)
```

CI builds via GitHub Actions (`.github/workflows/build.yml`) — push a `v*` tag to publish a Release.

## License & attribution

This project is licensed under **AGPL-3.0** (see [LICENSE](LICENSE)).

- Original project: [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- Screen recording engine partially derived from [Azayaka](https://github.com/Mnpn/Azayaka) by @Mnpn
- Fork maintained by [33to9](https://github.com/33to9) — Copyright © 2026
