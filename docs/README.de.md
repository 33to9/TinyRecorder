<p align="center">
<img src="../img/tinyrecorder-header.png" alt="TinyRecorder" width="800">
</p>
<h3 align="center">Eine schlanke Bildschirmaufnahme für macOS, mit Unterstützung für macOS 27</h3>
<p align="center">
<a href="https://github.com/33to9/TinyRecorder/releases/latest"><img src="https://img.shields.io/github/v/release/33to9/TinyRecorder?style=flat" alt="Latest release"></a> <a href="https://github.com/33to9/TinyRecorder/releases"><img src="https://img.shields.io/github/downloads/33to9/TinyRecorder/total?style=flat" alt="Total downloads"></a> <a href="https://github.com/33to9/TinyRecorder/releases/latest"><img src="https://img.shields.io/github/downloads/33to9/TinyRecorder/latest/total?style=flat" alt="Downloads of the latest release"></a> <a href="https://github.com/33to9/TinyRecorder/blob/main/LICENSE"><img src="https://img.shields.io/github/license/33to9/TinyRecorder?style=flat" alt="License"></a>
</p>
<p align="center">
<a href="https://www.tinyrecorder.app/de/"><b>Website: www.tinyrecorder.app</b></a> · <a href="https://www.tinyrecorder.app/de/#video"><b>▶ Schnellstart-Video (Englisch)</b></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <b>Deutsch</b> · <a href="README.es.md">Español</a>
</p>

