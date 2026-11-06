# Capas para Icon Composer

<a href="../README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.zh-TW.md">繁體中文</a> · <a href="README.it.md">Italiano</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <b>Español</b>

Estos archivos son fuentes SVG para importar, **no un proyecto `.icon` compilado y verificado**.
El proyecto ya usa el AppIcon clásico y compatible, así que no hace falta hacer esto primero.

1. En un Mac, abre Icon Composer (viene con Xcode) y crea un icono nuevo de macOS con un lienzo de 1024 × 1024.
2. Pon Background en el color sólido opaco `#F3F5FA`; para el aspecto oscuro usa `#242C3D`. Los SVG de fondo son referencias de color y también se pueden importar como fondo a sangre.
3. Importa `layers/monitor-light.svg` y después `layers/record-dot.svg`, de abajo arriba. Mantén ambas capas en su posición y tamaño originales en el lienzo; no recortes antes el contenido visible.
4. Para el aspecto oscuro, sustituye la capa de la pantalla por `monitor-dark.svg`. Los archivos `mono` son referencias monocromas; previsualiza en Composer cómo trata el sistema los modos tinted y clear.
5. Ajusta el resultado con los controles de material, iluminación y cristal de Composer. Estas fuentes no llevan sombras, esquinas redondeadas ni brillos incrustados; el sistema se encarga de la forma y los efectos.
6. Comprueba default / dark / clear / tinted y las vistas previas en tamaños pequeños, y guarda `AppIcon.icon`. Arrástralo al target de la app en Xcode y asegúrate de que el icono principal apunta a él.
7. El `.icon` sustituirá al appiconset principal actual. Compila en un Mac y comprueba el Dock, el Finder, la barra de menús y el comportamiento en versiones anteriores de macOS antes de cambiar el proceso de publicación.

`flat-square-reference.png` es solo una referencia de composición plana, no un resultado de Liquid Glass procesado por Icon Composer.

Guía de Apple: https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer
