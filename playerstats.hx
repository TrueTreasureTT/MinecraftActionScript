package voxel;

/**
 * Bundles Health + Hunger + the active GameMode's ruleset into the one
 * object a game loop actually needs to hold and tick each frame.
 * Mirrors js-pe/playerStats.js. Health and Hunger stay independently
 * usable; this is just the wiring (starvation damage, well-fed regen)
 * plus a single entry point.
 */
class PlayerStats
{
	public var gameMode:String;
	public var health:Health;
	public var hunger:Hunger;
	var starveAccumulator:Float = 0;
	var regenAccumulator:Float = 0;

	public function new(gameMode:String = GameMode.SURVIVAL)
	{
		this.gameMode = gameMode;
		health = new Health();
		hunger = new Hunger();
	}

	public var rules(get, never):GameModeRules;
	function get_rules():GameModeRules return GameMode.rulesFor(gameMode);

	/**
	 * Advances hunger depletion, starvation damage, and well-fed
	 * regeneration by dtSeconds. No-ops entirely in Creative, so it's
	 * safe to call this every frame regardless of mode.
	 */
	public function tick(dtSeconds:Float):Void
	{
		var r = rules;
		if (!r.hungerEnabled) return;

		var HUNGER_DEPLETE_PER_SECOND = 20.0 / (20 * 60); // full bar drains over ~20 in-game minutes
		hunger.deplete(HUNGER_DEPLETE_PER_SECOND * dtSeconds);

		if (!r.takesDamage) return;

		var STARVE_DAMAGE_INTERVAL = 4.0;
		if (hunger.isStarving)
		{
			starveAccumulator += dtSeconds;
			if (starveAccumulator >= STARVE_DAMAGE_INTERVAL)
			{
				starveAccumulator -= STARVE_DAMAGE_INTERVAL;
				health.damage(1);
			}
		}
		else
		{
			starveAccumulator = 0;
		}

		var REGEN_INTERVAL = 4.0;
		if (hunger.isWellFed && !health.isDead)
		{
			regenAccumulator += dtSeconds;
			if (regenAccumulator >= REGEN_INTERVAL)
			{
				regenAccumulator -= REGEN_INTERVAL;
				health.heal(1);
			}
		}
		else
		{
			regenAccumulator = 0;
		}
	}

	public function respawn():Void
	{
		health.respawn();
		hunger.eat(hunger.max);
		starveAccumulator = 0;
		regenAccumulator = 0;
	}
}
