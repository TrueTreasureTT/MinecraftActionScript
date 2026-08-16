// Run with: node verify.mjs
// Exercises every module's actual behavior, not just "does it parse."
// Exits non-zero on any failure so this can gate delivery honestly.

import { BLOCK, isSolid, nameOf } from "./blocks.js";
import { ITEM, ITEM_INFO } from "./items.js";
import { Inventory } from "./inventory.js";
import { RECIPES, craft, craftableRecipes } from "./crafting.js";
import { Furnace, SMELTING_RECIPES } from "./furnace.js";
import { CharacterProfile, SKIN_TONES, SHIRT_COLORS, PANTS_COLORS } from "./character.js";
import { SettingsManager, RENDER_DISTANCE_OPTIONS } from "./settings.js";
import { ChatSystem } from "./chat.js";
import { ValueNoise2D, TerrainGenerator } from "./terrain.js";

let pass = 0;
let fail = 0;

function check(label, condition) {
  if (condition) {
    pass++;
  } else {
    fail++;
    console.error(`FAIL: ${label}`);
  }
}

function memStorage() {
  const mem = new Map();
  return { get: (k) => (mem.has(k) ? mem.get(k) : null), set: (k, v) => mem.set(k, v) };
}

// ---------------- blocks.js ----------------
check("blocks: AIR is not solid", isSolid(BLOCK.AIR) === false);
check("blocks: WATER is not solid", isSolid(BLOCK.WATER) === false);
check("blocks: GRASS is solid", isSolid(BLOCK.GRASS) === true);
check("blocks: GLASS is solid (visually transparent but still blocks movement)", isSolid(BLOCK.GLASS) === true);
check("blocks: ICE is solid", isSolid(BLOCK.ICE) === true);
check("blocks: all 22 IDs 0-21 resolve to a known name", Object.keys(BLOCK).length === 22 &&
  Object.values(BLOCK).every((id) => nameOf(id) !== "Unknown"));
check("blocks: unknown id returns Unknown", nameOf(999) === "Unknown");

// ---------------- inventory.js ----------------
{
  const inv = new Inventory(4);
  const leftover1 = inv.addItem(BLOCK.STONE, 10);
  check("inventory: adding 10 stone to empty inv leaves 0 leftover", leftover1 === 0);
  check("inventory: countItem reflects the add", inv.countItem(BLOCK.STONE) === 10);

  const removed = inv.removeItem(BLOCK.STONE, 4);
  check("inventory: removeItem succeeds when enough is present", removed === true);
  check("inventory: count drops correctly after removal", inv.countItem(BLOCK.STONE) === 6);

  const failedRemove = inv.removeItem(BLOCK.STONE, 999);
  check("inventory: removeItem fails when not enough present", failedRemove === false);
  check("inventory: failed removeItem leaves inventory untouched", inv.countItem(BLOCK.STONE) === 6);

  const tiny = new Inventory(1);
  const overflow = tiny.addItem(BLOCK.DIRT, 100); // 1 slot, stack cap 64 -> 36 should overflow
  check("inventory: overflow returns correct leftover count", overflow === 36);
  check("inventory: overflowed inventory still holds a full stack", tiny.countItem(BLOCK.DIRT) === 64);

  // Tool stacking: stack size 1, so 3 pickaxes need 3 slots, not 1.
  const toolInv = new Inventory(5);
  toolInv.addItem(ITEM.WOODEN_PICKAXE, 3);
  const usedSlots = toolInv.slots.filter((s) => s !== null).length;
  check("inventory: stackSize=1 items don't stack into one slot", usedSlots === 3);
}

// ---------------- crafting.js ----------------
{
  const inv = new Inventory(36);
  inv.addItem(BLOCK.WOOD_LOG, 1);
  const planksRecipe = RECIPES.find((r) => r.id === "planks_from_log");
  const ok = craft(inv, planksRecipe);
  check("crafting: planks_from_log succeeds with 1 log available", ok === true);
  check("crafting: log was consumed", inv.countItem(BLOCK.WOOD_LOG) === 0);
  check("crafting: 4 planks produced", inv.countItem(BLOCK.PLANK) === 4);

  const inv2 = new Inventory(36); // empty
  const failedCraft = craft(inv2, planksRecipe);
  check("crafting: fails cleanly with no ingredients", failedCraft === false);
  check("crafting: failed craft adds nothing", inv2.countItem(BLOCK.PLANK) === 0);

  // Full-inventory-blocks-output case: fill every slot with an unrelated
  // item so there's no room for crafting output, and confirm ingredients
  // are NOT consumed when the craft can't complete.
  const fullInv = new Inventory(1);
  fullInv.addItem(BLOCK.COBBLESTONE, 64); // the only slot is now full and it's not planks/sticks
  const pickaxeRecipe = RECIPES.find((r) => r.id === "wooden_pickaxe");
  const blockedCraft = craft(fullInv, pickaxeRecipe);
  check("crafting: fails when output has nowhere to go", blockedCraft === false);
  check("crafting: blocked craft doesn't touch existing inventory contents", fullInv.countItem(BLOCK.COBBLESTONE) === 64);

  // Full recipe chain: log -> planks -> sticks -> wooden pickaxe
  const chainInv = new Inventory(36);
  chainInv.addItem(BLOCK.WOOD_LOG, 2);
  craft(chainInv, RECIPES.find((r) => r.id === "planks_from_log")); // -> 4 planks, 1 log left... wait only crafts once
  craft(chainInv, RECIPES.find((r) => r.id === "planks_from_log")); // consume 2nd log -> 8 planks total
  craft(chainInv, RECIPES.find((r) => r.id === "sticks_from_planks")); // consume 2 planks -> 4 sticks, 6 planks left
  const madePickaxe = craft(chainInv, RECIPES.find((r) => r.id === "wooden_pickaxe")); // needs 3 planks + 2 sticks
  check("crafting: full log->planks->sticks->pickaxe chain succeeds", madePickaxe === true);
  check("crafting: pickaxe present after chain", chainInv.countItem(ITEM.WOODEN_PICKAXE) === 1);

  check("crafting: craftableRecipes only lists recipes with available ingredients",
    craftableRecipes(new Inventory(36)).length === 0); // empty inventory -> nothing craftable
}

