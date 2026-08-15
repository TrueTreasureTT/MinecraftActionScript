package voxel;

/**
 * A single chunk: 16 wide (X) x 64 tall (Y) x 16 deep (Z).
 * Storage is a flat Int array indexed as: x + z*W + y*W*D
 * (Y is the outer stride so horizontal slices are contiguous -- helps
 * cache locality when meshing layer by layer.)
 */
class Chunk
{
	public static inline var W:Int = 16; // width  (X)
	public static inline var H:Int = 64; // height (Y)
	public static inline var D:Int = 16; // depth  (Z)

	public var cx:Int; // chunk grid coordinate (chunk units, not block units)
	public var cz:Int;
	public var blocks:Array<Int>;
	public var dirty:Bool = true; // needs remesh

	public function new(cx:Int, cz:Int)
	{
		this.cx = cx;
		this.cz = cz;
		blocks = [for (i in 0...(W * H * D)) Block.AIR];
	}

	public inline function index(x:Int, y:Int, z:Int):Int
	{
		return x + z * W + y * W * D;
	}

	public inline function inBounds(x:Int, y:Int, z:Int):Bool
	{
		return x >= 0 && x < W && y >= 0 && y < H && z >= 0 && z < D;
	}

	public inline function get(x:Int, y:Int, z:Int):Int
	{
		if (!inBounds(x, y, z)) return Block.AIR;
		return blocks[index(x, y, z)];
	}

	public inline function set(x:Int, y:Int, z:Int, id:Int):Void
	{
		if (!inBounds(x, y, z)) return;
		blocks[index(x, y, z)] = id;
		dirty = true;
	}

	/** World-space origin of this chunk, in blocks. */
	public inline function worldX():Int return cx * W;
	public inline function worldZ():Int return cz * D;
}
