/**
 * Non-block items: materials and tools that live in an inventory slot
 * but aren't placeable in the world. IDs start at 100 to leave headroom
 * in the block ID space (0-21 used, room to grow) without ever
 * colliding with a block ID -- Inventory/Crafting/Furnace treat block
 * IDs and item IDs as the same numeric namespace, exactly like real
 * Minecraft treats blocks as a subset of items.
 *
 * Durability numbers below are original round values for this project,
 * not a claim about matching any specific real game's exact numbers.
 */

export const ITEM = Object.freeze({
  STICK: 100,
  IRON_INGOT: 101,
  GOLD_INGOT: 102,
  WOODEN_PICKAXE: 110,
  STONE_PICKAXE: 111,
  IRON_PICKAXE: 112,
  WOODEN_AXE: 113,
  STONE_AXE: 114,
  IRON_AXE: 115,
});

export const ITEM_INFO = Object.freeze({
  [ITEM.STICK]: { name: "Stick", stackSize: 64 },
  [ITEM.IRON_INGOT]: { name: "Iron Ingot", stackSize: 64 },
  [ITEM.GOLD_INGOT]: { name: "Gold Ingot", stackSize: 64 },
  [ITEM.WOODEN_PICKAXE]: { name: "Wooden Pickaxe", stackSize: 1, durability: 30 },
  [ITEM.STONE_PICKAXE]: { name: "Stone Pickaxe", stackSize: 1, durability: 60 },
  [ITEM.IRON_PICKAXE]: { name: "Iron Pickaxe", stackSize: 1, durability: 120 },
  [ITEM.WOODEN_AXE]: { name: "Wooden Axe", stackSize: 1, durability: 30 },
  [ITEM.STONE_AXE]: { name: "Stone Axe", stackSize: 1, durability: 60 },
  [ITEM.IRON_AXE]: { name: "Iron Axe", stackSize: 1, durability: 120 },
});

export function nameOfItem(id) {
  return ITEM_INFO[id]?.name ?? "Unknown Item";
}

export function isTool(id) {
  return ITEM_INFO[id]?.durability != null;
}