> **TinyRecorder** ist ein Community-Fork von [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) von [lihaoyun6](https://github.com/lihaoyun6): ein kleiner, schneller und richtig guter Bildschirmrekorder, der seit Mitte 2025 nicht mehr weiterentwickelt wird. Unter macOS 27 reagieren seine Stopp-, Pause- und Kamera-Tasten in der Menüleiste nicht mehr.
> Eine gute App sollte nicht verschwinden, nur weil keine Updates mehr kommen. Dieser Fork führt sie fort und konzentriert sich auf die **Kompatibilität mit den neuesten macOS-Versionen** (angefangen bei macOS 27 / „Golden Gate“).


https://github.com/user-attachments/assets/bf8c2512-a823-40e2-bb89-748e7202bd74

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
- **Einstellungen → Allgemein → Berechtigungen → Berechtigung für Bildschirmaufnahme → Reparieren …**; oder
- Beende TinyRecorder, führe `tccutil reset ScreenCapture com.33to9.TinyRecorder` im Terminal aus, öffne TinyRecorder erneut und erteile die Berechtigung noch einmal.

## Datenschutz

Deine Aufnahmen verlassen nie deinen Mac. Um die App zu verbessern, sendet TinyRecorder anonyme Nutzungsstatistiken über [TelemetryDeck](https://telemetrydeck.com/privacy/): App- und macOS-Version, Sprache und Mac-Modell sowie für jede Aufnahme Art (Bildschirm, Fenster, Bereich, Audio usw.), Format, Encoder, Bildrate, ob das Mikrofon an war, Länge, ob sie gespeichert wurde, und bei einem Fehler einen Fehlercode. Jede Aufnahme erhält eine eigene zufällige ID, damit diese Angaben zusammengehören; sie ist weder mit dir noch mit der Datei verknüpft. Außerdem wird gemeldet, welche Schritte der Ersteinrichtung du erreicht oder übersprungen hast und ob der Zugriff auf Bildschirmaufnahme und Mikrofon angefragt und erteilt wurde. Zu jeder Aufnahme wird außerdem vermerkt, wo du sie gestartet hast (Symbolleiste, Menüleiste, Tastenkürzel, Skript oder Befehlszeile) und ob es deine erste war. Niemals gesendet werden deine Aufnahmen, Dateinamen, Ordner, Fenster- oder App-Titel und Fehlermeldungen. Es gibt kein Konto und keine Benutzer-ID: Die App erzeugt eine zufällige Kennung, die vor dem Senden gehasht wird, und TelemetryDeck speichert keine IP-Adressen. Zum Abschalten öffne Einstellungen › Allgemein › Datenschutz und deaktiviere „Anonyme Nutzungsdaten teilen“.

Die Nutzungsstatistik ist standardmäßig eingeschaltet. Alle Details: [Datenschutzseite](https://www.tinyrecorder.app/de/privacy).

## Befehlszeilenwerkzeug

TinyRecorder bringt den Befehl `tinyrecorder` mit. Homebrew richtet ihn bei der Installation ein, und das Ein-Zeilen-Installationsskript verlinkt ihn, wenn dafür kein Passwort nötig ist. Andernfalls wähle **TinyRecorder › Befehlszeilenwerkzeug installieren …** (auch unter Einstellungen › Allgemein, ab Version 1.8.22) oder führe einmal aus:

```bash
sudo mkdir -p /usr/local/bin && sudo ln -sf /Applications/TinyRecorder.app/Contents/Resources/tinyrecorder /usr/local/bin/tinyrecorder
```

Danach zum Beispiel:

```bash
tinyrecorder record screen 1 --duration 10
tinyrecorder list windows --app TextEdit          # Fenster-IDs, Titel und Größen
tinyrecorder record window --id 1234 --output ~/Desktop/demo.mp4
tinyrecorder status
tinyrecorder stop
tinyrecorder record area 0,0,1280,720 --duration 5 --quiet
tinyrecorder frames ~/Desktop/demo.mp4 --sheet    # ein Bild, das zeigt, was aufgenommen wurde
tinyrecorder screenshot window --id 1234 --output shot.png
tinyrecorder doctor                               # prüft die Berechtigungen und den Speicherordner
```

`record` wartet, bis die Aufnahme wirklich läuft, `stop` wartet, bis die Datei gespeichert ist, und gibt ihren Pfad aus, und mit `--json` gibt jeder Befehl ein JSON-Objekt aus.

- `list displays`, `list windows` und `list apps` zeigen, was sich aufnehmen lässt, mit Bildschirmnummern und Fenster-IDs.
- `record area X,Y,WIDTH,HEIGHT` nimmt einen Bereich auf, angegeben in Punkten ab der linken oberen Ecke des Bildschirms (`--display N` für einen anderen Bildschirm), ganz ohne Aufziehen mit der Maus.
- `screenshot` speichert ein PNG eines Bildschirms, eines Fensters oder eines Bereichs und gibt seinen Pfad aus. Dafür nutzt es die Berechtigung für Bildschirmaufnahme von TinyRecorder, dein Terminal braucht also keine eigene.
- `--output PATH` speichert die Aufnahme unter diesem Namen. `config --format mp4|mov --codec h264|h265` legt Dateiformat und Codec fest.
- `--quiet` startet sofort und zeigt danach keine Vorschau, sodass nichts die Aufnahme oder den nächsten Screenshot stört (`--no-countdown` und `--no-preview` übernehmen jeweils nur eines davon).
- `frames FILE` speichert Standbilder aus einer Aufnahme (`--every 2`, `--count 8` oder `--sheet` für einen einzigen Kontaktbogen mit Zeitangaben), damit ein Agent prüfen kann, was er aufgenommen hat, ohne das Video abzuspielen.
- `doctor` prüft, ob alles Nötige vorhanden ist: die Berechtigung für Bildschirmaufnahme, die Erlaubnis, TinyRecorder zu steuern, der Befehl im PATH und der Speicherordner. `config --show` gibt die aktuellen Einstellungen aus.

Alle Befehle und Optionen zeigt `tinyrecorder help`. `list`, `screenshot`, `record area X,Y,WIDTH,HEIGHT`, `--id`, `--output`, `--format` und `--codec` setzen Version 1.8.25 oder neuer voraus; `doctor`, `frames`, `config --show`, `--quiet`, `--no-countdown` und `--no-preview` setzen 1.8.26 oder neuer voraus.

### Mit KI-Agenten nutzen

Coding-Agenten wie Claude Code, Codex oder Cursor führen Terminalbefehle aus und können deshalb mit `tinyrecorder` den Bildschirm aufnehmen, etwa einen nachgestellten Fehler oder eine Demo einer gerade gebauten Funktion. Damit ein Agent davon weiß, füge Folgendes in die `CLAUDE.md` oder `AGENTS.md` deines Projekts ein:

```markdown
## Bildschirmaufnahme
TinyRecorder ist installiert. Mit dem Befehl `tinyrecorder` lässt sich der Bildschirm aufnehmen:
- Schlägt ein Befehl fehl, führe `tinyrecorder doctor` aus und sag mir, was er meldet.
- `tinyrecorder record screen 1 --duration 15 --quiet --json` nimmt den Hauptbildschirm 15 Sekunden lang auf und gibt {"file": "<PFAD>"} aus.
- `tinyrecorder frames <PFAD> --sheet --json` speichert ein Bild mit Einzelbildern aus der Aufnahme; sieh es dir an, um zu prüfen, was aufgenommen wurde.
- `tinyrecorder list windows --json` listet die Fenster mit ihren IDs auf; `tinyrecorder record window --id <ID>` startet die Aufnahme eines Fensters, und `tinyrecorder stop --json` beendet sie und gibt die Datei aus.
- `tinyrecorder screenshot window --id <ID> --json` (oder `screenshot screen 1`) speichert ein PNG und gibt {"file": "<PFAD>"} aus.
- `--output <PFAD>` bei `record` legt fest, wo die Aufnahme gespeichert wird.
- `tinyrecorder status --json` zeigt, ob gerade aufgenommen wird.
Fehler gehen nach stderr, der Exit-Status ist dann ungleich 0. Alle Optionen zeigt `tinyrecorder help`.
```

macOS fragt trotzdem einmal nach der Berechtigung für die Bildschirmaufnahme und danach, ob das Terminal TinyRecorder steuern darf, und die Menüleiste zeigt eine laufende Aufnahme an. Es wird also nichts aufgenommen, ohne dass du es siehst.

## Automatisierung (AppleScript)

TinyRecorder lässt sich per AppleScript steuern. So kannst du Aufnahmen aus dem Terminal, der Kurzbefehle-App (Aktion **AppleScript ausführen**), Raycast, Alfred, Keyboard Maestro oder eigenen Skripten starten und stoppen.

Im Terminal:

```bash
osascript -e 'tell application "TinyRecorder" to record screen numbered 1'
osascript -e 'tell application "TinyRecorder" to stop recording'
```

Beim ersten Mal fragt macOS, ob die App, die das Skript ausführt (z. B. Terminal), TinyRecorder steuern darf. Klicke auf **OK**. Später lässt sich das unter **Systemeinstellungen → Datenschutz & Sicherheit → Automation** ändern.

| Befehl | Funktion |
|---|---|
| `record screen numbered 1` | Nimmt Bildschirm 1 auf (Zählung beginnt bei 1). Ohne `numbered` öffnet sich die Bildschirmauswahl |
| `record application named "Safari"` | Nimmt eine App anhand ihres Namens auf. Ohne `named` öffnet sich die App-Auswahl |
| `record window titled "Titel" in application "Safari"` | Nimmt ein Fenster anhand seines genauen Titels auf; `in application` ist optional. Ohne `titled` öffnet sich die Fensterauswahl |
| `record window identified by 1234` | Nimmt das Fenster mit dieser ID auf (siehe `list targets`) |
| `record screen area` | Öffnet die Bereichsauswahl; du ziehst den Bereich mit der Maus auf |
| `record screen area rectangle "0,0,1280,720"` | Nimmt diesen Bereich auf: x, y, Breite und Höhe in Punkten ab der linken oberen Ecke des Bildschirms. Mit `display number 2` für einen anderen Bildschirm |
| `record system audio` | Nimmt nur den Systemton auf. Mit `microphone true` wird bei dieser Aufnahme auch das Mikrofon aufgenommen |
| `pause recording` / `resume recording` | Pausiert / setzt die Aufnahme fort |
| `stop recording` | Stoppt und speichert die Aufnahme |
| `stop recording with waiting until saved` | Stoppt die Aufnahme, wartet, bis die Datei gespeichert ist (einschließlich Audio-Mischung oder Umwandlung), und gibt ihren Pfad zurück. Schlägt das Speichern fehl, kommt ein Fehler zurück. |
| `recording status` | Gibt den Status zurück (idle, countdown, starting, recording oder paused) und während einer Aufnahme ihre Art und die bisher aufgenommenen Sekunden. |
| `discard recording` | Stoppt die Aufnahme und legt sie in den Papierkorb |
| `list targets showing "windows"` | Listet die aufnehmbaren Fenster mit ihren IDs auf, eines pro Zeile. Auch `"displays"` und `"apps"`; mit `in application "Safari"` eingrenzen oder mit `json true` als JSON ausgeben |
| `diagnose` | Prüft die Berechtigungen für Bildschirmaufnahme und Mikrofon sowie den Speicherordner und listet die Einstellungen auf: eine Zeile pro Eintrag (Art, Status, Name, Wert) oder mit `json true` als JSON |
| `extract frames from file "/path/demo.mp4"` | Speichert Standbilder aus einer Aufnahme und gibt ihre Pfade zurück. Möglich sind `interval 2`, `frame count 8`, `contact sheet true`, `maximum width 640` oder `saving to "/folder"` |
| `take screenshot` | Speichert ein PNG von Bildschirm 1 und gibt seinen Pfad zurück. Möglich sind `display number 2`, `window identified by 1234`, `window titled "Titel"` oder `rectangle "x,y,w,h"` sowie `saving to "~/shot.png"` |
| `configure …` | Ändert Aufnahmeeinstellungen (siehe unten) |

`configure` akzeptiert beliebige der folgenden Parameter. Die Änderungen werden gespeichert, genau wie in den Einstellungen, und während einer Aufnahme ist der Befehl nicht möglich.

| Parameter | Wert |
|---|---|
| `fps` | 10, 15, 24, 30, 60, 90, 120, 144 oder 240 |
| `quality` | 1 = niedrig, 2 = mittel, 3 = hoch |
| `hires` | `true` nimmt in Retina-Auflösung auf |
| `cursor` | Mauszeiger aufnehmen |
| `sound` | System- / App-Ton aufnehmen |
| `microphone` | Mikrofon aufnehmen |
| `mic device` | Name des Eingabegeräts oder `"default"` |
| `hdr` | In HDR aufnehmen (ab macOS 15) |
| `save folder` | Ordner für Aufnahmen; er muss existieren, `~` ist erlaubt |
| `file format` | `"mp4"` oder `"mov"` |
| `video codec` | `"h264"` oder `"h265"` |
| `countdown` | Verzögerung vor der Aufnahme, in Sekunden (0 bis 99) |
| `show preview` | Nach dem Speichern die Vorschau-Miniatur anzeigen |

Beispiel: Bildschirm 1 eine Minute lang aufnehmen.

```applescript
tell application "TinyRecorder"
    configure fps 30 quality 2 cursor true save folder "~/Movies"
    record screen numbered 1
end tell
delay 60
tell application "TinyRecorder" to stop recording
```

Gut zu wissen:
- Die Aufnahmebefehle kehren sofort zurück. Ist **Verzögerung vor der Aufnahme** eingestellt (Einstellungen → Aufnahme), beginnt die Aufnahme erst nach dem Countdown – rechne diese Zeit zu `delay` hinzu.
- Während des Countdowns bricht `stop recording` oder `discard recording` die Aufnahme ab, bevor sie beginnt; ein weiterer Aufnahmebefehl wird abgelehnt, als liefe bereits eine Aufnahme.
- Jeder Aufnahmebefehl (außer denen, die eine Auswahl öffnen) akzeptiert `countdown 0`, um sofort zu starten, und `showing preview false`, um danach weder Vorschau noch Trimmen-Fenster noch Mitteilung anzuzeigen – jeweils nur für diese Aufnahme.
- Jeder Aufnahmebefehl (außer denen, die eine Auswahl öffnen) akzeptiert `saving to "/path/name"`: Die Aufnahme wird dort gespeichert, mit der Endung des aktuellen Formats. Der Ordner muss existieren, und eine vorhandene Datei wird nie ersetzt.
- Passt ein Titel auf mehrere Fenster, gibt der Befehl einen Fehler zurück; nimm dann die ID des Fensters. Hat eine App Fenster auf mehreren Bildschirmen, öffnet TinyRecorder die Auswahl, damit du selbst wählst, und der Befehl gibt einen Fehler zurück.
- Fehler (Aufnahme läuft bereits, keine Aufnahme aktiv, keine Berechtigung für Bildschirmaufnahme) werden an das Skript zurückgegeben; `osascript` endet dann mit einem Fehler. Das gilt auch für eine ungültige Bildschirmnummer und eine App oder ein Fenster, das nicht gefunden wird; es erscheint kein Dialog.
- `pause`, `resume` und `discard` funktionieren nicht bei iPhone-/iPad-Aufnahmen; `stop recording` schon.

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
