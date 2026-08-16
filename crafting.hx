package voxel;

class Ingredient
{
	public var item:Int;
	public var count:Int;
	public function new(item:Int, count:Int) { this.item = item; this.count = count; }
}

class Recipe
{
	public var id:String;
	public var inputs:Array<Ingredient>;
	public var outputItem:Int;
	public var outputCount:Int;
	public function new(id:String, inputs:Array<Ingredient>, outputItem:Int, outputCount:Int)
	{
		this.id = id;
		this.inputs = inputs;
		this.outputItem = outputItem;
		this.outputCount = outputCount;
	}
}

/**
 * Shapeless crafting: ingredient counts -> output, no 3x3 grid-position
 * matching -- same scope choice as js-pe/crafting.js, and the same
 * recipe list, kept in sync by hand. craft() uses the identical
 * clone-and-simulate strategy: check ingredient availability, then try
 * the whole operation on a cloned inventory, and only commit if BOTH
 * the ingredients were available AND the output had room to fit. That
 * makes both failure modes atomic without separate refund logic.
 */
class Crafting
{
	public static var RECIPES:Array<Recipe>;
	static var initialized:Bool = false;

	public static function init():Void
	{
		if (initialized) return;
		initialized = true;
		Item.init();

		RECIPES = [
			new Recipe("planks_from_log", [new Ingredient(Block.WOOD_LOG, 1)], Block.PLANK, 4),
			new Recipe("sticks_from_planks", [new Ingredient(Block.PLANK, 2)], Item.STICK, 4),
			new Recipe("wooden_pickaxe", [new Ingredient(Block.PLANK, 3), new Ingredient(Item.STICK, 2)], Item.WOODEN_PICKAXE, 1),
			new Recipe("wooden_axe", [new Ingredient(Block.PLANK, 3), new Ingredient(Item.STICK, 2)], Item.WOODEN_AXE, 1),
			new Recipe("stone_pickaxe", [new Ingredient(Block.COBBLESTONE, 3), new Ingredient(Item.STICK, 2)], Item.STONE_PICKAXE, 1),
			new Recipe("stone_axe", [new Ingredient(Block.COBBLESTONE, 3), new Ingredient(Item.STICK, 2)], Item.STONE_AXE, 1),
			new Recipe("iron_pickaxe", [new Ingredient(Item.IRON_INGOT, 3), new Ingredient(Item.STICK, 2)], Item.IRON_PICKAXE, 1),
			new Recipe("iron_axe", [new Ingredient(Item.IRON_INGOT, 3), new Ingredient(Item.STICK, 2)], Item.IRON_AXE, 1),
		];
	}

	public static function craft(inventory:Inventory, recipe:Recipe):Bool
	{
		for (ing in recipe.inputs)
		{
			if (!inventory.hasItem(ing.item, ing.count)) return false;
		}

		var trial = inventory.clone();
		for (ing in recipe.inputs)
		{
			trial.removeItem(ing.item, ing.count);
		}
		var leftover = trial.addItem(recipe.outputItem, recipe.outputCount);
		if (leftover > 0) return false; // no room for the result; real inventory untouched

		inventory.slots = trial.slots;
		return true;
	}

	public static function craftableRecipes(inventory:Inventory):Array<Recipe>
	{
		init();
		return RECIPES.filter(function(r)
		{
			for (ing in r.inputs)
			{
				if (!inventory.hasItem(ing.item, ing.count)) return false;
			}
			return true;
		});
	}
}
