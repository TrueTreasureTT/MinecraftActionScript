package voxel;

/**
 * Generates a small flat creative world: a fixed grid of chunks (default 4x4),
 * each filled with the classic flatland layer stack:
 *   y=0            bedrock
 *   y=1..3         stone
 *   y=4..6         dirt
 *   y=7            grass
 * A handful of trees are scattered on top for visual interest and to
 * exercise non-flat geometry in the mesher.
 */
class WorldGen
{
	public static inline var SURFACE_Y:Int = 7;
	public static inline var CHUNKS_X:Int = 4;
	public static inline var CHUNKS_Z:Int = 4;

	public static function generateFlatChunk(cx:Int, cz:Int):Chunk
	{
		var c = new Chunk(cx, cz);

		for (x in 0...Chunk.W)
		{
			for (z in 0...Chunk.D)
			{
				c.set(x, 0, z, Block.BEDROCK);
				for (y in 1...4) c.set(x, y, z, Block.STONE);
				for (y in 4...7) c.set(x, y, z, Block.DIRT);
				c.set(x, SURFACE_Y, z, Block.GRASS);
			}
		}

		return c;
	}

	/**
	 * Places a simple tree (log trunk + leaf ball) into the given chunk at
	 * local (lx, lz), rooted at the surface. Only called for chunks/positions
	 * chosen deterministically so trees are stable across save/load without
	 * needing to persist them separately (they're just baked into the block
	 * array like anything else once generated).
	 */
	public static function plantTree(c:Chunk, lx:Int, lz:Int):Void
	{
		var trunkH = 4;
		var baseY = SURFACE_Y + 1;

		for (i in 0...trunkH)
		{
			c.set(lx, baseY + i, lz, Block.WOOD_LOG);
		}

		var leafY = baseY + trunkH - 1;
		for (dx in -2...3)
		{
			for (dz in -2...3)
			{
				for (dy in 0...3)
				{
					if (dx == 0 && dz == 0 && dy < 2) continue; // don't overwrite trunk top area oddly
					var dist = Math.abs(dx) + Math.abs(dz) + dy;
					if (dist <= 4)
					{
						var lxx = lx + dx;
						var lzz = lz + dz;
						if (lxx >= 0 && lxx < Chunk.W && lzz >= 0 && lzz < Chunk.D)
						{
							if (c.get(lxx, leafY + dy, lzz) == Block.AIR)
							{
								c.set(lxx, leafY + dy, lzz, Block.LEAVES);
							}
						}
					}
				}
			}
		}
	}

	/** Deterministic tree placement so regenerating (without a save) is stable. */
	public static function defaultTreeSpots(cx:Int, cz:Int):Array<Array<Int>>
	{
		// One tree roughly in the middle-ish of a subset of chunks, offset by
		// chunk coords so trees don't line up in a boring grid.
		var seedPick = ((cx * 7 + cz * 13) % 5);
		if (seedPick != 0) return [];
		var lx = 4 + ((cx * 3) % 8);
		var lz = 4 + ((cz * 5) % 8);
		return [[lx, lz]];
	}
}
