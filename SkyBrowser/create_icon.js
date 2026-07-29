const { PNG } = require('pngjs');
const fs = require('fs');

const width = 256;
const height = 256;
const png = new PNG({ width, height });

for (let y = 0; y < height; y++) {
  for (let x = 0; x < width; x++) {
    const idx = (width * y + x) << 2;

    const cx = Math.min(Math.max(x, 48), width - 48);
    const cy = Math.min(Math.max(y, 48), height - 48);
    const dist = Math.hypot(x - cx, y - cy);

    if (dist > 48) {
      png.data[idx] = 0;
      png.data[idx + 1] = 0;
      png.data[idx + 2] = 0;
      png.data[idx + 3] = 0;
      continue;
    }

    // Sky logo circle & wing shape
    const dx = x - 128;
    const dy = y - 128;
    const radius = Math.hypot(dx, dy);

    if (radius < 80) {
      // Sky Blue Gradient
      const t = (y / height);
      png.data[idx] = Math.round(14 + t * 40);       // R
      png.data[idx + 1] = Math.round(165 + t * 40);   // G
      png.data[idx + 2] = Math.round(233 + t * 20);   // B
      png.data[idx + 3] = 255;
    } else {
      // Dark Slate Rounded Card Background
      png.data[idx] = 13;
      png.data[idx + 1] = 15;
      png.data[idx + 2] = 23;
      png.data[idx + 3] = 250;
    }
  }
}

// Make sure output folder exists
png.pack().pipe(fs.createWriteStream(__dirname + '/icon.png')).on('finish', () => {
  console.log('Sky icon.png created!');
});
