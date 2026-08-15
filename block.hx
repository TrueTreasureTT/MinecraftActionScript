package voxel;

/**
 * Static block registry. Each block has:
 *  - id: byte value stored in the chunk array (0 = air)
 *  - name: display name
 *  - solid: whether it blocks movement / occludes neighbor faces
 *  - atlas coords per face (in 16px tile units, on a 256x256 = 16x16 tile atlas)
 *
 * Face order for atlas lookup is always: top, bottom, north, south, east, west
 * (north = -Z, south = +Z, east = +X, west = -X)
 */
class Block
{
	public static inline var AIR:Int = 0;
	public static inline var GRASS:Int = 1;
	public static inline var DIRT:Int = 2;
	public static inline var STONE:Int = 3;
	public static inline var WOOD_LOG:Int = 4;
	public static inline var LEAVES:Int = 5;
	public static inline var SAND:Int = 6;
	public static inline var WATER:Int = 7;
	public static inline var PLANK:Int = 8;
	public static inline var BEDROCK:Int = 9;
	public static inline var COBBLESTONE:Int = 10;

	// Total distinct block ids, used to size lookup tables
	public static inline var COUNT:Int = 11;

	// Atlas is 16x16 tiles. Each entry is [tx, ty] tile index (0-based, top-left origin).
	static var TOP:Array<Array<Int>>;
	static var BOTTOM:Array<Array<Int>>;
	static var NORTH:Array<Array<Int>>;
	static var SOUTH:Array<Array<Int>>;
	static var EAST:Array<Array<Int>>;
	static var WEST:Array<Array<Int>>;
	static var SOLID:Array<Bool>;
	static var TRANSPARENT:Array<Bool>; // leaves/water: still occludes some faces but rendered differently
	static var NAMES:Array<String>;

	static var initialized:Bool = false;

	public static function init():Void
	{
		if (initialized) return;
		initialized = true;

		TOP = [for (i in 0...COUNT) [0, 0]];
		BOTTOM = [for (i in 0...COUNT) [0, 0]];
		NORTH = [for (i in 0...COUNT) [0, 0]];
		SOUTH = [for (i in 0...COUNT) [0, 0]];
		EAST = [for (i in 0...COUNT) [0, 0]];
		WEST = [for (i in 0...COUNT) [0, 0]];
		SOLID = [for (i in 0...COUNT) true];
		TRANSPARENT = [for (i in 0...COUNT) false];
		NAMES = [for (i in 0...COUNT) "unknown"];

		// AIR
		SOLID[AIR] = false;
		NAMES[AIR] = "Air";

		// GRASS: green top, dirt bottom, dirt+green-fringe sides
		setUniform(GRASS, [3, 0]); // fallback for all faces
		TOP[GRASS] = [3, 0];
		BOTTOM[GRASS] = [2, 0];
		NORTH[GRASS] = SOUTH[GRASS] = EAST[GRASS] = WEST[GRASS] = [1, 0];
		NAMES[GRASS] = "Grass";

		setUniform(DIRT, [2, 0]);
		NAMES[DIRT] = "Dirt";

		setUniform(STONE, [4, 0]);
		NAMES[STONE] = "Stone";

		setUniform(COBBLESTONE, [5, 0]);
		NAMES[COBBLESTONE] = "Cobblestone";

		TOP[WOOD_LOG] = BOTTOM[WOOD_LOG] = [6, 1];
		NORTH[WOOD_LOG] = SOUTH[WOOD_LOG] = EAST[WOOD_LOG] = WEST[WOOD_LOG] = [6, 0];
		NAMES[WOOD_LOG] = "Wood Log";

		setUniform(LEAVES, [7, 0]);
		TRANSPARENT[LEAVES] = true;
		NAMES[LEAVES] = "Leaves";

		setUniform(SAND, [8, 0]);
		NAMES[SAND] = "Sand";

		setUniform(WATER, [9, 0]);
		SOLID[WATER] = false;
		TRANSPARENT[WATER] = true;
		NAMES[WATER] = "Water";

		setUniform(PLANK, [10, 0]);
		NAMES[PLANK] = "Wood Planks";

		setUniform(BEDROCK, [11, 0]);
		NAMES[BEDROCK] = "Bedrock";
	}

	static function setUniform(id:Int, tile:Array<Int>):Void
	{
		TOP[id] = tile;
		BOTTOM[id] = tile;
		NORTH[id] = tile;
		SOUTH[id] = tile;
		EAST[id] = tile;
		WEST[id] = tile;
	}

	public static inline function isSolid(id:Int):Bool
	{
		return id >= 0 && id < COUNT && SOLID[id];
	}

	public static inline function isTransparent(id:Int):Bool
	{
		return id >= 0 && id < COUNT && TRANSPARENT[id];
	}

	public static inline function nameOf(id:Int):String
	{
		return (id >= 0 && id < COUNT) ? NAMES[id] : "unknown";
	}

	public static function tileFor(id:Int, face:Int):Array<Int>
	{
		// face: 0=top 1=bottom 2=north 3=south 4=east 5=west
		return switch (face)
		{
			case 0: TOP[id];
			case 1: BOTTOM[id];
			case 2: NORTH[id];
			case 3: SOUTH[id];
			case 4: EAST[id];
			case 5: WEST[id];
			default: TOP[id];
		}
	}
}
