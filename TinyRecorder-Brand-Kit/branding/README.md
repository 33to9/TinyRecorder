# TinyRecorder · macOS icon and brand assets

<b>English</b> · <a href="docs/README.zh-Hans.md">简体中文</a> · <a href="docs/README.zh-Hant.md">繁體中文</a> · <a href="docs/README.it.md">Italiano</a> · <a href="docs/README.ja.md">日本語</a> · <a href="docs/README.de.md">Deutsch</a> · <a href="docs/README.es.md">Español</a>

All vector geometry was redrawn from the supplied "display + record dot" reference image, without the noise, leftover edges and decorative file badge of the reference collage. The light version is the project's default app icon; the dark version is an optional alternative. Every PNG carries an sRGB profile; the SVGs scale without limit, and the brand wordmark is converted to outlines.

## Already in the project

- `TinyRecorder/Assets.xcassets/AppIcon.appiconset/`: the full classic macOS set of 10 PNGs, 16 / 32 / 128 / 256 / 512 pt, each at 1× and 2×.
- `TinyRecorder/Assets.xcassets/TinyRecorderMenuBar.imageset/`: an 18 pt black template on a transparent background, macOS 1× / 2×. When not recording, SwiftUI renders it with `.template`, so it follows the menu bar appearance. 18 pt is this project's design size, not a size Apple requires; `menubar/` also has a 54 px export.
- `img/tinyrecorder-header.png`: shown at the top of the README in every language.

## Folders

| Folder | Contents |
| --- | --- |
| `macos/` | Light and dark `.icns` with complete `.iconset` folders, for classic macOS / Finder / Dock |
| `xcode/` | AppIcon, AppIconDark and menu bar asset catalog sets, ready to import |
| `source/` | 1024 vector masters and optically adjusted 16/32 pt versions |
| `png/` | Light and dark app icons at 1024 and 2048 px, transparent around the icon |
| `logo/` | Color, reversed, dark mono and white mono; mark alone, horizontal, stacked and wordmark only; SVG + transparent PNG |
| `menubar/` | Menu bar template plus an alternative SVG for the paused state |
| `icon-composer/` | New layered SVGs, a full-bleed background color reference and import steps for the Mac |
| `documents/` | Optional QMA document icon: SVG / PNG / iconset / icns; the existing document type declaration is unchanged |
| `web/` | Optional website favicon SVG / ICO, 180/192/512 PNG, apple-touch-icon and manifest |
| `marketing/` | GitHub README banner 1600×480, GitHub social preview 1280×640, DMG installer background 660×400 and its 2× version |
| `preview/` | Overview of all assets, SVG / PNG |

## Light and dark icons

A classic macOS appiconset does not switch automatically just because both sets are in the folder. `AppIcon` is used by default. To use the dark icon everywhere, add `xcode/AppIconDark.appiconset/` to the project and set the target's App Icon Set Name to `AppIconDark`, or replace the default PNGs with the matching ones from the dark iconset.

For the new appearance and the system glass effects, use the layered files in `icon-composer/`. The background must be full-bleed and opaque, the foreground stays transparent, and the system applies the rounded corners. These are source files for import: no `.icon` project has been created or verified on a Mac yet, and a classic pre-rendered icon must not be called a native Liquid Glass icon.

## Design rules

- Colors: Ink `#293248`, Record `#FF435C`, Canvas `#F3F5FA`.
- Leave clear space of at least one record dot diameter around the logo. Don't stretch it, don't move the dot, and don't add text to the app icon.
- Small app icons have thicker outlines, stand and dot. Pick the source by logical pt size: 16pt@2x and 32pt@1x are both 32 px but are still exported for their own use.
- The menu bar icon uses only black and transparency and is set as a Template image. The brand red is never baked into the menu bar template.
- The "SVG" file badge at the bottom right of the reference image does not stand for the app's real file type. This kit adds a QMA document icon as an optional extra.

## Regenerating and validating

Run in the `TinyRecorder-Brand-Kit` folder:

```sh
python -m pip install -r scripts/requirements-branding.txt
python scripts/generate_brand_assets.py
python scripts/validate_brand_assets.py
```

The generator renders from the SVG geometry and does not depend on the uploaded PNGs. `scripts/brand-fonts/Manrope.ttf` comes from Google Fonts under the SIL OFL; the license is in the same folder. The brand wordmark is exported as outlines, so nobody needs the font installed.

Besides `branding/`, the generator updates the copies used by the app in the TinyRecorder repository (`TinyRecorder/Assets.xcassets/`, `img/tinyrecorder-header.png` and the DMG background in `.github/assets/`) and writes a zip of the kit to `deliverables/`. The README files are maintained by hand and are not touched.

The ICNS files store every standard size as PNG data. On a Mac you can rebuild and check them with the system tools (`iconutil` in this folder, `xcodebuild` at the repository root):

```sh
iconutil -c icns branding/macos/TinyRecorder.iconset -o /tmp/TinyRecorder.icns
xcodebuild -project TinyRecorder.xcodeproj -scheme TinyRecorder -configuration Release -destination 'generic/platform=macOS' CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build
```

These assets were made on Windows. Sizes, alpha channels, ICNS structure, SVGs, template tinting and project references were checked; Xcode, actool, Icon Composer and real Finder/Dock checks were not run.

## Apple references

- [App icons (HIG)](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Configuring your app icon](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
- [Creating your app icon using Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
- [Classic macOS high-resolution icon sizes and iconutil](https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Optimizing/Optimizing.html)
- [The menu bar (HIG)](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [NSImage.isTemplate](https://developer.apple.com/documentation/appkit/nsimage/istemplate)
