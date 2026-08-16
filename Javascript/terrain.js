import { BLOCK } from "./blocks.js";

/**
 * Procedural terrain generation: a deterministic 2D value-noise function
 * drives a heightmap, which fills voxel columns using the same layer
 * logic as the Haxe WorldGen (grass/sand on top depending on sea level,
 * dirt below, stone deeper, bedrock at y=0), plus simple tree scatter.
 * Framework-independent -- returns plain data any renderer can consume.
 */

// ---- Seeded PRNG (mulberry32): deterministic so the same seed always
// produces the same world -- matters for reproducibility (tests, sharing
// a seed). Well-known, widely-used algorithm, not invented here. ----
function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * Deterministic 2D value noise: interpolates known random VALUES at
 * integer grid points (rather than gradients, as true Perlin noise
 * does). Chosen over a full Perlin implementation for this scope
 * because it has a smaller surface for subtle direction/gradient bugs
 * while still producing smooth, natural-looking terrain.
 */
export class ValueNoise2D {
  constructor(seed = 1) {
    this.seed = seed >>> 0;
    this._gridCache = new Map();
  }

  _gridValue(ix, iy) {
    const key = `${ix},${iy}`;
    const cached = this._gridCache.get(key);
    if (cached !== undefined) return cached;
    const rng = mulberry32((ix * 374761393 + iy * 668265263 + this.seed * 2246822519) >>> 0);
    const v = rng();
    this._gridCache.set(key, v);
    return v;
  }

  static _smoothstep(t) {
    return t * t * (3 - 2 * t);
  }

  /** Continuous noise value in [0, 1) at (x, y). */
  sample(x, y) {
    const x0 = Math.floor(x);
    const y0 = Math.floor(y);
    const x1 = x0 + 1;
    const y1 = y0 + 1;
    const sx = ValueNoise2D._smoothstep(x - x0);
    const sy = ValueNoise2D._smoothstep(y - y0);

    const v00 = this._gridValue(x0, y0);
    const v10 = this._gridValue(x1, y0);
    const v01 = this._gridValue(x0, y1);
    const v11 = this._gridValue(x1, y1);

    const ix0 = v00 + (v10 - v00) * sx;
    const ix1 = v01 + (v11 - v01) * sx;
    return ix0 + (ix1 - ix0) * sy;
  }

  /** Fractal sum of several octaves for more natural-looking terrain. Result stays in [0, 1). */
  fractal(x, y, octaves = 4, persistence = 0.5, scale = 0.05) {
    let total = 0;
    let amplitude = 1;
    let frequency = scale;
    let maxAmplitude = 0;
    for (let i = 0; i < octaves; i++) {
      total += this.sample(x * frequency, y * frequency) * amplitude;
      maxAmplitude += amplitude;
      amplitude *= persistence;
      frequency *= 2;
    }
    return total / maxAmplitude;
  }
}

export class TerrainGenerator {
  constructor(seed = 1, { seaLevel = 6, baseHeight = 7, heightVariance = 6, worldHeight = 64 } = {}) {
    this.noise = new ValueNoise2D(seed);
    this.seaLevel = seaLevel;
    this.baseHeight = baseHeight;
    this.heightVariance = heightVariance;
    this.worldHeight = worldHeight;
  }

  /** Integer surface height at world (x, z), clamped to [1, worldHeight - 2]. */
  heightAt(x, z) {
    const n = this.noise.fractal(x, z, 4, 0.5, 0.04); // in [0,1)
    const h = Math.round(this.baseHeight + (n - 0.5) * 2 * this.heightVariance);
    return Math.max(1, Math.min(this.worldHeight - 2, h));
  }

  /** Full vertical column at (x, z) as a Uint8Array of length worldHeight. */
  columnAt(x, z) {
    const column = new Uint8Array(this.worldHeight);
    const surface = this.heightAt(x, z);

    column[0] = BLOCK.BEDROCK;
    for (let y = 1; y < surface - 3 && y < this.worldHeight; y++) {
      column[y] = BLOCK.STONE;
    }
    for (let y = Math.max(1, surface - 3); y < surface; y++) {
      column[y] = BLOCK.DIRT;
    }

    if (surface <= this.seaLevel) {
      column[surface] = BLOCK.SAND;
      for (let y = surface + 1; y <= this.seaLevel; y++) {
        column[y] = BLOCK.WATER;
      }
    } else {
      column[surface] = BLOCK.GRASS;
    }

    return column;
  }

  /** Whether a tree should be rooted at (x, z) -- sparse, clustered via a second noise field, never on beaches/underwater. */
  treeAt(x, z) {
    const surface = this.heightAt(x, z);
    if (surface <= this.seaLevel) return false;
    const density = this.noise.fractal(x + 10000, z + 10000, 2, 0.5, 0.15);
    return density > 0.78;
  }

  /** Heightmap for a rectangular region -- useful for a quick 2D preview. */
  heightmap(x0, z0, width, depth) {
    const map = [];
    for (let z = 0; z < depth; z++) {
      const row = new Array(width);
      for (let x = 0; x < width; x++) {
        row[x] = this.heightAt(x0 + x, z0 + z);
      }
      map.push(row);
    }
    return map;
  }
}
