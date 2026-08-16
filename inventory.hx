package voxel;

/** A single inventory slot: an item/block id plus a count. Never constructed with count <= 0 -- empty slots are represented as null, not a zero-count Slot. */
class Slot
{
	public var item:Int;
	public var count:Int;

	public function new(item:Int, count:Int)
	{
		this.item = item;
		this.count = count;
	}

	public function clone():Slot
	{
		return new Slot(item, count);
	}
}

/**
 * Fixed-size slot inventory. Same algorithm as the (Node-tested) JS
 * version in js-pe/inventory.js: top up existing stacks first, then
 * fill empty slots; removeItem checks availability via hasItem() before
 * touching anything, so a failed removal never partially consumes.
 */
class Inventory
{
	public var size:Int;
	public var slots:Array<Slot>;

	public function new(size:Int = 36)
	{
		this.size = size;
		slots = [for (i in 0...size) null];
	}

	static inline function stackSizeFor(item:Int):Int
	{
		Item.init();
		return Item.stackSizeOf(item);
	}

	/** Returns leftover count that didn't fit (0 means everything fit). */
	public function addItem(item:Int, count:Int):Int
	{
		if (count <= 0) return 0;
		var maxStack = stackSizeFor(item);
		var remaining = count;

		for (i in 0...size)
		{
			if (remaining <= 0) break;
			var slot = slots[i];
			if (slot != null && slot.item == item && slot.count < maxStack)
			{
				var space = maxStack - slot.count;
				var add = space < remaining ? space : remaining;
				slot.count += add;
				remaining -= add;
			}
		}

		for (i in 0...size)
		{
			if (remaining <= 0) break;
			if (slots[i] == null)
			{
				var add = maxStack < remaining ? maxStack : remaining;
				slots[i] = new Slot(item, add);
				remaining -= add;
			}
		}

		return remaining;
	}

	public function hasItem(item:Int, count:Int):Bool
	{
		var total = 0;
		for (slot in slots)
		{
			if (slot != null && slot.item == item) total += slot.count;
			if (total >= count) return true;
		}
		return false;
	}

	/** Returns false (leaving the inventory completely untouched) if the full amount isn't available. */
	public function removeItem(item:Int, count:Int):Bool
	{
		if (!hasItem(item, count)) return false;

		var remaining = count;
		for (i in 0...size)
		{
			if (remaining <= 0) break;
			var slot = slots[i];
			if (slot != null && slot.item == item)
			{
				var take = slot.count < remaining ? slot.count : remaining;
				slot.count -= take;
				remaining -= take;
				if (slot.count <= 0) slots[i] = null;
			}
		}
		return true;
	}

	public function countItem(item:Int):Int
	{
		var total = 0;
		for (slot in slots)
		{
			if (slot != null && slot.item == item) total += slot.count;
		}
		return total;
	}

	public function clone():Inventory
	{
		var copy = new Inventory(size);
		for (i in 0...size)
		{
			copy.slots[i] = slots[i] != null ? slots[i].clone() : null;
		}
		return copy;
	}
}
