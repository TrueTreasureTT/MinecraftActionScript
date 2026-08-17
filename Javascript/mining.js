import { BLOCK } from "./blocks.js";
import { ITEM } from "./items.js";
import { GameMode } from "./gamemode.js";

/**
 * Tool tiers: a higher tier can harvest everything a lower tier can,
 * plus more. 0 = bare hands (the default for anything not listed).
 */
export const TOOL_TIER = Object.freeze({
  [ITEM.WOODEN_PICKAXE]: 1,
  [ITEM.STONE_PICKAXE]: 2,
  [ITEM.IRON_PICKAXE]: 3,
  [ITEM.WOODEN_AXE]: 1,
  [ITEM.STONE_AXE]: 2,
  [ITEM.IRON_AXE]: 3,
});

/** Minimum tool tier required to get a drop from this block. Anything not listed is 0 (breakable by hand). */
const REQUIRED_TIER = Object.freeze({
  [BLOCK.STONE]: 1,
  [BLOCK.COBBLESTONE]: 1,
  [BLOCK.COAL_ORE]: 1,
  [BLOCK.IRON_ORE]: 2,
  [BLOCK.GOLD_ORE]: 2,
  [BLOCK.DIAMOND_ORE]: 3,
  [BLOCK.OBSIDIAN]: 3,
});

/** Seconds to break with bare hands (tier 0). Original round numbers for this project, not sourced from any specific game's data files. */
const HARDNESS = Object.freeze({
  [BLOCK.GRASS]: 0.6, [BLOCK.DIRT]: 0.5, [BLOCK.SAND]: 0.5, [BLOCK.GRAVEL]: 0.6,
  [BLOCK.LEAVES]: 0.2, [BLOCK.SNOW]: 0.2, [BLOCK.GLASS]: 0.3, [BLOCK.ICE]: 0.5,
  [BLOCK.WOOD_LOG]: 2.0, [BLOCK.PLANK]: 2.0, [BLOCK.STONE]: 1.5, [BLOCK.COBBLESTONE]: 2.0,
  [BLOCK.MOSSY_COBBLESTONE]: 2.0, [BLOCK.BRICK]: 2.0, [BLOCK.COAL_ORE]: 3.0,
  [BLOCK.IRON_ORE]: 3.0, [BLOCK.GOLD_ORE]: 3.0, [BLOCK.DIAMOND_ORE]: 3.0,
  [BLOCK.OBSIDIAN]: 9.0,
});

const TOOL_SPEED_MULTIPLIER = Object.freeze({ 0: 1, 1: 2, 2: 4, 3: 6 });

export function requiredTier(blockId) {
  return REQUIRED_TIER[blockId] ?? 0;
}

export function toolTier(itemId) {
  return TOOL_TIER[itemId] ?? 0;
}

/** BEDROCK can never be harvested outside Creative, regardless of tool -- matches the general "unbreakable floor" convention. */
export function canHarvest(blockId, toolItemId, gameMode) {
  if (gameMode === GameMode.CREATIVE) return true;
  if (blockId === BLOCK.BEDROCK) return false;
  return toolTier(toolItemId) >= requiredTier(blockId);
}

/**
 * Seconds to break the block. Infinity means it cannot be broken at all
 * with this tool in this mode -- a deliberate choice over "breaks
 * eventually but yields nothing," since a hard stop is a clearer signal
 * for a UI to communicate ("you need a better pickaxe") than a
 * dig-forever-for-nothing state.
 */
export function breakTimeSeconds(blockId, toolItemId, gameMode) {
  if (gameMode === GameMode.CREATIVE) return 0;
  if (blockId === BLOCK.BEDROCK) return Infinity;
  if (!canHarvest(blockId, toolItemId, gameMode)) return Infinity;
  const hardness = HARDNESS[blockId] ?? 1.0;
  const mult = TOOL_SPEED_MULTIPLIER[toolTier(toolItemId)] ?? 1;
  return hardness / mult;
}
