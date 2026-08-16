import { BLOCK } from "./blocks.js";
import { ITEM } from "./items.js";

/**
 * Shapeless crafting: ingredient counts -> output, no 3x3 grid-position
 * matching. Deliberate scope choice -- shaped recipes (exact layout,
 * rotation/reflection rules) add real complexity for a first pass;
 * shapeless still delivers the actual mechanic ("combine resources into
 * tools") with a much smaller bug surface. Shaped recipes are a natural
 * follow-up if specific layouts should matter later.
 */
export const RECIPES = Object.freeze([
  { id: "planks_from_log", inputs: [{ item: BLOCK.WOOD_LOG, count: 1 }], output: { item: BLOCK.PLANK, count: 4 } },
  { id: "sticks_from_planks", inputs: [{ item: BLOCK.PLANK, count: 2 }], output: { item: ITEM.STICK, count: 4 } },
  { id: "wooden_pickaxe", inputs: [{ item: BLOCK.PLANK, count: 3 }, { item: ITEM.STICK, count: 2 }], output: { item: ITEM.WOODEN_PICKAXE, count: 1 } },
  { id: "wooden_axe", inputs: [{ item: BLOCK.PLANK, count: 3 }, { item: ITEM.STICK, count: 2 }], output: { item: ITEM.WOODEN_AXE, count: 1 } },
  { id: "stone_pickaxe", inputs: [{ item: BLOCK.COBBLESTONE, count: 3 }, { item: ITEM.STICK, count: 2 }], output: { item: ITEM.STONE_PICKAXE, count: 1 } },
  { id: "stone_axe", inputs: [{ item: BLOCK.COBBLESTONE, count: 3 }, { item: ITEM.STICK, count: 2 }], output: { item: ITEM.STONE_AXE, count: 1 } },
  { id: "iron_pickaxe", inputs: [{ item: ITEM.IRON_INGOT, count: 3 }, { item: ITEM.STICK, count: 2 }], output: { item: ITEM.IRON_PICKAXE, count: 1 } },
  { id: "iron_axe", inputs: [{ item: ITEM.IRON_INGOT, count: 3 }, { item: ITEM.STICK, count: 2 }], output: { item: ITEM.IRON_AXE, count: 1 } },
]);

/**
 * Attempts to craft `recipe` from `inventory`. Returns true and mutates
 * the inventory if it succeeded; returns false and leaves the inventory
 * completely untouched otherwise. Simulates the whole operation on a
 * cloned inventory first (consume inputs, add output) and only commits
 * the clone's slot state back if the simulation fully succeeds -- this
 * makes "not enough ingredients" AND "output doesn't fit" both fail
 * atomically, with no special-case refund logic needed for either.
 */
export function craft(inventory, recipe) {
  for (const ing of recipe.inputs) {
    if (!inventory.hasItem(ing.item, ing.count)) return false;
  }

  const trial = inventory.clone();
  for (const ing of recipe.inputs) {
    trial.removeItem(ing.item, ing.count);
  }
  const leftover = trial.addItem(recipe.output.item, recipe.output.count);
  if (leftover > 0) return false; // no room for the result; real inventory untouched

  inventory.slots = trial.slots;
  return true;
}

export function craftableRecipes(inventory) {
  return RECIPES.filter((r) => r.inputs.every((ing) => inventory.hasItem(ing.item, ing.count)));
}
