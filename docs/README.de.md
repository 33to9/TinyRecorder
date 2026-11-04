<p align="center">
<img src="../img/tinyrecorder-header.png" alt="TinyRecorder" width="800">
</p>
<h3 align="center">Eine schlanke Bildschirmaufnahme für macOS, mit Unterstützung für macOS 27</h3>
<p align="center">
<a href="https://www.tinyrecorder.app/de/"><b>Website: www.tinyrecorder.app</b></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.zh-TW.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <b>Deutsch</b> · <a href="README.es.md">Español</a>
</p>

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

Das Skript lädt die neueste Version von GitHub, prüft ihre SHA-256-Prüfsumme, installiert sie im Ordner „Programme“ und öffnet sie. Mit curl geladene Dateien tragen keine Quarantäne-Markierung, daher blockiert macOS den ersten Start nicht. Das Skript ist kurz – du kannst es gern vorher [ansehen](../install.sh).

### Option 2: Homebrew

```bash
brew install --cask 33to9/tap/tinyrecorder
```

### Option 3: DMG

Lade die neueste Datei `TinyRecorder_vX.Y.Z.dmg` von [Releases](https://github.com/33to9/TinyRecorder/releases/latest), öffne sie und ziehe TinyRecorder in den Ordner „Programme“.

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
open TinyRecorder.xcodeproj
# Schema „TinyRecorder“ auswählen, dann bauen (⌘B / ⌘R)
```

Die CI kompiliert über GitHub Actions (`.github/workflows/build.yml`) – pushe ein Tag `v*`, um ein Release zu veröffentlichen.

## Lizenz & Danksagungen

Dieses Projekt steht unter der Lizenz **AGPL-3.0** (siehe [LICENSE](../LICENSE)).

- Ursprüngliches Projekt: [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- Aufnahme-Engine teilweise abgeleitet von [Azayaka](https://github.com/Mnpn/Azayaka) von @Mnpn
- Fork gepflegt von [33to9](https://github.com/33to9) — Copyright © 2026
