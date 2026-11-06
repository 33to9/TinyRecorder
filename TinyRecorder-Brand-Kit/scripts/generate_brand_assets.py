"""Build TinyRecorder's original vector artwork and all distribution assets.

Install scripts/requirements-branding.txt, then run this script from any directory.
No uploaded raster is edited or embedded: all artwork is drawn as SVG geometry.
"""
from __future__ import annotations

import hashlib
import io
import json
from pathlib import Path
import shutil
import struct
import zipfile
from xml.sax.saxutils import escape

from PIL import Image
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
import resvg_py

ROOT = Path(__file__).resolve().parents[1]          # TinyRecorder-Brand-Kit/
REPO = ROOT.parent                                    # the TinyRecorder repository
BRAND = ROOT / 'branding'
ASSETS = REPO / 'TinyRecorder/Assets.xcassets'
NAVY = '#293248'
WHITE = '#F5F7FC'
RED = '#FF435C'
SLOTS = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1),
         (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]
TILE = ('M320 100H704C850 100 924 174 924 320V704'
        'C924 850 850 924 704 924H320C174 924 100 850 100 704V320'
        'C100 174 174 100 320 100Z')


def put(path: Path, value: str | bytes):
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(value, str):
        path.write_text(value, encoding='utf-8', newline='\n')
    else:
        path.write_bytes(value)


def svg(body: str, width=1024, height=1024, title='TinyRecorder'):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" '
            f'height="{height}" viewBox="0 0 {width} {height}" role="img">'
            f'<title>{escape(title)}</title>{body}</svg>')


def render(source: str, path: Path, width: int, height: int | None = None):
    data = resvg_py.svg_to_bytes(svg_string=source, width=width, height=height,
                                skip_system_fonts=False)
    # Explicit sRGB metadata is included in every exported PNG.
    from PIL import ImageCms
    profile = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
    im = Image.open(io.BytesIO(data)).convert('RGBA')
    out = io.BytesIO()
    im.save(out, format='PNG', icc_profile=profile)
    put(path, out.getvalue())


def monitor(fill=NAVY, compact=False):
    # Even-odd geometry gives a genuine transparent screen opening.
    if compact:
        return (f'<path fill="{fill}" fill-rule="evenodd" d="'
                'M260 298H764Q812 298 812 346V646Q812 694 764 694H260'
                'Q212 694 212 646V346Q212 298 260 298Z '
                'M282 352Q268 352 268 366V626Q268 640 282 640H742'
                'Q756 640 756 626V366Q756 352 742 352Z"/>'
                f'<path fill="{fill}" d="M480 684H544V756H480Z"/>'
                f'<rect x="368" y="742" width="288" height="44" rx="22" fill="{fill}"/>')
    return (f'<path fill="{fill}" fill-rule="evenodd" d="'
            'M276 302H748Q796 302 796 350V634Q796 682 748 682H276'
            'Q228 682 228 634V350Q228 302 276 302Z '
            'M290 346Q272 346 272 364V620Q272 638 290 638H734'
            'Q752 638 752 620V364Q752 346 734 346Z"/>'
            f'<path fill="{fill}" d="M482 672H542V750H482Z"/>'
            f'<rect x="378" y="738" width="268" height="40" rx="20" fill="{fill}"/>')


def dot(fill=RED, compact=False):
    return f'<circle cx="674" cy="564" r="{52 if compact else 46}" fill="{fill}"/>'


def app_body(dark=False, compact=False):
    a, b = ('#30394C', '#1D2432') if dark else ('#FFFFFF', '#E9EDF6')
    ma, mb = ('#FFFFFF', '#E8EDF8') if dark else ('#34405B', '#252E43')
    edge = '#465066' if dark else '#D5DCE9'
    return (f'<defs><linearGradient id="tile" x2="0.35" y2="1">'
            f'<stop stop-color="{a}"/><stop offset="1" stop-color="{b}"/></linearGradient>'
            f'<linearGradient id="ink" x2="0.2" y2="1"><stop stop-color="{ma}"/>'
            f'<stop offset="1" stop-color="{mb}"/></linearGradient>'
            '<linearGradient id="red" x2="0.3" y2="1"><stop stop-color="#FF526B"/>'
            '<stop offset="1" stop-color="#FF334F"/></linearGradient></defs>'
            f'<path d="{TILE}" transform="translate(0 9)" fill="#101828" opacity=".08"/>'
            f'<path d="{TILE}" fill="url(#tile)" stroke="{edge}" stroke-width="2"/>'
            f'{monitor("url(#ink)", compact)}{dot("url(#red)", compact)}')


