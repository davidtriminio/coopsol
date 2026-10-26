import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

type Rgb = { r: number; g: number; b: number }
type Rgba = Rgb & { a: number }
type Palette = Record<string, string>

const TOKEN_NAMES = [
  'glow-top',
  'glow-bottom',
  'base-start',
  'base-end',
  'card-bg',
  'card-border',
  'card-shadow',
  'text',
  'text-muted',
  'field-bg',
  'field-border',
  'btn-bg',
  'btn-fg',
  'error',
]

function readPalette(block: string): Palette {
  const palette: Palette = {}
  for (const match of block.matchAll(/--glass-([a-z-]+):\s*([^;]+);/g)) {
    palette[match[1]] = match[2].trim()
  }
  return palette
}

function blockAfter(source: string, marker: string): string {
  const start = source.indexOf(marker)
  return source.slice(start, source.indexOf('}', start))
}

const stylesheet = readFileSync(resolve(process.cwd(), 'src/styles.css'), 'utf8')

const light = readPalette(blockAfter(stylesheet, ':root {'))
const dark = readPalette(blockAfter(stylesheet, '@media (prefers-color-scheme: dark)'))

function parseColor(value: string): Rgba {
  const hex = /^#([0-9a-f]{6})$/i.exec(value)
  if (hex) {
    const n = parseInt(hex[1], 16)
    return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255, a: 1 }
  }
  const rgba = /^rgba\(\s*(\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\s*\)$/.exec(value)
  if (rgba) {
    return { r: +rgba[1], g: +rgba[2], b: +rgba[3], a: +rgba[4] }
  }
  throw new Error(`Unsupported color: ${value}`)
}

function over(top: Rgba, bottom: Rgb): Rgb {
  return {
    r: top.r * top.a + bottom.r * (1 - top.a),
    g: top.g * top.a + bottom.g * (1 - top.a),
    b: top.b * top.a + bottom.b * (1 - top.a),
  }
}

function luminance(color: Rgb): number {
  const channel = (value: number) => {
    const s = value / 255
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4)
  }
  return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b)
}

function contrast(a: Rgb, b: Rgb): number {
  const first = luminance(a)
  const second = luminance(b)
  return (Math.max(first, second) + 0.05) / (Math.min(first, second) + 0.05)
}

function backdrops(palette: Palette): Rgb[] {
  return ['glow-top', 'base-start', 'glow-bottom'].map((name) => parseColor(palette[name]))
}

function cardOver(palette: Palette, backdrop: Rgb): Rgb {
  return over(parseColor(palette['card-bg']), backdrop)
}

function fieldOver(palette: Palette, backdrop: Rgb): Rgb {
  return over(parseColor(palette['field-bg']), cardOver(palette, backdrop))
}

function minContrast(foreground: string, surfaces: Rgb[], palette: Palette): number {
  const color = parseColor(palette[foreground])
  return Math.min(...surfaces.map((surface) => contrast(over(color, surface), surface)))
}

describe('glass tokens', () => {
  it('defines the same tokens in the light and dark palettes', () => {
    expect(Object.keys(light).sort()).toEqual([...TOKEN_NAMES].sort())
    expect(Object.keys(dark).sort()).toEqual([...TOKEN_NAMES].sort())
  })

  it('uses the dark error color agreed in the design system', () => {
    expect(dark['error']).toBe('#ffc8c8')
  })

  describe('light palette', () => {
    const cards = backdrops(light).map((backdrop) => cardOver(light, backdrop))
    const fields = backdrops(light).map((backdrop) => fieldOver(light, backdrop))

    it('body text is at least 7:1 on the card over every part of the gradient', () => {
      expect(minContrast('text', cards, light)).toBeGreaterThanOrEqual(7)
    })

    it('secondary text is at least 4.5:1 on the card and on the fields', () => {
      expect(minContrast('text-muted', cards, light)).toBeGreaterThanOrEqual(4.5)
      expect(minContrast('text-muted', fields, light)).toBeGreaterThanOrEqual(4.5)
    })

    it('the button label is at least 7:1 on the button', () => {
      const button = parseColor(light['btn-bg'])
      expect(contrast(parseColor(light['btn-fg']), button)).toBeGreaterThanOrEqual(7)
    })

    it('the error color is at least 4.5:1 on the card', () => {
      expect(minContrast('error', cards, light)).toBeGreaterThanOrEqual(4.5)
    })
  })

  describe('dark palette', () => {
    const cards = backdrops(dark).map((backdrop) => cardOver(dark, backdrop))
    const fields = backdrops(dark).map((backdrop) => fieldOver(dark, backdrop))

    it('body text is at least 4.5:1 on the card over every part of the gradient', () => {
      expect(minContrast('text', cards, dark)).toBeGreaterThanOrEqual(4.5)
    })

    it('secondary text is at least 4.5:1 on the card', () => {
      expect(minContrast('text-muted', cards, dark)).toBeGreaterThanOrEqual(4.5)
    })

    it('field labels stay at least 4:1 over the brightest glow', () => {
      expect(minContrast('text-muted', fields, dark)).toBeGreaterThanOrEqual(4)
    })

    it('the button label is at least 7:1 on the button', () => {
      const button = parseColor(dark['btn-bg'])
      expect(contrast(parseColor(dark['btn-fg']), button)).toBeGreaterThanOrEqual(7)
    })

    it('the error color is at least 4.5:1 on the card', () => {
      expect(minContrast('error', cards, dark)).toBeGreaterThanOrEqual(4.5)
    })
  })
})