// ---------------- furnace.js ----------------
{
  const f = new Furnace();
  f.setInput(BLOCK.IRON_ORE, 1);
  f.setFuel(BLOCK.WOOD_LOG, 1);

  const ironRecipe = SMELTING_RECIPES.find((r) => r.id === "iron_ingot");
  let completed = false;
  for (let i = 0; i < ironRecipe.cookTicks + 5; i++) {
    f.tick();
    if (f.outputSlot) { completed = true; break; }
  }
  check("furnace: smelting completes within expected tick count", completed === true);
  check("furnace: input ore was consumed", f.inputSlot === null);
  check("furnace: output is iron ingot", f.outputSlot && f.outputSlot.item === ITEM.IRON_INGOT);

  const collected = f.collectOutput();
  check("furnace: collectOutput returns the smelted item and clears the slot", collected.item === ITEM.IRON_INGOT && f.outputSlot === null);

  // No fuel -> should never light, never progress.
  const unlit = new Furnace();
  unlit.setInput(BLOCK.IRON_ORE, 1);
  for (let i = 0; i < 50; i++) unlit.tick();
  check("furnace: without fuel, nothing smelts", unlit.outputSlot === null && unlit.isLit === false);

  // Non-fuel item in fuel slot should never ignite.
  const badFuel = new Furnace();
  badFuel.setInput(BLOCK.IRON_ORE, 1);
  badFuel.setFuel(BLOCK.STONE, 5); // stone isn't in FUEL_BURN_TICKS
  for (let i = 0; i < 50; i++) badFuel.tick();
  check("furnace: invalid fuel item never ignites", badFuel.isLit === false);
}

// ---------------- character.js ----------------
{
  const p = new CharacterProfile();
  check("character: default name is Player", p.name === "Player");
  p.setName("   Steve   ");
  check("character: setName trims whitespace", p.name === "Steve");
  p.setName("x".repeat(50));
  check("character: setName clamps length to 24", p.name.length === 24);

  p.setSkinIndex(999);
  check("character: out-of-range index wraps instead of crashing", p.skinIndex >= 0 && p.skinIndex < SKIN_TONES.length);

  p.randomize();
  check("character: randomize stays within valid ranges", p.skinIndex < SKIN_TONES.length && p.shirtIndex < SHIRT_COLORS.length && p.pantsIndex < PANTS_COLORS.length);

  const json = p.toJSON();
  const restored = CharacterProfile.fromJSON(json);
  check("character: toJSON/fromJSON round-trips exactly", JSON.stringify(restored.toJSON()) === JSON.stringify(json));

  const storage = memStorage();
  p.save(storage);
  const loaded = CharacterProfile.load(storage);
  check("character: save/load round-trips through storage", loaded.name === p.name && loaded.skinIndex === p.skinIndex);

  const freshLoad = CharacterProfile.load(memStorage());
  check("character: loading with no saved data returns sane defaults", freshLoad.name === "Player");
}

// ---------------- settings.js ----------------
{
  const s = new SettingsManager(memStorage());
  check("settings: defaults match spec", s.get("musicVolume") === 80 && s.get("renderDistance") === 8);

  s.set("musicVolume", 150); // out of range
  check("settings: volume clamps to 100", s.get("musicVolume") === 100);
  s.set("musicVolume", -20);
  check("settings: volume clamps to 0", s.get("musicVolume") === 0);

  s.set("renderDistance", 5); // not a valid step; nearest of [2,4,8,16] to 5 is 4
  check("settings: renderDistance snaps to nearest valid option", s.get("renderDistance") === 4 && RENDER_DISTANCE_OPTIONS.includes(4));

  let notified = null;
  const unsub = s.onChange((key, value) => { notified = { key, value }; });
  s.set("soundVolume", 42);
  check("settings: onChange listener fires with correct key/value", notified && notified.key === "soundVolume" && notified.value === 42);
  unsub();
  notified = null;
  s.set("soundVolume", 10);
  check("settings: unsubscribe actually stops notifications", notified === null);

  let threw = false;
  try { s.set("notARealSetting", 1); } catch (e) { threw = true; }
  check("settings: setting an unknown key throws", threw === true);

  s.reset();
  check("settings: reset restores defaults", s.get("musicVolume") === 80 && s.get("renderDistance") === 8);

  // Persistence: a second manager reading the same storage should see saved values.
  const storage2 = memStorage();
  const sA = new SettingsManager(storage2);
  sA.set("mouseSensitivity", 77);
  const sB = new SettingsManager(storage2);
  check("settings: persists across manager instances via shared storage", sB.get("mouseSensitivity") === 77);
}

