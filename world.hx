package voxel;

/**
 * Owns all loaded chunks and provides world-space block queries that
 * transparently cross chunk boundaries. This matters for meshing: a block
 * at the edge of chunk (0,0) needs to know about its neighbor in chunk (1,0)
 * to decide whether to render a face there, otherwise you get phantom faces
 * (or missing faces) at every chunk seam.
 */
class World
{
	public var chunks:Map<String, Chunk>;

	public function new()
	{
		chunks = new Map();
	}

	static inline function key(cx:Int, cz:Int):String
	{
		return cx + "_" + cz;
	}

	public function getChunk(cx:Int, cz:Int):Chunk
	{
		return chunks.get(key(cx, cz));
	}

	public function setChunk(c:Chunk):Void
	{
		chunks.set(key(c.cx, c.cz), c);
	}

	public inline function allChunks():Array<Chunk>
	{
		var out = [];
		for (c in chunks) out.push(c);
		return out;
	}

	/**
	 * Get a block by WORLD block coordinates (not chunk-local). Resolves
	 * which chunk owns (wx, wz), then looks up local coords within it.
	 * Returns AIR for anywhere outside loaded chunks or Y bounds, which is
	 * the correct behavior for face culling (an unloaded neighbor should
	 * not hide a face -- better to draw an extra face than leave a hole).
	 */
	public function getBlockWorld(wx:Int, wy:Int, wz:Int):Int
	{
		if (wy < 0 || wy >= Chunk.H) return Block.AIR;

		var cx = Math.floor(wx / Chunk.W);
		var cz = Math.floor(wz / Chunk.D);
		var c = getChunk(Std.int(cx), Std.int(cz));
		if (c == null) return Block.AIR;

		var lx = wx - Std.int(cx) * Chunk.W;
		var lz = wz - Std.int(cz) * Chunk.D;
		return c.get(lx, wy, lz);
	}

	public function setBlockWorld(wx:Int, wy:Int, wz:Int, id:Int):Void
	{
		if (wy < 0 || wy >= Chunk.H) return;

		var cx = Std.int(Math.floor(wx / Chunk.W));
		var cz = Std.int(Math.floor(wz / Chunk.D));
		var c = getChunk(cx, cz);
		if (c == null) return;

		var lx = wx - cx * Chunk.W;
		var lz = wz - cz * Chunk.D;
		c.set(lx, wy, lz, id);

		// If the edit happened on a chunk border, the NEIGHBOR chunk's mesh
		// also needs to be rebuilt, since its border faces depend on this
		// block. Without this, breaking a block at x=0 of chunk (1,0) would
		// leave a stale face rendered on chunk (0,0)'s side of the seam.
		if (lx == 0)
		{
			var n = getChunk(cx - 1, cz);
			if (n != null) n.dirty = true;
		}
		else if (lx == Chunk.W - 1)
		{
			var n = getChunk(cx + 1, cz);
			if (n != null) n.dirty = true;
		}
		if (lz == 0)
		{
			var n = getChunk(cx, cz - 1);
			if (n != null) n.dirty = true;
		}
		else if (lz == Chunk.D - 1)
		{
			var n = getChunk(cx, cz + 1);
			if (n != null) n.dirty = true;
		}
	}
}
