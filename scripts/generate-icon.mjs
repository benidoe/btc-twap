import sharp from 'sharp';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const svg = await readFile(path.join(root, 'scripts', 'icon.svg'));
const out = path.join(
  root,
  'ios',
  'App',
  'App',
  'Assets.xcassets',
  'AppIcon.appiconset',
  'AppIcon-512@2x.png'
);

await sharp(svg, { density: 144 })
  .resize(1024, 1024, { fit: 'fill' })
  .png()
  .toFile(out);
console.log('wrote', out);
