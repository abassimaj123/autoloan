// UK Icon + Splash generator — pure pngjs (no native deps)
// Design: Red #C62828 bg, white car, blue #0D47A1 £ badge, subtle Union Jack cross
'use strict';
const { PNG } = require('pngjs');
const fs      = require('fs');
const path    = require('path');

const ROOT = path.join(__dirname, '..');

const SIZES = [
  { dir: 'mipmap-mdpi',    px: 48  },
  { dir: 'mipmap-hdpi',    px: 72  },
  { dir: 'mipmap-xhdpi',   px: 96  },
  { dir: 'mipmap-xxhdpi',  px: 144 },
  { dir: 'mipmap-xxxhdpi', px: 192 },
];

// ── Pixel canvas helpers ────────────────────────────────────────────────────
class Canvas {
  constructor(w, h) {
    this.w = w; this.h = h;
    this.d = new Uint8Array(w * h * 4); // RGBA
  }

  _idx(x, y) { return (Math.round(y) * this.w + Math.round(x)) * 4; }

  setPixel(x, y, r, g, b, a = 255) {
    x = Math.round(x); y = Math.round(y);
    if (x < 0 || x >= this.w || y < 0 || y >= this.h) return;
    const i = (y * this.w + x) * 4;
    // Alpha blend over existing
    const sa = a / 255, da = this.d[i + 3] / 255;
    const oa = sa + da * (1 - sa);
    if (oa < 0.001) return;
    this.d[i]     = Math.round((r * sa + this.d[i]     * da * (1 - sa)) / oa);
    this.d[i + 1] = Math.round((g * sa + this.d[i + 1] * da * (1 - sa)) / oa);
    this.d[i + 2] = Math.round((b * sa + this.d[i + 2] * da * (1 - sa)) / oa);
    this.d[i + 3] = Math.round(oa * 255);
  }

  fillRect(x1, y1, x2, y2, r, g, b, a = 255) {
    for (let y = Math.max(0, y1 | 0); y <= Math.min(this.h - 1, y2 | 0); y++)
      for (let x = Math.max(0, x1 | 0); x <= Math.min(this.w - 1, x2 | 0); x++)
        this.setPixel(x, y, r, g, b, a);
  }

  fillCircle(cx, cy, rad, r, g, b, a = 255) {
    const r2 = rad * rad;
    for (let y = cy - rad; y <= cy + rad; y++)
      for (let x = cx - rad; x <= cx + rad; x++)
        if ((x - cx) ** 2 + (y - cy) ** 2 <= r2)
          this.setPixel(x, y, r, g, b, a);
  }

  /** Rounded rectangle — filled */
  fillRoundRect(x1, y1, x2, y2, rad, r, g, b, a = 255) {
    const r2 = rad * rad;
    for (let y = y1 | 0; y <= (y2 | 0); y++) {
      for (let x = x1 | 0; x <= (x2 | 0); x++) {
        let inside = true;
        if (x < x1 + rad && y < y1 + rad)
          inside = (x - x1 - rad) ** 2 + (y - y1 - rad) ** 2 <= r2;
        else if (x > x2 - rad && y < y1 + rad)
          inside = (x - x2 + rad) ** 2 + (y - y1 - rad) ** 2 <= r2;
        else if (x < x1 + rad && y > y2 - rad)
          inside = (x - x1 - rad) ** 2 + (y - y2 + rad) ** 2 <= r2;
        else if (x > x2 - rad && y > y2 - rad)
          inside = (x - x2 + rad) ** 2 + (y - y2 + rad) ** 2 <= r2;
        if (inside) this.setPixel(x, y, r, g, b, a);
      }
    }
  }

  /** Thick line (rectangle approximation) */
  fillLine(x1, y1, x2, y2, thick, r, g, b, a = 255) {
    const dx = x2 - x1, dy = y2 - y1;
    const len = Math.sqrt(dx * dx + dy * dy) || 1;
    const nx = -dy / len, ny = dx / len;
    const h = thick / 2;
    // Rasterise as axis-aligned band — approximate but sufficient
    for (let y = 0; y < this.h; y++) {
      for (let x = 0; x < this.w; x++) {
        // Project onto line
        const t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);
        if (t < 0 || t > 1) continue;
        const dist = Math.abs((x - x1) * ny - (y - y1) * nx);
        if (dist <= h) this.setPixel(x, y, r, g, b, a);
      }
    }
  }

  toPNG() {
    const png = new PNG({ width: this.w, height: this.h });
    png.data = Buffer.from(this.d);
    return PNG.sync.write(png);
  }
}

