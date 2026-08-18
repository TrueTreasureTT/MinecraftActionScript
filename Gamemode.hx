package voxel;

class GameModeRules
{
	public var infiniteBlocks:Bool;
	public var takesDamage:Bool;
	public var hungerEnabled:Bool;
	public var instantBreak:Bool;
	public var requiresTool:Bool;

	public function new(infiniteBlocks:Bool, takesDamage:Bool, hungerEnabled:Bool, instantBreak:Bool, requiresTool:Bool)
	{
		this.infiniteBlocks = infiniteBlocks;
		this.takesDamage = takesDamage;
		this.hungerEnabled = hungerEnabled;
		this.instantBreak = instantBreak;
		this.requiresTool = requiresTool;
	}
}

/** Survival vs Creative: mirrors js-pe/gamemode.js. Any system that behaves differently per mode reads its ruleset from here instead of hardcoding mode checks. */
class GameMode
{
	public static inline var SURVIVAL:String = "survival";
	public static inline var CREATIVE:String = "creative";

	public static function rulesFor(mode:String):GameModeRules
	{
		return switch (mode)
		{
			case CREATIVE: new GameModeRules(true, false, false, true, false);
			default: new GameModeRules(false, true, true, false, true); // SURVIVAL, and the fallback for any unrecognized value
		}
	}

	public static function isValid(mode:String):Bool
	{
		return mode == SURVIVAL || mode == CREATIVE;
	}
}
