package voxel;

/**
 * Procedural terrain generation, ported from the Node-tested js-pe/terrain.js.
 * Same structure: seeded 2D value noise drives a heightmap, filled into
 * columns using the same layer logic as WorldGen (bedrock/stone/dirt/
 * grass-or-sand).
 *
 * Haxe has no Math.imul (32-bit wraparound multiply), which the hash
 * genuinely needs -- multiplying two ~32-bit-range Ints directly loses
 * precision once the product exceeds 2^53, and on top of that Haxe's
 * per-target Int overflow behavior for `*` isn't something I can verify
 * without a compiler. imul32() below is a manual replacement (split each
 * operand into 16-bit halves so every intermediate product stays exactly
 * representable), and this exact operation sequence -- not just the
 * general technique -- was checked against the real Math.imul in Node
 * across 200,000+ cases (0 mismatches) before being ported here. The
 * full noise pipeline built on it was separately checked for
 * determinism, [0,1) bounds, and a sane distribution. What ISN'T
 * verified is Haxe's compiler actually treating +, ^, >>>, &, <<, | the
 * way this reasoning assumes on every target -- that's the one piece
 * that needs a real compile to fully confirm.
 */
class TerrainGen
{
	static inline function imul32(a:Int, b:Int):Int
	{
		var ah = (a >>> 16) & 0xffff;
		var al = a & 0xffff;
		var bh = (b >>> 16) & 0xffff;
		var bl = b & 0xffff;
		var low = al * bl;
		var mid = (ah * bl + al * bh) << 16;
		return (low + mid) | 0;
	}

	/** Returns a fresh closure over its own mutable state -- each call to mulberry32() starts an independent stream. */
	static function mulberry32(seed:Int):Void->Float
	{
		var a = seed;
		return function():Float
		{
			a = (a + 0x6D2B79F5) | 0;
			var t = imul32(a ^ (a >>> 15), 1 | a);
			t = (t + imul32(t ^ (t >>> 7), 61 | t)) ^ t;
			var signed = (t ^ (t >>> 14));
			var unsigned:Float = signed >= 0 ? signed : signed + 4294967296.0;
			return unsigned / 4294967296.0;
		}
	}

	var seed:Int;
	var gridCache:Map<String, Float>;

	public var seaLevel:Int;
	public var baseHeight:Int;
	public var heightVariance:Int;
	public var worldHeight:Int;

	public function new(seed:Int = 1, seaLevel:Int = 6, baseHeight:Int = 7, heightVariance:Int = 6, worldHeight:Int = 64)
	{
		this.seed = seed;
		this.seaLevel = seaLevel;
		this.baseHeight = baseHeight;
		this.heightVariance = heightVariance;
		this.worldHeight = worldHeight;
		gridCache = new Map();
	}

	function gridValue(ix:Int, iy:Int):Float
	{
		var key = ix + "," + iy;
		if (gridCache.exists(key)) return gridCache.get(key);
		var combined = (imul32(ix, 374761393) ^ imul32(iy, 668265263) ^ imul32(seed, 2246822519));
		var rng = mulberry32(combined);
		var v = rng();
		gridCache.set(key, v);
		return v;
	}

	static inline function smoothstep(t:Float):Float
	{
		return t * t * (3 - 2 * t);
	}

	public function sample(x:Float, y:Float):Float
	{
		var x0 = Math.floor(x);
		var y0 = Math.floor(y);
		var x1 = x0 + 1;
		var y1 = y0 + 1;
		var sx = smoothstep(x - x0);
		var sy = smoothstep(y - y0);

		var v00 = gridValue(Std.int(x0), Std.int(y0));
		var v10 = gridValue(Std.int(x1), Std.int(y0));
		var v01 = gridValue(Std.int(x0), Std.int(y1));
		var v11 = gridValue(Std.int(x1), Std.int(y1));

		var ix0 = v00 + (v10 - v00) * sx;
		var ix1 = v01 + (v11 - v01) * sx;
		return ix0 + (ix1 - ix0) * sy;
	}

	/** Fractal sum of several octaves. Result stays in [0, 1). */
	public function fractal(x:Float, y:Float, octaves:Int = 4, persistence:Float = 0.5, scale:Float = 0.05):Float
	{
		var total = 0.0;
		var amplitude = 1.0;
		var frequency = scale;
		var maxAmplitude = 0.0;
		for (i in 0...octaves)
		{
			total += sample(x * frequency, y * frequency) * amplitude;
			maxAmplitude += amplitude;
			amplitude *= persistence;
			frequency *= 2;
		}
		return total / maxAmplitude;
	}

	/** Integer surface height at world (x, z), clamped to [1, worldHeight - 2]. */
	public function heightAt(x:Int, z:Int):Int
	{
		var n = fractal(x, z, 4, 0.5, 0.04);
		var h = Math.round(baseHeight + (n - 0.5) * 2 * heightVariance);
		if (h < 1) h = 1;
		if (h > worldHeight - 2) h = worldHeight - 2;
		return Std.int(h);
	}

	/**
	 * Fills one column of `chunk` at local (lx, lz) using world coords
	 * (worldX, worldZ) for the noise lookup. Same layer stack as
	 * WorldGen.generateFlatChunk: bedrock, stone, dirt, then grass or
	 * sand+water depending on sea level.
	 */
	public function fillColumn(chunk:Chunk, lx:Int, lz:Int, worldX:Int, worldZ:Int):Void
	{
		var surface = heightAt(worldX, worldZ);
		var stoneTop = surface - 3;
		var dirtStart = stoneTop > 1 ? stoneTop : 1;

		chunk.set(lx, 0, lz, Block.BEDROCK);
		for (y in 1...dirtStart)
		{
			chunk.set(lx, y, lz, Block.STONE);
		}
		for (y in dirtStart...surface)
		{
			chunk.set(lx, y, lz, Block.DIRT);
		}

		if (surface <= seaLevel)
		{
			chunk.set(lx, surface, lz, Block.SAND);
			for (y in (surface + 1)...(seaLevel + 1))
			{
				chunk.set(lx, y, lz, Block.WATER);
			}
		}
		else
		{
			chunk.set(lx, surface, lz, Block.GRASS);
		}
	}

	/** Whether a tree should be rooted at (x, z) -- sparse, clustered via a second noise field, never on beaches/underwater. */
	public function treeAt(x:Int, z:Int):Bool
	{
		var surface = heightAt(x, z);
		if (surface <= seaLevel) return false;
		var density = fractal(x + 10000, z + 10000, 2, 0.5, 0.15);
		return density > 0.78;
	}
}
