<p align="center">
<img src="../img/tinyrecorder-header.png" alt="TinyRecorder" width="800">
</p>
<h3 align="center">Un registratore dello schermo leggero per macOS, con supporto per macOS 27</h3>
<p align="center">
<a href="https://github.com/33to9/TinyRecorder/releases/latest"><img src="https://img.shields.io/github/v/release/33to9/TinyRecorder?style=flat" alt="Latest release"></a> <a href="https://github.com/33to9/TinyRecorder/releases"><img src="https://img.shields.io/github/downloads/33to9/TinyRecorder/total?style=flat" alt="Total downloads"></a> <a href="https://github.com/33to9/TinyRecorder/releases/latest"><img src="https://img.shields.io/github/downloads/33to9/TinyRecorder/latest/total?style=flat" alt="Downloads of the latest release"></a> <a href="https://github.com/33to9/TinyRecorder/blob/main/LICENSE"><img src="https://img.shields.io/github/license/33to9/TinyRecorder?style=flat" alt="License"></a>
</p>
<p align="center">
<a href="https://www.tinyrecorder.app/it/"><b>Sito web: www.tinyrecorder.app</b></a> · <a href="https://www.tinyrecorder.app/it/#video"><b>▶ Video introduttivo (in inglese)</b></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <b>Italiano</b> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.es.md">Español</a>
</p>

