<p align="center">
<img src="../img/tinyrecorder-header.png" alt="TinyRecorder" width="800">
</p>
<h3 align="center">Un registratore dello schermo leggero per macOS, con supporto per macOS 27</h3>
<p align="center">
<a href="https://www.tinyrecorder.app/it/"><b>Sito web: www.tinyrecorder.app</b></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.zh-TW.md">繁體中文</a> · <b>Italiano</b> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>
</p>

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

Lo script scarica l'ultima versione da GitHub, ne verifica lo SHA-256, la installa in Applicazioni e la apre. I file scaricati con curl non hanno l'attributo di quarantena, quindi macOS non blocca il primo avvio. Lo script è breve: se vuoi, [leggilo](../install.sh) prima.

### Opzione 2: Homebrew

```bash
brew install --cask 33to9/tap/tinyrecorder
```

### Opzione 3: DMG

Scarica l'ultimo `TinyRecorder_vX.Y.Z.dmg` da [Releases](https://github.com/33to9/TinyRecorder/releases/latest), aprilo e trascina TinyRecorder nella cartella Applicazioni.

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

Questo progetto è distribuito con licenza **AGPL-3.0** (vedi [LICENSE](../LICENSE)).

- Progetto originale: [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- Motore di registrazione dello schermo derivato in parte da [Azayaka](https://github.com/Mnpn/Azayaka) di @Mnpn
- Fork curato da [33to9](https://github.com/33to9) — Copyright © 2026
