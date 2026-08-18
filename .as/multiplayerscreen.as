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
	 * Server list, mirroring classic Minecraft's "Add Server" address
	 * book pattern: stores name + host:port entries locally. "Connect" is
	 * a labeled stub -- there's no matchmaking or server backend here,
	 * just the address book. Wiring a real connection means writing a
	 * socket/WebSocket client against a server you actually run.
	 */
	public class MultiplayerScreen extends Sprite
	{
		private static const SCREEN_W:Number = 960;
		private static const SCREEN_H:Number = 640;
		private static const SO_NAME:String = "voxelpe_servers";

		private var screens:ScreenManager;
		private var homepage:Sprite;
		private var listContainer:Sprite;
		private var nameInput:TextField;
		private var addressInput:TextField;
		private var statusLabel:TextField;

		public function MultiplayerScreen(screens:ScreenManager, homepage:Sprite)
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

			var title:TextField = UITheme.makeLabel("Multiplayer", 28, 0xFFFFFF, true);
			title.x = 40; title.y = 30;
			addChild(title);

			nameInput = makeInput(40, 80, 200, "Server Name");
			addressInput = makeInput(256, 80, 200, "host:port");

			var addBtn:Sprite = UITheme.makeButton("Add Server", 140, 28);
			addBtn.x = 472; addBtn.y = 80;
			addBtn.addEventListener(MouseEvent.CLICK, onAddServer);
			addChild(addBtn);

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

		private function makeInput(x:Number, y:Number, w:Number, placeholder:String):TextField
		{
			var tf:TextField = new TextField();
			tf.type = TextFieldType.INPUT;
			tf.border = true;
			tf.borderColor = 0xFFFFFF;
			tf.background = true;
			tf.backgroundColor = 0x000000;
			tf.textColor = 0xFFFFFF;
			tf.width = w;
			tf.height = 28;
			tf.x = x;
			tf.y = y;
			tf.defaultTextFormat = new TextFormat(UITheme.FONT, 13, 0xFFFFFF);
			tf.text = placeholder;
			tf.addEventListener(FocusEvent.FOCUS_IN, function(e:FocusEvent):void
			{
				if (tf.text == placeholder) tf.text = "";
			});
			addChild(tf);
			return tf;
		}

		private function loadServers():Array
		{
			var so:SharedObject = SharedObject.getLocal(SO_NAME);
			var servers:Array = so.data.servers as Array;
			return servers != null ? servers : [];
		}

		private function saveServers(servers:Array):void
		{
			var so:SharedObject = SharedObject.getLocal(SO_NAME);
			so.data.servers = servers;
			try { so.flush(); } catch (e:Error) {}
		}

		private function onAddServer(e:MouseEvent):void
		{
			var name:String = nameInput.text;
			var address:String = addressInput.text;
			if (name == null || name == "" || address == null || address == "")
			{
				statusLabel.text = "Enter both a name and a host:port address.";
				return;
			}
			var servers:Array = loadServers();
			servers.push({ name: name, address: address });
			saveServers(servers);
			statusLabel.text = "Added \"" + name + "\".";
			refreshList();
		}

		private function refreshList():void
		{
			while (listContainer.numChildren > 0) listContainer.removeChildAt(0);

			var servers:Array = loadServers();
			if (servers.length == 0)
			{
				listContainer.addChild(UITheme.makeLabel("No servers added yet.", 13, 0xCCCCCC, false));
				return;
			}

			for (var i:int = 0; i < servers.length; i++)
			{
				var entry:Object = servers[i];
				var row:Sprite = buildServerRow(entry.name as String, entry.address as String, i);
				row.y = i * 44;
				listContainer.addChild(row);
			}
		}

		private function buildServerRow(name:String, address:String, index:int):Sprite
		{
			var row:Sprite = UITheme.makePanel(600, 36);

			var label:TextField = UITheme.makeLabel(name + "  --  " + address, 13, 0xFFFFFF, false);
			label.x = 10; label.y = 8;
			row.addChild(label);

			var connectBtn:Sprite = UITheme.makeButton("Connect", 90, 26);
			connectBtn.x = 420; connectBtn.y = 5;
			connectBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				statusLabel.text = "This screen stores addresses -- it doesn't dial them (no connection backend here).";
			});
			row.addChild(connectBtn);

			var deleteBtn:Sprite = UITheme.makeButton("Delete", 70, 26);
			deleteBtn.x = 520; deleteBtn.y = 5;
			deleteBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				var servers:Array = loadServers();
				servers.splice(index, 1);
				saveServers(servers);
				refreshList();
			});
			row.addChild(deleteBtn);

			return row;
		}
	}
}