// ── Hex colour parser ───────────────────────────────────────────────────────
function hex(h) {
  const v = parseInt(h.replace('#', ''), 16);
  return { r: (v >> 16) & 0xff, g: (v >> 8) & 0xff, b: v & 0xff };
}

// ── Draw a simplified flat car ──────────────────────────────────────────────
function drawCar(c, cx, cy, size, col) {
  const s   = size * 0.52;
  const x   = cx - s / 2;
  const y   = cy - s * 0.28;
  const { r, g, b } = hex(col);

  // Body
  c.fillRoundRect(x, y + s * 0.30, x + s, y + s * 0.62, s * 0.07, r, g, b);

  // Cabin — trapezoid via rows
  for (let row = 0; row <= (s * 0.24) | 0; row++) {
    const t    = row / (s * 0.24);
    const rowY = y + s * 0.06 + row;
    const lx   = x + s * (0.30 + 0.10 * (1 - t));  // interpolate x positions
    const rx   = x + s * (0.70 - 0.10 * (1 - t));
    if (lx <= rx) c.fillRect(lx | 0, rowY | 0, rx | 0, rowY | 0, r, g, b);
  }

  // Windows — dark overlay
  const winA = 55;
  // Front windshield
  for (let row = 0; row <= (s * 0.19) | 0; row++) {
    const t = row / (s * 0.19);
    const wy = (y + s * 0.10 + row) | 0;
    const lx = (x + s * (0.32 - 0.08 * t)) | 0;
    const rx = (x + s * 0.51) | 0;
    if (lx < rx) c.fillRect(lx, wy, rx, wy, 0, 0, 0, winA);
  }
  // Rear window
  for (let row = 0; row <= (s * 0.19) | 0; row++) {
    const t = row / (s * 0.19);
    const wy = (y + s * 0.10 + row) | 0;
    const lx = (x + s * 0.53) | 0;
    const rx = (x + s * (0.68 + 0.08 * t)) | 0;
    if (lx < rx) c.fillRect(lx, wy, rx, wy, 0, 0, 0, winA);
  }

  // Wheels
  const wr = (s * 0.13) | 0;
  [[x + s * 0.22, y + s * 0.62], [x + s * 0.78, y + s * 0.62]].forEach(([wx, wy]) => {
    c.fillCircle(wx, wy, wr,     0,   0,   0, 90);
    c.fillCircle(wx, wy, (wr * 0.54) | 0, r, g, b);
  });
}

// ── Draw pixel-art "£" glyph (16×16 reference, scaled) ─────────────────────
// 1 = filled, 0 = empty — 7-column × 9-row bitmap
const POUND_BITMAP = [
  [0,0,1,1,1,0,0],
  [0,1,0,0,0,1,0],
  [0,1,0,0,0,0,0],
  [0,1,0,0,0,0,0],
  [1,1,1,1,0,0,0],
  [0,1,0,0,0,0,0],
  [0,1,0,0,0,0,0],
  [1,0,0,0,0,0,1],
  [1,1,1,1,1,1,1],
];

function drawPound(c, cx, cy, charH, r, g, b) {
  const cols = POUND_BITMAP[0].length;
  const rows = POUND_BITMAP.length;
  const cw   = charH / rows;
  const tw   = cw * cols;
  const ox   = cx - tw / 2;
  const oy   = cy - charH / 2;
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      if (POUND_BITMAP[row][col]) {
        const px1 = (ox + col * cw) | 0;
        const py1 = (oy + row * cw) | 0;
        const px2 = (ox + (col + 1) * cw - 1) | 0;
        const py2 = (oy + (row + 1) * cw - 1) | 0;
        c.fillRect(px1, py1, px2, py2, r, g, b);
      }
    }
  }
}

