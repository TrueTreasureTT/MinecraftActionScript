package voxel;

class SmeltingRecipe
{
	public var id:String;
	public var input:Int;
	public var outputItem:Int;
	public var outputCount:Int;
	public var cookTicks:Int;
	public function new(id:String, input:Int, outputItem:Int, outputCount:Int, cookTicks:Int)
	{
		this.id = id;
		this.input = input;
		this.outputItem = outputItem;
		this.outputCount = outputCount;
		this.cookTicks = cookTicks;
	}
}

/**
 * Furnace/smelting: input + fuel -> output over time (ticks), distinct
 * from instant Crafting. Same logic and same simplifications as
 * js-pe/furnace.js: fuel is a small whitelist of blocks rather than a
 * full mining-drop-table system, and output stack-size capping isn't
 * enforced -- a known, noted gap rather than a silent one.
 */
class Furnace
{
	public static var RECIPES:Array<SmeltingRecipe>;
	static var FUEL_BURN_TICKS:Map<Int, Int>;
	static var initialized:Bool = false;

	public var inputSlot:Slot;
	public var fuelSlot:Slot;
	public var outputSlot:Slot;
	public var cookProgress:Int = 0;
	public var burnTimeRemaining:Int = 0;

	public static function initStatics():Void
	{
		if (initialized) return;
		initialized = true;

		RECIPES = [
			new SmeltingRecipe("iron_ingot", Block.IRON_ORE, Item.IRON_INGOT, 1, 200),
			new SmeltingRecipe("gold_ingot", Block.GOLD_ORE, Item.GOLD_INGOT, 1, 200),
			new SmeltingRecipe("glass", Block.SAND, Block.GLASS, 1, 200),
		];

		FUEL_BURN_TICKS = new Map();
		FUEL_BURN_TICKS.set(Block.WOOD_LOG, 300);
		FUEL_BURN_TICKS.set(Block.PLANK, 150);
		FUEL_BURN_TICKS.set(Block.COAL_ORE, 1600);
	}

	public function new()
	{
		Furnace.initStatics();
	}

	public function setInput(item:Int, count:Int):Void
	{
		inputSlot = count > 0 ? new Slot(item, count) : null;
	}

	public function setFuel(item:Int, count:Int):Void
	{
		fuelSlot = count > 0 ? new Slot(item, count) : null;
	}

	public var isLit(get, never):Bool;
	function get_isLit():Bool return burnTimeRemaining > 0;

	function activeRecipe():SmeltingRecipe
	{
		if (inputSlot == null) return null;
		for (r in RECIPES)
		{
			if (r.input == inputSlot.item) return r;
		}
		return null;
	}

	function canAcceptOutput(recipe:SmeltingRecipe):Bool
	{
		if (outputSlot == null) return true;
		return outputSlot.item == recipe.outputItem;
	}

	/** Advances the furnace by one tick. Call this from a game loop. */
	public function tick():Void
	{
		var recipe = activeRecipe();

		if (burnTimeRemaining <= 0 && recipe != null && fuelSlot != null && FUEL_BURN_TICKS.exists(fuelSlot.item))
		{
			if (canAcceptOutput(recipe))
			{
				burnTimeRemaining = FUEL_BURN_TICKS.get(fuelSlot.item);
				fuelSlot.count -= 1;
				if (fuelSlot.count <= 0) fuelSlot = null;
			}
		}

		if (burnTimeRemaining > 0)
		{
			burnTimeRemaining -= 1;

			if (recipe != null && canAcceptOutput(recipe))
			{
				cookProgress += 1;
				if (cookProgress >= recipe.cookTicks)
				{
					completeSmelt(recipe);
					cookProgress = 0;
				}
			}
			else
			{
				cookProgress = 0;
			}
		}
	}

	function completeSmelt(recipe:SmeltingRecipe):Void
	{
		inputSlot.count -= 1;
		if (inputSlot.count <= 0) inputSlot = null;

		if (outputSlot != null)
		{
			outputSlot.count += recipe.outputCount;
		}
		else
		{
			outputSlot = new Slot(recipe.outputItem, recipe.outputCount);
		}
	}

	/** Removes and returns the current output slot, clearing it (simulates the player collecting it). */
	public function collectOutput():Slot
	{
		var out = outputSlot;
		outputSlot = null;
		return out;
	}
}
