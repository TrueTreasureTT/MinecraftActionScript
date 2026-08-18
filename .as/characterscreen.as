package ui
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;

	/**
	 * Character customization: name + three color choices (skin, shirt,
	 * pants), rendered as a simple blocky paperdoll -- consistent with
	 * the project's low-fidelity original art style, and achievable
	 * without a 3D engine in this 2D menu layer. Persisted via
	 * SharedObject under "voxelpe_character"; ChatPanel reads the same
	 * key so chat messages use your customized name.
	 */
	public class CharacterScreen extends Sprite
	{
		private static const SCREEN_W:Number = 960;
		private static const SCREEN_H:Number = 640;
		private static const SO_NAME:String = "voxelpe_character";

		private static const SKIN_TONES:Array = [0xF2C29E, 0xC98F63, 0x8D5A3B, 0x5B3A24, 0xE8B37A];
		private static const SHIRT_COLORS:Array = [0x3B7FD6, 0xD63B3B, 0x3BD65A, 0xD6C43B, 0x8B3BD6, 0x3BD6C4];
		private static const PANTS_COLORS:Array = [0x2B2B44, 0x4A3524, 0x333333, 0x5A2B2B, 0x2B4A2B];

		private var screens:ScreenManager;
		private var homepage:Sprite;
		private var nameInput:TextField;
		private var preview:Sprite;

		private var skinIndex:int = 0;
		private var shirtIndex:int = 0;
		private var pantsIndex:int = 0;

		public function CharacterScreen(screens:ScreenManager, homepage:Sprite)
		{
			this.screens = screens;
			this.homepage = homepage;
			loadState();
			build();
			redrawPreview();
		}

		private function loadState():void
		{
			var so:SharedObject = SharedObject.getLocal(SO_NAME);
			if (so.data.skinIndex != null) skinIndex = so.data.skinIndex;
			if (so.data.shirtIndex != null) shirtIndex = so.data.shirtIndex;
			if (so.data.pantsIndex != null) pantsIndex = so.data.pantsIndex;
		}

		private function saveState():void
		{
			var so:SharedObject = SharedObject.getLocal(SO_NAME);
			so.data.name = nameInput != null ? nameInput.text : "Player";
			so.data.skinIndex = skinIndex;
			so.data.shirtIndex = shirtIndex;
			so.data.pantsIndex = pantsIndex;
			try { so.flush(); } catch (e:Error) {}
		}

		private function build():void
		{
			var bg:Shape = new Shape();
			bg.graphics.beginFill(UITheme.SKY_COLOR);
			bg.graphics.drawRect(0, 0, SCREEN_W, SCREEN_H);
			bg.graphics.endFill();
			addChild(bg);

			var title:TextField = UITheme.makeLabel("Character", 28, 0xFFFFFF, true);
			title.x = 40; title.y = 30;
			addChild(title);

			var so:SharedObject = SharedObject.getLocal(SO_NAME);
			var savedName:String = (so.data.name != null) ? so.data.name as String : "Player";

			nameInput = new TextField();
			nameInput.type = TextFieldType.INPUT;
			nameInput.border = true;
			nameInput.borderColor = 0xFFFFFF;
			nameInput.background = true;
			nameInput.backgroundColor = 0x000000;
			nameInput.textColor = 0xFFFFFF;
			nameInput.width = 220;
			nameInput.height = 28;
			nameInput.x = 40;
			nameInput.y = 90;
			nameInput.defaultTextFormat = new TextFormat(UITheme.FONT, 14, 0xFFFFFF);
			nameInput.text = savedName;
			nameInput.addEventListener(FocusEvent.FOCUS_OUT, function(e:FocusEvent):void { saveState(); });
			addChild(nameInput);

			preview = new Sprite();
			preview.x = 680;
			preview.y = 100;
			addChild(preview);

			buildSwatchRow("Skin Tone", SKIN_TONES, 150, function(i:int):void { skinIndex = i; redrawPreview(); saveState(); });
			buildSwatchRow("Shirt Color", SHIRT_COLORS, 230, function(i:int):void { shirtIndex = i; redrawPreview(); saveState(); });
			buildSwatchRow("Pants Color", PANTS_COLORS, 310, function(i:int):void { pantsIndex = i; redrawPreview(); saveState(); });

			var randomBtn:Sprite = UITheme.makeButton("Randomize", 160, 32);
			randomBtn.x = 40; randomBtn.y = 400;
			randomBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				skinIndex = int(Math.random() * SKIN_TONES.length);
				shirtIndex = int(Math.random() * SHIRT_COLORS.length);
				pantsIndex = int(Math.random() * PANTS_COLORS.length);
				redrawPreview();
				saveState();
			});
			addChild(randomBtn);

			var backBtn:Sprite = UITheme.makeButton("Back", 120, 36);
			backBtn.x = 40; backBtn.y = SCREEN_H - 56;
			backBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { saveState(); screens.show(homepage); });
			addChild(backBtn);
		}

		private function buildSwatchRow(label:String, colors:Array, y:Number, onPick:Function):void
		{
			var lbl:TextField = UITheme.makeLabel(label, 14, 0xFFFFFF, true);
			lbl.x = 40; lbl.y = y;
			addChild(lbl);

			// NOTE: swatches are Sprite, not Shape -- Shape doesn't extend
			// InteractiveObject and never dispatches MouseEvent, so a Shape
			// here would be an invisible dead click target. Sprite has the
			// same .graphics API plus real interactivity.
			for (var i:int = 0; i < colors.length; i++)
			{
				var swatch:Sprite = new Sprite();
				swatch.graphics.beginFill(colors[i] as uint);
				swatch.graphics.drawRect(0, 0, 28, 28);
				swatch.graphics.endFill();
				swatch.graphics.lineStyle(2, 0xFFFFFF, 0.8);
				swatch.graphics.drawRect(0, 0, 28, 28);
				swatch.x = 40 + i * 34;
				swatch.y = y + 26;
				swatch.buttonMode = true;
				addChild(swatch);

				var idx:int = i; // per-iteration capture for the closure below
				swatch.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onPick(idx); });
			}
		}

		private function redrawPreview():void
		{
			while (preview.numChildren > 0) preview.removeChildAt(0);

			var skin:uint = SKIN_TONES[skinIndex] as uint;
			var shirt:uint = SHIRT_COLORS[shirtIndex] as uint;
			var pants:uint = PANTS_COLORS[pantsIndex] as uint;

			// Blocky paperdoll: head, torso, two arms, two hands, two legs.
			// Same proportions are mirrored in js-pe/character.js's
			// drawPaperdoll() for visual consistency across stacks.
			drawBlock(preview, 20, 0, 40, 40, skin);    // head
			drawBlock(preview, 12, 40, 56, 60, shirt);  // torso
			drawBlock(preview, -4, 40, 16, 56, shirt);  // left arm
			drawBlock(preview, 68, 40, 16, 56, shirt);  // right arm
			drawBlock(preview, -4, 96, 16, 24, skin);   // left hand
			drawBlock(preview, 68, 96, 16, 24, skin);   // right hand
			drawBlock(preview, 12, 100, 26, 60, pants); // left leg
			drawBlock(preview, 42, 100, 26, 60, pants); // right leg
		}

		private function drawBlock(container:Sprite, x:Number, y:Number, w:Number, h:Number, color:uint):void
		{
			// Decorative only, no interactivity needed -- Shape is the
			// right (cheaper) choice here, unlike the swatches above.
			var s:Shape = new Shape();
			s.graphics.beginFill(color);
			s.graphics.drawRect(0, 0, w, h);
			s.graphics.endFill();
			s.graphics.lineStyle(1, 0x000000, 0.35);
			s.graphics.drawRect(0, 0, w, h);
			s.x = x; s.y = y;
			container.addChild(s);
		}
	}
}
