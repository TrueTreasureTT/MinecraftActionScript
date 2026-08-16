const SKIN_TONES = ["#F2C29E", "#C98F63", "#8D5A3B", "#5B3A24", "#E8B37A"];
const SHIRT_COLORS = ["#3B7FD6", "#D63B3B", "#3BD65A", "#D6C43B", "#8B3BD6", "#3BD6C4"];
const PANTS_COLORS = ["#2B2B44", "#4A3524", "#333333", "#5A2B2B", "#2B4A2B"];

export { SKIN_TONES, SHIRT_COLORS, PANTS_COLORS };

const STORAGE_KEY = "voxelpe_character";

/**
 * CharacterProfile: name + appearance state for the player's avatar.
 * Framework/DOM-independent -- works in Node (for tests) or a browser.
 * Storage is injected (any {get,set} object) so this can be backed by
 * localStorage on a real page, or an in-memory Map in tests, without
 * this class depending on either directly.
 */
export class CharacterProfile {
  constructor({ name = "Player", skinIndex = 0, shirtIndex = 0, pantsIndex = 0 } = {}) {
    this.name = "Player";
    this.setName(name);
    this.skinIndex = clampIndex(skinIndex, SKIN_TONES.length);
    this.shirtIndex = clampIndex(shirtIndex, SHIRT_COLORS.length);
    this.pantsIndex = clampIndex(pantsIndex, PANTS_COLORS.length);
  }

  setName(name) {
    const trimmed = String(name ?? "").trim();
    this.name = trimmed.length > 0 ? trimmed.slice(0, 24) : "Player";
  }

  setSkinIndex(i) {
    this.skinIndex = clampIndex(i, SKIN_TONES.length);
  }
  setShirtIndex(i) {
    this.shirtIndex = clampIndex(i, SHIRT_COLORS.length);
  }
  setPantsIndex(i) {
    this.pantsIndex = clampIndex(i, PANTS_COLORS.length);
  }

  randomize() {
    this.skinIndex = Math.floor(Math.random() * SKIN_TONES.length);
    this.shirtIndex = Math.floor(Math.random() * SHIRT_COLORS.length);
    this.pantsIndex = Math.floor(Math.random() * PANTS_COLORS.length);
    return this;
  }

  colors() {
    return {
      skin: SKIN_TONES[this.skinIndex],
      shirt: SHIRT_COLORS[this.shirtIndex],
      pants: PANTS_COLORS[this.pantsIndex],
    };
  }

  toJSON() {
    return { name: this.name, skinIndex: this.skinIndex, shirtIndex: this.shirtIndex, pantsIndex: this.pantsIndex };
  }

  static fromJSON(obj) {
    return new CharacterProfile(obj || {});
  }

  save(storage = defaultStorage()) {
    storage.set(STORAGE_KEY, JSON.stringify(this.toJSON()));
  }

  static load(storage = defaultStorage()) {
    const raw = storage.get(STORAGE_KEY);
    if (!raw) return new CharacterProfile();
    try {
      return CharacterProfile.fromJSON(JSON.parse(raw));
    } catch (e) {
      return new CharacterProfile();
    }
  }
}

function clampIndex(i, length) {
  const n = Number.isInteger(i) ? i : 0;
  if (length <= 0) return 0;
  return ((n % length) + length) % length; // wraps instead of throwing on negative/out-of-range input
}

function defaultStorage() {
  if (typeof localStorage !== "undefined") {
    return {
      get: (k) => localStorage.getItem(k),
      set: (k, v) => localStorage.setItem(k, v),
    };
  }
  const mem = new Map();
  return {
    get: (k) => (mem.has(k) ? mem.get(k) : null),
    set: (k, v) => mem.set(k, v),
  };
}

/**
 * Draws a blocky paperdoll preview onto a 2D canvas context. Geometry
 * (block positions/sizes) is identical to CharacterScreen.as's preview
 * in the AS3 build, so the same profile looks the same shape across
 * both stacks. Pure function of (ctx, profile) -- no internal state.
 */
export function drawPaperdoll(ctx, profile, originX = 0, originY = 0) {
  const { skin, shirt, pants } = profile.colors();
  const block = (x, y, w, h, color) => {
    ctx.fillStyle = color;
    ctx.fillRect(originX + x, originY + y, w, h);
    ctx.strokeStyle = "rgba(0,0,0,0.35)";
    ctx.strokeRect(originX + x, originY + y, w, h);
  };
  block(20, 0, 40, 40, skin); // head
  block(12, 40, 56, 60, shirt); // torso
  block(-4, 40, 16, 56, shirt); // left arm
  block(68, 40, 16, 56, shirt); // right arm
  block(-4, 96, 16, 24, skin); // left hand
  block(68, 96, 16, 24, skin); // right hand
  block(12, 100, 26, 60, pants); // left leg
  block(42, 100, 26, 60, pants); // right leg
}
