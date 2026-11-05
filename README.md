<p align="center">
<img src="img/tinyrecorder-header.png" alt="TinyRecorder" width="800">
</p>
<h3 align="center">A lightweight screen recorder for macOS, with macOS 27 support</h3>
<p align="center">
<a href="https://www.tinyrecorder.app/en/"><b>Website: www.tinyrecorder.app</b></a>
</p>
<p align="center">
<b>English</b> · <a href="docs/README.zh-CN.md">简体中文</a> · <a href="docs/README.zh-TW.md">繁體中文</a> · <a href="docs/README.it.md">Italiano</a> · <a href="docs/README.ja.md">日本語</a> · <a href="docs/README.de.md">Deutsch</a> · <a href="docs/README.es.md">Español</a>
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
- **Settings → General → Permissions → Screen Recording Permission → Repair…**; or
- Quit TinyRecorder, run `tccutil reset ScreenCapture com.33to9.TinyRecorder` in Terminal, reopen TinyRecorder and grant the permission again.

## Automation (AppleScript)

TinyRecorder can be controlled with AppleScript, so you can start and stop recordings from Terminal, the Shortcuts app (**Run AppleScript** action), Raycast, Alfred, Keyboard Maestro or your own scripts.

From Terminal:

```bash
osascript -e 'tell application "TinyRecorder" to record screen numbered 1'
osascript -e 'tell application "TinyRecorder" to stop recording'
```

The first time, macOS asks whether the app running the script (for example Terminal) may control TinyRecorder. Click **OK**. You can change this later in **System Settings → Privacy & Security → Automation**.

| Command | What it does |
|---|---|
| `record screen numbered 1` | Records display 1 (numbering starts at 1). Without `numbered`, opens the screen picker |
| `record application named "Safari"` | Records an app by its name. Without `named`, opens the app picker |
| `record window titled "Title" in application "Safari"` | Records one window by its exact title; `in application` is optional. Without `titled`, opens the window picker |
| `record screen area` | Opens the area selector; you drag the area with the mouse |
| `record system audio` | Records system audio only. Add `microphone true` to include the microphone in this recording |
| `pause recording` / `resume recording` | Pauses / resumes the recording |
| `stop recording` | Stops and saves the recording |
| `discard recording` | Stops the recording and moves it to the Trash |
| `configure …` | Changes recording settings (see below) |

`configure` takes any of these parameters. The changes are saved, just like changing them in Preferences, and it can't be used while recording.

| Parameter | Value |
|---|---|
| `fps` | 10, 15, 24, 30, 60, 90, 120, 144 or 240 |
| `quality` | 1 = low, 2 = medium, 3 = high |
| `hires` | `true` records at Retina resolution |
| `cursor` | Record the mouse pointer |
| `sound` | Record system / app sound |
| `microphone` | Record the microphone |
| `mic device` | Name of the input device, or `"default"` |
| `hdr` | Record in HDR (macOS 15 and later) |
| `save folder` | Folder to save recordings to; it must exist, `~` is allowed |

Example: record display 1 for one minute.

```applescript
tell application "TinyRecorder"
    configure fps 30 quality 2 cursor true save folder "~/Movies"
    record screen numbered 1
end tell
delay 60
tell application "TinyRecorder" to stop recording
```

Good to know:
- The record commands return right away. If **Delay Before Recording** is set (Preferences → Recorder), recording starts after the countdown, so add that time to `delay`.
- During the countdown, `stop recording` or `discard recording` cancels the recording before it starts, and another record command is refused as already recording.
- If a name matches several windows, or the app has windows on more than one screen, TinyRecorder opens the picker so you can choose.
- Errors (already recording, not recording, no Screen Recording permission) are returned to the script, so `osascript` exits with an error.
- `pause`, `resume` and `discard` don't work for iPhone / iPad recordings; `stop recording` does.

## Building from source

Requirements: Xcode 15+ with macOS SDK.

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open TinyRecorder.xcodeproj
# Select the TinyRecorder scheme, then build (⌘B / ⌘R)
```

CI builds via GitHub Actions (`.github/workflows/build.yml`) — push a `v*` tag to publish a Release.

## License & attribution

This project is licensed under **AGPL-3.0** (see [LICENSE](LICENSE)).

- Original project: [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- Screen recording engine partially derived from [Azayaka](https://github.com/Mnpn/Azayaka) by @Mnpn
- Fork maintained by [33to9](https://github.com/33to9) — Copyright © 2026
