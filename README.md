<p align="center">
<h1 align="center">TinyRecorder</h1>
<h3 align="center">A lightweight screen recorder for macOS, with macOS 27 support<br><a href="README_zh.md">[简体中文]</a>
</p>

> **TinyRecorder** is a community fork of [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) by [lihaoyun6](https://github.com/lihaoyun6), which has been inactive since mid-2025.
> The fork focuses on **compatibility with the latest macOS releases** (starting with macOS 27 / "Golden Gate").

## What's fixed in this fork

- ✅ **Menu bar recording controls (stop / pause / camera) not responding on macOS 27** — upstream issue [#295](https://github.com/lihaoyun6/QuickRecorder/issues/295) / [#296](https://github.com/lihaoyun6/QuickRecorder/issues/296). Root cause: macOS 27 reports `locationInWindow` as the centre of an `NSStatusItem`'s window regardless of the real pointer position; SwiftUI hit-testing then only ever fires the centred control. Fixed by rebuilding mouse events with the real pointer position via `NSEvent.mouseLocation`.

## What it records

- Full screen, a selected area, one or more windows, or a single app
- System audio only, with or without the microphone
- **A connected iPhone or iPad** — see below
- Camera overlay and Presenter Overlay (macOS 14+) while recording

### Recording an iPhone / iPad

TinyRecorder can record the screen of an iPhone or iPad connected to your Mac. It runs on the Mac; it is not an iOS app.

1. Connect the device with a USB cable, unlock it and tap **Trust** if asked.
2. In TinyRecorder's recording toolbar, click **Mobile Device**. Connected devices are listed.
3. Turn on **Mute** if needed and pick a **Preset** (quality), then click the device name to start recording.

The device appears to macOS as an external camera, so this needs the **Camera** permission (not Screen Recording). If no device is listed, reconnect the cable and make sure the device is unlocked.

## System Requirements

- macOS 12.3 and later

## Install

### Option 1: one-line install (recommended, no Gatekeeper warning)

Open Terminal, paste this and press Return:

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/TinyRecorder/main/install.sh | bash
```

The script downloads the latest release from GitHub, verifies its SHA-256, installs it to Applications and opens it. Files downloaded with curl carry no quarantine flag, so macOS doesn't block the first launch. The script is short — feel free to [read it](install.sh) first.

### Option 2: Homebrew

```bash
brew install --cask 33to9/tap/tinyrecorder
```

### Option 3: DMG

Download the latest `TinyRecorder_vX.Y.Z.dmg` from [Releases](../../releases/latest), open it and drag TinyRecorder into your Applications folder.

The app is not notarized by Apple, so macOS blocks the first launch once:
- **macOS 15 and later**: double-click (a warning appears), then open **System Settings → Privacy & Security**, scroll down and click **Open Anyway**
- **macOS 12–14**: right-click the app → **Open**

### Updating

Use **Check for Updates…** inside the app: no download, no Gatekeeper warning, and permissions are kept.

## Required permissions

| Permission | Needed for |
|---|---|
| Screen Recording | Recording screen / window / app / system audio |
| Microphone | Recording your voice |
| Camera | Camera overlay / Presenter Overlay / recording an iPhone or iPad |

### First-launch setup

On first launch a short step-by-step guide opens:

1. **Screen Recording**: click **Grant Permission**, then turn on **TinyRecorder** in **System Settings → Privacy & Security → Screen & System Audio Recording**. Once the guide shows a green checkmark, TinyRecorder restarts automatically after 3 seconds (or restart right away).
2. **Microphone** (optional): allow it now if you narrate, so your first recording isn't interrupted by a system prompt.
3. **Default format**: H.265 / H.264 and MP4 / MOV — changeable later in Preferences.
4. **Get started**: shows where recording starts (menu bar icon / Dock) and opens the recording toolbar.

### The permission guide keeps appearing after an update

Since v1.7.15 the app is signed with a fixed certificate, so in-app updates keep the permission. You will normally only see this when updating from an older version.

If TinyRecorder's toggle is already on, won't stay on, or every button still opens the permission guide, the permission record in macOS belongs to an older build (macOS ties the permission to the app's code signature, and that signature changed). Fix it in any one of these ways:

- In the permission guide, click **Reset Permission & Relaunch**, then grant the permission again; or
- **Settings → General → Permissions → Repair Screen Recording Permission**; or
- Quit TinyRecorder, run `tccutil reset ScreenCapture com.33to9.TinyRecorder` in Terminal, reopen TinyRecorder and grant the permission again.

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
