const { createCanvas } = require('canvas');
const fs = require('fs');
const path = require('path');

const MIPMAP_SIZES = [
  { dir: 'mipmap-mdpi',    px: 48  },
  { dir: 'mipmap-hdpi',    px: 72  },
  { dir: 'mipmap-xhdpi',   px: 96  },
  { dir: 'mipmap-xxhdpi',  px: 144 },
  { dir: 'mipmap-xxxhdpi', px: 192 },
];

// ── Shared: draw a simple flat car ────────────────────────────────────────────
function drawCar(ctx, cx, cy, size, bodyColor = '#FFFFFF') {
  const s = size * 0.52;
  const x = cx - s / 2;
  const y = cy - s * 0.28;

  ctx.fillStyle = bodyColor;

  // Car body
  ctx.beginPath();
  ctx.roundRect(x, y + s * 0.30, s, s * 0.32, s * 0.07);
  ctx.fill();

  // Cabin/roof
  ctx.beginPath();
  ctx.moveTo(x + s * 0.20, y + s * 0.30);
  ctx.lineTo(x + s * 0.30, y + s * 0.06);
  ctx.lineTo(x + s * 0.70, y + s * 0.06);
  ctx.lineTo(x + s * 0.80, y + s * 0.30);
  ctx.closePath();
  ctx.fill();

  // Windows (semi-transparent dark)
  ctx.fillStyle = 'rgba(0,0,0,0.22)';
  // Front windshield
  ctx.beginPath();
  ctx.moveTo(x + s * 0.24, y + s * 0.29);
  ctx.lineTo(x + s * 0.32, y + s * 0.10);
  ctx.lineTo(x + s * 0.51, y + s * 0.10);
  ctx.lineTo(x + s * 0.51, y + s * 0.29);
  ctx.closePath();
  ctx.fill();
  // Rear window
  ctx.beginPath();
  ctx.moveTo(x + s * 0.53, y + s * 0.10);
  ctx.lineTo(x + s * 0.68, y + s * 0.10);
  ctx.lineTo(x + s * 0.76, y + s * 0.29);
  ctx.lineTo(x + s * 0.53, y + s * 0.29);
  ctx.closePath();
  ctx.fill();

  // Wheels
  const wheelColor = ctx.fillStyle; // will reset
  [[x + s * 0.22, y + s * 0.62], [x + s * 0.78, y + s * 0.62]].forEach(([wx, wy]) => {
    ctx.fillStyle = 'rgba(0,0,0,0.35)';
    ctx.beginPath(); ctx.arc(wx, wy, s * 0.13, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = bodyColor;
    ctx.beginPath(); ctx.arc(wx, wy, s * 0.07, 0, Math.PI * 2); ctx.fill();
  });
}

function roundedRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y); ctx.arcTo(x + w, y,     x + w, y + r,     r);
  ctx.lineTo(x + w, y + h - r); ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
  ctx.lineTo(x + r, y + h); ctx.arcTo(x,     y + h, x,     y + h - r, r);
  ctx.lineTo(x, y + r);     ctx.arcTo(x,     y,     x + r, y,         r);
  ctx.closePath();
}

// ═══════════════════════════════════════════════════════════════════════════════
// ICON CA — Green #166534 + white car + gold $ badge + "$/2W" label
// ═══════════════════════════════════════════════════════════════════════════════
function drawIconCA(size) {
  const c = createCanvas(size, size);
  const ctx = c.getContext('2d');
  const s = size, r = s * 0.22;

  // Background
  ctx.fillStyle = '#166534';
  roundedRect(ctx, 0, 0, s, s, r); ctx.fill();

  // Car (white, center slightly above middle)
  drawCar(ctx, s * 0.50, s * 0.42, s, '#FFFFFF');

  // "$/2W" label bottom-center (compact, readable at small size)
  ctx.fillStyle = '#FFFFFF';
  ctx.font      = `bold ${Math.round(s * 0.155)}px Arial, sans-serif`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('$/2W', s * 0.50, s * 0.820);

  // Gold $ badge top-right
  const bx = s * 0.775, by = s * 0.225, br = s * 0.155;
  ctx.shadowColor = 'rgba(0,0,0,0.30)'; ctx.shadowBlur = s * 0.04;
  ctx.fillStyle = '#FACC15';
  ctx.beginPath(); ctx.arc(bx, by, br, 0, Math.PI * 2); ctx.fill();
  ctx.shadowBlur = 0;
  ctx.fillStyle = '#166534';
  ctx.font = `bold ${Math.round(s * 0.16)}px Arial, sans-serif`;
  ctx.fillText('$', bx, by + s * 0.010);

  return c;
}

