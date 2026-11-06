# Icon-Composer-Ebenen

<a href="../README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.zh-TW.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <b>Deutsch</b> · <a href="README.es.md">Español</a>

Diese Dateien sind SVG-Quellen zum Import, **kein kompiliertes, geprüftes `.icon`-Projekt**.
Das Projekt verwendet bereits das klassische, kompatible AppIcon, diese Schritte sind also nicht vorab nötig.

1. Öffne auf dem Mac Icon Composer (liegt Xcode bei) und lege ein neues macOS-Symbol mit einer Arbeitsfläche von 1024 × 1024 an.
2. Setze Background auf die deckende Volltonfarbe `#F3F5FA`; für das dunkle Erscheinungsbild `#242C3D`. Die Hintergrund-SVGs sind Farbreferenzen und lassen sich auch als vollflächiger Hintergrund importieren.
3. Importiere von unten nach oben `layers/monitor-light.svg` und dann `layers/record-dot.svg`. Beide Ebenen behalten ihre ursprüngliche Position und Größe auf der Arbeitsfläche; den sichtbaren Inhalt vorher nicht zuschneiden.
4. Für das dunkle Erscheinungsbild ersetzt du die Bildschirm-Ebene durch `monitor-dark.svg`. Die `mono`-Dateien sind einfarbige Referenzen; die Darstellung des Systems in tinted und clear siehst du in der Vorschau von Composer.
5. Passe das Ergebnis mit den Material-, Licht- und Glas-Reglern von Composer an. Die Quellen enthalten keine eingebackenen Schatten, abgerundeten Ecken oder Glanzlichter; Form und Effekte übernimmt das System.
6. Prüfe default / dark / clear / tinted und die Vorschau in kleinen Größen, dann speichere `AppIcon.icon`. Ziehe die Datei in das App-Target in Xcode und stelle sicher, dass das Hauptsymbol darauf verweist.
7. Das `.icon` ersetzt das aktuelle Haupt-appiconset. Baue auf dem Mac und prüfe Dock, Finder, Menüleiste und das Verhalten unter älteren macOS-Versionen, bevor du den Release-Prozess umstellst.

`flat-square-reference.png` ist nur eine flache Kompositionsreferenz, kein von Icon Composer verarbeitetes Liquid-Glass-Ergebnis.

Anleitung von Apple: https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer
