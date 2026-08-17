import { Health } from "./health.js";
import { Hunger } from "./hunger.js";
import { GameMode, rulesFor } from "./gamemode.js";

/**
 * Bundles Health + Hunger + the active GameMode's ruleset into the one
 * object a game loop actually needs to hold and tick each frame. Health
 * and Hunger stay independently usable and independently tested; this
 * is just the wiring between them (starvation damage, well-fed regen)
 * plus the single entry point a caller needs.
 */
export class PlayerStats {
  constructor(gameMode = GameMode.SURVIVAL) {
    this.gameMode = gameMode;
    this.health = new Health();
    this.hunger = new Hunger();
    this._starveAccumulator = 0;
    this._regenAccumulator = 0;
  }

  setGameMode(mode) {
    this.gameMode = mode;
  }

  get rules() {
    return rulesFor(this.gameMode);
  }

  /**
   * Advances hunger depletion, starvation damage, and well-fed
   * regeneration by dtSeconds. No-ops entirely in Creative (rules there
   * have hungerEnabled=false), so it's safe to call this every frame
   * regardless of mode -- callers don't need their own if(survival) guard.
   */
  tick(dtSeconds) {
    if (!this.rules.hungerEnabled) return;

    // Constant-rate depletion rather than modeling per-action exhaustion
    // (sprinting/jumping/mining each costing hunger) -- a scope choice,
    // matching this pass's other "simple first, refine later" calls
    // (e.g. shapeless crafting instead of shaped).
    const HUNGER_DEPLETE_PER_SECOND = 20 / (20 * 60); // full bar drains over ~20 in-game minutes
    this.hunger.deplete(HUNGER_DEPLETE_PER_SECOND * dtSeconds);

    if (!this.rules.takesDamage) return;

    const STARVE_DAMAGE_INTERVAL = 4;
    if (this.hunger.isStarving) {
      this._starveAccumulator += dtSeconds;
      if (this._starveAccumulator >= STARVE_DAMAGE_INTERVAL) {
        this._starveAccumulator -= STARVE_DAMAGE_INTERVAL;
        this.health.damage(1);
      }
    } else {
      this._starveAccumulator = 0;
    }

    const REGEN_INTERVAL = 4;
    if (this.hunger.isWellFed && !this.health.isDead) {
      this._regenAccumulator += dtSeconds;
      if (this._regenAccumulator >= REGEN_INTERVAL) {
        this._regenAccumulator -= REGEN_INTERVAL;
        this.health.heal(1);
      }
    } else {
      this._regenAccumulator = 0;
    }
  }

  respawn() {
    this.health.respawn();
    this.hunger.eat(this.hunger.max);
    this._starveAccumulator = 0;
    this._regenAccumulator = 0;
  }
}
