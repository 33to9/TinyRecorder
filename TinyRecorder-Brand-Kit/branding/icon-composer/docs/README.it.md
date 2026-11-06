# Livelli per Icon Composer

<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <b>Italiano</b> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>

Questi file sono sorgenti SVG da importare, **non un progetto `.icon` compilato e verificato**.
Il progetto usa già l'AppIcon classica e compatibile, quindi non serve completare prima questi passaggi.

1. Su un Mac, apri Icon Composer (incluso in Xcode) e crea una nuova icona macOS con una tela di 1024 × 1024.
2. Imposta Background sul colore pieno opaco `#F3F5FA`; per l'aspetto scuro usa `#242C3D`. Gli SVG di sfondo sono riferimenti di colore e si possono anche importare come sfondo al vivo.
3. Importa `layers/monitor-light.svg` e poi `layers/record-dot.svg`, dal basso verso l'alto. Mantieni entrambi i livelli nella posizione e nelle dimensioni originali sulla tela; non ritagliare prima il contenuto visibile.
4. Per l'aspetto scuro, sostituisci il livello dello schermo con `monitor-dark.svg`. I file `mono` sono riferimenti monocromatici; in Composer visualizza in anteprima come il sistema gestisce le modalità tinted e clear.
5. Regola il risultato con i controlli di materiale, illuminazione e vetro di Composer. Queste sorgenti non contengono ombre, angoli arrotondati o riflessi incorporati; forma ed effetti li gestisce il sistema.
6. Controlla default / dark / clear / tinted e le anteprime in piccolo, poi salva `AppIcon.icon`. Trascinalo nel target dell'app in Xcode e verifica che l'icona principale punti a esso.
7. Il file `.icon` sostituirà l'appiconset principale attuale. Prima di cambiare il processo di rilascio, compila su un Mac e verifica Dock, Finder, barra dei menu e comportamento sulle versioni precedenti di macOS.

`flat-square-reference.png` è solo un riferimento di composizione piatto, non un risultato Liquid Glass elaborato da Icon Composer.

Guida di Apple: https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer
