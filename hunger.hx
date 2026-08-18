package voxel;

class HungerEvent
{
	public var type:String;
	public var current:Float;
	public var max:Float;
	public function new(type:String, current:Float, max:Float) { this.type = type; this.current = current; this.max = max; }
}

/** Hunger: mirrors js-pe/hunger.js. Doesn't know about specific food items -- that's a content concern (Farming), left as a generic eat(amount)/deplete(amount) API. */
class Hunger
{
	public static inline var DEFAULT_MAX:Float = 20; // same 20-point scale as Health

	public var max:Float;
	public var current:Float;
	var listeners:Array<HungerEvent->Void>;

	public function new(max:Float = DEFAULT_MAX)
	{
		this.max = max;
		this.current = max;
		listeners = [];
	}

	public var isStarving(get, never):Bool;
	function get_isStarving():Bool return current <= 0;

	/** "Well-fed" convention (>=90% of max), not a claim about any specific game's exact number. */
	public var isWellFed(get, never):Bool;
	function get_isWellFed():Bool return current >= max * 0.9;

	public function deplete(amount:Float):Void
	{
		if (amount <= 0) return;
		current = current - amount < 0 ? 0 : current - amount;
		notify("deplete");
	}

	public function eat(restoreAmount:Float):Void
	{
		if (restoreAmount <= 0) return;
		current = current + restoreAmount > max ? max : current + restoreAmount;
		notify("eat");
	}

	public function onChange(listener:HungerEvent->Void):Void->Void
	{
		listeners.push(listener);
		return function() listeners.remove(listener);
	}

	function notify(type:String):Void
	{
		var evt = new HungerEvent(type, current, max);
		for (l in listeners) l(evt);
	}
}