// ---------------- chat.js ----------------
{
  const chat = new ChatSystem({ playerName: "Alex" });
  const msg = chat.send("hello world");
  check("chat: send() returns the message and appends to log", msg !== null && chat.log.length === 1);
  check("chat: own message is marked isSelf", chat.log[0].isSelf === true);
  check("chat: sender name matches player name", chat.log[0].sender === "Alex");

  chat.send("   "); // whitespace-only, should be ignored
  check("chat: whitespace-only message is not sent", chat.log.length === 1);

  chat.send("/nick Steve");
  check("chat: /nick changes the player name", chat.playerName === "Steve");
  check("chat: /nick appends a system confirmation message", chat.log[chat.log.length - 1].sender === "system");

  chat.send("/bogus");
  check("chat: unknown command produces a system message instead of crashing", chat.log[chat.log.length - 1].text.includes("Unknown command"));

  chat.send("/clear");
  check("chat: /clear empties the log", chat.log.length === 0);

  // Log length cap
  for (let i = 0; i < 250; i++) chat.send(`msg ${i}`);
  check("chat: log is capped at MAX_LOG_LENGTH (200)", chat.log.length === 200);
  check("chat: cap keeps the MOST RECENT messages, not the oldest", chat.log[chat.log.length - 1].text === "msg 249");

  // BroadcastChannel availability (informational, not a hard requirement).
  check("chat: BroadcastChannel is available in this Node runtime", typeof BroadcastChannel !== "undefined");
}

// ---------------- terrain.js ----------------
{
  const noise = new ValueNoise2D(42);
  const a = noise.sample(3.3, 7.1);
  const b = noise.sample(3.3, 7.1);
  check("terrain: ValueNoise2D.sample is deterministic for repeated calls", a === b);
  check("terrain: sample stays within [0,1)", a >= 0 && a < 1);

  const gen1 = new TerrainGenerator(1234);
  const gen2 = new TerrainGenerator(1234);
  let allMatch = true;
  for (let x = 0; x < 20; x++) {
    for (let z = 0; z < 20; z++) {
      if (gen1.heightAt(x, z) !== gen2.heightAt(x, z)) allMatch = false;
    }
  }
  check("terrain: same seed produces identical heights across separate instances", allMatch);

  const gen3 = new TerrainGenerator(9999); // different seed
  let anyDifferent = false;
  for (let x = 0; x < 20; x++) {
    for (let z = 0; z < 20; z++) {
      if (gen1.heightAt(x, z) !== gen3.heightAt(x, z)) anyDifferent = true;
    }
  }
  check("terrain: different seeds produce different terrain (not a constant function)", anyDifferent);

  const gen = new TerrainGenerator(1);
  let boundsOk = true;
  let bedrockOk = true;
  let noAirBelowSurface = true;
  let knownBlocksOnly = true;
  const validIds = new Set(Object.values(BLOCK));
  for (let x = -50; x < 50; x += 3) {
    for (let z = -50; z < 50; z += 3) {
      const h = gen.heightAt(x, z);
      if (h < 1 || h > gen.worldHeight - 2) boundsOk = false;

      const col = gen.columnAt(x, z);
      if (col[0] !== BLOCK.BEDROCK) bedrockOk = false;
      for (let y = 0; y <= h; y++) {
        if (col[y] === BLOCK.AIR) noAirBelowSurface = false;
        if (!validIds.has(col[y])) knownBlocksOnly = false;
      }
      // treeAt should never say yes at/under sea level
      if (gen.treeAt(x, z) && h <= gen.seaLevel) {
        check(`terrain: treeAt never true at/under sea level (x=${x} z=${z} h=${h})`, false);
      }
    }
  }
  check("terrain: heightAt always within configured bounds", boundsOk);
  check("terrain: every column has bedrock at y=0", bedrockOk);
  check("terrain: no air gaps between bedrock and the surface block", noAirBelowSurface);
  check("terrain: columns never contain an unregistered block id", knownBlocksOnly);

  // Column length invariant: always exactly worldHeight entries.
  check("terrain: columnAt always returns a full-height array", gen.columnAt(5, 5).length === gen.worldHeight);
}

// ---------------- summary ----------------
console.log(`\n${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