// ═══════════════════════════════════════════════════════════════════════════════
// ICON AU — Amber/gold #F59E0B background + white car + green badge showing contrast
// Small "$320" top + big "$12K" balloon badge bottom-right
// ═══════════════════════════════════════════════════════════════════════════════
function drawIconAU(size) {
  const c = createCanvas(size, size);
  const ctx = c.getContext('2d');
  const s = size, r = s * 0.22;

  // Background gradient amber→dark amber
  const grad = ctx.createLinearGradient(0, 0, s, s);
  grad.addColorStop(0, '#F59E0B');
  grad.addColorStop(1, '#D97706');
  ctx.fillStyle = grad;
  roundedRect(ctx, 0, 0, s, s, r); ctx.fill();

  // Car (white, upper half)
  drawCar(ctx, s * 0.50, s * 0.37, s * 0.88, '#FFFFFF');

  // Small payment label top-left (the "regular" payment)
  ctx.fillStyle = 'rgba(255,255,255,0.92)';
  ctx.font      = `bold ${Math.round(s * 0.105)}px Arial, sans-serif`;
  ctx.textAlign = 'left';
  ctx.textBaseline = 'middle';
  ctx.fillText('$320/mo', s * 0.07, s * 0.080);

  // Divider line
  ctx.strokeStyle = 'rgba(255,255,255,0.4)';
  ctx.lineWidth = s * 0.012;
  ctx.beginPath();
  ctx.moveTo(s * 0.07, s * 0.735);
  ctx.lineTo(s * 0.93, s * 0.735);
  ctx.stroke();

  // Big balloon badge bottom-right
  const bx = s * 0.76, by = s * 0.84, br = s * 0.175;
  ctx.shadowColor = 'rgba(0,0,0,0.28)'; ctx.shadowBlur = s * 0.035;
  ctx.fillStyle = '#166534';
  ctx.beginPath(); ctx.arc(bx, by, br, 0, Math.PI * 2); ctx.fill();
  ctx.shadowBlur = 0;
  ctx.fillStyle = '#FACC15';
  ctx.font = `bold ${Math.round(s * 0.13)}px Arial, sans-serif`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('$12K', bx, by);

  // "Final" micro label bottom-left
  ctx.fillStyle = 'rgba(255,255,255,0.80)';
  ctx.font = `${Math.round(s * 0.082)}px Arial, sans-serif`;
  ctx.textAlign = 'left';
  ctx.fillText('Final →', s * 0.07, by);

  return c;
}

// ═══════════════════════════════════════════════════════════════════════════════
// ICON US — Navy #1E3A8A background + white car + red "-$5K" savings badge
// ═══════════════════════════════════════════════════════════════════════════════
function drawIconUS(size) {
  const c = createCanvas(size, size);
  const ctx = c.getContext('2d');
  const s = size, r = s * 0.22;

  // Background
  ctx.fillStyle = '#1E3A8A';
  roundedRect(ctx, 0, 0, s, s, r); ctx.fill();

  // Subtle diagonal stripe pattern (US flag feel)
  ctx.strokeStyle = 'rgba(255,255,255,0.05)';
  ctx.lineWidth = s * 0.035;
  for (let i = -s; i < s * 2; i += s * 0.18) {
    ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i + s, s); ctx.stroke();
  }

  // Car (white)
  drawCar(ctx, s * 0.50, s * 0.40, s, '#FFFFFF');

  // Red trade-in savings pill — bottom center
  const pw = s * 0.72, ph = s * 0.23, px = (s - pw) / 2, py = s * 0.700;
  ctx.shadowColor = 'rgba(0,0,0,0.30)'; ctx.shadowBlur = s * 0.04;
  ctx.fillStyle = '#B91C1C';
  roundedRect(ctx, px, py, pw, ph, ph / 2); ctx.fill();
  ctx.shadowBlur = 0;

  ctx.fillStyle = '#FFFFFF';
  ctx.font      = `bold ${Math.round(s * 0.165)}px Arial, sans-serif`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('-$5,000', s / 2, py + ph / 2);

  // "trade-in" micro label above pill
  ctx.fillStyle = 'rgba(255,255,255,0.65)';
  ctx.font      = `${Math.round(s * 0.078)}px Arial, sans-serif`;
  ctx.fillText('TRADE-IN', s / 2, py - s * 0.055);

  return c;
}

