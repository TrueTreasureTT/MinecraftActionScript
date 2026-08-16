import { BLOCK } from "./blocks.js";
import { ITEM } from "./items.js";

/**
 * Furnace/smelting: input + fuel -> output over a cook time. Distinct
 * from Crafting because it's time-gated (ticks, not instant) and
 * consumes fuel as a separate resource rather than as another recipe
 * ingredient.
 *
 * Simplification: fuel is checked against a small whitelist (wood log,
 * wood planks, coal ore) rather than modeling a full "mining drops a
 * different item than the block" system -- e.g. real Minecraft's coal
 * ore drops a Coal item, not the ore block itself. That drop-table
 * layer isn't built here, so ore/log blocks are used directly as fuel.
 * Output stack-size capping (e.g. stopping at 64) also isn't enforced
 * here -- noted as a known gap, not silently hidden.
 */

export const SMELTING_RECIPES = Object.freeze([
  { id: "iron_ingot", input: BLOCK.IRON_ORE, output: { item: ITEM.IRON_INGOT, count: 1 }, cookTicks: 200 },
  { id: "gold_ingot", input: BLOCK.GOLD_ORE, output: { item: ITEM.GOLD_INGOT, count: 1 }, cookTicks: 200 },
  { id: "glass", input: BLOCK.SAND, output: { item: BLOCK.GLASS, count: 1 }, cookTicks: 200 },
]);

export const FUEL_BURN_TICKS = new Map([
  [BLOCK.WOOD_LOG, 300],
  [BLOCK.PLANK, 150],
  [BLOCK.COAL_ORE, 1600],
]);

export class Furnace {
  constructor() {
    this.inputSlot = null; // { item, count }
    this.fuelSlot = null; // { item, count }
    this.outputSlot = null; // { item, count }
    this.cookProgress = 0;
    this.burnTimeRemaining = 0;
  }

  setInput(item, count) {
    this.inputSlot = count > 0 ? { item, count } : null;
  }

  setFuel(item, count) {
    this.fuelSlot = count > 0 ? { item, count } : null;
  }

  get isLit() {
    return this.burnTimeRemaining > 0;
  }

  _activeRecipe() {
    if (!this.inputSlot) return null;
    return SMELTING_RECIPES.find((r) => r.input === this.inputSlot.item) || null;
  }

  _canAcceptOutput(recipe) {
    if (!this.outputSlot) return true;
    return this.outputSlot.item === recipe.output.item;
  }

  /** Advances the furnace by one tick. Call this from a game loop. */
  tick() {
    const recipe = this._activeRecipe();

    if (this.burnTimeRemaining <= 0 && recipe && this.fuelSlot && FUEL_BURN_TICKS.has(this.fuelSlot.item)) {
      if (this._canAcceptOutput(recipe)) {
        this.burnTimeRemaining = FUEL_BURN_TICKS.get(this.fuelSlot.item);
        this.fuelSlot.count -= 1;
        if (this.fuelSlot.count <= 0) this.fuelSlot = null;
      }
    }

    if (this.burnTimeRemaining > 0) {
      this.burnTimeRemaining -= 1;

      if (recipe && this._canAcceptOutput(recipe)) {
        this.cookProgress += 1;
        if (this.cookProgress >= recipe.cookTicks) {
          this._completeSmelt(recipe);
          this.cookProgress = 0;
        }
      } else {
        this.cookProgress = 0; // input changed/removed mid-cook; don't carry over stale progress
      }
    }
  }

  _completeSmelt(recipe) {
    this.inputSlot.count -= 1;
    if (this.inputSlot.count <= 0) this.inputSlot = null;

    if (this.outputSlot) {
      this.outputSlot.count += recipe.output.count;
    } else {
      this.outputSlot = { item: recipe.output.item, count: recipe.output.count };
    }
  }

  /** Removes and returns the current output stack, clearing the slot (simulates the player collecting it). */
  collectOutput() {
    const out = this.outputSlot;
    this.outputSlot = null;
    return out;
  }
}
