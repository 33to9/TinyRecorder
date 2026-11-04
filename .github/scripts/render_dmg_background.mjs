// Renders .github/assets/dmg_background.svg to dmg_background.png (1x) and @2x.
// Usage: npm i @resvg/resvg-js@2.6.2 && node render_dmg_background.mjs NotoSansCJKsc-Regular.otf NotoSansCJKsc-Medium.otf NotoSansCJKsc-Bold.otf
// (static Noto Sans CJK SC: https://github.com/notofonts/noto-cjk/tree/main/Sans/OTF/SimplifiedChinese)
import { Resvg } from '@resvg/resvg-js'
import { readFileSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const assets = join(dirname(fileURLToPath(import.meta.url)), '..', 'assets')
const svg = readFileSync(join(assets, 'dmg_background.svg'), 'utf8')
const font = { fontFiles: process.argv.slice(2), loadSystemFonts: false, defaultFontFamily: 'Noto Sans CJK SC' }
for (const [scale, name] of [[1, 'dmg_background.png'], [2, 'dmg_background@2x.png']]) {
  const png = new Resvg(svg, { font, fitTo: { mode: 'zoom', value: scale } }).render().asPng()
  writeFileSync(join(assets, name), png)
  console.log('wrote', name)
}
