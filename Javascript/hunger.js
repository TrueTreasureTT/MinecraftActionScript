const DEFAULT_MAX_HUNGER = 20; // same 20-point scale as Health, for a consistent HUD

/**
 * Hunger: depletes over time, restored by eat(). Doesn't know about
 * specific food items -- that's a content concern (tied to the Farming
 * bullet from the earlier mechanics list, deliberately not built yet),
 * this just tracks the pool and exposes eat(amount)/deplete(amount) as
 * a generic API something else can drive.
 */
export class Hunger {
  constructor(max = DEFAULT_MAX_HUNGER) {
    this.max = max;
    this.current = max;
    this.listeners = new Set();
  }

  get isStarving() {
    return this.current <= 0;
  }

  /** Health should only passively regenerate at/above this threshold -- a "well-fed" convention, not a claim about any specific game's exact number. */
  get isWellFed() {
    return this.current >= this.max * 0.9;
  }

  deplete(amount) {
    if (amount <= 0) return;
    this.current = Math.max(0, this.current - amount);
    this._notify("deplete");
  }

  eat(restoreAmount) {
    if (restoreAmount <= 0) return;
    this.current = Math.min(this.max, this.current + restoreAmount);
    this._notify("eat");
  }

  /** Returns an unsubscribe function. Listener receives { type, current, max }. */
  onChange(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  _notify(type) {
    for (const l of this.listeners) l({ type, current: this.current, max: this.max });
  }
}
