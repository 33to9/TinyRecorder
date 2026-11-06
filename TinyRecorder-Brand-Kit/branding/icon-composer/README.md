# Icon Composer layered assets

<b>English</b> · <a href="docs/README.zh-CN.md">简体中文</a> · <a href="docs/README.zh-TW.md">繁體中文</a> · <a href="docs/README.it.md">Italiano</a> · <a href="docs/README.ja.md">日本語</a> · <a href="docs/README.de.md">Deutsch</a> · <a href="docs/README.es.md">Español</a>

These are SVG source files for import, **not a compiled, verified `.icon` project**.
The project already uses the classic, compatible AppIcon, so you don't need to do this first.

1. On a Mac, open Icon Composer (it comes with Xcode) and create a new macOS icon with a 1024 × 1024 canvas.
2. Set Background to the opaque solid color `#F3F5FA`; for the dark appearance use `#242C3D`. The background SVGs are color references and can also be imported as a full-bleed background.
3. Import `layers/monitor-light.svg` and then `layers/record-dot.svg`, bottom to top. Keep both layers at their original canvas position and size; don't crop the visible content first.
4. For the dark appearance, replace the monitor layer with `monitor-dark.svg`. The `mono` files are single-color references; preview the system's tinted and clear treatments in Composer.
5. Adjust the result with Composer's material, lighting and glass controls. These sources have no pre-baked shadows, rounded corners or highlights; the system handles the shape and effects.
6. Check default / dark / clear / tinted and the small-size previews, then save `AppIcon.icon`. Drag it into the Xcode app target and make sure the main icon points to it.
7. The `.icon` will replace the current main appiconset. Build on a Mac and check the Dock, Finder, the menu bar and behavior on older versions of macOS before changing the release process.

`flat-square-reference.png` is only a flat composition reference, not a Liquid Glass result processed by Icon Composer.

Apple's guide: https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer
