# TinyRecorder · macOS-Symbol und Markenassets

<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <b>Deutsch</b> · <a href="README.es.md">Español</a>

Die gesamte Vektorgeometrie wurde nach der gelieferten Vorlage „Bildschirm + Aufnahmepunkt“ neu gezeichnet, ohne das Rauschen, die Kantenreste und das dekorative Dateisymbol der Vorlagencollage. Die helle Variante ist das Standard-App-Symbol des Projekts, die dunkle eine optionale Alternative. Alle PNGs enthalten ein sRGB-Profil; die SVGs lassen sich beliebig skalieren, und die Wortmarke ist in Pfade umgewandelt.

## Bereits im Projekt

- `TinyRecorder/Assets.xcassets/AppIcon.appiconset/`: der vollständige klassische macOS-Satz aus 10 PNGs, 16 / 32 / 128 / 256 / 512 pt, jeweils in 1× und 2×.
- `TinyRecorder/Assets.xcassets/TinyRecorderMenuBar.imageset/`: eine schwarze 18-pt-Vorlage auf transparentem Hintergrund, macOS 1× / 2×. Wenn nicht aufgenommen wird, rendert SwiftUI sie mit `.template`, sodass sie sich dem Erscheinungsbild der Menüleiste anpasst. 18 pt ist die Designgröße dieses Projekts, keine Vorgabe von Apple; `menubar/` enthält zusätzlich einen 54-px-Export.
- `img/tinyrecorder-header.png`: oben in der README jeder Sprache.

## Ordner

| Ordner | Inhalt |
| --- | --- |
| `macos/` | Helle und dunkle `.icns` mit vollständigen `.iconset`-Ordnern, für klassisches macOS / Finder / Dock |
| `xcode/` | AppIcon, AppIconDark und Menüleisten-Sets für den Asset-Katalog, direkt importierbar |
| `source/` | 1024er-Vektorvorlagen und optisch angepasste Versionen für 16/32 pt |
| `png/` | Helles und dunkles App-Symbol in 1024 und 2048 px, außen transparent |
| `logo/` | Farbig, invertiert, dunkel einfarbig und weiß einfarbig; Bildmarke allein, horizontal, gestapelt und nur Wortmarke; SVG + transparentes PNG |
| `menubar/` | Menüleisten-Vorlage plus ein alternatives SVG für den Pausenzustand |
| `icon-composer/` | Neue SVG-Ebenen, eine Referenz für die vollflächige Hintergrundfarbe und Importschritte für den Mac |
| `documents/` | Optionales QMA-Dokumentsymbol: SVG / PNG / iconset / icns; die bestehende Dateityp-Deklaration bleibt unverändert |
| `web/` | Optionales Website-Favicon SVG / ICO, PNG in 180/192/512, apple-touch-icon und Manifest |
| `marketing/` | GitHub-README-Banner 1600×480, GitHub-Social-Preview 1280×640, DMG-Installer-Hintergrund 660×400 und seine 2×-Version |
| `preview/` | Übersicht aller Assets, SVG / PNG |

## Helles und dunkles Symbol

Ein klassisches macOS-appiconset wechselt nicht automatisch, nur weil beide Sätze im Ordner liegen. Standardmäßig wird `AppIcon` verwendet. Um überall das dunkle Symbol zu nutzen, füge `xcode/AppIconDark.appiconset/` zum Projekt hinzu und setze den App Icon Set Name des Targets auf `AppIconDark`, oder ersetze die Standard-PNGs durch die entsprechenden aus dem dunklen iconset.

Für das neue Erscheinungsbild und die Glaseffekte des Systems verwende die Ebenen aus `icon-composer/`. Der Hintergrund muss vollflächig und deckend sein, der Vordergrund bleibt transparent, und die abgerundeten Ecken setzt das System. Es handelt sich um Quelldateien zum Import: Ein `.icon`-Projekt wurde auf dem Mac noch nicht erstellt oder geprüft, und ein klassisches, vorgerendertes Symbol darf nicht als natives Liquid-Glass-Symbol bezeichnet werden.

## Gestaltungsregeln

- Farben: Ink `#293248`, Record `#FF435C`, Canvas `#F3F5FA`.
- Rund um das Logo mindestens einen Durchmesser des Aufnahmepunkts frei lassen. Nicht verzerren, den Punkt nicht verschieben und keinen Text in das App-Symbol setzen.
- Kleine App-Symbole haben eigens verstärkte Rahmen, Ständer und Punkte. Wähle die Vorlage nach der logischen pt-Größe: 16pt@2x und 32pt@1x haben zwar beide 32 px, werden aber für ihren jeweiligen Zweck exportiert.
- Das Menüleistensymbol verwendet nur Schwarz und Transparenz und ist als Template gesetzt. Das Markenrot wird nie in die Menüleisten-Vorlage eingebacken.
- Das „SVG“-Dateisymbol unten rechts in der Vorlage steht nicht für den echten Dateityp der App. Dieses Kit enthält zusätzlich ein QMA-Dokumentsymbol als optionales Asset.

## Neu erzeugen und prüfen

Im Ordner `TinyRecorder-Brand-Kit` ausführen:

```sh
python -m pip install -r scripts/requirements-branding.txt
python scripts/generate_brand_assets.py
python scripts/validate_brand_assets.py
```

Der Generator rendert aus der SVG-Geometrie und hängt nicht von den hochgeladenen PNGs ab. `scripts/brand-fonts/Manrope.ttf` stammt von Google Fonts und steht unter der SIL OFL; die Lizenz liegt im selben Ordner. Die Wortmarke wird als Pfade exportiert, niemand muss die Schrift installieren.

Außer `branding/` aktualisiert der Generator die von der App genutzten Kopien im TinyRecorder-Repository (`TinyRecorder/Assets.xcassets/`, `img/tinyrecorder-header.png` und den DMG-Hintergrund in `.github/assets/`) und schreibt ein Zip des Kits nach `deliverables/`. Die README-Dateien werden von Hand gepflegt und nicht verändert.

Die ICNS-Dateien speichern alle Standardgrößen als PNG-Daten. Auf dem Mac lassen sie sich mit den Systemwerkzeugen neu erzeugen und prüfen (`iconutil` in diesem Ordner, `xcodebuild` im Wurzelverzeichnis des Repositorys):

```sh
iconutil -c icns branding/macos/TinyRecorder.iconset -o /tmp/TinyRecorder.icns
xcodebuild -project TinyRecorder.xcodeproj -scheme TinyRecorder -configuration Release -destination 'generic/platform=macOS' CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build
```

Diese Assets wurden unter Windows erstellt. Geprüft wurden Größen, Alphakanäle, ICNS-Struktur, SVGs, Template-Einfärbung und Projektverweise; Xcode, actool und Icon Composer wurden nicht ausgeführt, und es gab keine Prüfung in Finder/Dock auf einem echten Mac.

## Apple-Quellen

- [App-Symbole (HIG)](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [App-Symbol im Asset-Katalog konfigurieren](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
- [App-Symbol mit Icon Composer erstellen](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
- [Klassische hochauflösende macOS-Symbolgrößen und iconutil](https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Optimizing/Optimizing.html)
- [Die Menüleiste (HIG)](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [NSImage.isTemplate](https://developer.apple.com/documentation/appkit/nsimage/istemplate)
