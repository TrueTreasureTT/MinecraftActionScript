package ui
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.net.LocalConnection;
	import flash.net.SharedObject;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;

	/**
	 * Local chat -- explicitly NOT Mojang's chat or friends network (no
	 * such access exists for third-party projects; nothing here reaches
	 * outside this machine). Works between multiple instances of this SWF
	 * running in the same browser on the same origin, via LocalConnection
	 * -- e.g. two tabs both pointed at your localhost dev server. It does
	 * not reach across different machines; that would need a real socket
	 * server, which is future work, not something built here.
	 *
	 * Both tabs must be served from the same origin (e.g. both
	 * http://localhost:PORT/..., not one of them opened as a file://
	 * path) or LocalConnection won't be able to link them.
	 *
	 * Design note: a sent message is echoed into the sender's own log
	 * immediately rather than waiting to hear it back over
	 * LocalConnection. LocalConnection.send() reports genuine structural
	 * failures (bad connection name, etc) synchronously, but "nobody else
	 * is listening right now" is not one of them -- it's a silent no-op,
	 * not a catchable error -- so local echo is both more correct and
	 * matches how every real chat client behaves anyway.
	 */
	public class ChatPanel extends Sprite
	{
		private static const SCREEN_W:Number = 960;
		private static const SCREEN_H:Number = 640;
		private static const CHANNEL:String = "voxelpe_chat_channel";

		private var screens:ScreenManager;
		private var homepage:Sprite;
		private var log:TextField;
		private var input:TextField;

		private var receiver:LocalConnection;
		private var sender:LocalConnection;

		public function ChatPanel(screens:ScreenManager, homepage:Sprite)
		{
			this.screens = screens;
			this.homepage = homepage;
			build();
			setupLocalConnection();
		}

		private function build():void
		{
			var bg:Shape = new Shape();
			bg.graphics.beginFill(UITheme.SKY_COLOR);
			bg.graphics.drawRect(0, 0, SCREEN_W, SCREEN_H);
			bg.graphics.endFill();
			addChild(bg);

			var title:TextField = UITheme.makeLabel("Chat", 28, 0xFFFFFF, true);
			title.x = 40; title.y = 30;
			addChild(title);

			var notice:TextField = UITheme.makeLabel("Local chat between browser tabs on this machine -- not Mojang's chat or friends network.", 12, 0xFFE08A, false);
			notice.x = 40; notice.y = 68;
			addChild(notice);

			var logPanel:Sprite = UITheme.makePanel(700, 380);
			logPanel.x = 40; logPanel.y = 100;
			addChild(logPanel);

			log = new TextField();
			log.x = 50; log.y = 108;
			log.width = 680;
			log.height = 364;
			log.multiline = true;
			log.wordWrap = true;
			log.selectable = true;
			log.textColor = 0xFFFFFF;
			log.defaultTextFormat = new TextFormat(UITheme.FONT, 13, 0xFFFFFF);
			log.text = "-- chat started --\n";
			addChild(log);

			input = new TextField();
			input.type = TextFieldType.INPUT;
			input.border = true;
			input.borderColor = 0xFFFFFF;
			input.background = true;
			input.backgroundColor = 0x000000;
			input.textColor = 0xFFFFFF;
			input.width = 560;
			input.height = 30;
			input.x = 40;
			input.y = 494;
			input.defaultTextFormat = new TextFormat(UITheme.FONT, 14, 0xFFFFFF);
			input.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void
			{
				if (e.keyCode == Keyboard.ENTER) sendCurrentMessage();
			});
			addChild(input);

			var sendBtn:Sprite = UITheme.makeButton("Send", 100, 30);
			sendBtn.x = 610; sendBtn.y = 494;
			sendBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { sendCurrentMessage(); });
			addChild(sendBtn);

			var backBtn:Sprite = UITheme.makeButton("Back", 120, 36);
			backBtn.x = 40; backBtn.y = SCREEN_H - 56;
			backBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { screens.show(homepage); });
			addChild(backBtn);
		}

		private function setupLocalConnection():void
		{
			receiver = new LocalConnection();
			receiver.client = this;
			try
			{
				receiver.connect(CHANNEL);
			}
			catch (err:Error)
			{
				appendLine("(local connection already active)");
			}

			sender = new LocalConnection();
		}

		/**
		 * Invoked by OTHER instances' `sender.send(CHANNEL, "receiveMessage", ...)`.
		 * Must be public -- LocalConnection calls it as a client method.
		 */
		public function receiveMessage(fromName:String, text:String):void
		{
			appendLine(fromName + ": " + text);
		}

		private function sendCurrentMessage():void
		{
			var text:String = input.text;
			if (text == null || text.replace(/^\s+|\s+$/g, "") == "") return;

			var name:String = currentPlayerName();
			appendLine(name + " (you): " + text);

			try
			{
				sender.send(CHANNEL, "receiveMessage", name, text);
			}
			catch (err:Error)
			{
				// Catches structural send failures only (e.g. malformed
				// connection name). "No other tab is listening" is a
				// silent no-op in LocalConnection, not an exception, so
				// this catch existing is defensive, not a delivery signal.
			}

			input.text = "";
		}

		/** Reads the live name from CharacterScreen's save data on every send, so a mid-session rename shows up immediately without needing a lifecycle hook. */
		private function currentPlayerName():String
		{
			var so:SharedObject = SharedObject.getLocal("voxelpe_character");
			return (so.data.name != null && String(so.data.name).length > 0) ? so.data.name as String : "Player";
		}

		private function appendLine(line:String):void
		{
			log.appendText(line + "\n");
			log.scrollV = log.maxScrollV;
		}
	}
}
