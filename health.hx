package voxel;

/** Fired on every Health change: type is "damage", "heal", "death", or "respawn". */
class HealthEvent
{
	public var type:String;
	public var current:Int;
	public var max:Int;
	public function new(type:String, current:Int, max:Int) { this.type = type; this.current = current; this.max = max; }
}

/**
 * Health: mirrors js-pe/health.js. heal() intentionally no-ops while
 * dead -- death is a real state transition that needs an explicit
 * respawn(), not something a stray heal-over-time tick reverses.
 */
class Health
{
	public static inline var DEFAULT_MAX:Int = 20; // familiar 20-point scale; a numeric convention, not copyrighted content

	public var max:Int;
	public var current:Int;
	var listeners:Array<HealthEvent->Void>;

	public function new(max:Int = DEFAULT_MAX)
	{
		this.max = max;
		this.current = max;
		listeners = [];
	}

	public var isDead(get, never):Bool;
	function get_isDead():Bool return current <= 0;

	public function damage(amount:Int):Void
	{
		if (amount <= 0) return;
		var wasAlive = !isDead;
		current = current - amount < 0 ? 0 : current - amount;
		notify("damage");
		if (wasAlive && isDead) notify("death"); // fires exactly once, at the transition
	}

	public function heal(amount:Int):Void
	{
		if (amount <= 0 || isDead) return;
		current = current + amount > max ? max : current + amount;
		notify("heal");
	}

	public function respawn():Void
	{
		current = max;
		notify("respawn");
	}

	/** Returns an unsubscribe function. */
	public function onChange(listener:HealthEvent->Void):Void->Void
	{
		listeners.push(listener);
		return function() listeners.remove(listener);
	}

	function notify(type:String):Void
	{
		var evt = new HealthEvent(type, current, max);
		for (l in listeners) l(evt);
	}
}
