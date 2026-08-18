package voxel;

/**
 * Tool tiers and break rules, mirroring js-pe/mining.js. A higher tier
 * can harvest everything a lower tier can, plus more. 0 = bare hands.
 */
class MiningRules
{
	static var TOOL_TIER:Map<Int, Int>;
	static var REQUIRED_TIER:Map<Int, Int>;
	static var HARDNESS:Map<Int, Float>;
	static var TOOL_SPEED_MULTIPLIER:Map<Int, Float>;
	static var initialized:Bool = false;

	public static function init():Void
	{
		if (initialized) return;
		initialized = true;
		Item.init();

		TOOL_TIER = new Map();
		TOOL_TIER.set(Item.WOODEN_PICKAXE, 1);
		TOOL_TIER.set(Item.STONE_PICKAXE, 2);
		TOOL_TIER.set(Item.IRON_PICKAXE, 3);
		TOOL_TIER.set(Item.WOODEN_AXE, 1);
		TOOL_TIER.set(Item.STONE_AXE, 2);
		TOOL_TIER.set(Item.IRON_AXE, 3);

		REQUIRED_TIER = new Map();
		REQUIRED_TIER.set(Block.STONE, 1);
		REQUIRED_TIER.set(Block.COBBLESTONE, 1);
		REQUIRED_TIER.set(Block.COAL_ORE, 1);
		REQUIRED_TIER.set(Block.IRON_ORE, 2);
		REQUIRED_TIER.set(Block.GOLD_ORE, 2);
		REQUIRED_TIER.set(Block.DIAMOND_ORE, 3);
		REQUIRED_TIER.set(Block.OBSIDIAN, 3);

		// Original round numbers for this project, not sourced from any specific game's data files.
		HARDNESS = new Map();
		HARDNESS.set(Block.GRASS, 0.6); HARDNESS.set(Block.DIRT, 0.5); HARDNESS.set(Block.SAND, 0.5); HARDNESS.set(Block.GRAVEL, 0.6);
		HARDNESS.set(Block.LEAVES, 0.2); HARDNESS.set(Block.SNOW, 0.2); HARDNESS.set(Block.GLASS, 0.3); HARDNESS.set(Block.ICE, 0.5);
		HARDNESS.set(Block.WOOD_LOG, 2.0); HARDNESS.set(Block.PLANK, 2.0); HARDNESS.set(Block.STONE, 1.5); HARDNESS.set(Block.COBBLESTONE, 2.0);
		HARDNESS.set(Block.MOSSY_COBBLESTONE, 2.0); HARDNESS.set(Block.BRICK, 2.0); HARDNESS.set(Block.COAL_ORE, 3.0);
		HARDNESS.set(Block.IRON_ORE, 3.0); HARDNESS.set(Block.GOLD_ORE, 3.0); HARDNESS.set(Block.DIAMOND_ORE, 3.0);
		HARDNESS.set(Block.OBSIDIAN, 9.0);

		TOOL_SPEED_MULTIPLIER = new Map();
		TOOL_SPEED_MULTIPLIER.set(0, 1.0);
		TOOL_SPEED_MULTIPLIER.set(1, 2.0);
		TOOL_SPEED_MULTIPLIER.set(2, 4.0);
		TOOL_SPEED_MULTIPLIER.set(3, 6.0);
	}

	public static function requiredTier(blockId:Int):Int
	{
		init();
		return REQUIRED_TIER.exists(blockId) ? REQUIRED_TIER.get(blockId) : 0;
	}

	public static function toolTier(itemId:Int):Int
	{
		init();
		return TOOL_TIER.exists(itemId) ? TOOL_TIER.get(itemId) : 0;
	}

	/** BEDROCK can never be harvested outside Creative, regardless of tool. */
	public static function canHarvest(blockId:Int, toolItemId:Int, gameMode:String):Bool
	{
		if (gameMode == GameMode.CREATIVE) return true;
		if (blockId == Block.BEDROCK) return false;
		return toolTier(toolItemId) >= requiredTier(blockId);
	}

	/**
	 * Seconds to break the block. Infinity means it cannot be broken at
	 * all with this tool in this mode -- a hard stop is a clearer signal
	 * for a UI ("you need a better pickaxe") than dig-forever-for-nothing.
	 */
	public static function breakTimeSeconds(blockId:Int, toolItemId:Int, gameMode:String):Float
	{
		init();
		if (gameMode == GameMode.CREATIVE) return 0;
		if (blockId == Block.BEDROCK) return Math.POSITIVE_INFINITY;
		if (!canHarvest(blockId, toolItemId, gameMode)) return Math.POSITIVE_INFINITY;
		var hardness = HARDNESS.exists(blockId) ? HARDNESS.get(blockId) : 1.0;
		var mult = TOOL_SPEED_MULTIPLIER.exists(toolTier(toolItemId)) ? TOOL_SPEED_MULTIPLIER.get(toolTier(toolItemId)) : 1.0;
		return hardness / mult;
	}
}