// ── UK icon ─────────────────────────────────────────────────────────────────
function makeUKIcon(size) {
  const c   = new Canvas(size, size);
  const s   = size;
  const rad = (s * 0.22) | 0;
  const bg  = hex('#C62828');
  const blA = hex('#0D47A1');

  // Red rounded-rect background
  c.fillRoundRect(0, 0, s - 1, s - 1, rad, bg.r, bg.g, bg.b);

  // Subtle Union Jack cross (very faint white, alpha ~10%)
  const crossW = (s * 0.22) | 0;
  c.fillRect((s / 2 - crossW / 2) | 0, 0, (s / 2 + crossW / 2) | 0, s - 1, 255, 255, 255, 25);
  c.fillRect(0, (s / 2 - crossW / 2) | 0, s - 1, (s / 2 + crossW / 2) | 0, 255, 255, 255, 25);

  // White car (center-upper)
  drawCar(c, s * 0.50, s * 0.40, s, '#FFFFFF');

  // Blue circle badge (bottom-right)
  const bx  = (s * 0.775) | 0;
  const by  = (s * 0.775) | 0;
  const br  = (s * 0.155) | 0;
  // Drop shadow
  c.fillCircle(bx + 1, by + 2, br, 0, 0, 0, 40);
  c.fillCircle(bx,     by,     br, blA.r, blA.g, blA.b);
  // £ glyph (white)
  drawPound(c, bx, by, (br * 1.2) | 0, 255, 255, 255);

  return c;
}

// ── UK splash logo (transparent bg, white car + £ badge) ───────────────────
function makeUKSplash() {
  const s  = 512;
  const c  = new Canvas(s, s);
  // Transparent background — only draw the elements

  // White car
  drawCar(c, s * 0.50, s * 0.38, s * 0.85, '#FFFFFF');

  // Blue £ badge
  const bx = (s * 0.62) | 0, by = (s * 0.62) | 0, br = 60;
  c.fillCircle(bx + 2, by + 3, br, 0, 0, 0, 40);
  c.fillCircle(bx, by, br, ...Object.values(hex('#0D47A1')));
  drawPound(c, bx, by, (br * 1.2) | 0, 255, 255, 255);

  // App name text (pixel-art letters 'AutoLoanUK' — draw as white bar)
  // Use a wide bold bar as placeholder for text at this scale
  const textY = (s * 0.68) | 0;
  c.fillRect(s * 0.10, textY, s * 0.90, textY + (s * 0.065) | 0, 255, 255, 255, 220);

  // Subtitle bar (thinner, lighter)
  const subY = textY + (s * 0.10) | 0;
  c.fillRect(s * 0.20, subY, s * 0.80, subY + (s * 0.038) | 0, 255, 255, 255, 120);

  return c;
}

// ── Generate files ──────────────────────────────────────────────────────────
const resBASE = path.join(ROOT, 'android', 'app', 'src', 'uk', 'res');

console.log('\n── UK ──');

function makeRound(squareCanvas) {
  const s = squareCanvas.w;
  const c = new Canvas(s, s);
  const cx = s / 2, cy = s / 2, r2 = (s / 2) * (s / 2);
  for (let y = 0; y < s; y++) {
    for (let x = 0; x < s; x++) {
      if ((x - cx) ** 2 + (y - cy) ** 2 <= r2) {
        const si = (y * s + x) * 4;
        c.d[si]   = squareCanvas.d[si];
        c.d[si+1] = squareCanvas.d[si+1];
        c.d[si+2] = squareCanvas.d[si+2];
        c.d[si+3] = squareCanvas.d[si+3];
      }
    }
  }
  return c;
}

SIZES.forEach(({ dir, px }) => {
  const outDir = path.join(resBASE, dir);
  fs.mkdirSync(outDir, { recursive: true });
  const sq = makeUKIcon(px);
  fs.writeFileSync(path.join(outDir, 'ic_launcher.png'),       sq.toPNG());
  fs.writeFileSync(path.join(outDir, 'ic_launcher_round.png'), makeRound(sq).toPNG());
  console.log(`  ✓ ${dir}  ${px}×${px}px`);
});

// Store icon 512×512
const storeDir = path.join(ROOT, 'store_assets');
fs.mkdirSync(storeDir, { recursive: true });
const store512 = makeUKIcon(512);
fs.writeFileSync(path.join(storeDir, 'icon_uk_512x512.png'), store512.toPNG());
console.log(`  ✓ store_assets/icon_uk_512x512.png`);

// Splash logo
const splashDir = path.join(ROOT, 'assets', 'images', 'uk');
fs.mkdirSync(splashDir, { recursive: true });
const splash = makeUKSplash();
fs.writeFileSync(path.join(splashDir, 'splash_logo.png'), splash.toPNG());
console.log(`  ✓ assets/images/uk/splash_logo.png`);

console.log('\n✅ UK icons generated!');
