const { PNG } = require('pngjs');
const fs = require('fs');

const width = 256;
const height = 256;
const png = new PNG({ width, height });

// Fill background with dark obsidian rounded rectangle & draw sharp cyan/violet lightning bolt
for (let y = 0; y < height; y++) {
  for (let x = 0; x < width; x++) {
    const idx = (width * y + x) << 2;

    // Corner radius check (radius = 48)
    const cx = Math.min(Math.max(x, 48), width - 48);
    const cy = Math.min(Math.max(y, 48), height - 48);
    const dist = Math.hypot(x - cx, y - cy);

    if (dist > 48) {
      // Transparent outside rounded rectangle
      png.data[idx] = 0;
      png.data[idx + 1] = 0;
      png.data[idx + 2] = 0;
      png.data[idx + 3] = 0;
      continue;
    }

    // Lightning bolt shape polygon check
    // Bolt points (scaled to 256x256): (140, 24), (50, 140), (130, 140), (105, 232), (206, 116), (130, 116)
    const px = x;
    const py = y;
    
    // Check if inside bolt using standard point-in-polygon
    const boltPoints = [
      [140, 24], [50, 140], [130, 140], [105, 232], [206, 116], [130, 116]
    ];
    
    let insideBolt = false;
    for (let i = 0, j = boltPoints.length - 1; i < boltPoints.length; j = i++) {
      const xi = boltPoints[i][0], yi = boltPoints[i][1];
      const xj = boltPoints[j][0], yj = boltPoints[j][1];
      const intersect = ((yi > py) !== (yj > py)) && (px < (xj - xi) * (py - yi) / (yj - yi) + xi);
      if (intersect) insideBolt = !insideBolt;
    }

    if (insideBolt) {
      // Glowing Cyan to Violet Gradient for Lightning Bolt
      const t = y / height;
      png.data[idx] = Math.round(56 + t * (139 - 56));     // R
      png.data[idx + 1] = Math.round(189 - t * (189 - 92)); // G
      png.data[idx + 2] = Math.round(248 - t * (248 - 246)); // B
      png.data[idx + 3] = 255;                              // A
    } else {
      // Dark Obsidian Background with subtle border glow
      const isBorder = (dist > 44 || x < 6 || x > width - 6 || y < 6 || y > height - 6);
      if (isBorder) {
        png.data[idx] = 56;
        png.data[idx + 1] = 189;
        png.data[idx + 2] = 248;
        png.data[idx + 3] = 180;
      } else {
        png.data[idx] = 12;
        png.data[idx + 1] = 14;
        png.data[idx + 2] = 22;
        png.data[idx + 3] = 245;
      }
    }
  }
}

png.pack().pipe(fs.createWriteStream(__dirname + '/icon.png')).on('finish', () => {
  console.log('icon.png created successfully!');
});
