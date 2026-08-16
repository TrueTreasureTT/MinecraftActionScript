package voxel;

/**
 * Non-block items: materials and tools that live in an inventory slot
 * but aren't placeable in the world. IDs start at 100 to leave headroom
 * in the block ID space (Block.hx uses 0-21) without ever colliding --
 * Inventory/Crafting/Furnace treat block IDs and item IDs as the same
 * numeric namespace. Mirrors js-pe/items.js exactly (same IDs, names,
 * stack sizes, durability) so the two stacks agree on what a given
 * number means.
 */
class Item
{
	public static inline var STICK:Int = 100;
	public static inline var IRON_INGOT:Int = 101;
	public static inline var GOLD_INGOT:Int = 102;
	public static inline var WOODEN_PICKAXE:Int = 110;
	public static inline var STONE_PICKAXE:Int = 111;
	public static inline var IRON_PICKAXE:Int = 112;
	public static inline var WOODEN_AXE:Int = 113;
	public static inline var STONE_AXE:Int = 114;
	public static inline var IRON_AXE:Int = 115;

	static var NAMES:Map<Int, String>;
	static var STACK_SIZE:Map<Int, Int>;
	static var initialized:Bool = false;

	public static function init():Void
	{
		if (initialized) return;
		initialized = true;

		NAMES = new Map();
		STACK_SIZE = new Map();

		NAMES.set(STICK, "Stick"); STACK_SIZE.set(STICK, 64);
		NAMES.set(IRON_INGOT, "Iron Ingot"); STACK_SIZE.set(IRON_INGOT, 64);
		NAMES.set(GOLD_INGOT, "Gold Ingot"); STACK_SIZE.set(GOLD_INGOT, 64);
		NAMES.set(WOODEN_PICKAXE, "Wooden Pickaxe"); STACK_SIZE.set(WOODEN_PICKAXE, 1);
		NAMES.set(STONE_PICKAXE, "Stone Pickaxe"); STACK_SIZE.set(STONE_PICKAXE, 1);
		NAMES.set(IRON_PICKAXE, "Iron Pickaxe"); STACK_SIZE.set(IRON_PICKAXE, 1);
		NAMES.set(WOODEN_AXE, "Wooden Axe"); STACK_SIZE.set(WOODEN_AXE, 1);
		NAMES.set(STONE_AXE, "Stone Axe"); STACK_SIZE.set(STONE_AXE, 1);
		NAMES.set(IRON_AXE, "Iron Axe"); STACK_SIZE.set(IRON_AXE, 1);
	}

	public static function nameOf(id:Int):String
	{
		return NAMES.exists(id) ? NAMES.get(id) : "Unknown Item";
	}

	/** Default stack size is 64, matching how blocks (not listed here) stack. */
	public static function stackSizeOf(id:Int):Int
	{
		return STACK_SIZE.exists(id) ? STACK_SIZE.get(id) : 64;
	}
}