def mark_body(fill=NAVY, record=RED):
    return f'<g transform="translate(-196 -270)">{monitor(fill)}{dot(record)}</g>'


FONT = instantiateVariableFont(TTFont(ROOT / 'scripts/brand-fonts/Manrope.ttf'),
                               {'wght': 650}, inplace=False)
GLYPHS = FONT.getGlyphSet()
CMAP = FONT.getBestCmap()
UPM = FONT['head'].unitsPerEm


def outlined(text: str, x: float, baseline: float, size: float, fill=NAVY):
    cursor = x
    paths = []
    for letter in text:
        name = CMAP[ord(letter)]
        glyph = GLYPHS[name]
        pen = SVGPathPen(GLYPHS)
        glyph.draw(TransformPen(pen, (size / UPM, 0, 0, -size / UPM, cursor, baseline)))
        paths.append(f'<path d="{pen.getCommands()}"/>')
        cursor += glyph.width * size / UPM
    return f'<g fill="{fill}">{"".join(paths)}</g>', cursor - x


def label(text, x, y, size=18, fill='#687386', weight=400, **attrs):
    extra = ' '.join(f'{k.replace("_", "-")}="{v}"' for k, v in attrs.items())
    return (f'<text x="{x}" y="{y}" font-family="Segoe UI,Arial,sans-serif" '
            f'font-size="{size}" font-weight="{weight}" fill="{fill}" {extra}>'
            f'{escape(text)}</text>')


def icon_filename(points, scale):
    return f'icon_{points}x{points}{"@2x" if scale == 2 else ""}.png'


def make_icns(folder: Path, output: Path):
    # Standard PNG-backed Apple ICNS types. Retina entries have their own tags.
    tags = {(16, 1): b'icp4', (16, 2): b'ic11', (32, 1): b'icp5',
            (32, 2): b'ic12', (128, 1): b'ic07', (128, 2): b'ic13',
            (256, 1): b'ic08', (256, 2): b'ic14', (512, 1): b'ic09',
            (512, 2): b'ic10'}
    chunks = []
    for points, scale in SLOTS:
        data = (folder / icon_filename(points, scale)).read_bytes()
        chunks.append(tags[points, scale] + struct.pack('>I', len(data) + 8) + data)
    data = b''.join(chunks)
    put(output, b'icns' + struct.pack('>I', len(data) + 8) + data)


def app_icons():
    for dark in (False, True):
        name = 'TinyRecorder-Dark' if dark else 'TinyRecorder'
        appearance = 'dark' if dark else 'light'
        source = svg(app_body(dark))
        put(BRAND / f'source/app-icon-{appearance}.svg', source)
        put(BRAND / f'source/app-icon-{appearance}-small.svg', svg(app_body(dark, True)))
        for size in (1024, 2048):
            render(source, BRAND / f'png/app-icon-{appearance}-{size}.png', size)
        folder = BRAND / f'macos/{name}.iconset'
        for points, scale in SLOTS:
            # Optical correction follows the point size, not only pixel count.
            render(svg(app_body(dark, points <= 32)),
                   folder / icon_filename(points, scale), points * scale)
        make_icns(folder, BRAND / f'macos/{name}.icns')
        catalog = BRAND / f'xcode/AppIcon{ "Dark" if dark else ""}.appiconset'
        catalog.mkdir(parents=True, exist_ok=True)
        for points, scale in SLOTS:
            shutil.copyfile(folder / icon_filename(points, scale),
                            catalog / icon_filename(points, scale))
        manifest = {'images': [{'filename': icon_filename(p, s), 'idiom': 'mac',
                               'scale': f'{s}x', 'size': f'{p}x{p}'} for p, s in SLOTS],
                    'info': {'author': 'xcode', 'version': 1}}
        put(catalog / 'Contents.json', json.dumps(manifest, indent=2) + '\n')
        if not dark:
            (ASSETS / 'AppIcon.appiconset').mkdir(parents=True, exist_ok=True)
            for p in catalog.iterdir():
                shutil.copyfile(p, ASSETS / 'AppIcon.appiconset' / p.name)


