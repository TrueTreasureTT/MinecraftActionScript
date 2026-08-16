const STORAGE_KEY = "voxelpe_settings";

const DEFAULTS = Object.freeze({
  musicVolume: 80,
  soundVolume: 100,
  mouseSensitivity: 50,
  renderDistance: 8, // chunks
  showFps: false,
  chatEnabled: true,
});

export const RENDER_DISTANCE_OPTIONS = Object.freeze([2, 4, 8, 16]);
export const SETTINGS_DEFAULTS = DEFAULTS;

/**
 * SettingsManager: game options with validation/clamping, persistence
 * via injectable storage, and a subscribe/notify pattern so UI can react
 * to changes without polling.
 */
export class SettingsManager {
  constructor(storage = defaultStorage()) {
    this.storage = storage;
    this.listeners = new Set();
    this.values = { ...DEFAULTS, ...this._loadRaw() };
  }

  _loadRaw() {
    const raw = this.storage.get(STORAGE_KEY);
    if (!raw) return {};
    try {
      return JSON.parse(raw);
    } catch (e) {
      return {};
    }
  }

  get(key) {
    return this.values[key];
  }

  getAll() {
    return { ...this.values };
  }

  set(key, value) {
    if (!(key in DEFAULTS)) {
      throw new Error(`Unknown setting: ${key}`);
    }
    const validated = this._validate(key, value);
    this.values[key] = validated;
    this._persist();
    this._notify(key, validated);
    return validated;
  }

  reset() {
    this.values = { ...DEFAULTS };
    this._persist();
    for (const key of Object.keys(DEFAULTS)) {
      this._notify(key, this.values[key]);
    }
  }

  /** Returns an unsubscribe function. */
  onChange(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  _validate(key, value) {
    switch (key) {
      case "musicVolume":
      case "soundVolume":
      case "mouseSensitivity":
        return clamp(Number(value), 0, 100);
      case "renderDistance": {
        const n = Number(value);
        // Snap to the nearest supported step -- the chunk-loading system
        // (Haxe side) only knows how to work in these increments.
        return RENDER_DISTANCE_OPTIONS.reduce((closest, opt) =>
          Math.abs(opt - n) < Math.abs(closest - n) ? opt : closest
        );
      }
      case "showFps":
      case "chatEnabled":
        return Boolean(value);
      default:
        return value;
    }
  }

  _persist() {
    this.storage.set(STORAGE_KEY, JSON.stringify(this.values));
  }

  _notify(key, value) {
    for (const listener of this.listeners) {
      listener(key, value, this.values);
    }
  }
}

function clamp(n, min, max) {
  if (Number.isNaN(n)) return min;
  return Math.min(max, Math.max(min, n));
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
