package ui
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	/**
	 * Shared visual language for every menu screen: dark semi-transparent
	 * panels, white borders, a plain sans font -- matches the Haxe build's
	 * in-game HUD style. Centralizing button/label/panel construction here
	 * means each screen doesn't hand-roll its own slightly-different
	 * rounded-rect-plus-textfield code.
	 *
	 * IMPORTANT: interactive elements here are built on Sprite, never
	 * Shape. flash.display.Shape does NOT extend InteractiveObject, so a
	 * bare Shape never dispatches MouseEvent -- attaching a CLICK listener
	 * to one silently does nothing. Sprite has the same .graphics drawing
	 * API plus real interactivity, so it's the only correct choice for
	 * anything clickable. Shape is fine (and cheaper) for pure decoration.
	 */
	public class UITheme
	{
		public static const PANEL_BG:uint = 0x000000;
		public static const PANEL_ALPHA:Number = 0.55;
		public static const BORDER_COLOR:uint = 0xFFFFFF;
		public static const SKY_COLOR:uint = 0x7EC0EE;
		public static const ACCENT_GREEN:uint = 0x5B993D;
		public static const FONT:String = "_sans";

		public static function makeButton(label:String, w:Number, h:Number):Sprite
		{
			var btn:Sprite = new Sprite();
			drawButtonBackground(btn, w, h, false);

			var tf:TextField = new TextField();
			tf.name = "label"; // retrievable via getChildByName("label") if a caller needs to update text later
			tf.selectable = false;
			tf.mouseEnabled = false;
			tf.width = w;
			tf.height = 20;
			tf.y = (h - 20) / 2;
			var fmt:TextFormat = new TextFormat(FONT, 14, 0xFFFFFF);
			fmt.align = TextFormatAlign.CENTER;
			fmt.bold = true;
			tf.defaultTextFormat = fmt;
			tf.text = label;
			btn.addChild(tf);

			btn.buttonMode = true;
			btn.mouseChildren = false; // clicks on the label are handled by btn itself, not swallowed differently by the child

			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void
			{
				drawButtonBackground(btn, w, h, true);
			});
			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void
			{
				drawButtonBackground(btn, w, h, false);
			});

			return btn;
		}

		public static function drawButtonBackground(btn:Sprite, w:Number, h:Number, hover:Boolean):void
		{
			btn.graphics.clear();
			btn.graphics.beginFill(PANEL_BG, hover ? 0.75 : PANEL_ALPHA);
			btn.graphics.drawRect(0, 0, w, h);
			btn.graphics.endFill();
			btn.graphics.lineStyle(hover ? 2 : 1, BORDER_COLOR, hover ? 1.0 : 0.7);
			btn.graphics.drawRect(0, 0, w, h);
		}

		public static function makeLabel(text:String, size:int = 14, color:uint = 0xFFFFFF, bold:Boolean = false):TextField
		{
			var tf:TextField = new TextField();
			tf.selectable = false;
			tf.mouseEnabled = false;
			tf.autoSize = TextFieldAutoSize.LEFT;
			var fmt:TextFormat = new TextFormat(FONT, size, color);
			fmt.bold = bold;
			tf.defaultTextFormat = fmt;
			tf.text = text;
			return tf;
		}

		public static function makePanel(w:Number, h:Number):Sprite
		{
			var panel:Sprite = new Sprite();
			panel.graphics.beginFill(PANEL_BG, PANEL_ALPHA);
			panel.graphics.drawRect(0, 0, w, h);
			panel.graphics.endFill();
			panel.graphics.lineStyle(1, BORDER_COLOR, 0.5);
			panel.graphics.drawRect(0, 0, w, h);
			return panel;
		}
	}
}