def logos():
    for name, ink, record in [('color', NAVY, RED), ('reverse', WHITE, RED),
                              ('mono-dark', NAVY, NAVY), ('mono-light', '#FFFFFF', '#FFFFFF')]:
        source = svg(mark_body(ink, record), 632, 540, f'TinyRecorder {name} logo')
        put(BRAND / f'logo/tinyrecorder-mark-{name}.svg', source)
        for width in (256, 512, 1024):
            render(source, BRAND / f'logo/tinyrecorder-mark-{name}-{width}.png', width)
    for name, ink, record in [('dark', NAVY, RED), ('light', WHITE, RED)]:
        word, width = outlined('TinyRecorder', 0, 118, 144, ink)
        word_source = svg(word, round(width + 4), 150, f'TinyRecorder {name} wordmark')
        put(BRAND / f'logo/tinyrecorder-wordmark-{name}.svg', word_source)
        render(word_source, BRAND / f'logo/tinyrecorder-wordmark-{name}-1600.png', 1600)
        word, width = outlined('TinyRecorder', 212, 138, 94, ink)
        body = (f'<g transform="translate(0 2) scale(.29)">{mark_body(ink, record)}</g>' + word)
        source = svg(body, round(212 + width + 14), 174, f'TinyRecorder {name} horizontal logo')
        put(BRAND / f'logo/tinyrecorder-horizontal-{name}.svg', source)
        for pixels in (800, 1600):
            render(source, BRAND / f'logo/tinyrecorder-horizontal-{name}-{pixels}.png', pixels)
        word, width = outlined('TinyRecorder', 0, 0, 90, ink)
        body = (f'<g transform="translate(134 10) scale(.5)">{mark_body(ink, record)}</g>'
                f'<g transform="translate({(584-width)/2} 392)">{word}</g>')
        source = svg(body, 584, 440, f'TinyRecorder {name} stacked logo')
        put(BRAND / f'logo/tinyrecorder-stacked-{name}.svg', source)
        render(source, BRAND / f'logo/tinyrecorder-stacked-{name}-1024.png', 1024)


def menu_shape(state='idle'):
    # Pixel-aligned at 18 pt, with 1.5 pt outline and a 2.75 pt recording dot.
    graphic = ('<path fill="#000" fill-rule="evenodd" d="M3 2H15Q17 2 17 4V12'
               'Q17 14 15 14H3Q1 14 1 12V4Q1 2 3 2Z '
               'M3 3.5Q2.5 3.5 2.5 4V12Q2.5 12.5 3 12.5H15'
               'Q15.5 12.5 15.5 12V4Q15.5 3.5 15 3.5Z"/>'
               '<path d="M8 13H10V16H8Z" fill="#000"/>'
               '<rect x="5" y="15.5" width="8" height="1.5" rx=".75" fill="#000"/>')
    if state == 'paused':
        graphic += '<path d="M10.5 8H11.7V11H10.5ZM12.6 8H13.8V11H12.6Z" fill="#000"/>'
    else:
        graphic += '<circle cx="12.5" cy="9.5" r="1.5" fill="#000"/>'
    return graphic


def menu_icons():
    source = svg(menu_shape(), 18, 18, 'TinyRecorder menu bar template')
    put(BRAND / 'menubar/TinyRecorderMenuBar.svg', source)
    manifest = {'images': [], 'info': {'author': 'xcode', 'version': 1},
                'properties': {'template-rendering-intent': 'template'}}
    catalog = BRAND / 'xcode/TinyRecorderMenuBar.imageset'
    for scale in (1, 2, 3):
        name = f'tinyrecorder-menubar{"@"+str(scale)+"x" if scale > 1 else ""}.png'
        render(source, BRAND / 'menubar' / name, 18 * scale)
        if scale <= 2:
            put(catalog / name, (BRAND / 'menubar' / name).read_bytes())
            manifest['images'].append({'filename': name, 'idiom': 'mac', 'scale': f'{scale}x'})
    put(catalog / 'Contents.json', json.dumps(manifest, indent=2) + '\n')
    target = ASSETS / 'TinyRecorderMenuBar.imageset'
    target.mkdir(parents=True, exist_ok=True)
    # Keep the optional 3x export outside macOS asset catalogs, which use 1x/2x.
    for directory in (catalog, target):
        obsolete = directory / 'tinyrecorder-menubar@3x.png'
        if obsolete.exists():
            obsolete.unlink()
    for file in catalog.iterdir():
        shutil.copyfile(file, target / file.name)
    put(BRAND / 'menubar/TinyRecorderMenuBar-Paused.svg',
        svg(menu_shape('paused'), 18, 18, 'Optional paused template; not wired to recording controls'))


