package ui
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	import flash.text.TextField;

	/**
	 * Settings: click-to-set bars (AS3 has no built-in Slider component
	 * outside the old Flex framework, so a click-along-the-track bar is
	 * the simplest reliable substitute) plus a render-distance stepper
	 * and an FPS toggle. Persisted via SharedObject.
	 */
	public class SettingsScreen extends Sprite
	{
		private static const SCREEN_W:Number = 960;
		private static const SCREEN_H:Number = 640;
		private static const SO_NAME:String = "voxelpe_settings";
		private static const RENDER_DISTANCE_OPTIONS:Array = [2, 4, 8, 16]; // chunks

		private var screens:ScreenManager;
		private var homepage:Sprite;

		private var musicVolume:int = 80;
		private var soundVolume:int = 100;
		private var mouseSensitivity:int = 50;
		private var renderDistanceIndex:int = 2;
		private var showFps:Boolean = false;

		private var renderLabel:TextField;
		private var fpsToggleLabel:TextField;

		public function SettingsScreen(screens:ScreenManager, homepage:Sprite)
		{
			this.screens = screens;
			this.homepage = homepage;
			loadState();
			build();
		}

		private function loadState():void
		{
			var so:SharedObject = SharedObject.getLocal(SO_NAME);
			if (so.data.musicVolume != null) musicVolume = so.data.musicVolume;
			if (so.data.soundVolume != null) soundVolume = so.data.soundVolume;
			if (so.data.mouseSensitivity != null) mouseSensitivity = so.data.mouseSensitivity;
			if (so.data.renderDistanceIndex != null) renderDistanceIndex = so.data.renderDistanceIndex;
			if (so.data.showFps != null) showFps = so.data.showFps;
		}

		private function saveState():void
		{
			var so:SharedObject = SharedObject.getLocal(SO_NAME);
			so.data.musicVolume = musicVolume;
			so.data.soundVolume = soundVolume;
			so.data.mouseSensitivity = mouseSensitivity;
			so.data.renderDistanceIndex = renderDistanceIndex;
			so.data.showFps = showFps;
			try { so.flush(); } catch (e:Error) {}
		}

		private function build():void
		{
			var bg:Shape = new Shape();
			bg.graphics.beginFill(UITheme.SKY_COLOR);
			bg.graphics.drawRect(0, 0, SCREEN_W, SCREEN_H);
			bg.graphics.endFill();
			addChild(bg);

			var title:TextField = UITheme.makeLabel("Settings", 28, 0xFFFFFF, true);
			title.x = 40; title.y = 30;
			addChild(title);

			buildBarRow("Music Volume", 100, musicVolume, 100, function(v:int):void { musicVolume = v; saveState(); });
			buildBarRow("Sound Volume", 160, soundVolume, 100, function(v:int):void { soundVolume = v; saveState(); });
			buildBarRow("Mouse Sensitivity", 220, mouseSensitivity, 100, function(v:int):void { mouseSensitivity = v; saveState(); });

			buildRenderDistanceRow(280);
			buildFpsToggleRow(340);

			var backBtn:Sprite = UITheme.makeButton("Back", 120, 36);
			backBtn.x = 40; backBtn.y = SCREEN_H - 56;
			backBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { screens.show(homepage); });
			addChild(backBtn);
		}

		/** Click-to-set bar: clicking anywhere along its width sets the value proportionally. Track must be Sprite (not Shape) since it needs to receive the click. */
		private function buildBarRow(label:String, y:Number, initial:int, max:int, onChange:Function):void
		{
			var lbl:TextField = UITheme.makeLabel(label, 14, 0xFFFFFF, true);
			lbl.x = 40; lbl.y = y;
			addChild(lbl);

			var trackW:Number = 300;
			var trackH:Number = 18;

			var track:Sprite = new Sprite();
			track.x = 260; track.y = y + 2;
			track.graphics.beginFill(0x000000, 0.5);
			track.graphics.drawRect(0, 0, trackW, trackH);
			track.graphics.endFill();
			track.graphics.lineStyle(1, 0xFFFFFF, 0.6);
			track.graphics.drawRect(0, 0, trackW, trackH);
			addChild(track);

			var fill:Shape = new Shape(); // decorative fill bar, no listener needed -- Shape is fine here
			fill.graphics.beginFill(UITheme.ACCENT_GREEN);
			fill.graphics.drawRect(0, 0, trackW * (initial / max), trackH);
			fill.graphics.endFill();
			track.addChild(fill);

			var valueLabel:TextField = UITheme.makeLabel(String(initial), 12, 0xFFFFFF, false);
			valueLabel.x = trackW + 12;
			valueLabel.y = 0;
			track.addChild(valueLabel);

			track.buttonMode = true;
			track.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				var ratio:Number = e.localX / trackW;
				if (ratio < 0) ratio = 0;
				if (ratio > 1) ratio = 1;
				var v:int = Math.round(ratio * max);

				fill.graphics.clear();
				fill.graphics.beginFill(UITheme.ACCENT_GREEN);
				fill.graphics.drawRect(0, 0, trackW * (v / max), trackH);
				fill.graphics.endFill();
				valueLabel.text = String(v);

				onChange(v);
			});
		}

		private function buildRenderDistanceRow(y:Number):void
		{
			var lbl:TextField = UITheme.makeLabel("Render Distance", 14, 0xFFFFFF, true);
			lbl.x = 40; lbl.y = y;
			addChild(lbl);

			renderLabel = UITheme.makeLabel(RENDER_DISTANCE_OPTIONS[renderDistanceIndex] + " chunks", 13, 0xFFFFFF, false);
			renderLabel.x = 420; renderLabel.y = y;
			addChild(renderLabel);

			var prevBtn:Sprite = UITheme.makeButton("<", 36, 28);
			prevBtn.x = 260; prevBtn.y = y - 2;
			prevBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				renderDistanceIndex = (renderDistanceIndex - 1 + RENDER_DISTANCE_OPTIONS.length) % RENDER_DISTANCE_OPTIONS.length;
				renderLabel.text = RENDER_DISTANCE_OPTIONS[renderDistanceIndex] + " chunks";
				saveState();
			});
			addChild(prevBtn);

			var nextBtn:Sprite = UITheme.makeButton(">", 36, 28);
			nextBtn.x = 310; nextBtn.y = y - 2;
			nextBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				renderDistanceIndex = (renderDistanceIndex + 1) % RENDER_DISTANCE_OPTIONS.length;
				renderLabel.text = RENDER_DISTANCE_OPTIONS[renderDistanceIndex] + " chunks";
				saveState();
			});
			addChild(nextBtn);
		}

		private function buildFpsToggleRow(y:Number):void
		{
			var lbl:TextField = UITheme.makeLabel("Show FPS Counter", 14, 0xFFFFFF, true);
			lbl.x = 40; lbl.y = y;
			addChild(lbl);

			var toggleBtn:Sprite = UITheme.makeButton(showFps ? "ON" : "OFF", 80, 30);
			toggleBtn.x = 260; toggleBtn.y = y - 2;
			fpsToggleLabel = toggleBtn.getChildByName("label") as TextField;
			toggleBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				showFps = !showFps;
				fpsToggleLabel.text = showFps ? "ON" : "OFF";
				saveState();
			});
			addChild(toggleBtn);
		}
	}
}
