# TinyRecorder · icono de macOS y recursos de marca

<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <b>Español</b>

Toda la geometría vectorial se redibujó a partir de la imagen de referencia «pantalla + punto de grabación» que se entregó, sin el ruido, los bordes sobrantes ni la insignia de archivo decorativa del collage de referencia. La versión clara es el icono predeterminado de la app; la oscura es una alternativa opcional. Todos los PNG llevan perfil sRGB; los SVG escalan sin límite y el logotipo de texto está convertido a contornos.

## Ya incluido en el proyecto

- `TinyRecorder/Assets.xcassets/AppIcon.appiconset/`: el juego completo clásico de macOS de 10 PNG, 16 / 32 / 128 / 256 / 512 pt, cada uno a 1× y 2×.
- `TinyRecorder/Assets.xcassets/TinyRecorderMenuBar.imageset/`: una plantilla negra de 18 pt sobre fondo transparente, macOS 1× / 2×. Cuando no se está grabando, SwiftUI la renderiza con `.template`, así que sigue el aspecto de la barra de menús. 18 pt es el tamaño de diseño de este proyecto, no un tamaño que exija Apple; `menubar/` incluye también una exportación de 54 px.
- `img/tinyrecorder-header.png`: aparece al principio del README en todos los idiomas.

## Carpetas

| Carpeta | Contenido |
| --- | --- |
| `macos/` | `.icns` claro y oscuro con sus `.iconset` completos, para macOS clásico / Finder / Dock |
| `xcode/` | Conjuntos AppIcon, AppIconDark y de barra de menús para el catálogo de recursos, listos para importar |
| `source/` | Originales vectoriales de 1024 y versiones con ajuste óptico para 16/32 pt |
| `png/` | Iconos de la app claro y oscuro a 1024 y 2048 px, transparentes alrededor |
| `logo/` | Color, invertido, monocromo oscuro y monocromo blanco; símbolo solo, horizontal, vertical y solo texto; SVG + PNG transparente |
| `menubar/` | Plantilla de la barra de menús y un SVG alternativo para el estado en pausa |
| `icon-composer/` | Nuevas capas SVG, una referencia del color de fondo a sangre y los pasos de importación en el Mac |
| `documents/` | Icono de documento QMA opcional: SVG / PNG / iconset / icns; la declaración de tipo de archivo existente no cambia |
| `web/` | Favicon opcional para la web SVG / ICO, PNG de 180/192/512, apple-touch-icon y manifest |
| `marketing/` | Banner para el README de GitHub 1600×480, vista previa social de GitHub 1280×640, fondo del instalador DMG 660×400 y su versión 2× |
| `preview/` | Vista general de todos los recursos, SVG / PNG |

## Icono claro y oscuro

Un appiconset clásico de macOS no cambia automáticamente solo porque los dos juegos estén en la carpeta. Por defecto se usa `AppIcon`. Para usar el icono oscuro en todas partes, añade `xcode/AppIconDark.appiconset/` al proyecto y cambia el App Icon Set Name del target a `AppIconDark`, o sustituye los PNG predeterminados por los correspondientes del iconset oscuro.

Para el nuevo aspecto y los efectos de cristal del sistema, usa las capas de `icon-composer/`. El fondo debe ser a sangre y opaco, el primer plano queda transparente y el sistema aplica las esquinas redondeadas. Son archivos fuente para importar: todavía no se ha creado ni verificado un proyecto `.icon` en un Mac, y un icono clásico prerenderizado no debe presentarse como un icono nativo de Liquid Glass.

## Reglas de diseño

- Colores: Ink `#293248`, Record `#FF435C`, Canvas `#F3F5FA`.
- Deja alrededor del logotipo un margen de al menos el diámetro del punto de grabación. No lo estires, no muevas el punto ni añadas texto al icono de la app.
- Los iconos pequeños tienen el marco, el soporte y el punto engrosados por separado. Elige el original según el tamaño lógico en pt: 16pt@2x y 32pt@1x miden ambos 32 px, pero se exportan cada uno para su uso.
- El icono de la barra de menús usa solo negro y transparencia y se marca como Template. El rojo de la marca nunca se incrusta en la plantilla de la barra de menús.
- La insignia de archivo «SVG» de la esquina inferior derecha de la referencia no representa el tipo de archivo real de la app. Este kit añade un icono de documento QMA como recurso opcional.

## Volver a generar y validar

Ejecuta en la carpeta `TinyRecorder-Brand-Kit`:

```sh
python -m pip install -r scripts/requirements-branding.txt
python scripts/generate_brand_assets.py
python scripts/validate_brand_assets.py
```

El generador renderiza a partir de la geometría SVG y no depende de los PNG subidos. `scripts/brand-fonts/Manrope.ttf` procede de Google Fonts con licencia SIL OFL; la licencia está en la misma carpeta. El logotipo de texto se exporta como contornos, así que nadie necesita instalar la fuente.

El generador se escribió para la estructura de carpetas original del proyecto QuickRecorder. Además de `branding/`, escribe `QuickRecorder/Assets.xcassets/`, `img/` y `.github/assets/` dentro de esta carpeta, y vuelve a crear los antiguos archivos README en chino. Copia a mano los archivos del proyecto a su sitio y borra los README que vuelva a crear.

Los ICNS guardan todos los tamaños estándar como datos PNG. En un Mac puedes regenerarlos y comprobarlos con las herramientas del sistema (`iconutil` en esta carpeta, `xcodebuild` en la raíz del repositorio):

```sh
iconutil -c icns branding/macos/TinyRecorder.iconset -o /tmp/TinyRecorder.icns
xcodebuild -project TinyRecorder.xcodeproj -scheme TinyRecorder -configuration Release -destination 'generic/platform=macOS' CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build
```

Estos recursos se crearon en Windows. Se comprobaron los tamaños, los canales alfa, la estructura ICNS, los SVG, el tintado de las plantillas y las referencias del proyecto; no se ejecutaron Xcode, actool ni Icon Composer, ni se comprobaron en Finder/Dock en un Mac real.

## Referencias de Apple

- [Iconos de app (HIG)](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Configurar el icono de la app en el catálogo de recursos](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
- [Crear el icono de la app con Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
- [Tamaños clásicos de iconos de alta resolución en macOS e iconutil](https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Optimizing/Optimizing.html)
- [La barra de menús (HIG)](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [NSImage.isTemplate](https://developer.apple.com/documentation/appkit/nsimage/istemplate)
