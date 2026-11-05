#!/usr/bin/env python3
"""Inspect exported TinyRecorder artwork without requiring Apple's build tools.

Requires Pillow. This checks file structure, raster dimensions, transparency,
template colors, SVG references, and the consistency of the Xcode copy. It does
not replace actool, Icon Composer, an Xcode build, or visual review on macOS.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import re
import struct
import sys
from pathlib import Path
from xml.etree import ElementTree as ET

from PIL import Image


ICON_SLOTS = {
    "icon_16x16.png": (16, "16x16", "1x"),
    "icon_16x16@2x.png": (32, "16x16", "2x"),
    "icon_32x32.png": (32, "32x32", "1x"),
    "icon_32x32@2x.png": (64, "32x32", "2x"),
    "icon_128x128.png": (128, "128x128", "1x"),
    "icon_128x128@2x.png": (256, "128x128", "2x"),
    "icon_256x256.png": (256, "256x256", "1x"),
    "icon_256x256@2x.png": (512, "256x256", "2x"),
    "icon_512x512.png": (512, "512x512", "1x"),
    "icon_512x512@2x.png": (1024, "512x512", "2x"),
}
ICNS_PNG_SIZES = {
    b"icp4": 16, b"icp5": 32, b"icp6": 64,
    b"ic07": 128, b"ic08": 256, b"ic09": 512, b"ic10": 1024,
    b"ic11": 32, b"ic12": 64, b"ic13": 256, b"ic14": 512,
}
TEMPLATE_SLOTS = {
    "tinyrecorder-menubar.png": (18, "1x"),
    "tinyrecorder-menubar@2x.png": (36, "2x"),
}


class Inspector:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.errors: list[str] = []
        self.counts = {"PNG": 0, "SVG": 0, "ICNS": 0, "catalog": 0}
        self.counted: dict[str, set[Path]] = {kind: set() for kind in self.counts}

    def record(self, kind: str, path: Path) -> None:
        self.counted[kind].add(path.resolve())
        self.counts[kind] = len(self.counted[kind])

    def label(self, path: Path) -> str:
        return path.relative_to(self.root).as_posix()

    def require(self, condition: bool, message: str) -> None:
        if not condition:
            self.errors.append(message)

    def png(self, path: Path, expected: int | None = None,
            transparent_border: bool = False, template: bool = False) -> None:
        try:
            with Image.open(path) as image:
                image.load()
                self.require(image.format == "PNG", f"{self.label(path)}: not PNG")
                if expected is not None:
                    self.require(image.size == (expected, expected),
                                 f"{self.label(path)}: {image.size}, expected {expected} x {expected}")
                self.require(image.mode in ("RGB", "RGBA"),
                             f"{self.label(path)}: unexpected color mode {image.mode}")
                rgba = image.convert("RGBA")
                alpha = rgba.getchannel("A")
                self.require(alpha.getbbox() is not None,
                             f"{self.label(path)}: empty image")
                if transparent_border:
                    self.require(image.mode == "RGBA", f"{self.label(path)}: missing alpha channel")
                    bbox = alpha.getbbox()
                    if bbox:
                        left, top, right, bottom = bbox
                        self.require(left > 0 and top > 0 and right < image.width and bottom < image.height,
                                     f"{self.label(path)}: artwork or shadow reaches canvas edge: {bbox}")
                    self.require(alpha.getextrema() == (0, 255),
                                 f"{self.label(path)}: expected transparent margin and opaque artwork")
                if template:
                    self.require(image.mode == "RGBA", f"{self.label(path)}: template needs alpha")
                    pixels = rgba.tobytes()
                    self.require(all(pixels[index:index + 3] == b"\x00\x00\x00"
                                     for index in range(0, len(pixels), 4) if pixels[index + 3]),
                                 f"{self.label(path)}: visible template pixels must be black")
                self.record("PNG", path)
        except (OSError, ValueError) as exc:
            self.errors.append(f"{self.label(path)}: {exc}")

    def iconset(self, path: Path) -> None:
        self.require(path.is_dir(), f"{self.label(path)}: missing iconset")
        found = {item.name for item in path.glob("*.png")}
        self.require(found == set(ICON_SLOTS),
                     f"{self.label(path)}: PNG filenames differ; missing={sorted(set(ICON_SLOTS) - found)}, "
                     f"extra={sorted(found - set(ICON_SLOTS))}")
        for filename, (pixels, _, _) in ICON_SLOTS.items():
            self.png(path / filename, pixels, transparent_border=True)

    def catalog(self, path: Path, template: bool = False) -> None:
        try:
            data = json.loads((path / "Contents.json").read_text(encoding="utf-8-sig"))
            entries = data["images"]
            self.require(isinstance(entries, list), f"{self.label(path)}: images must be an array")
            self.require(data.get("info", {}).get("version") == 1,
                         f"{self.label(path)}: unsupported catalog version")
            expected_names = set(TEMPLATE_SLOTS if template else ICON_SLOTS)
            names = [entry.get("filename") for entry in entries]
            self.require(set(names) == expected_names and len(names) == len(expected_names),
                         f"{self.label(path)}: missing, duplicate, or unexpected images")
            if template:
                self.require(data.get("properties", {}).get("template-rendering-intent") == "template",
                             f"{self.label(path)}: template-rendering-intent must be template")
            for entry in entries:
                filename = entry.get("filename", "")
                if filename not in expected_names:
                    continue
                if template:
                    pixels, scale = TEMPLATE_SLOTS[filename]
                    self.require(entry.get("scale") == scale,
                                 f"{self.label(path)} / {filename}: incorrect scale")
                    self.require(entry.get("idiom") == "mac",
                                 f"{self.label(path)} / {filename}: expected mac idiom")
                else:
                    pixels, size, scale = ICON_SLOTS[filename]
                    self.require(entry.get("size") == size and entry.get("scale") == scale,
                                 f"{self.label(path)} / {filename}: incorrect size or scale")
                    self.require(entry.get("idiom") == "mac",
                                 f"{self.label(path)} / {filename}: expected mac idiom")
                self.png(path / filename, pixels, transparent_border=True, template=template)
            self.record("catalog", path)
        except (OSError, ValueError, KeyError, TypeError) as exc:
            self.errors.append(f"{self.label(path)}: malformed catalog: {exc}")

    def icns(self, path: Path) -> None:
        try:
            raw = path.read_bytes()
            self.require(len(raw) >= 8, f"{self.label(path)}: truncated header")
            if len(raw) < 8:
                return
            magic, declared = struct.unpack(">4sI", raw[:8])
            self.require(magic == b"icns", f"{self.label(path)}: incorrect magic")
            self.require(declared == len(raw), f"{self.label(path)}: incorrect declared length")
            offset, seen, sizes = 8, set(), set()
            while offset < len(raw):
                if offset + 8 > len(raw):
                    self.errors.append(f"{self.label(path)}: truncated chunk header at {offset}")
                    break
                kind, length = struct.unpack(">4sI", raw[offset:offset + 8])
                if length < 8 or offset + length > len(raw):
                    self.errors.append(f"{self.label(path)}: invalid chunk length at {offset}")
                    break
                self.require(kind not in seen, f"{self.label(path)}: duplicate chunk {kind!r}")
                seen.add(kind)
                payload = raw[offset + 8:offset + length]
                if kind in ICNS_PNG_SIZES:
                    self.require(payload.startswith(b"\x89PNG\r\n\x1a\n"),
                                 f"{self.label(path)}: {kind!r} payload must be PNG")
                    with Image.open(io.BytesIO(payload)) as image:
                        image.load()
                        pixels = ICNS_PNG_SIZES[kind]
                        self.require(image.size == (pixels, pixels),
                                     f"{self.label(path)}: {kind!r} has wrong pixel dimensions {image.size}")
                        sizes.add(pixels)
                elif kind not in (b"TOC ", b"icnV", b"name", b"info"):
                    self.errors.append(f"{self.label(path)}: unexpected non-PNG chunk {kind!r}")
                offset += length
            self.require(offset == len(raw), f"{self.label(path)}: unparsed trailing data")
            self.require({16, 32, 64, 128, 256, 512, 1024} <= sizes,
                         f"{self.label(path)}: incomplete raster sizes: {sorted(sizes)}")
            self.record("ICNS", path)
        except (OSError, ValueError, struct.error) as exc:
            self.errors.append(f"{self.label(path)}: invalid ICNS: {exc}")

    def svg(self, path: Path) -> None:
        try:
            raw = path.read_text(encoding="utf-8-sig")
            self.require("<!ENTITY" not in raw and "<!DOCTYPE" not in raw,
                         f"{self.label(path)}: SVG must not contain external declarations")
            root = ET.fromstring(raw)
            self.require(root.tag == "{http://www.w3.org/2000/svg}svg",
                         f"{self.label(path)}: missing SVG namespace")
            self.require(bool(root.get("viewBox")), f"{self.label(path)}: missing viewBox")
            for node in root.iter():
                name = node.tag.rsplit("}", 1)[-1]
                self.require(name not in ("image", "script", "foreignObject"),
                             f"{self.label(path)}: forbidden raster/script/HTML element {name}")
                for key, value in node.attrib.items():
                    attr = key.rsplit("}", 1)[-1]
                    if attr == "href":
                        self.require(value.startswith("#"),
                                     f"{self.label(path)}: external or embedded href {value[:80]}")
                    for target in re.findall(r"url\(\s*['\"]?([^)'\"]+)", value):
                        self.require(target.startswith("#"),
                                     f"{self.label(path)}: external URL reference {target[:80]}")
                if name == "style" and node.text:
                    self.require("@import" not in node.text,
                                 f"{self.label(path)}: CSS imports are not allowed")
                    for target in re.findall(r"url\(\s*['\"]?([^)'\"]+)", node.text):
                        self.require(target.startswith("#"),
                                     f"{self.label(path)}: external stylesheet URL {target[:80]}")
            self.record("SVG", path)
        except (OSError, ValueError, ET.ParseError) as exc:
            self.errors.append(f"{self.label(path)}: invalid SVG: {exc}")

    def same(self, first: Path, second: Path) -> None:
        if first.is_file() and second.is_file():
            self.require(first.read_bytes() == second.read_bytes(),
                         f"{self.label(second)}: differs from {self.label(first)}")

    def web(self, path: Path) -> None:
        try:
            data = json.loads((path / "site.webmanifest").read_text(encoding="utf-8-sig"))
            self.require(data.get("name") == "TinyRecorder", "web manifest: incorrect app name")
            found = set()
            for entry in data["icons"]:
                filename = entry["src"]
                self.require(Path(filename).name == filename,
                             "web manifest: icon src must be a local filename")
                if Path(filename).name != filename:
                    continue
                with Image.open(path / filename) as image:
                    self.require(entry["sizes"] == f"{image.width}x{image.height}",
                                 f"web manifest: incorrect size for {filename}")
                    self.require(entry.get("type") == "image/png" and image.format == "PNG",
                                 f"web manifest: incorrect type for {filename}")
                    found.add(image.size)
            self.require({(192, 192), (512, 512)} <= found,
                         "web manifest: missing 192px or 512px icon")
            with Image.open(path / "favicon.ico") as icon:
                self.require(icon.format == "ICO", "favicon.ico: incorrect format")
                self.require(icon.ico.sizes() == {(16, 16), (32, 32), (48, 48)},
                             "favicon.ico: expected 16px / 32px / 48px representations")
                for size in icon.ico.sizes():
                    icon.ico.getimage(size).load()
            self.png(path / "apple-touch-icon.png", 180)
        except (OSError, ValueError, KeyError, TypeError, AttributeError) as exc:
            self.errors.append(f"{self.label(path)}: invalid website export: {exc}")

    def checksums(self, branding: Path) -> None:
        manifest = branding / "SHA256SUMS.txt"
        try:
            listed = set()
            for line in manifest.read_text(encoding="utf-8-sig").splitlines():
                match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
                if not match:
                    self.errors.append("SHA256SUMS.txt: malformed entry")
                    continue
                expected, filename = match.groups()
                path = (branding / filename).resolve()
                if not path.is_relative_to(branding.resolve()):
                    self.errors.append(f"SHA256SUMS.txt: invalid path {filename}")
                    continue
                self.require(filename not in listed, f"SHA256SUMS.txt: duplicate {filename}")
                listed.add(filename)
                if not path.is_file():
                    self.errors.append(f"SHA256SUMS.txt: missing {filename}")
                    continue
                self.require(hashlib.sha256(path.read_bytes()).hexdigest() == expected,
                             f"SHA256SUMS.txt: hash mismatch for {filename}")
            actual = {path.relative_to(branding).as_posix()
                      for path in branding.rglob("*") if path.is_file() and path != manifest}
            self.require(listed == actual, "SHA256SUMS.txt: file list is incomplete or contains stale entries")
        except (OSError, ValueError) as exc:
            self.errors.append(f"SHA256SUMS.txt: {exc}")

    def run(self) -> int:
        branding = self.root / "branding"
        macos = branding / "macos"
        for name in ("TinyRecorder", "TinyRecorder-Dark"):
            self.iconset(macos / f"{name}.iconset")
            self.icns(macos / f"{name}.icns")

        # Exported catalogs are the primary deliverable. This also works when
        # validating the downloadable kit without a cloned application source.
        exports = branding / "xcode"
        for catalog, iconset in (("AppIcon", "TinyRecorder"),
                                 ("AppIconDark", "TinyRecorder-Dark")):
            self.catalog(exports / f"{catalog}.appiconset")
            for filename in ICON_SLOTS:
                self.same(macos / f"{iconset}.iconset" / filename,
                          exports / f"{catalog}.appiconset" / filename)
        self.catalog(exports / "TinyRecorderMenuBar.imageset", template=True)
        for filename, (pixels, _) in TEMPLATE_SLOTS.items():
            self.png(branding / "menubar" / filename, pixels,
                     transparent_border=True, template=True)
            self.same(branding / "menubar" / filename,
                      exports / "TinyRecorderMenuBar.imageset" / filename)
        self.png(branding / "menubar" / "tinyrecorder-menubar@3x.png", 54,
                 transparent_border=True, template=True)

        # The source repository additionally contains the copies used by Xcode.
        assets = self.root / "QuickRecorder" / "Assets.xcassets"
        if (self.root / "QuickRecorder").is_dir():
            self.catalog(assets / "AppIcon.appiconset")
            self.catalog(assets / "TinyRecorderMenuBar.imageset", template=True)
            for filename in ICON_SLOTS:
                self.same(exports / "AppIcon.appiconset" / filename,
                          assets / "AppIcon.appiconset" / filename)
            for filename in TEMPLATE_SLOTS:
                self.same(exports / "TinyRecorderMenuBar.imageset" / filename,
                          assets / "TinyRecorderMenuBar.imageset" / filename)
            self.same(branding / "marketing" / "github-header.png",
                      self.root / "img" / "tinyrecorder-header.png")

        self.iconset(branding / "documents" / "TinyRecorder-QMA.iconset")
        self.icns(branding / "documents" / "TinyRecorder-QMA.icns")
        for directory in (branding / "logo", branding / "icon-composer" / "layers"):
            self.require(any(directory.rglob("*.svg")), f"{self.label(directory)}: no SVG artwork found")
        for path in sorted(branding.rglob("*.svg")):
            self.svg(path)
        for path in sorted(branding.rglob("*.png")):
            self.png(path)
        self.web(branding / "web")
        self.checksums(branding)
        if self.errors:
            print(f"FAIL: {len(self.errors)} issue(s)", file=sys.stderr)
            for error in self.errors:
                print(f"  - {error}", file=sys.stderr)
            return 1
        print("PASS: " + ", ".join(f"{count} {kind}" for kind, count in self.counts.items()))
        print("Verified dimensions, alpha margins, black templates, ICNS chunks, SVG references, catalog copies, website exports, and SHA-256 hashes.")
        print("macOS Xcode / actool / Icon Composer validation still requires a Mac.")
        return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", type=Path,
                        default=Path(__file__).resolve().parents[1],
                        help="TinyRecorder repository or extracted brand kit directory")
    args = parser.parse_args()
    return Inspector(args.root.resolve()).run()


if __name__ == "__main__":
    raise SystemExit(main())
