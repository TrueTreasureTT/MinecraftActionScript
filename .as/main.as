package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.ui.ContextMenu;
	import ui.Homepage;
	import ui.ScreenManager;

	/**
	 * Document class for the AS3 menu shell: Homepage, Singleplayer world
	 * list, Multiplayer server list, Character customization, local Chat,
	 * and Settings. This is the UI layer only -- no 3D voxel renderer is
	 * included (that's the Haxe/OpenFL build, and eventually the JS/WebGL
	 * build). "Play" and "Connect" in this shell are honest, labeled
	 * stubs rather than a fake launch into a game engine that doesn't
	 * exist in this file.
	 */
	public class Main extends Sprite
	{
		public function Main()
		{
			if (stage != null)
			{
				init();
			}
			else
			{
				addEventListener(Event.ADDED_TO_STAGE, function(e:Event):void { init(); });
			}
		}

		private function init():void
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			// Right-click could later be used for in-menu context actions;
			// suppressing the native menu now avoids a jarring browser
			// popup even though nothing currently binds to right-click.
			var menu:ContextMenu = new ContextMenu();
			menu.hideBuiltInItems();
			stage.contextMenu = menu;

			var screens:ScreenManager = new ScreenManager(this);
			var homepage:Homepage = new Homepage(screens);
			screens.show(homepage);
		}
	}
}
