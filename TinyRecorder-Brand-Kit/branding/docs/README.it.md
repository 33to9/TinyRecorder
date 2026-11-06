# TinyRecorder · icona macOS e risorse del marchio

<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <b>Italiano</b> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>

Tutta la geometria vettoriale è stata ridisegnata a partire dall'immagine di riferimento «schermo + punto di registrazione» fornita, senza il rumore, i bordi residui e il badge di file decorativo del collage di riferimento. La versione chiara è l'icona predefinita dell'app; quella scura è un'alternativa facoltativa. Tutti i PNG includono un profilo sRGB; gli SVG si scalano senza limiti e il logotipo è convertito in tracciati.

## Già incluso nel progetto

- `TinyRecorder/Assets.xcassets/AppIcon.appiconset/`: il set classico completo di macOS con 10 PNG, 16 / 32 / 128 / 256 / 512 pt, ciascuno a 1× e 2×.
- `TinyRecorder/Assets.xcassets/TinyRecorderMenuBar.imageset/`: un modello nero da 18 pt su sfondo trasparente, macOS 1× / 2×. Quando non si registra, SwiftUI lo rende con `.template`, così segue l'aspetto della barra dei menu. 18 pt è la dimensione di progetto di questa app, non una dimensione richiesta da Apple; `menubar/` include anche un'esportazione da 54 px.
- `img/tinyrecorder-header.png`: in cima al README in ogni lingua.

## Cartelle

| Cartella | Contenuto |
| --- | --- |
| `macos/` | `.icns` chiaro e scuro con i relativi `.iconset` completi, per macOS classico / Finder / Dock |
| `xcode/` | Set AppIcon, AppIconDark e della barra dei menu per il catalogo delle risorse, pronti da importare |
| `source/` | Originali vettoriali da 1024 e versioni corrette otticamente per 16/32 pt |
| `png/` | Icone dell'app chiara e scura a 1024 e 2048 px, trasparenti attorno |
| `logo/` | A colori, in negativo, monocromatico scuro e monocromatico bianco; simbolo da solo, orizzontale, verticale e solo logotipo; SVG + PNG trasparente |
| `menubar/` | Modello della barra dei menu e un SVG alternativo per lo stato in pausa |
| `icon-composer/` | Nuovi livelli SVG, un riferimento per il colore di sfondo al vivo e i passaggi di importazione sul Mac |
| `documents/` | Icona facoltativa per i documenti QMA: SVG / PNG / iconset / icns; la dichiarazione del tipo di file esistente non cambia |
| `web/` | Favicon facoltativa per il sito SVG / ICO, PNG da 180/192/512, apple-touch-icon e manifest |
| `marketing/` | Banner per il README di GitHub 1600×480, anteprima social di GitHub 1280×640, sfondo del programma di installazione DMG 660×400 e la sua versione 2× |
| `preview/` | Panoramica di tutte le risorse, SVG / PNG |

## Icona chiara e scura

Un appiconset classico di macOS non cambia automaticamente solo perché entrambi i set sono nella cartella. Per impostazione predefinita si usa `AppIcon`. Per usare ovunque l'icona scura, aggiungi `xcode/AppIconDark.appiconset/` al progetto e imposta l'App Icon Set Name del target su `AppIconDark`, oppure sostituisci i PNG predefiniti con quelli corrispondenti dell'iconset scuro.

Per il nuovo aspetto e gli effetti vetro del sistema, usa i livelli in `icon-composer/`. Lo sfondo deve essere al vivo e opaco, il primo piano resta trasparente e gli angoli arrotondati li applica il sistema. Sono file sorgente da importare: un progetto `.icon` non è ancora stato creato né verificato su un Mac, e un'icona classica prerenderizzata non va presentata come icona Liquid Glass nativa.

## Regole di design

- Colori: Ink `#293248`, Record `#FF435C`, Canvas `#F3F5FA`.
- Lascia attorno al logo uno spazio libero pari almeno al diametro del punto di registrazione. Non deformarlo, non spostare il punto e non aggiungere testo all'icona dell'app.
- Le icone piccole hanno cornice, supporto e punto ispessiti a parte. Scegli l'originale in base alla dimensione logica in pt: 16pt@2x e 32pt@1x misurano entrambi 32 px, ma vengono esportati ciascuno per il proprio uso.
- L'icona della barra dei menu usa solo nero e trasparenza ed è impostata come Template. Il rosso del marchio non viene mai incorporato nel modello della barra dei menu.
- Il badge di file «SVG» in basso a destra nel riferimento non rappresenta il tipo di file reale dell'app. Questo kit aggiunge un'icona per i documenti QMA come risorsa facoltativa.

## Rigenerare e verificare

Esegui nella cartella `TinyRecorder-Brand-Kit`:

```sh
python -m pip install -r scripts/requirements-branding.txt
python scripts/generate_brand_assets.py
python scripts/validate_brand_assets.py
```

Il generatore esegue il rendering dalla geometria SVG e non dipende dai PNG caricati. `scripts/brand-fonts/Manrope.ttf` proviene da Google Fonts con licenza SIL OFL; la licenza si trova nella stessa cartella. Il logotipo è esportato come tracciati, quindi non serve installare il font.

Il generatore è stato scritto per la struttura di cartelle originale del progetto QuickRecorder. Oltre a `branding/`, scrive `QuickRecorder/Assets.xcassets/`, `img/` e `.github/assets/` dentro questa cartella e ricrea i vecchi file README in cinese. Copia a mano i file del progetto al loro posto ed elimina i README ricreati.

I file ICNS memorizzano tutte le dimensioni standard come dati PNG. Su un Mac puoi rigenerarli e verificarli con gli strumenti di sistema (`iconutil` in questa cartella, `xcodebuild` nella radice del repository):

```sh
iconutil -c icns branding/macos/TinyRecorder.iconset -o /tmp/TinyRecorder.icns
xcodebuild -project TinyRecorder.xcodeproj -scheme TinyRecorder -configuration Release -destination 'generic/platform=macOS' CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build
```

Queste risorse sono state create su Windows. Sono stati verificati dimensioni, canali alfa, struttura ICNS, SVG, colorazione dei modelli e riferimenti nel progetto; Xcode, actool e Icon Composer non sono stati eseguiti, né ci sono state verifiche in Finder/Dock su un Mac reale.

## Riferimenti Apple

- [Icone delle app (HIG)](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Configurare l'icona dell'app nel catalogo delle risorse](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
- [Creare l'icona dell'app con Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
- [Dimensioni classiche delle icone ad alta risoluzione di macOS e iconutil](https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Optimizing/Optimizing.html)
- [La barra dei menu (HIG)](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [NSImage.isTemplate](https://developer.apple.com/documentation/appkit/nsimage/istemplate)