def composer_sources():
    # Full square layers, without baked shadows, highlights, clipping or effects.
    for name, ink, bg in [('light', NAVY, '#F3F5FA'),
                           ('dark', '#F5F7FC', '#242C3D'),
                           ('mono', '#FFFFFF', '#293248')]:
        put(BRAND / f'icon-composer/layers/monitor-{name}.svg', svg(monitor(ink)))
        put(BRAND / f'icon-composer/layers/background-{name}.svg',
            svg(f'<rect width="1024" height="1024" fill="{bg}"/>'))
    put(BRAND / 'icon-composer/layers/record-dot.svg', svg(dot()))
    put(BRAND / 'icon-composer/layers/record-dot-mono.svg', svg(dot('#FFFFFF')))
    preview = svg('<rect width="1024" height="1024" fill="#F3F5FA"/>' + monitor() + dot())
    render(preview, BRAND / 'icon-composer/flat-square-reference.png', 1024)


def documents_and_web():
    word, _ = outlined('QMA', 335, 830, 116, '#69758B')
    body = ('<path d="M270 108H642L800 266V868Q800 916 752 916H270'
            'Q222 916 222 868V156Q222 108 270 108Z" fill="#F3F5FA" stroke="#D5DCE8" stroke-width="3"/>'
            '<path d="M642 108V218Q642 266 690 266H800Z" fill="#D8DFEB"/>'
            f'<g transform="translate(294 356) scale(.69)">{mark_body()}</g>' + word)
    doc = svg(body, title='TinyRecorder QMA document icon')
    put(BRAND / 'documents/TinyRecorder-QMA.svg', doc)
    folder = BRAND / 'documents/TinyRecorder-QMA.iconset'
    for p, s in SLOTS:
        # The QMA lettering is omitted at 16/32pt to keep the file silhouette legible.
        small = svg(body.replace(word, '')) if p <= 32 else doc
        render(small, folder / icon_filename(p, s), p * s)
    make_icns(folder, BRAND / 'documents/TinyRecorder-QMA.icns')
    render(doc, BRAND / 'documents/TinyRecorder-QMA-1024.png', 1024)
    # Optional browser assets: these don't alter the native macOS build.
    websvg = svg(f'<rect width="1024" height="1024" rx="220" fill="#F3F5FA"/>{monitor()}{dot()}')
    put(BRAND / 'web/favicon.svg', websvg)
    for size in (16, 32, 48, 180, 192, 512):
        render(websvg, BRAND / f'web/icon-{size}.png', size)
    favicon = Image.open(BRAND / 'web/icon-512.png')
    favicon.save(BRAND / 'web/favicon.ico', sizes=[(16, 16), (32, 32), (48, 48)])
    shutil.copyfile(BRAND / 'web/icon-180.png', BRAND / 'web/apple-touch-icon.png')
    manifest = {'name': 'TinyRecorder', 'short_name': 'TinyRecorder', 'display': 'standalone',
                'background_color': '#F3F5FA', 'theme_color': NAVY,
                'icons': [{'src': f'icon-{s}.png', 'sizes': f'{s}x{s}', 'type': 'image/png',
                           'purpose': 'any'} for s in (192, 512)]}
    put(BRAND / 'web/site.webmanifest', json.dumps(manifest, indent=2) + '\n')