> **TinyRecorder** è un fork comunitario di [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) di [lihaoyun6](https://github.com/lihaoyun6): un registratore dello schermo piccolo, veloce e davvero valido, fermo da metà 2025. Su macOS 27 i suoi pulsanti Interrompi, Pausa e Fotocamera nella barra dei menu non rispondono più.
> Una buona app non dovrebbe sparire solo perché non riceve più aggiornamenti. Questo fork ne raccoglie il testimone e si concentra sulla **compatibilità con le ultime versioni di macOS** (a partire da macOS 27 / "Golden Gate").


https://github.com/user-attachments/assets/bf8c2512-a823-40e2-bb89-748e7202bd74

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
- **Preferenze → Generali → Permessi → Permesso di registrazione schermo → Ripara…**; oppure
- Chiudi TinyRecorder, esegui `tccutil reset ScreenCapture com.33to9.TinyRecorder` in Terminale, riapri TinyRecorder e concedi di nuovo il permesso.

## Privacy

Le registrazioni non lasciano mai il tuo Mac. Per migliorare l'app, TinyRecorder invia statistiche d'uso anonime tramite [TelemetryDeck](https://telemetrydeck.com/privacy/): la versione dell'app e di macOS, la lingua, il modello di Mac e, per ogni registrazione, il tipo (schermo, finestra, area, audio e così via), il formato, il codificatore, la frequenza dei fotogrammi, se il microfono era attivo, la durata, se è stata salvata e, in caso di errore, un codice di errore. Ogni registrazione riceve un proprio ID casuale per collegare questi dati; non è legato a te né al file. Indica inoltre quali passaggi della configurazione iniziale hai raggiunto o saltato e se l'accesso alla registrazione dello schermo e al microfono è stato richiesto e concesso. Per ogni registrazione indica anche da dove l'hai avviata (barra degli strumenti, barra dei menu, scorciatoia, script o riga di comando) e se era la prima. Non invia mai le registrazioni, i nomi dei file, le cartelle, i titoli di finestre o app né i messaggi di errore. Non ci sono account né ID utente: l'app crea un identificatore casuale che viene sottoposto a hash prima dell'invio, e TelemetryDeck non memorizza gli indirizzi IP. Per disattivarle, apri Preferenze › Generali › Privacy e disattiva “Condividi dati di utilizzo anonimi”.

Le statistiche d'uso sono attive per impostazione predefinita. Tutti i dettagli: [pagina sulla privacy](https://www.tinyrecorder.app/it/privacy).

## Strumento da riga di comando

TinyRecorder include il comando `tinyrecorder`. Homebrew lo configura quando installa l'app, e il programma di installazione su una riga lo collega se non serve la password. Altrimenti scegli **TinyRecorder › Installa strumento da riga di comando…** (anche in Impostazioni › Generali, dalla versione 1.8.22) oppure esegui una volta:

```bash
sudo mkdir -p /usr/local/bin && sudo ln -sf /Applications/TinyRecorder.app/Contents/Resources/tinyrecorder /usr/local/bin/tinyrecorder
```

Poi, per esempio:

```bash
tinyrecorder record screen 1 --duration 10
tinyrecorder list windows --app TextEdit          # ID, titoli e dimensioni delle finestre
tinyrecorder record window --id 1234 --output ~/Desktop/demo.mp4
tinyrecorder status
tinyrecorder stop
tinyrecorder record area 0,0,1280,720 --duration 5
tinyrecorder screenshot window --id 1234 --output shot.png
```

`record` attende che la registrazione sia davvero iniziata, `stop` attende che il file sia salvato e ne stampa il percorso, e con `--json` ogni comando stampa un oggetto JSON.

- `list displays`, `list windows` e `list apps` mostrano cosa si può registrare, con i numeri degli schermi e gli ID delle finestre.
- `record area X,Y,WIDTH,HEIGHT` registra un'area indicata in punti dall'angolo superiore sinistro dello schermo (`--display N` per un altro schermo), senza trascinare.
- `screenshot` salva un PNG di uno schermo, di una finestra o di un'area e ne stampa il percorso. Usa il permesso di registrazione schermo di TinyRecorder, quindi il terminale non ne ha bisogno.
- `--output PATH` salva la registrazione con quel nome. `config --format mp4|mov --codec h264|h265` imposta il formato del file e il codec.

Esegui `tinyrecorder help` per vedere tutti i comandi e le opzioni. `list`, `screenshot`, `record area X,Y,WIDTH,HEIGHT`, `--id`, `--output`, `--format` e `--codec` richiedono la versione 1.8.25 o successiva.

### Uso con gli agenti IA

Gli agenti di programmazione come Claude Code, Codex o Cursor eseguono comandi da terminale, quindi possono registrare lo schermo con `tinyrecorder`: per esempio un bug che riproducono o una demo di una funzione appena creata. Perché un agente lo sappia, aggiungi questo al `CLAUDE.md` o all'`AGENTS.md` del progetto:

```markdown
## Registrazione dello schermo
TinyRecorder è installato. Usa il comando `tinyrecorder` per registrare lo schermo:
- `tinyrecorder record screen 1 --duration 15 --json` registra lo schermo principale per 15 secondi e stampa {"file": "<PERCORSO>"}.
- `tinyrecorder list windows --json` elenca le finestre con i loro ID; `tinyrecorder record window --id <ID>` avvia la registrazione di una finestra, e `tinyrecorder stop --json` la interrompe e stampa il file.
- `tinyrecorder screenshot window --id <ID> --json` (o `screenshot screen 1`) salva un PNG e stampa {"file": "<PERCORSO>"}.
- `--output <PERCORSO>` su `record` sceglie dove salvare la registrazione.
- `tinyrecorder status --json` indica se è in corso una registrazione.
Gli errori vanno su stderr con uno stato di uscita diverso da 0. Esegui `tinyrecorder help` per tutte le opzioni.
```

macOS chiede comunque una volta il permesso di registrazione dello schermo e quello di controllare TinyRecorder dal terminale, e la barra dei menu mostra quando è in corso una registrazione, quindi nulla viene registrato senza che tu lo veda.

## Automazione (AppleScript)

TinyRecorder si può controllare con AppleScript: puoi avviare e fermare le registrazioni dal Terminale, dall'app Comandi Rapidi (azione **Esegui AppleScript**), da Raycast, Alfred, Keyboard Maestro o dai tuoi script.

Dal Terminale:

```bash
osascript -e 'tell application "TinyRecorder" to record screen numbered 1'
osascript -e 'tell application "TinyRecorder" to stop recording'
```

La prima volta macOS chiede se l'app che esegue lo script (per esempio Terminale) può controllare TinyRecorder. Fai clic su **OK**. Puoi cambiarlo in seguito in **Impostazioni di Sistema → Privacy e sicurezza → Automazione**.

| Comando | Cosa fa |
|---|---|
| `record screen numbered 1` | Registra lo schermo 1 (la numerazione parte da 1). Senza `numbered` apre la scelta dello schermo |
| `record application named "Safari"` | Registra un'app indicandone il nome. Senza `named` apre la scelta dell'app |
| `record window titled "Titolo" in application "Safari"` | Registra una finestra indicandone il titolo esatto; `in application` è facoltativo. Senza `titled` apre la scelta della finestra |
| `record window identified by 1234` | Registra la finestra con questo ID (vedi `list targets`) |
| `record screen area` | Apre la selezione dell'area; trascini l'area con il mouse |
| `record screen area rectangle "0,0,1280,720"` | Registra quest'area: x, y, larghezza e altezza in punti dall'angolo superiore sinistro dello schermo. Aggiungi `display number 2` per un altro schermo |
| `record system audio` | Registra solo l'audio di sistema. Aggiungi `microphone true` per includere il microfono in questa registrazione |
| `pause recording` / `resume recording` | Mette in pausa / riprende la registrazione |
| `stop recording` | Ferma e salva la registrazione |
| `stop recording with waiting until saved` | Interrompe la registrazione, attende che il file sia salvato (incluso il missaggio o la conversione dell'audio) e ne restituisce il percorso. Se il salvataggio non riesce, restituisce un errore. |
| `recording status` | Restituisce lo stato (idle, countdown, starting, recording o paused) e, durante la registrazione, il tipo e i secondi registrati. |
| `discard recording` | Ferma la registrazione e la sposta nel Cestino |
| `list targets showing "windows"` | Elenca le finestre registrabili con i loro ID, una per riga. Anche `"displays"` e `"apps"`; aggiungi `in application "Safari"` per restringere l'elenco, o `json true` per avere JSON |
| `take screenshot` | Salva un PNG dello schermo 1 e ne restituisce il percorso. Aggiungi `display number 2`, `window identified by 1234`, `window titled "Titolo"` o `rectangle "x,y,w,h"`, e `saving to "~/shot.png"` |
| `configure …` | Modifica le impostazioni di registrazione (vedi sotto) |

`configure` accetta uno qualsiasi di questi parametri. Le modifiche vengono salvate, come se le cambiassi nelle Impostazioni, e il comando non si può usare durante una registrazione.

| Parametro | Valore |
|---|---|
| `fps` | 10, 15, 24, 30, 60, 90, 120, 144 o 240 |
| `quality` | 1 = bassa, 2 = media, 3 = alta |
| `hires` | `true` registra in risoluzione Retina |
| `cursor` | Registra il puntatore del mouse |
| `sound` | Registra l'audio di sistema / delle app |
| `microphone` | Registra il microfono |
| `mic device` | Nome del dispositivo di ingresso, oppure `"default"` |
| `hdr` | Registra in HDR (macOS 15 e successivi) |
| `save folder` | Cartella in cui salvare le registrazioni; deve esistere, `~` è consentito |
| `file format` | `"mp4"` o `"mov"` |
| `video codec` | `"h264"` o `"h265"` |

Esempio: registra lo schermo 1 per un minuto.

```applescript
tell application "TinyRecorder"
    configure fps 30 quality 2 cursor true save folder "~/Movies"
    record screen numbered 1
end tell
delay 60
tell application "TinyRecorder" to stop recording
```

Da sapere:
- I comandi di registrazione ritornano subito. Se è impostato **Ritardo prima della registrazione** (Impostazioni → Registrazione), la registrazione parte dopo il conto alla rovescia: aggiungi quel tempo a `delay`.
- Durante il conto alla rovescia, `stop recording` o `discard recording` annullano la registrazione prima che inizi; un altro comando di registrazione viene rifiutato come se fosse già in corso.
- Ogni comando di registrazione (tranne quelli che aprono una scelta) accetta `saving to "/path/name"`: la registrazione viene salvata lì, con l'estensione del formato attuale. La cartella deve esistere e un file esistente non viene mai sostituito.
- Se un titolo corrisponde a più finestre, il comando restituisce un errore; usa invece l'ID della finestra. Se un'app ha finestre su più schermi, TinyRecorder apre la scelta per farti selezionare manualmente, e il comando restituisce un errore.
- Gli errori (registrazione già in corso, nessuna registrazione attiva, permesso di registrazione schermo mancante) vengono restituiti allo script, quindi `osascript` termina con un errore. Lo stesso vale per un numero di schermo non valido o un'app o finestra non trovata; non compare alcuna finestra di dialogo.
- `pause`, `resume` e `discard` non funzionano per le registrazioni di iPhone / iPad; `stop recording` sì.

## Compilazione dal codice sorgente

Requisiti: Xcode 15 o versioni successive con l'SDK di macOS.

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open TinyRecorder.xcodeproj
# Seleziona lo schema TinyRecorder, poi compila (⌘B / ⌘R)
```

La CI compila tramite GitHub Actions (`.github/workflows/build.yml`): fai il push di un tag `v*` per pubblicare una release.

## Licenza e riconoscimenti

Questo progetto è distribuito con licenza **AGPL-3.0** (vedi [LICENSE](../LICENSE)).

- Progetto originale: [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- Motore di registrazione dello schermo derivato in parte da [Azayaka](https://github.com/Mnpn/Azayaka) di @Mnpn
- Fork curato da [33to9](https://github.com/33to9) — Copyright © 2026
