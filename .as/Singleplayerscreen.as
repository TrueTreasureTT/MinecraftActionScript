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
	 * Lists locally-saved "worlds" (name + created date), backed by
	 * SharedObject. Pressing Play is intentionally a labeled stub: this
	 * AS3 layer is the menu/UI shell, not a 3D voxel engine (that's the
	 * Haxe/OpenFL build, and eventually the JS/WebGL build) -- so Play
	 * records the selection rather than pretending to launch a renderer
	 * that doesn't exist in this file.
	 */
	public class SingleplayerScreen extends Sprite
	{
		private static const SCREEN_W:Number = 960;
		private static const SCREEN_H:Number = 640;
		private static const SO_NAME:String = "voxelpe_worlds";
		private static const PLACEHOLDER:String = "New World";

		private var screens:ScreenManager;
		private var homepage:Sprite;
		private var listContainer:Sprite;
		private var nameInput:TextField;
		private var statusLabel:TextField;

		public function SingleplayerScreen(screens:ScreenManager, homepage:Sprite)
		{
			this.screens = screens;
			this.homepage = homepage;
			build();
			refreshList();
		}

		private function build():void
		{
			var bg:Shape = new Shape();
			bg.graphics.beginFill(UITheme.SKY_COLOR);
			bg.graphics.drawRect(0, 0, SCREEN_W, SCREEN_H);
			bg.graphics.endFill();
			addChild(bg);

			var title:TextField = UITheme.makeLabel("Singleplayer", 28, 0xFFFFFF, true);
			title.x = 40; title.y = 30;
			addChild(title);

			nameInput = new TextField();
			nameInput.type = TextFieldType.INPUT;
			nameInput.border = true;
			nameInput.borderColor = 0xFFFFFF;
			nameInput.background = true;
			nameInput.backgroundColor = 0x000000;
			nameInput.textColor = 0xFFFFFF;
			nameInput.width = 300;
			nameInput.height = 28;
			nameInput.x = 40;
			nameInput.y = 80;
			nameInput.defaultTextFormat = new TextFormat(UITheme.FONT, 14, 0xFFFFFF);
			nameInput.text = PLACEHOLDER;
			nameInput.addEventListener(FocusEvent.FOCUS_IN, function(e:FocusEvent):void
			{
				if (nameInput.text == PLACEHOLDER) nameInput.text = "";
			});
			addChild(nameInput);

			var createBtn:Sprite = UITheme.makeButton("Create World", 160, 28);
			createBtn.x = 356; createBtn.y = 80;
			createBtn.addEventListener(MouseEvent.CLICK, onCreateWorld);
			addChild(createBtn);

			listContainer = new Sprite();
			listContainer.x = 40;
			listContainer.y = 130;
			addChild(listContainer);

			statusLabel = UITheme.makeLabel("", 12, 0xFFE08A, false);
			statusLabel.x = 40;
			statusLabel.y = SCREEN_H - 90;
			addChild(statusLabel);

			var backBtn:Sprite = UITheme.makeButton("Back", 120, 36);
			backBtn.x = 40; backBtn.y = SCREEN_H - 56;
			backBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { screens.show(homepage); });
			addChild(backBtn);
		}

		private function loadWorlds():Array
		{
			var so:SharedObject = SharedObject.getLocal(SO_NAME);
			var worlds:Array = so.data.worlds as Array;
			return worlds != null ? worlds : [];
		}

		private function saveWorlds(worlds:Array):void
		{
			var so:SharedObject = SharedObject.getLocal(SO_NAME);
			so.data.worlds = worlds;
			try { so.flush(); } catch (e:Error) {}
		}

		private function onCreateWorld(e:MouseEvent):void
		{
			var name:String = nameInput.text;
			if (name == null || name.replace(/^\s+|\s+$/g, "") == "")
			{
				statusLabel.text = "Enter a world name first.";
				return;
			}
			var worlds:Array = loadWorlds();
			worlds.push({ name: name, created: new Date().toString() });
			saveWorlds(worlds);
			statusLabel.text = "Created \"" + name + "\".";
			nameInput.text = PLACEHOLDER;
			refreshList();
		}

		private function refreshList():void
		{
			while (listContainer.numChildren > 0) listContainer.removeChildAt(0);

			var worlds:Array = loadWorlds();
			if (worlds.length == 0)
			{
				listContainer.addChild(UITheme.makeLabel("No saved worlds yet -- create one above.", 13, 0xCCCCCC, false));
				return;
			}

			for (var i:int = 0; i < worlds.length; i++)
			{
				var entry:Object = worlds[i];
				var row:Sprite = buildWorldRow(entry.name as String, entry.created as String, i);
				row.y = i * 44;
				listContainer.addChild(row);
			}
		}

		private function buildWorldRow(name:String, created:String, index:int):Sprite
		{
			var row:Sprite = UITheme.makePanel(600, 36);

			var label:TextField = UITheme.makeLabel(name + "  (" + created + ")", 13, 0xFFFFFF, false);
			label.x = 10; label.y = 8;
			row.addChild(label);

			var playBtn:Sprite = UITheme.makeButton("Play", 70, 26);
			playBtn.x = 440; playBtn.y = 5;
			playBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				statusLabel.text = "\"" + name + "\" selected -- handing off to a renderer isn't wired up in this menu shell yet.";
			});
			row.addChild(playBtn);

			var deleteBtn:Sprite = UITheme.makeButton("Delete", 70, 26);
			deleteBtn.x = 520; deleteBtn.y = 5;
			deleteBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				var worlds:Array = loadWorlds();
				worlds.splice(index, 1); // safe: `index` is a per-call parameter, not a shared loop variable, so each row's closure has its own fixed value
				saveWorlds(worlds);
				refreshList();
			});
			row.addChild(deleteBtn);

			return row;
		}
	}
}
