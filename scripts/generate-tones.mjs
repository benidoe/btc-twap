import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = join(root, 'ios', 'App', 'App', 'Resources');

const SR = 44100;
const BITS = 16;

function sine(freq, t) {
  return Math.sin(2 * Math.PI * freq * t);
}

// Mirrors dashboard playGentleTone: 50ms attack to volume, hold, 100ms release to 0.
function toneBuffer(freq, duration, volume) {
  const n = Math.max(1, Math.round(SR * duration));
  const buf = new Float32Array(n);
  const attack = 0.05;
  const release = 0.1;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    let env = 1;
    if (t < attack) env = t / attack;
    if (t > duration - release) env = Math.max(0, (duration - t) / release);
    buf[i] = sine(freq, t) * volume * env;
  }
  return buf;
}

function silenceBuffer(duration) {
  return new Float32Array(Math.max(1, Math.round(SR * duration)));
}

function mixBuffers(parts) {
  const total = Math.max(1, Math.ceil(parts[parts.length - 1].t + parts[parts.length - 1].buf.length));
  const out = new Float32Array(total);
  for (const { t, buf } of parts) {
    const start = Math.round(t * SR);
    for (let i = 0; i < buf.length && start + i < total; i++) {
      out[start + i] += buf[i];
    }
  }
  return out;
}

function toPcm16(buf) {
  const pcm = new Int16Array(buf.length);
  for (let i = 0; i < buf.length; i++) {
    const v = Math.max(-1, Math.min(1, buf[i]));
    pcm[i] = v < 0 ? v * 0x8000 : v * 0x7fff;
  }
  return Buffer.from(pcm.buffer);
}

function toWav(pcm16, sampleRate) {
  const dataSize = pcm16.length;
  const header = Buffer.alloc(44);
  header.write('RIFF', 0);
  header.writeUInt32LE(36 + dataSize, 4);
  header.write('WAVE', 8);
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(1, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(sampleRate * 2, 28);
  header.writeUInt16LE(2, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36);
  header.writeUInt32LE(dataSize, 40);
  return Buffer.concat([header, pcm16]);
}

function writeWav(name, buf) {
  const file = join(outDir, `${name}.wav`);
  writeFileSync(file, toWav(toPcm16(buf), SR));
  console.log(`wrote ${file}`);
}

mkdirSync(outDir, { recursive: true });

// WARN: one soft chime E5 (660Hz), 0.4s, peak 0.2
writeWav('warn', toneBuffer(660, 0.4, 0.2));

// EXIT: gentle two-note fall D5 (587.33Hz, 0.28s, peak 0.16) -> A4 (440Hz, 0.3s, peak 0.14, offset 0.28)
writeWav('exit', mixBuffers([
  { t: 0, buf: toneBuffer(587.33, 0.28, 0.16) },
  { t: 0.28, buf: toneBuffer(440, 0.3, 0.14) },
]));

// SILENCE: looped to keep the background audio session alive
writeWav('silence', silenceBuffer(0.3));

console.log('done');
