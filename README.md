<p align="center">
<img src="img/tinyrecorder-header.png" alt="TinyRecorder" width="800">
</p>
<h3 align="center">A lightweight screen recorder for macOS, with macOS 27 support</h3>
<p align="center">
<a href="https://www.tinyrecorder.app/en/"><b>Website: www.tinyrecorder.app</b></a>
</p>
<p align="center">
<b>English</b> · <a href="#zh">简体中文</a> · <a href="#zh-Hant">繁體中文</a> · <a href="#it">Italiano</a> · <a href="#ja">日本語</a> · <a href="#de">Deutsch</a> · <a href="#es">Español</a>
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

---

<a id="zh"></a>
<details>
<summary><b>简体中文</b> — 轻量化、高性能的 macOS 录屏工具（支持 macOS 27）</summary>

<a href="https://www.tinyrecorder.app/zh-Hans/"><b>官网：www.tinyrecorder.app</b></a>

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

</details>

<a id="zh-Hant"></a>
<details>
<summary><b>繁體中文</b> — 輕巧的 macOS 螢幕錄影工具，已支援 macOS 27</summary>

<a href="https://www.tinyrecorder.app/zh-Hant/"><b>官方網站：www.tinyrecorder.app</b></a>

> **TinyRecorder** 是由社群接手維護的 [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) 分支，原專案由 [lihaoyun6](https://github.com/lihaoyun6) 開發，自 2025 年年中起已停止更新。
> 此分支著重於**與最新 macOS 版本的相容性**（從 macOS 27「Golden Gate」開始）。

## 此分支修正了哪些問題

- ✅ **macOS 27 上選單列的錄製控制項（停止／暫停／攝影機）無法回應**：原專案議題 [#295](https://github.com/lihaoyun6/QuickRecorder/issues/295)／[#296](https://github.com/lihaoyun6/QuickRecorder/issues/296)。根本原因：在 macOS 27 上，無論指標實際位於何處，`locationInWindow` 一律回報為 `NSStatusItem` 視窗的中心點；因此 SwiftUI 的點擊判定永遠只會觸發位於中央的控制項。修正方式是透過 `NSEvent.mouseLocation` 取得指標的實際位置，重新建立滑鼠事件。

## 可以錄製什麼

- 整個螢幕、選取的區域、一個或多個視窗，或單一應用程式
- 只錄系統聲音，可選擇是否同時收錄麥克風
- **連接的 iPhone 或 iPad**：詳見下方說明
- 錄影時顯示攝影機懸浮視窗與「發表人置前」（macOS 14 以上版本）

### 錄製 iPhone／iPad

TinyRecorder 可以錄製連接到 Mac 的 iPhone 或 iPad 螢幕。它是在 Mac 上執行的應用程式，並非 iOS App。

1. 以 USB 傳輸線連接裝置，解鎖後若出現提示，請點一下「**信任**」。
2. 在 TinyRecorder 的錄製工具列中，按一下**錄製行動裝置**，即會列出已連接的裝置。
3. 視需要開啟**靜音**並選擇**預設**（畫質），然後按一下裝置名稱即可開始錄影。

macOS 會將裝置視為外接攝影機，因此需要的是**相機**權限（而非螢幕錄製權限）。如果清單中沒有出現裝置，請重新連接傳輸線，並確認裝置已解鎖。

## 系統需求

- macOS 12.3 或以上版本

## 安裝

### 方式一：一行指令安裝（推薦，不會出現 Gatekeeper 警告）

打開「終端機」，貼上以下指令並按下 Return 鍵：

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/TinyRecorder/main/install.sh | bash
```

此指令碼會從 GitHub 下載最新版本，驗證其 SHA-256，安裝到「應用程式」檔案夾並打開。以 curl 下載的檔案不帶隔離標記，因此 macOS 不會阻擋首次啟動。指令碼很短，歡迎先[閱讀內容](install.sh)。

### 方式二：Homebrew

```bash
brew install --cask 33to9/tap/tinyrecorder
```

### 方式三：DMG

從 [Releases](../../releases/latest) 下載最新的 `TinyRecorder_vX.Y.Z.dmg`，打開後將 TinyRecorder 拖移到「應用程式」檔案夾。

由於此應用程式未經 Apple 公證，macOS 會阻擋一次首次啟動：
- **macOS 15 及以上版本**：按兩下應用程式（會出現警告），接著打開「**系統設定**」→「**隱私權與安全性**」，向下捲動並按一下「**強制打開**」
- **macOS 12–14**：在應用程式上按右鍵 →「**打開**」

### 更新

在應用程式中使用**檢查程式更新…**即可：不必自行下載，不會出現 Gatekeeper 警告，權限也會保留。

## 所需權限

| 權限 | 用途 |
|---|---|
| 螢幕錄製 | 錄製螢幕／視窗／應用程式／系統聲音 |
| 麥克風 | 錄下你的聲音 |
| 相機 | 攝影機懸浮視窗／發表人置前／錄製 iPhone 或 iPad |

### 首次啟動設定

首次啟動時，會出現簡短的逐步設定導引：

1. **螢幕錄製**：按一下**開始授權**，然後在「**系統設定**」→「**隱私權與安全性**」→「**螢幕與系統錄音**」中開啟 **TinyRecorder**。導引顯示綠色勾號後，TinyRecorder 會在 3 秒後自動重新啟動（也可以立即重新啟動）。
2. **麥克風**（選用）：如果需要旁白，建議現在就允許，以免第一次錄影被系統提示中斷。
3. **預設格式**：H.265／H.264 與 MP4／MOV，之後可在偏好設定中變更。
4. **開始使用**：告訴你從哪裡開始錄影（選單列圖示／Dock），並打開錄製工具列。

### 更新後權限導引一直出現

從 v1.7.15 起，應用程式改用固定憑證簽署，因此透過應用程式內更新會保留權限。通常只有從舊版本更新時才會遇到這個情況。

如果 TinyRecorder 的開關已經開啟、無法保持開啟，或是每個按鈕仍會打開權限導引，代表 macOS 中的權限紀錄屬於舊版本（macOS 會將權限與應用程式的程式碼簽章綁定，而簽章已經變更）。可用以下任一方式解決：

- 在權限導引中按一下**重設授權並重新啟動**，然後重新授予權限；或
- 「**偏好設定**」→「**一般設定**」→「**權限**」→**修復螢幕錄製權限**；或
- 結束 TinyRecorder，在「終端機」中執行 `tccutil reset ScreenCapture com.33to9.TinyRecorder`，再重新打開 TinyRecorder 並授予權限。

## 從原始碼建置

需求：Xcode 15 以上版本（含 macOS SDK）。

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open QuickRecorder.xcodeproj
# 選擇 QuickRecorder scheme 後建置（⌘B / ⌘R）
```

CI 透過 GitHub Actions（`.github/workflows/build.yml`）建置：推送 `v*` 標籤即可發佈 Release。

## 授權與致謝

本專案採用 **AGPL-3.0** 授權（詳見 [LICENSE](LICENSE)）。

- 原始專案：[QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- 螢幕錄製引擎部分源自 @Mnpn 開發的 [Azayaka](https://github.com/Mnpn/Azayaka)
- 分支維護者：[33to9](https://github.com/33to9) — Copyright © 2026

</details>

<a id="it"></a>
<details>
<summary><b>Italiano</b> — Un registratore dello schermo leggero per macOS, con supporto per macOS 27</summary>

<a href="https://www.tinyrecorder.app/it/"><b>Sito web: www.tinyrecorder.app</b></a>

> **TinyRecorder** è un fork comunitario di [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) di [lihaoyun6](https://github.com/lihaoyun6), fermo da metà 2025.
> Il fork si concentra sulla **compatibilità con le ultime versioni di macOS** (a partire da macOS 27 / "Golden Gate").

## Cosa corregge questo fork

- ✅ **I controlli di registrazione nella barra dei menu (interruzione / pausa / fotocamera) non rispondono su macOS 27**: segnalazioni originali [#295](https://github.com/lihaoyun6/QuickRecorder/issues/295) / [#296](https://github.com/lihaoyun6/QuickRecorder/issues/296). Causa: macOS 27 riporta `locationInWindow` come il centro della finestra di un `NSStatusItem`, indipendentemente dalla posizione reale del puntatore; l'hit testing di SwiftUI attiva quindi sempre e solo il controllo al centro. Risolto ricostruendo gli eventi del mouse con la posizione reale del puntatore tramite `NSEvent.mouseLocation`.

## Cosa registra

- Lo schermo intero, un'area selezionata, una o più finestre oppure una singola app
- Solo l'audio di sistema, con o senza il microfono
- **Un iPhone o iPad collegato**: vedi sotto
- Sovrapposizione fotocamera e Sovrapposizione relatore (macOS 14 e versioni successive) durante la registrazione

### Registrare un iPhone / iPad

TinyRecorder può registrare lo schermo di un iPhone o iPad collegato al tuo Mac. Funziona sul Mac: non è un'app per iOS.

1. Collega il dispositivo con un cavo USB, sbloccalo e tocca **Autorizza** se richiesto.
2. Nella barra strumenti di registrazione di TinyRecorder, fai clic su **Dispositivo mobile**. Vengono elencati i dispositivi collegati.
3. Se serve, attiva **Muto** e scegli un **Predefinito** (qualità), poi fai clic sul nome del dispositivo per avviare la registrazione.

macOS vede il dispositivo come una fotocamera esterna, quindi serve il permesso **Fotocamera** (non Registrazione schermo). Se non compare alcun dispositivo, ricollega il cavo e verifica che il dispositivo sia sbloccato.

## Requisiti di sistema

- macOS 12.3 o versioni successive

## Installazione

### Opzione 1: installazione con un comando (consigliata, nessun avviso di Gatekeeper)

Apri Terminale, incolla questo comando e premi Invio:

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/TinyRecorder/main/install.sh | bash
```

Lo script scarica l'ultima versione da GitHub, ne verifica lo SHA-256, la installa in Applicazioni e la apre. I file scaricati con curl non hanno l'attributo di quarantena, quindi macOS non blocca il primo avvio. Lo script è breve: se vuoi, [leggilo](install.sh) prima.

### Opzione 2: Homebrew

```bash
brew install --cask 33to9/tap/tinyrecorder
```

### Opzione 3: DMG

Scarica l'ultimo `TinyRecorder_vX.Y.Z.dmg` da [Releases](../../releases/latest), aprilo e trascina TinyRecorder nella cartella Applicazioni.

L'app non è autenticata da Apple, quindi macOS ne blocca il primo avvio una sola volta:
- **macOS 15 e versioni successive**: fai doppio clic sull'app (compare un avviso), poi apri **Impostazioni di Sistema → Privacy e sicurezza**, scorri verso il basso e fai clic su **Apri comunque**
- **macOS 12–14**: fai clic destro sull'app → **Apri**

### Aggiornamenti

Usa **Verifica aggiornamenti…** nell'app: non devi scaricare nulla, non compare alcun avviso di Gatekeeper e i permessi vengono mantenuti.

## Permessi necessari

| Permesso | Serve per |
|---|---|
| Registrazione schermo | Registrare schermo / finestra / app / audio di sistema |
| Microfono | Registrare la tua voce |
| Fotocamera | Sovrapposizione fotocamera / Sovrapposizione relatore / registrazione di iPhone o iPad |

### Configurazione al primo avvio

Al primo avvio si apre una breve guida passo passo:

1. **Registrazione schermo**: fai clic su **Concedi permesso**, poi attiva **TinyRecorder** in **Impostazioni di Sistema → Privacy e sicurezza → Registrazione schermo e audio di sistema**. Quando la guida mostra un segno di spunta verde, TinyRecorder si riavvia automaticamente dopo 3 secondi (oppure puoi riavviarlo subito).
2. **Microfono** (facoltativo): se commenti a voce, consentilo subito, così la prima registrazione non verrà interrotta da una richiesta di sistema.
3. **Formato predefinito**: H.265 / H.264 e MP4 / MOV, modificabile in seguito in Preferenze.
4. **Inizia**: mostra da dove si avvia la registrazione (icona nella barra dei menu / Dock) e apre la barra strumenti di registrazione.

### La guida ai permessi continua a comparire dopo un aggiornamento

Dalla versione 1.7.15 l'app è firmata con un certificato fisso, quindi gli aggiornamenti dall'app mantengono il permesso. Di norma lo vedrai solo aggiornando da una versione precedente.

Se l'interruttore di TinyRecorder è già attivo, non resta attivo, oppure ogni pulsante apre ancora la guida ai permessi, il permesso registrato in macOS appartiene a una build precedente (macOS associa il permesso alla firma del codice dell'app, e quella firma è cambiata). Puoi risolvere in uno di questi modi:

- Nella guida ai permessi, fai clic su **Reimposta permesso e riavvia**, poi concedi di nuovo il permesso; oppure
- **Preferenze → Generali → Permessi → Ripara permesso di registrazione schermo**; oppure
- Chiudi TinyRecorder, esegui `tccutil reset ScreenCapture com.33to9.TinyRecorder` in Terminale, riapri TinyRecorder e concedi di nuovo il permesso.

## Compilazione dal codice sorgente

Requisiti: Xcode 15 o versioni successive con l'SDK di macOS.

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open QuickRecorder.xcodeproj
# Seleziona lo schema QuickRecorder, poi compila (⌘B / ⌘R)
```

La CI compila tramite GitHub Actions (`.github/workflows/build.yml`): fai il push di un tag `v*` per pubblicare una release.

## Licenza e riconoscimenti

Questo progetto è distribuito con licenza **AGPL-3.0** (vedi [LICENSE](LICENSE)).

- Progetto originale: [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- Motore di registrazione dello schermo derivato in parte da [Azayaka](https://github.com/Mnpn/Azayaka) di @Mnpn
- Fork curato da [33to9](https://github.com/33to9) — Copyright © 2026

</details>

<a id="ja"></a>
<details>
<summary><b>日本語</b> — macOS 用の軽量な画面収録アプリ（macOS 27 に対応）</summary>

<a href="https://www.tinyrecorder.app/ja/"><b>公式サイト：www.tinyrecorder.app</b></a>

> **TinyRecorder** は、2025 年半ばから開発が止まっている [lihaoyun6](https://github.com/lihaoyun6) 氏の [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) のコミュニティフォークです。
> このフォークは、**最新の macOS リリースとの互換性**（macOS 27 /「Golden Gate」以降）を重視しています。

## このフォークでの修正点

- ✅ **macOS 27 でメニューバーの録画コントロール（停止／一時停止／カメラ）が反応しない問題** — アップストリームの Issue [#295](https://github.com/lihaoyun6/QuickRecorder/issues/295) / [#296](https://github.com/lihaoyun6/QuickRecorder/issues/296)。原因：macOS 27 では、実際のポインタの位置にかかわらず、`locationInWindow` が `NSStatusItem` のウインドウの中心として報告されます。そのため SwiftUI のヒットテストでは、常に中央のコントロールしか反応しませんでした。`NSEvent.mouseLocation` で取得した実際のポインタの位置を使ってマウスイベントを再構築することで修正しました。

## 録画できるもの

- 画面全体、選択した範囲、1 つまたは複数のウインドウ、1 つのアプリケーション
- システムオーディオのみ（マイクの音声の有無を選択可能）
- **接続した iPhone や iPad** — 下記を参照してください
- 録画中のカメラオーバーレイと発表者オーバーレイ（macOS 14 以降）

### iPhone / iPad の録画

TinyRecorder では、Mac に接続した iPhone や iPad の画面を録画できます。TinyRecorder は Mac で動作するアプリで、iOS アプリではありません。

1. USB ケーブルでデバイスを接続してロックを解除し、確認が表示されたら **信頼** をタップします。
2. TinyRecorder の録画ツールバーで **モバイルデバイス** をクリックします。接続されているデバイスが一覧表示されます。
3. 必要に応じて **消音** をオンにし、**プリセット**（画質）を選んでから、デバイス名をクリックして録画を開始します。

macOS はデバイスを外部カメラとして認識するため、（画面収録ではなく）**カメラ** の権限が必要です。デバイスが一覧に表示されない場合は、ケーブルを接続し直し、デバイスのロックが解除されていることを確認してください。

## 動作環境

- macOS 12.3 以降

## インストール

### 方法 1：1 行でインストール（おすすめ、Gatekeeper の警告なし）

「ターミナル」を開き、次のコマンドをペーストして return キーを押します：

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/TinyRecorder/main/install.sh | bash
```

このスクリプトは GitHub から最新リリースをダウンロードし、SHA-256 を確認したうえで「アプリケーション」フォルダにインストールして起動します。curl でダウンロードしたファイルには検疫属性が付かないため、初回起動時に macOS にブロックされません。スクリプトは短いので、先に[内容を確認](install.sh)することもできます。

### 方法 2：Homebrew

```bash
brew install --cask 33to9/tap/tinyrecorder
```

### 方法 3：DMG

[リリースページ](../../releases/latest)から最新の `TinyRecorder_vX.Y.Z.dmg` をダウンロードして開き、TinyRecorder を「アプリケーション」フォルダにドラッグします。

このアプリは Apple の公証を受けていないため、初回起動時に一度だけ macOS にブロックされます：
- **macOS 15 以降**：アプリをダブルクリックし（警告が表示されます）、**「システム設定」→「プライバシーとセキュリティ」** を開いて下にスクロールし、**「このまま開く」** をクリックします
- **macOS 12〜14**：アプリを右クリック → **「開く」** を選択します

### アップデート

アプリの **アップデートを確認…** を使用してください。ご自身でダウンロードする必要はなく、Gatekeeper の警告も表示されず、権限もそのまま保持されます。

## 必要な権限

| 権限 | 用途 |
|---|---|
| 画面収録 | 画面／ウインドウ／アプリケーション／システムオーディオの録画 |
| マイク | 音声の録音 |
| カメラ | カメラオーバーレイ／発表者オーバーレイ／iPhone や iPad の録画 |

### 初回起動時の設定

初回起動時に、簡単なステップごとのガイドが表示されます：

1. **画面収録**：**権限を付与** をクリックし、**「システム設定」→「プライバシーとセキュリティ」→「画面とシステムオーディオの録音」** で **TinyRecorder** をオンにします。ガイドに緑のチェックマークが表示されると、3 秒後に TinyRecorder が自動的に再起動します（すぐに再起動することもできます）。
2. **マイク**（オプション）：ナレーションを入れる場合は、最初の録画がシステムの確認ダイアログで中断されないよう、ここで許可しておきます。
3. **デフォルトのフォーマット**：H.265 / H.264 と MP4 / MOV を選択します。あとから「設定」で変更できます。
4. **はじめる**：録画を開始する場所（メニューバーのアイコン／Dock）が表示され、録画ツールバーが開きます。

### アップデート後に権限のガイドが何度も表示される場合

バージョン 1.7.15 以降、アプリは固定の証明書で署名されているため、アプリ内でのアップデート後も権限が保持されます。通常これが起きるのは、古いバージョンからアップデートした場合のみです。

TinyRecorder のスイッチがすでにオンになっている、オンのままにならない、あるいはどのボタンを押しても権限のガイドが開く場合は、macOS に記録されている権限が古いビルドのものになっています（macOS は権限をアプリのコード署名に結び付けており、その署名が変更されたためです）。次のいずれかの方法で解決できます：

- 権限のガイドで **権限をリセットして再起動** をクリックし、もう一度権限を付与します。
- **「設定」→「一般」→「権限」→「画面収録の権限を修復」** を開きます。
- TinyRecorder を終了し、「ターミナル」で `tccutil reset ScreenCapture com.33to9.TinyRecorder` を実行してから、TinyRecorder をもう一度開いて権限を付与します。

## ソースからのビルド

必要なもの：macOS SDK を含む Xcode 15 以降。

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open QuickRecorder.xcodeproj
# QuickRecorder スキームを選択してビルド（⌘B / ⌘R）
```

CI では GitHub Actions（`.github/workflows/build.yml`）でビルドします。`v*` タグをプッシュすると リリースが公開されます。

## ライセンスとクレジット

このプロジェクトは **AGPL-3.0** のもとでライセンスされています（[LICENSE](LICENSE) を参照）。

- オリジナルプロジェクト：[QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- 画面録画エンジンの一部は @Mnpn 氏の [Azayaka](https://github.com/Mnpn/Azayaka) をもとにしています
- フォークのメンテナンス：[33to9](https://github.com/33to9) — Copyright © 2026

</details>

<a id="de"></a>
<details>
<summary><b>Deutsch</b> — Eine schlanke Bildschirmaufnahme für macOS, mit Unterstützung für macOS 27</summary>

<a href="https://www.tinyrecorder.app/de/"><b>Website: www.tinyrecorder.app</b></a>

> **TinyRecorder** ist ein Community-Fork von [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) von [lihaoyun6](https://github.com/lihaoyun6), das seit Mitte 2025 nicht mehr weiterentwickelt wird.
> Der Fork konzentriert sich auf die **Kompatibilität mit den neuesten macOS-Versionen** (angefangen bei macOS 27 / „Golden Gate“).

## Was in diesem Fork behoben ist

- ✅ **Aufnahmesteuerung in der Menüleiste (Stoppen / Pausieren / Kamera) reagiert unter macOS 27 nicht** – Upstream-Issue [#295](https://github.com/lihaoyun6/QuickRecorder/issues/295) / [#296](https://github.com/lihaoyun6/QuickRecorder/issues/296). Ursache: macOS 27 meldet `locationInWindow` unabhängig von der tatsächlichen Zeigerposition als Mitte des Fensters eines `NSStatusItem`; das Hit-Testing von SwiftUI löst dadurch immer nur das mittige Steuerelement aus. Behoben, indem die Mausereignisse mit der tatsächlichen Zeigerposition über `NSEvent.mouseLocation` neu erzeugt werden.

## Was die App aufnimmt

- Den ganzen Bildschirm, einen ausgewählten Bereich, ein oder mehrere Fenster oder eine einzelne App
- Nur das Systemaudio, mit oder ohne Mikrofon
- **Ein angeschlossenes iPhone oder iPad** – siehe unten
- Kameraeinblendung und Moderatorüberlagerung (ab macOS 14) während der Aufnahme

### iPhone / iPad aufnehmen

TinyRecorder kann den Bildschirm eines iPhone oder iPad aufnehmen, das an deinen Mac angeschlossen ist. Die App läuft auf dem Mac; es ist keine iOS-App.

1. Schließe das Gerät per USB-Kabel an, entsperre es und tippe auf **Vertrauen**, falls du gefragt wirst.
2. Klicke in der Aufnahme-Symbolleiste von TinyRecorder auf **Mobilgerät**. Die angeschlossenen Geräte werden aufgelistet.
3. Aktiviere bei Bedarf **Stumm** und wähle eine **Voreinstellung** (Qualität), klicke dann auf den Gerätenamen, um die Aufnahme zu starten.

Für macOS erscheint das Gerät als externe Kamera, daher wird die Berechtigung für die **Kamera** benötigt (nicht für die Bildschirmaufnahme). Wird kein Gerät angezeigt, schließe das Kabel erneut an und prüfe, ob das Gerät entsperrt ist.

## Systemvoraussetzungen

- macOS 12.3 oder neuer

## Installation

### Option 1: Installation mit einer Zeile (empfohlen, keine Gatekeeper-Warnung)

Öffne Terminal, füge diese Zeile ein und drücke den Zeilenschalter:

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/TinyRecorder/main/install.sh | bash
```

Das Skript lädt die neueste Version von GitHub, prüft ihre SHA-256-Prüfsumme, installiert sie im Ordner „Programme“ und öffnet sie. Mit curl geladene Dateien tragen keine Quarantäne-Markierung, daher blockiert macOS den ersten Start nicht. Das Skript ist kurz – du kannst es gern vorher [ansehen](install.sh).

### Option 2: Homebrew

```bash
brew install --cask 33to9/tap/tinyrecorder
```

### Option 3: DMG

Lade die neueste Datei `TinyRecorder_vX.Y.Z.dmg` von [Releases](../../releases/latest), öffne sie und ziehe TinyRecorder in den Ordner „Programme“.

Die App ist nicht von Apple notarisiert, daher blockiert macOS den ersten Start einmalig:
- **macOS 15 und neuer**: Doppelklicke auf die App (eine Warnung erscheint), öffne dann **Systemeinstellungen → Datenschutz & Sicherheit**, scrolle nach unten und klicke auf **Dennoch öffnen**
- **macOS 12–14**: Klicke mit der rechten Maustaste auf die App → **Öffnen**

### Aktualisieren

Verwende **Nach Updates suchen …** in der App: Du musst nichts selbst laden, es erscheint keine Gatekeeper-Warnung und deine Berechtigungen bleiben erhalten.

## Benötigte Berechtigungen

| Berechtigung | Verwendet für |
|---|---|
| Bildschirmaufnahme | Aufnahme von Bildschirm, Fenster, App oder Systemaudio |
| Mikrofon | Aufnahme deiner Stimme |
| Kamera | Kameraeinblendung, Moderatorüberlagerung und Aufnahme eines iPhone oder iPad |

### Einrichtung beim ersten Start

Beim ersten Start öffnet sich eine kurze Schritt-für-Schritt-Anleitung:

1. **Bildschirmaufnahme**: Klicke auf **Berechtigung erteilen** und aktiviere dann **TinyRecorder** unter **Systemeinstellungen → Datenschutz & Sicherheit → Bildschirm- & Systemaudioaufnahme**. Sobald die Anleitung ein grünes Häkchen zeigt, startet TinyRecorder nach 3 Sekunden automatisch neu (oder du startest es sofort neu).
2. **Mikrofon** (optional): Erlaube den Zugriff gleich, wenn du kommentierst – so wird deine erste Aufnahme nicht durch eine Systemabfrage unterbrochen.
3. **Standardformat**: H.265 / H.264 und MP4 / MOV – später in den Einstellungen änderbar.
4. **Los geht’s**: Zeigt dir, wo die Aufnahme beginnt (Symbol in der Menüleiste / Dock), und öffnet die Aufnahme-Symbolleiste.

### Die Anleitung zur Berechtigung erscheint nach einem Update immer wieder

Seit Version 1.7.15 ist die App mit einem festen Zertifikat signiert, daher bleibt die Berechtigung bei Updates in der App erhalten. Normalerweise siehst du die Anleitung nur noch beim Update von einer älteren Version.

Ist der Schalter für TinyRecorder bereits aktiviert, bleibt er nicht aktiviert oder öffnet jede Taste weiterhin die Anleitung zur Berechtigung, gehört der Berechtigungseintrag in macOS zu einem älteren Build (macOS bindet die Berechtigung an die Codesignatur der App, und diese Signatur hat sich geändert). Du kannst das auf eine der folgenden Arten beheben:

- Klicke in der Anleitung zur Berechtigung auf **Berechtigung zurücksetzen & neu starten** und erteile die Berechtigung dann erneut; oder
- **Einstellungen → Allgemein → Berechtigungen → Berechtigung für Bildschirmaufnahme reparieren**; oder
- Beende TinyRecorder, führe `tccutil reset ScreenCapture com.33to9.TinyRecorder` im Terminal aus, öffne TinyRecorder erneut und erteile die Berechtigung noch einmal.

## Aus dem Quellcode kompilieren

Voraussetzungen: Xcode 15 oder neuer mit macOS SDK.

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open QuickRecorder.xcodeproj
# Schema „QuickRecorder“ auswählen, dann bauen (⌘B / ⌘R)
```

Die CI kompiliert über GitHub Actions (`.github/workflows/build.yml`) – pushe ein Tag `v*`, um ein Release zu veröffentlichen.

## Lizenz & Danksagungen

Dieses Projekt steht unter der Lizenz **AGPL-3.0** (siehe [LICENSE](LICENSE)).

- Ursprüngliches Projekt: [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- Aufnahme-Engine teilweise abgeleitet von [Azayaka](https://github.com/Mnpn/Azayaka) von @Mnpn
- Fork gepflegt von [33to9](https://github.com/33to9) — Copyright © 2026

</details>

<a id="es"></a>
<details>
<summary><b>Español</b> — Un grabador de pantalla ligero para macOS, compatible con macOS 27</summary>

<a href="https://www.tinyrecorder.app/es/"><b>Sitio web: www.tinyrecorder.app</b></a>

> **TinyRecorder** es una bifurcación comunitaria de [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) de [lihaoyun6](https://github.com/lihaoyun6), que no recibe cambios desde mediados de 2025.
> La bifurcación se centra en la **compatibilidad con las versiones más recientes de macOS** (empezando por macOS 27 / "Golden Gate").

## Qué corrige esta bifurcación

- ✅ **Los controles de grabación de la barra de menús (detener / pausar / cámara) no responden en macOS 27**: incidencias [#295](https://github.com/lihaoyun6/QuickRecorder/issues/295) / [#296](https://github.com/lihaoyun6/QuickRecorder/issues/296) del proyecto original. Causa: macOS 27 informa de `locationInWindow` como el centro de la ventana de un `NSStatusItem`, sea cual sea la posición real del puntero; por eso, la detección de clics de SwiftUI solo activa el control situado en el centro. Se ha corregido reconstruyendo los eventos del ratón con la posición real del puntero mediante `NSEvent.mouseLocation`.

## Qué graba

- La pantalla completa, un área seleccionada, una o varias ventanas, o una sola app
- Solo el audio del sistema, con o sin el micrófono
- **Un iPhone o iPad conectado**: consulta más abajo
- Superposición de cámara y Superposición del presentador (macOS 14 y posterior) durante la grabación

### Grabar un iPhone o iPad

TinyRecorder puede grabar la pantalla de un iPhone o iPad conectado a tu Mac. Se ejecuta en el Mac; no es una app de iOS.

1. Conecta el dispositivo con un cable USB, desbloquéalo y toca **Confiar** si te lo pide.
2. En la barra de herramientas de grabación de TinyRecorder, haz clic en **Dispositivo móvil**. Aparecerá la lista de dispositivos conectados.
3. Activa **Silenciar** si lo necesitas y elige un **Preajuste** (calidad); después, haz clic en el nombre del dispositivo para empezar a grabar.

macOS trata el dispositivo como una cámara externa, por lo que se necesita el permiso de **Cámara** (no el de Grabación de pantalla). Si el dispositivo no aparece en la lista, vuelve a conectar el cable y comprueba que esté desbloqueado.

## Requisitos del sistema

- macOS 12.3 o posterior

## Instalación

### Opción 1: instalación en una línea (recomendada, sin aviso de Gatekeeper)

Abre Terminal, pega esto y pulsa Intro:

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/TinyRecorder/main/install.sh | bash
```

El script descarga la última versión desde GitHub, comprueba su SHA-256, la instala en Aplicaciones y la abre. Los archivos descargados con curl no llevan el atributo de cuarentena, así que macOS no bloquea el primer inicio. El script es breve: si quieres, puedes [leerlo](install.sh) antes.

### Opción 2: Homebrew

```bash
brew install --cask 33to9/tap/tinyrecorder
```

### Opción 3: DMG

Descarga el último `TinyRecorder_vX.Y.Z.dmg` desde [Versiones](../../releases/latest), ábrelo y arrastra TinyRecorder a tu carpeta Aplicaciones.

La app no está notarizada por Apple, así que macOS bloquea el primer inicio una vez:
- **macOS 15 y posterior**: haz doble clic en la app (aparecerá un aviso), abre **Ajustes del Sistema → Privacidad y seguridad**, desplázate hacia abajo y haz clic en **Abrir igualmente**
- **macOS 12–14**: haz clic derecho en la app → **Abrir**

### Actualizar

Usa **Buscar actualizaciones…** en la app: no tienes que descargar nada, no aparece el aviso de Gatekeeper y se conservan tus permisos.

## Permisos necesarios

| Permiso | Se usa para |
|---|---|
| Grabación de pantalla | Grabar la pantalla / una ventana / una app / el audio del sistema |
| Micrófono | Grabar tu voz |
| Cámara | Superposición de cámara / Superposición del presentador / grabación de un iPhone o iPad |

### Configuración en el primer inicio

La primera vez que abras la app aparecerá una breve guía paso a paso:

1. **Grabación de pantalla**: haz clic en **Conceder permiso** y activa **TinyRecorder** en **Ajustes del Sistema → Privacidad y seguridad → Grabación de pantalla y audio del sistema**. Cuando la guía muestre una marca de verificación verde, TinyRecorder se reiniciará automáticamente al cabo de 3 segundos (o puedes reiniciarlo en ese momento).
2. **Micrófono** (opcional): si vas a narrar, permítelo ahora para que tu primera grabación no se interrumpa con un aviso del sistema.
3. **Formato predeterminado**: H.265 / H.264 y MP4 / MOV. Puedes cambiarlo más adelante en Ajustes.
4. **Empezar**: te muestra dónde se inicia la grabación (icono de la barra de menús / Dock) y abre la barra de herramientas de grabación.

### La guía de permisos sigue apareciendo después de una actualización

Desde la versión 1.7.15, la app se firma con un certificado fijo, así que las actualizaciones desde la app conservan el permiso. Normalmente solo verás esto al actualizar desde una versión anterior.

Si el interruptor de TinyRecorder ya está activado, no se mantiene activado o todos los botones siguen abriendo la guía de permisos, el registro del permiso en macOS pertenece a una compilación anterior (macOS asocia el permiso a la firma de código de la app, y esa firma cambió). Puedes solucionarlo de cualquiera de estas formas:

- En la guía de permisos, haz clic en **Restablecer permiso y reiniciar** y vuelve a conceder el permiso; o
- **Ajustes → General → Permisos → Reparar el permiso de grabación de pantalla**; o
- Sal de TinyRecorder, ejecuta `tccutil reset ScreenCapture com.33to9.TinyRecorder` en Terminal, vuelve a abrir TinyRecorder y concede de nuevo el permiso.

## Compilar desde el código fuente

Requisitos: Xcode 15 o posterior con el SDK de macOS.

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open QuickRecorder.xcodeproj
# Selecciona el esquema QuickRecorder y compila (⌘B / ⌘R)
```

La integración continua compila con GitHub Actions (`.github/workflows/build.yml`): sube una etiqueta `v*` para publicar una versión.

## Licencia y créditos

Este proyecto se distribuye bajo la licencia **AGPL-3.0** (consulta [LICENSE](LICENSE)).

- Proyecto original: [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- Motor de grabación de pantalla derivado en parte de [Azayaka](https://github.com/Mnpn/Azayaka) de @Mnpn
- Bifurcación mantenida por [33to9](https://github.com/33to9) — Copyright © 2026

</details>
