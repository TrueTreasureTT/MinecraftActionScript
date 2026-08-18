package ui
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	/**
	 * Title screen: logo + five navigation buttons. Sub-screens are
	 * created lazily (on first visit) and cached, so switching back and
	 * forth preserves each screen's state -- e.g. unsent chat text, a
	 * half-filled "add server" form -- instead of rebuilding from scratch
	 * every time.
	 */
	public class Homepage extends Sprite
	{
		private var screens:ScreenManager;

		private static const SCREEN_W:Number = 960;
		private static const SCREEN_H:Number = 640;

		private var singleplayerScreen:SingleplayerScreen;
		private var multiplayerScreen:MultiplayerScreen;
		private var characterScreen:CharacterScreen;
		private var chatPanel:ChatPanel;
		private var settingsScreen:SettingsScreen;

		public function Homepage(screens:ScreenManager)
		{
			this.screens = screens;
			buildBackground();
			buildTitle();
			buildButtons();
		}

		private function buildBackground():void
		{
			var bg:Shape = new Shape();
			bg.graphics.beginFill(UITheme.SKY_COLOR);
			bg.graphics.drawRect(0, 0, SCREEN_W, SCREEN_H);
			bg.graphics.endFill();
			addChild(bg);
		}

		private function buildTitle():void
		{
			var title:TextField = UITheme.makeLabel("VOXEL PE", 42, 0xFFFFFF, true);
			title.x = (SCREEN_W - title.width) / 2;
			title.y = 90;
			addChild(title);

			var subtitle:TextField = UITheme.makeLabel("an original voxel sandbox -- not affiliated with Mojang", 12, 0xEFEFEF, false);
			subtitle.x = (SCREEN_W - subtitle.width) / 2;
			subtitle.y = 140;
			addChild(subtitle);
		}

		private function buildButtons():void
		{
			var labels:Array = ["Singleplayer", "Multiplayer", "Character", "Chat", "Settings"];
			var handlers:Array = [onSingleplayer, onMultiplayer, onCharacter, onChat, onSettings];

			var btnW:Number = 280;
			var btnH:Number = 48;
			var gap:Number = 14;
			var startY:Number = 220;

			for (var i:int = 0; i < labels.length; i++)
			{
				var btn:Sprite = UITheme.makeButton(labels[i] as String, btnW, btnH);
				btn.x = (SCREEN_W - btnW) / 2;
				btn.y = startY + i * (btnH + gap);
				btn.addEventListener(MouseEvent.CLICK, handlers[i]);
				addChild(btn);
			}
		}

		private function onSingleplayer(e:MouseEvent):void
		{
			if (singleplayerScreen == null) singleplayerScreen = new SingleplayerScreen(screens, this);
			screens.show(singleplayerScreen);
		}

		private function onMultiplayer(e:MouseEvent):void
		{
			if (multiplayerScreen == null) multiplayerScreen = new MultiplayerScreen(screens, this);
			screens.show(multiplayerScreen);
		}

		private function onCharacter(e:MouseEvent):void
		{
			if (characterScreen == null) characterScreen = new CharacterScreen(screens, this);
			screens.show(characterScreen);
		}

		private function onChat(e:MouseEvent):void
		{
			if (chatPanel == null) chatPanel = new ChatPanel(screens, this);
			screens.show(chatPanel);
		}

		private function onSettings(e:MouseEvent):void
		{
			if (settingsScreen == null) settingsScreen = new SettingsScreen(screens, this);
			screens.show(settingsScreen);
		}
	}
}
