package voxel;

import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/**
 * Screen-space UI overlay, drawn as OpenFL display objects on top of the
 * Stage3D layer (Stage3D always renders behind the normal display list,
 * so ordinary Sprites added to the stage naturally composite over it --
 * no special blending setup needed).
 *
 * Layout mirrors classic MCPE's control scheme:
 *  - Crosshair, dead center
 *  - Hotbar, bottom center, 9 slots, tap to select
 *  - Jump button, bottom right
 *  - Save button, top right (not present in original MCPE, but needed
 *    here since there's no pause menu yet -- kept small/unobtrusive)
 */
class GameUI extends Sprite
{
	public var onSlotSelected:Int->Void;
	public var onJump:Void->Void;
	public var onSave:Void->Void;

	var hotbarBlocks:Array<Int>;
	var selectedSlot:Int;
	var slotSprites:Array<Sprite>;
	var crosshair:Shape;

	static inline var SLOT_SIZE:Float = 44;
	static inline var SLOT_GAP:Float = 4;
	static inline var SCREEN_W:Float = 960;
	static inline var SCREEN_H:Float = 640;

	public function new(hotbarBlocks:Array<Int>, initialSlot:Int)
	{
		super();
		this.hotbarBlocks = hotbarBlocks;
		this.selectedSlot = initialSlot;
		slotSprites = [];

		buildCrosshair();
		buildHotbar();
		buildJumpButton();
		buildSaveButton();
	}

	function buildCrosshair():Void
	{
		crosshair = new Shape();
		var g = crosshair.graphics;
		g.lineStyle(2, 0xFFFFFF, 0.8);
		var cx = SCREEN_W / 2;
		var cy = SCREEN_H / 2;
		var size = 8.0;
		g.moveTo(cx - size, cy);
		g.lineTo(cx + size, cy);
		g.moveTo(cx, cy - size);
		g.lineTo(cx, cy + size);
		addChild(crosshair);
	}

	function buildHotbar():Void
	{
		var totalWidth = hotbarBlocks.length * (SLOT_SIZE + SLOT_GAP) - SLOT_GAP;
		var startX = (SCREEN_W - totalWidth) / 2;
		var y = SCREEN_H - SLOT_SIZE - 16;

		for (i in 0...hotbarBlocks.length)
		{
			var slot = new Sprite();
			slot.x = startX + i * (SLOT_SIZE + SLOT_GAP);
			slot.y = y;
			drawSlot(slot, i == selectedSlot);
			addSlotLabel(slot, hotbarBlocks[i]);

			var idx = i; // capture for closure
			slot.buttonMode = true;
			slot.addEventListener(MouseEvent.CLICK, function(e) selectSlot(idx));

			addChild(slot);
			slotSprites.push(slot);
		}
	}

	function drawSlot(slot:Sprite, selected:Bool):Void
	{
		slot.graphics.clear();
		// Dark semi-transparent panel background, classic hotbar look.
		slot.graphics.beginFill(0x000000, 0.5);
		slot.graphics.drawRect(0, 0, SLOT_SIZE, SLOT_SIZE);
		slot.graphics.endFill();
		// Border: bright white when selected, dim grey otherwise.
		slot.graphics.lineStyle(selected ? 3 : 1, selected ? 0xFFFFFF : 0x888888, selected ? 1.0 : 0.6);
		slot.graphics.drawRect(1, 1, SLOT_SIZE - 2, SLOT_SIZE - 2);
	}

	function addSlotLabel(slot:Sprite, blockId:Int):Void
	{
		// Small color swatch representing the block (a stand-in for a real
		// item-icon render; keeps the hotbar readable without needing a
		// separate icon-rendering pass for this first version).
		var swatch = new Shape();
		var color = swatchColorFor(blockId);
		swatch.graphics.beginFill(color);
		swatch.graphics.drawRect(6, 6, SLOT_SIZE - 12, SLOT_SIZE - 12);
		swatch.graphics.endFill();
		slot.addChild(swatch);
	}

	function swatchColorFor(blockId:Int):Int
	{
		if (blockId == Block.GRASS) return 0x5B993D;
		if (blockId == Block.DIRT) return 0x765435;
		if (blockId == Block.STONE) return 0x7F7F7F;
		if (blockId == Block.COBBLESTONE) return 0x7A7A7A;
		if (blockId == Block.WOOD_LOG) return 0x6E4E30;
		if (blockId == Block.PLANK) return 0xA1784C;
		if (blockId == Block.LEAVES) return 0x3F7A2E;
		if (blockId == Block.SAND) return 0xDBCD9A;
		if (blockId == Block.WATER) return 0x3064BF;
		return 0xFFFFFF;
	}

	function selectSlot(i:Int):Void
	{
		drawSlot(slotSprites[selectedSlot], false);
		selectedSlot = i;
		drawSlot(slotSprites[selectedSlot], true);
		if (onSlotSelected != null) onSlotSelected(i);
	}

	function buildJumpButton():Void
	{
		var btn = new Sprite();
		var size = 64.0;
		btn.graphics.beginFill(0xFFFFFF, 0.25);
		btn.graphics.drawCircle(size / 2, size / 2, size / 2);
		btn.graphics.endFill();
		btn.graphics.lineStyle(2, 0xFFFFFF, 0.6);
		btn.graphics.drawCircle(size / 2, size / 2, size / 2);

		var label = new TextField();
		label.text = "JUMP";
		label.selectable = false;
		label.width = size;
		label.height = 20;
		label.y = size / 2 - 8;
		var fmt = new TextFormat("_sans", 11, 0xFFFFFF);
		fmt.align = TextFormatAlign.CENTER;
		label.defaultTextFormat = fmt;
		label.setTextFormat(fmt);
		btn.addChild(label);

		btn.x = SCREEN_W - size - 24;
		btn.y = SCREEN_H - size - 100;
		btn.buttonMode = true;
		btn.addEventListener(MouseEvent.MOUSE_DOWN, function(e) { if (onJump != null) onJump(); });

		addChild(btn);
	}

	function buildSaveButton():Void
	{
		var btn = new Sprite();
		var w = 90.0, h = 32.0;
		btn.graphics.beginFill(0x000000, 0.5);
		btn.graphics.drawRoundRect(0, 0, w, h, 8);
		btn.graphics.endFill();
		btn.graphics.lineStyle(1, 0xFFFFFF, 0.7);
		btn.graphics.drawRoundRect(0, 0, w, h, 8);

		var label = new TextField();
		label.text = "SAVE WORLD";
		label.selectable = false;
		label.width = w;
		label.height = h;
		label.y = 8;
		var fmt = new TextFormat("_sans", 11, 0xFFFFFF);
		fmt.align = TextFormatAlign.CENTER;
		label.defaultTextFormat = fmt;
		label.setTextFormat(fmt);
		btn.addChild(label);

		btn.x = SCREEN_W - w - 16;
		btn.y = 16;
		btn.buttonMode = true;
		btn.addEventListener(MouseEvent.CLICK, function(e) { if (onSave != null) onSave(); });

		addChild(btn);
	}

	/** Slightly brightens the crosshair when a block is targeted, dims otherwise -- cheap visual feedback without a full outline-highlight pass. */
	public function updateCrosshairHint(targeting:Bool):Void
	{
		crosshair.alpha = targeting ? 1.0 : 0.55;
	}
}