def marketing():
    word, _ = outlined('TinyRecorder', 508, 238, 106)
    header = ('<rect width="1600" height="480" rx="32" fill="#F2F4F9"/>'
              '<circle cx="1440" cy="-180" r="560" fill="#E9EDF6"/>'
              f'<g transform="translate(72 38) scale(.39)">{app_body()}</g>' + word +
              label('A lightweight screen recorder for macOS', 513, 294, 31, '#687386'))
    header = svg(header, 1600, 480, 'TinyRecorder project header')
    put(BRAND / 'marketing/github-header.svg', header)
    render(header, BRAND / 'marketing/github-header.png', 1600)
    put(REPO / 'img/tinyrecorder-header.png', (BRAND / 'marketing/github-header.png').read_bytes())
    word, _ = outlined('TinyRecorder', 486, 290, 91)
    social = ('<rect width="1280" height="640" fill="#F2F4F9"/>'
              '<circle cx="1100" cy="70" r="460" fill="#E9EDF6"/>'
              f'<g transform="translate(24 112) scale(.42)">{app_body()}</g>' + word +
              label('Small app. Clear recordings.', 490, 356, 31, '#687386') +
              label('SCREEN  /  WINDOW  /  AUDIO', 490, 428, 17, '#7B8596', 600, letter_spacing='2') +
              f'<circle cx="505" cy="494" r="6" fill="{RED}"/>' +
              label('Made for macOS', 524, 501, 19, '#687386'))
    source = svg(social, 1280, 640, 'TinyRecorder GitHub social preview')
    put(BRAND / 'marketing/github-social-preview.svg', source)
    render(source, BRAND / 'marketing/github-social-preview.png', 1280)


def installer_assets():
    # This hand-authored outlined SVG is also the source used by the DMG job.
    source_path = BRAND / 'marketing/installer-background.svg'
    if not source_path.exists():
        return
    source = source_path.read_text(encoding='utf-8')
    put(REPO / '.github/assets/dmg_background.svg', source)
    for suffix, width in [('', 660), ('@2x', 1320)]:
        output = BRAND / f'marketing/installer-background{suffix}.png'
        render(source, output, width)
        put(REPO / f'.github/assets/dmg_background{suffix}.png', output.read_bytes())


def preview():
    parts = ['<rect width="1800" height="1660" fill="#F1F3F8"/>']
    parts += [label('TINYRECORDER', 80, 82, 22, NAVY, 650, letter_spacing='4'),
              label('macOS icon & identity kit', 80, 137, 39, NAVY, 600),
              label('A familiar screen. A single recording dot.', 80, 176, 20)]
    # Main app icons sit on matching cards to show the true transparent margins.
    for x, dark in [(80, False), (620, True)]:
        parts.append(f'<rect x="{x}" y="226" width="510" height="520" rx="28" fill="{ "#171E2B" if dark else "#FFFFFF"}"/>')
        # Unique IDs prevent gradients from the light and dark samples colliding.
        icon = app_body(dark).replace('id="', f'id="a{x}-').replace('url(#', f'url(#a{x}-')
        parts.append(f'<g transform="translate({x+40} 230) scale(.42)">{icon}</g>')
        parts.append(label('DARK ALTERNATE' if dark else 'PRIMARY / LIGHT', x+34, 707, 16,
                           '#B8C3D5' if dark else '#687386', 600, letter_spacing='2'))
    parts.append('<rect x="1160" y="226" width="560" height="520" rx="28" fill="#FFFFFF"/>')
    parts += [label('THE MARK', 1198, 278, 16, '#687386', 600, letter_spacing='2'),
              f'<g transform="translate(1260 300) scale(.57)">{mark_body()}</g>',
              label('Transparent, scalable SVG', 1198, 704, 18)]
    # Identity cards.
    parts.append('<rect x="80" y="776" width="1050" height="250" rx="24" fill="#FFFFFF"/>')
    parts.append(label('LOGO LOCKUP', 114, 820, 15, '#687386', 600, letter_spacing='2'))
    parts.append(f'<g transform="translate(130 849) scale(.22)">{mark_body()}</g>')
    word, _ = outlined('TinyRecorder', 300, 944, 89)
    parts.append(word)
    parts.append('<rect x="1160" y="776" width="560" height="250" rx="24" fill="#293248"/>')
    parts.append(label('REVERSE / MONOCHROME', 1198, 820, 15, '#C3CCDA', 600, letter_spacing='2'))
    parts.append(f'<g transform="translate(1232 855) scale(.23)">{mark_body(WHITE,RED)}</g>')
    parts.append(f'<g transform="translate(1490 855) scale(.23)">{mark_body("#FFFFFF","#FFFFFF")}</g>')
    # Template previews on menu bar backgrounds at actual and enlarged scales.
    parts.append('<rect x="80" y="1056" width="820" height="280" rx="24" fill="#FFFFFF"/>')
    parts.append(label('MENU BAR / TEMPLATE', 114, 1105, 15, '#687386', 600, letter_spacing='2'))
    for y, bg, ink in [(1134, '#EEF0F5', '#000'), (1212, '#202838', '#FFF')]:
        parts.append(f'<rect x="114" y="{y}" width="752" height="56" rx="13" fill="{bg}"/>')
        parts.append(f'<g transform="translate(148 {y+10}) scale(2)">{menu_shape().replace("#000", ink)}</g>')
        parts.append(label('TinyRecorder', 216, y+35, 18, '#667085' if ink == '#000' else '#CDD5E2'))
        parts.append(label('Wed  9:41', 750, y+34, 16, '#667085' if ink == '#000' else '#CDD5E2'))
    parts.append('<rect x="930" y="1056" width="790" height="280" rx="24" fill="#FFFFFF"/>')
    parts.append(label('DOCK / FINDER SIZES', 964, 1105, 15, '#687386', 600, letter_spacing='2'))
    for x, size in [(975, 32), (1070, 64), (1222, 128), (1450, 180)]:
        body = app_body(compact=size <= 64).replace('id="', f'id="s{size}-').replace('url(#', f'url(#s{size}-')
        parts.append(f'<g transform="translate({x} {1190-size/2}) scale({size/1024})">{body}</g>')
        parts.append(label(f'{size}px', x+size/2, 1302, 15, text_anchor='middle'))
    # Palette and deliverables.
    parts.append(label('CORE PALETTE', 80, 1406, 15, '#687386', 600, letter_spacing='2'))
    for x, color, name in [(80, NAVY, 'Ink / #293248'), (425, RED, 'Record / #FF435C'), (770, '#F3F5FA', 'Canvas / #F3F5FA')]:
        parts.append(f'<rect x="{x}" y="1432" width="64" height="64" rx="16" fill="{color}" stroke="#DCE1EB"/>')
        parts.append(label(name, x+82, 1472, 18, NAVY))
    parts.append(label('ICNS  ·  XCODE ASSETS  ·  SVG  ·  PNG  ·  COMPOSER LAYERS', 80, 1583, 17, '#687386', 600, letter_spacing='1.5'))
    parts.append(label('1024 master  /  2048 export  /  18pt template', 1720, 1583, 16, text_anchor='end'))
    source = svg(''.join(parts), 1800, 1660, 'TinyRecorder complete identity kit preview')
    put(BRAND / 'preview/brand-overview.svg', source)
    render(source, BRAND / 'preview/brand-overview.png', 1800)


