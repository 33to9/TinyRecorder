<p align="center">
<img src="img/tinyrecorder-header.png" alt="TinyRecorder" width="800">
</p>
<h3 align="center">Un grabador de pantalla ligero para macOS, compatible con macOS 27</h3>
<p align="center">
<a href="https://www.tinyrecorder.app/es/"><b>Sitio web: www.tinyrecorder.app</b></a>
</p>
<p align="center">
<a href="README.md">English</a> · <a href="README_zh.md">简体中文</a> · <a href="README_zh-Hant.md">繁體中文</a> · <a href="README_it.md">Italiano</a> · <a href="README_ja.md">日本語</a> · <a href="README_de.md">Deutsch</a> · <b>Español</b>
</p>

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
