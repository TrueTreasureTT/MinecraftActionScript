/**
 * Survival vs Creative: a small ruleset object per mode rather than
 * scattered `if (survival)` checks throughout the codebase. Any system
 * that behaves differently per mode (mining, hunger, damage) reads its
 * behavior from here instead of hardcoding mode checks itself.
 */

export const GameMode = Object.freeze({
  SURVIVAL: "survival",
  CREATIVE: "creative",
});

export const GAME_MODE_RULES = Object.freeze({
  [GameMode.SURVIVAL]: Object.freeze({
    infiniteBlocks: false,
    takesDamage: true,
    hungerEnabled: true,
    instantBreak: false,
    requiresTool: true,
  }),
  [GameMode.CREATIVE]: Object.freeze({
    infiniteBlocks: true,
    takesDamage: false,
    hungerEnabled: false,
    instantBreak: true,
    requiresTool: false,
  }),
});

export function rulesFor(mode) {
  return GAME_MODE_RULES[mode] ?? GAME_MODE_RULES[GameMode.SURVIVAL];
}

export function isValidGameMode(mode) {
  return mode === GameMode.SURVIVAL || mode === GameMode.CREATIVE;
}