// ═══════════════════════════════════════════════════════════════════════════════
// ICON UK — Red #C62828 + white car + blue £ badge + subtle Union Jack
// ═══════════════════════════════════════════════════════════════════════════════
function drawIconUK(size) {
  const c = createCanvas(size, size);
  const ctx = c.getContext('2d');
  const s = size, r = s * 0.22;

  // Background: Union Jack red
  ctx.fillStyle = '#C62828';
  roundedRect(ctx, 0, 0, s, s, r); ctx.fill();

  // Subtle Union Jack cross (very faint white lines)
  ctx.save();
  roundedRect(ctx, 0, 0, s, s, r); ctx.clip();
  ctx.strokeStyle = 'rgba(255,255,255,0.10)';
  ctx.lineWidth = s * 0.22;
  ctx.beginPath(); ctx.moveTo(s * 0.5, 0); ctx.lineTo(s * 0.5, s); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(0, s * 0.5); ctx.lineTo(s, s * 0.5); ctx.stroke();
  ctx.lineWidth = s * 0.09;
  ctx.strokeStyle = 'rgba(255,255,255,0.06)';
  ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(s, s); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(s, 0); ctx.lineTo(0, s); ctx.stroke();
  ctx.restore();

  // Car (white, center-upper)
  drawCar(ctx, s * 0.50, s * 0.40, s, '#FFFFFF');

  // Blue £ badge bottom-right
  const bx = s * 0.775, by = s * 0.775, br = s * 0.155;
  ctx.shadowColor = 'rgba(0,0,0,0.30)'; ctx.shadowBlur = s * 0.04;
  ctx.fillStyle = '#0D47A1';
  ctx.beginPath(); ctx.arc(bx, by, br, 0, Math.PI * 2); ctx.fill();
  ctx.shadowBlur = 0;
  ctx.fillStyle = '#FFFFFF';
  ctx.font = `bold ${Math.round(s * 0.16)}px Arial, sans-serif`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('£', bx, by + s * 0.010);

  return c;
}

// ── Generate all mipmap sizes + Play Store 512x512 ──────────────────────────
const configs = [
  { name: 'ca', draw: drawIconCA, resBASE: path.join(__dirname, '..', 'android', 'app', 'src', 'ca', 'res') },
  { name: 'au', draw: drawIconAU, resBASE: path.join(__dirname, '..', 'android', 'app', 'src', 'au', 'res') },
  { name: 'us', draw: drawIconUS, resBASE: path.join(__dirname, '..', 'android', 'app', 'src', 'us', 'res') },
  { name: 'uk', draw: drawIconUK, resBASE: path.join(__dirname, '..', 'android', 'app', 'src', 'uk', 'res') },
];

function makeRound(sq) {
  const s = sq.width;
  const c = createCanvas(s, s);
  const ctx = c.getContext('2d');
  ctx.beginPath(); ctx.arc(s/2, s/2, s/2, 0, Math.PI*2); ctx.clip();
  ctx.drawImage(sq, 0, 0);
  return c;
}

const storeDir = path.join(__dirname, '..', 'store_assets');
fs.mkdirSync(storeDir, { recursive: true });

configs.forEach(({ name, draw, resBASE }) => {
  console.log(`\n── ${name.toUpperCase()} ──`);

  // Mipmap icons
  MIPMAP_SIZES.forEach(({ dir, px }) => {
    const outDir = path.join(resBASE, dir);
    fs.mkdirSync(outDir, { recursive: true });
    const sq = draw(px);
    fs.writeFileSync(path.join(outDir, 'ic_launcher.png'),       sq.toBuffer('image/png'));
    fs.writeFileSync(path.join(outDir, 'ic_launcher_round.png'), makeRound(sq).toBuffer('image/png'));
    console.log(`  ✓ ${dir}  ${px}×${px}px`);
  });

  // Play Store icon 512×512
  const store = draw(512);
  fs.writeFileSync(path.join(storeDir, `icon_${name}_512x512.png`), store.toBuffer('image/png'));
  console.log(`  ✓ store_assets/icon_${name}_512x512.png`);
});

// ── Splash logos ──────────────────────────────────────────────────────────────
const splashDir = path.join(__dirname, '..', 'assets', 'images');
fs.mkdirSync(splashDir, { recursive: true });

function makeSplash(name, bgColor, draw) {
  const s = 512;
  const c = createCanvas(s, s);
  const ctx = c.getContext('2d');
  ctx.clearRect(0, 0, s, s);

  // Car (centered at 45% height)
  draw(ctx.canvas, 0, 0, s); // re-draw on transparent for splash
  // Actually draw the car elements directly
  drawCar(ctx, s * 0.50, s * 0.38, s * 0.85, '#FFFFFF');

  // App name
  ctx.fillStyle = '#FFFFFF';
  ctx.font = `bold 54px Arial, sans-serif`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';
  ctx.fillText(`AutoLoan${name.toUpperCase()}`, s / 2, s * 0.60);

  // Tagline
  ctx.fillStyle = 'rgba(255,255,255,0.75)';
  ctx.font = `26px Arial, sans-serif`;
  ctx.fillText('Know your real car cost', s / 2, s * 0.74);

  fs.writeFileSync(path.join(splashDir, `${name}`, 'splash_logo.png'), c.toBuffer('image/png'));
  console.log(`  ✓ assets/images/${name}/splash_logo.png`);
}

['ca', 'au', 'us', 'uk'].forEach(n => {
  fs.mkdirSync(path.join(splashDir, n), { recursive: true });
});
makeSplash('ca', '#166534', drawIconCA);
makeSplash('au', '#F59E0B', drawIconAU);
makeSplash('us', '#1E3A8A', drawIconUS);
makeSplash('uk', '#C62828', drawIconUK);

console.log('\n✅ All AutoLoan icons generated (CA + AU + US + UK)!');
