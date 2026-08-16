/**
 * JS mirror of the Haxe Block.hx / voxelpeblocks registry: block IDs and
 * names, kept numerically identical across stacks (Haxe, and this JS
 * module) so recipe ingredient IDs and any shared save data mean the
 * same thing everywhere. This module has no renderer, so atlas/UV logic
 * isn't included here -- only what a data layer (terrain, crafting,
 * inventory) actually needs.
 */

export const BLOCK = Object.freeze({
  AIR: 0,
  GRASS: 1,
  DIRT: 2,
  STONE: 3,
  WOOD_LOG: 4,
  LEAVES: 5,
  SAND: 6,
  WATER: 7,
  PLANK: 8,
  BEDROCK: 9,
  COBBLESTONE: 10,
  COAL_ORE: 11,
  IRON_ORE: 12,
  GOLD_ORE: 13,
  DIAMOND_ORE: 14,
  GRAVEL: 15,
  GLASS: 16,
  BRICK: 17,
  OBSIDIAN: 18,
  SNOW: 19,
  ICE: 20,
  MOSSY_COBBLESTONE: 21,
});

export const BLOCK_NAMES = {
  [BLOCK.AIR]: "Air",
  [BLOCK.GRASS]: "Grass",
  [BLOCK.DIRT]: "Dirt",
  [BLOCK.STONE]: "Stone",
  [BLOCK.WOOD_LOG]: "Wood Log",
  [BLOCK.LEAVES]: "Leaves",
  [BLOCK.SAND]: "Sand",
  [BLOCK.WATER]: "Water",
  [BLOCK.PLANK]: "Wood Planks",
  [BLOCK.BEDROCK]: "Bedrock",
  [BLOCK.COBBLESTONE]: "Cobblestone",
  [BLOCK.COAL_ORE]: "Coal Ore",
  [BLOCK.IRON_ORE]: "Iron Ore",
  [BLOCK.GOLD_ORE]: "Gold Ore",
  [BLOCK.DIAMOND_ORE]: "Diamond Ore",
  [BLOCK.GRAVEL]: "Gravel",
  [BLOCK.GLASS]: "Glass",
  [BLOCK.BRICK]: "Brick",
  [BLOCK.OBSIDIAN]: "Obsidian",
  [BLOCK.SNOW]: "Snow",
  [BLOCK.ICE]: "Ice",
  [BLOCK.MOSSY_COBBLESTONE]: "Mossy Cobblestone",
};

// Matches Block.hx exactly: SOLID defaults true for every block, then
// AIR and WATER are the only two explicitly set false.
export const NON_SOLID = new Set([BLOCK.AIR, BLOCK.WATER]);

export function isSolid(id) {
  return Object.prototype.hasOwnProperty.call(BLOCK_NAMES, id) && !NON_SOLID.has(id);
}

export function nameOf(id) {
  return BLOCK_NAMES[id] ?? "Unknown";
}
