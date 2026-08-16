import { ITEM_INFO } from "./items.js";

const DEFAULT_STACK_SIZE = 64;

function stackSizeFor(item) {
  return ITEM_INFO[item]?.stackSize ?? DEFAULT_STACK_SIZE;
}

/**
 * Fixed-size slot inventory. Each slot is either null (empty) or
 * { item, count }. Stack size per item comes from ITEM_INFO, defaulting
 * to 64 for anything not listed there (i.e. every block).
 */
export class Inventory {
  constructor(size = 36) {
    this.size = size;
    this.slots = new Array(size).fill(null);
  }

  /**
   * Adds up to `count` of `item`: tops up existing partial stacks first,
   * then fills empty slots. Returns leftover count that didn't fit (0
   * means everything fit).
   */
  addItem(item, count) {
    if (count <= 0) return 0;
    const maxStack = stackSizeFor(item);
    let remaining = count;

    for (let i = 0; i < this.size && remaining > 0; i++) {
      const slot = this.slots[i];
      if (slot && slot.item === item && slot.count < maxStack) {
        const space = maxStack - slot.count;
        const add = Math.min(space, remaining);
        slot.count += add;
        remaining -= add;
      }
    }

    for (let i = 0; i < this.size && remaining > 0; i++) {
      if (this.slots[i] === null) {
        const add = Math.min(maxStack, remaining);
        this.slots[i] = { item, count: add };
        remaining -= add;
      }
    }

    return remaining;
  }

  hasItem(item, count) {
    let total = 0;
    for (const slot of this.slots) {
      if (slot && slot.item === item) total += slot.count;
      if (total >= count) return true;
    }
    return false;
  }

  /**
   * Removes up to `count` of `item`. Returns false (leaving the
   * inventory completely untouched) if the full amount isn't available
   * -- checked via hasItem() first so this never partially removes on a
   * failed call.
   */
  removeItem(item, count) {
    if (!this.hasItem(item, count)) return false;

    let remaining = count;
    for (let i = 0; i < this.size && remaining > 0; i++) {
      const slot = this.slots[i];
      if (slot && slot.item === item) {
        const take = Math.min(slot.count, remaining);
        slot.count -= take;
        remaining -= take;
        if (slot.count <= 0) this.slots[i] = null;
      }
    }
    return true;
  }

  countItem(item) {
    let total = 0;
    for (const slot of this.slots) {
      if (slot && slot.item === item) total += slot.count;
    }
    return total;
  }

  clone() {
    const copy = new Inventory(this.size);
    copy.slots = this.slots.map((s) => (s ? { ...s } : null));
    return copy;
  }

  toJSON() {
    return { size: this.size, slots: this.slots };
  }

  static fromJSON(obj) {
    const inv = new Inventory(obj?.size ?? 36);
    if (Array.isArray(obj?.slots)) {
      inv.slots = obj.slots.map((s) => (s ? { item: s.item, count: s.count } : null));
    }
    return inv;
  }
}
