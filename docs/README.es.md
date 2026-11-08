<p align="center">
<img src="../img/tinyrecorder-header.png" alt="TinyRecorder" width="800">
</p>
<h3 align="center">Un grabador de pantalla ligero para macOS, compatible con macOS 27</h3>
<p align="center">
<a href="https://github.com/33to9/TinyRecorder/releases/latest"><img src="https://img.shields.io/github/v/release/33to9/TinyRecorder?style=flat" alt="Latest release"></a> <a href="https://github.com/33to9/TinyRecorder/releases"><img src="https://img.shields.io/github/downloads/33to9/TinyRecorder/total?style=flat" alt="Total downloads"></a> <a href="https://github.com/33to9/TinyRecorder/releases/latest"><img src="https://img.shields.io/github/downloads/33to9/TinyRecorder/latest/total?style=flat" alt="Downloads of the latest release"></a> <a href="https://github.com/33to9/TinyRecorder/blob/main/LICENSE"><img src="https://img.shields.io/github/license/33to9/TinyRecorder?style=flat" alt="License"></a>
</p>
<p align="center">
<a href="https://www.tinyrecorder.app/es/"><b>Sitio web: www.tinyrecorder.app</b></a> · <a href="https://www.tinyrecorder.app/es/#video"><b>▶ Vídeo de inicio rápido (en inglés)</b></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <b>Español</b>
</p>