def package():
    # Record integrity hashes for every deliverable except this file.
    files = sorted(p for p in BRAND.rglob('*') if p.is_file() and p.name != 'SHA256SUMS.txt')
    put(BRAND / 'SHA256SUMS.txt', ''.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.relative_to(BRAND).as_posix()}\n' for p in files))
    deliver = ROOT / 'deliverables'
    deliver.mkdir(exist_ok=True)
    with zipfile.ZipFile(deliver / 'TinyRecorder-macOS-Brand-Kit.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for file in sorted(BRAND.rglob('*')):
            if file.is_file():
                archive.write(file, f'TinyRecorder-Brand-Kit/branding/{file.relative_to(BRAND).as_posix()}')
        # The README files are maintained by hand (English plus translations in docs/).
        for file in [ROOT / 'README.md', *sorted((ROOT / 'docs').glob('README.*.md'))]:
            archive.write(file, f'TinyRecorder-Brand-Kit/{file.relative_to(ROOT).as_posix()}')
        for file in [Path(__file__), ROOT / 'scripts/validate_brand_assets.py',
                     ROOT / 'scripts/requirements-branding.txt',
                     ROOT / 'scripts/brand-fonts/Manrope.ttf', ROOT / 'scripts/brand-fonts/OFL.txt']:
            if file.exists():
                archive.write(file, f'TinyRecorder-Brand-Kit/{file.relative_to(ROOT).as_posix()}')


if __name__ == '__main__':
    app_icons()
    logos()
    menu_icons()
    composer_sources()
    documents_and_web()
    marketing()
    installer_assets()
    preview()
    package()
    print(f'Generated {sum(p.is_file() for p in BRAND.rglob("*"))} brand assets and delivery archive.')