> **TinyRecorder** es una bifurcación comunitaria de [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) de [lihaoyun6](https://github.com/lihaoyun6): un grabador de pantalla pequeño, rápido y realmente bueno que dejó de recibir cambios a mediados de 2025. En macOS 27, sus botones de detener, pausar y cámara de la barra de menús ya no responden.
> Una buena app no debería desaparecer solo porque dejó de actualizarse. Esta bifurcación toma el relevo y se centra en la **compatibilidad con las versiones más recientes de macOS** (empezando por macOS 27 / "Golden Gate").


https://github.com/user-attachments/assets/bf8c2512-a823-40e2-bb89-748e7202bd74

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

El script descarga la última versión desde GitHub, comprueba su SHA-256, la instala en Aplicaciones y la abre. Los archivos descargados con curl no llevan el atributo de cuarentena, así que macOS no bloquea el primer inicio. El script es breve: si quieres, puedes [leerlo](../install.sh) antes.

### Opción 2: Homebrew

```bash
brew install --cask 33to9/tap/tinyrecorder
```

### Opción 3: DMG

Descarga el último `TinyRecorder_vX.Y.Z.dmg` desde [Versiones](https://github.com/33to9/TinyRecorder/releases/latest), ábrelo y arrastra TinyRecorder a tu carpeta Aplicaciones.

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
- **Ajustes → General → Permisos → Permiso de grabación de pantalla → Reparar…**; o
- Sal de TinyRecorder, ejecuta `tccutil reset ScreenCapture com.33to9.TinyRecorder` en Terminal, vuelve a abrir TinyRecorder y concede de nuevo el permiso.

## Privacidad

Tus grabaciones nunca salen de tu Mac. Para mejorar la app, TinyRecorder envía estadísticas de uso anónimas a través de [TelemetryDeck](https://telemetrydeck.com/privacy/): la versión de la app y de macOS, el idioma, el modelo de Mac y, de cada grabación, el tipo (pantalla, ventana, área, audio, etc.), el formato, el codificador, la frecuencia de fotogramas, si el micrófono estaba activado, la duración, si se guardó y, si falló, un código de error. Cada grabación recibe su propio ID aleatorio para relacionar estos datos; no está vinculado a ti ni al archivo. También indica qué pasos de la configuración inicial alcanzaste u omitiste, y si se solicitó y concedió el acceso a la grabación de pantalla y al micrófono. De cada grabación indica además desde dónde la iniciaste (barra de herramientas, barra de menús, atajo, script o línea de comandos) y si fue la primera. Nunca envía tus grabaciones, nombres de archivo, carpetas, títulos de ventanas o apps ni mensajes de error. No hay cuentas ni ID de usuario: la app crea un identificador aleatorio que se cifra con hash antes de enviarse, y TelemetryDeck no guarda direcciones IP. Para desactivarlo, abre Ajustes › General › Privacidad y desactiva «Compartir datos de uso anónimos».

Las estadísticas de uso están activadas de forma predeterminada. Todos los detalles: [página de privacidad](https://www.tinyrecorder.app/es/privacy).

## Herramienta de línea de comandos

TinyRecorder incluye el comando `tinyrecorder`. Homebrew lo deja listo al instalar la app, y el instalador de una línea lo enlaza si no hace falta contraseña. Si no, elige **TinyRecorder › Instalar herramienta de línea de comandos…** (también en Ajustes › General, desde la versión 1.8.22) o ejecuta esto una vez:

```bash
sudo mkdir -p /usr/local/bin && sudo ln -sf /Applications/TinyRecorder.app/Contents/Resources/tinyrecorder /usr/local/bin/tinyrecorder
```

Después, por ejemplo:

```bash
tinyrecorder record screen 1 --duration 10
tinyrecorder record window "Untitled" --app TextEdit
tinyrecorder status
tinyrecorder stop
```

`record` espera a que la grabación haya empezado, `stop` espera a que se guarde el archivo e imprime su ruta, y con `--json` cada comando imprime un objeto JSON. Ejecuta `tinyrecorder help` para ver todos los comandos y opciones.

### Uso con agentes de IA

Los agentes de programación como Claude Code, Codex o Cursor ejecutan comandos de terminal, así que pueden grabar la pantalla con `tinyrecorder`: por ejemplo, un error que reproducen o una demo de una función que acaban de crear. Para que un agente lo sepa, añade esto al `CLAUDE.md` o `AGENTS.md` de tu proyecto:

```markdown
## Grabación de pantalla
TinyRecorder está instalado. Usa el comando `tinyrecorder` para grabar la pantalla:
- `tinyrecorder record screen 1 --duration 15 --json` graba la pantalla principal durante 15 segundos e imprime {"file": "<RUTA>"}.
- `tinyrecorder record window "<TÍTULO EXACTO>" --app "<NOMBRE DE LA APP>"` empieza a grabar una ventana; `tinyrecorder stop --json` la detiene e imprime el archivo.
- `tinyrecorder status --json` indica si hay una grabación en curso.
Los errores van a stderr con un estado de salida distinto de 0. Ejecuta `tinyrecorder help` para ver todas las opciones.
```

macOS sigue pidiéndote una vez el permiso de grabación de pantalla y el permiso para que la terminal controle TinyRecorder, y la barra de menús muestra cuándo hay una grabación en curso, así que no se graba nada sin que lo veas.

## Automatización (AppleScript)

TinyRecorder se puede controlar con AppleScript, así que puedes iniciar y detener grabaciones desde Terminal, la app Atajos (acción **Ejecutar AppleScript**), Raycast, Alfred, Keyboard Maestro o tus propios scripts.

Desde Terminal:

```bash
osascript -e 'tell application "TinyRecorder" to record screen numbered 1'
osascript -e 'tell application "TinyRecorder" to stop recording'
```

La primera vez, macOS pregunta si la app que ejecuta el script (por ejemplo, Terminal) puede controlar TinyRecorder. Haz clic en **OK**. Puedes cambiarlo más adelante en **Ajustes del Sistema → Privacidad y seguridad → Automatización**.

| Comando | Qué hace |
|---|---|
| `record screen numbered 1` | Graba la pantalla 1 (la numeración empieza en 1). Sin `numbered`, abre el selector de pantalla |
| `record application named "Safari"` | Graba una app por su nombre. Sin `named`, abre el selector de apps |
| `record window titled "Título" in application "Safari"` | Graba una ventana por su título exacto; `in application` es opcional. Sin `titled`, abre el selector de ventanas |
| `record screen area` | Abre el selector de área; arrastras el área con el ratón |
| `record system audio` | Graba solo el audio del sistema. Añade `microphone true` para incluir el micrófono en esta grabación |
| `pause recording` / `resume recording` | Pausa / reanuda la grabación |
| `stop recording` | Detiene y guarda la grabación |
| `stop recording with waiting until saved` | Detiene la grabación, espera a que se guarde el archivo (incluida la mezcla o conversión del audio) y devuelve su ruta. Si no se puede guardar, devuelve un error. |
| `recording status` | Devuelve el estado (idle, countdown, starting, recording o paused) y, mientras se graba, el tipo de grabación y los segundos grabados. |
| `discard recording` | Detiene la grabación y la mueve a la Papelera |
| `configure …` | Cambia los ajustes de grabación (ver abajo) |

`configure` acepta cualquiera de estos parámetros. Los cambios se guardan, igual que si los cambiaras en Preferencias, y no se puede usar durante una grabación.

| Parámetro | Valor |
|---|---|
| `fps` | 10, 15, 24, 30, 60, 90, 120, 144 o 240 |
| `quality` | 1 = baja, 2 = media, 3 = alta |
| `hires` | `true` graba en resolución Retina |
| `cursor` | Grabar el puntero del ratón |
| `sound` | Grabar el sonido del sistema / de las apps |
| `microphone` | Grabar el micrófono |
| `mic device` | Nombre del dispositivo de entrada, o `"default"` |
| `hdr` | Grabar en HDR (macOS 15 y posteriores) |
| `save folder` | Carpeta donde guardar las grabaciones; debe existir, se admite `~` |

Ejemplo: grabar la pantalla 1 durante un minuto.

```applescript
tell application "TinyRecorder"
    configure fps 30 quality 2 cursor true save folder "~/Movies"
    record screen numbered 1
end tell
delay 60
tell application "TinyRecorder" to stop recording
```

Conviene saber:
- Los comandos de grabación vuelven de inmediato. Si tienes configurado **Retardo antes de grabar** (Preferencias → Grabación), la grabación empieza tras la cuenta atrás: suma ese tiempo a `delay`.
- Durante la cuenta atrás, `stop recording` o `discard recording` cancelan la grabación antes de que empiece, y otro comando de grabación se rechaza como si ya se estuviera grabando.
- Si un nombre coincide con varias ventanas, o la app tiene ventanas en más de una pantalla, TinyRecorder abre el selector para que elijas tú. En ese caso el comando devuelve un error.
- Los errores (ya se está grabando, no se está grabando, falta el permiso de grabación de pantalla) se devuelven al script, así que `osascript` termina con error. Lo mismo ocurre con un número de pantalla no válido o una app o ventana que no se encuentra; no aparece ningún diálogo.
- `pause`, `resume` y `discard` no funcionan con grabaciones de iPhone / iPad; `stop recording` sí.

## Compilar desde el código fuente

Requisitos: Xcode 15 o posterior con el SDK de macOS.

```bash
git clone https://github.com/33to9/TinyRecorder.git
cd TinyRecorder
open TinyRecorder.xcodeproj
# Selecciona el esquema TinyRecorder y compila (⌘B / ⌘R)
```

La integración continua compila con GitHub Actions (`.github/workflows/build.yml`): sube una etiqueta `v*` para publicar una versión.

## Licencia y créditos

Este proyecto se distribuye bajo la licencia **AGPL-3.0** (consulta [LICENSE](../LICENSE)).

- Proyecto original: [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) — Copyright © 2024 [lihaoyun6](https://github.com/lihaoyun6)
- Motor de grabación de pantalla derivado en parte de [Azayaka](https://github.com/Mnpn/Azayaka) de @Mnpn
- Bifurcación mantenida por [33to9](https://github.com/33to9) — Copyright © 2026
