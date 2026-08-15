package;

import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.ui.ContextMenu;
import voxel.Game;

class Main extends Sprite
{
	public function new()
	{
		super();

		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;

		// Right-click is used for block placement, so the native/browser
		// context menu must be suppressed or it'll pop up over the game on
		// every placement attempt. An empty ContextMenu with hideBuiltInItems
		// still fires MOUSE events normally -- it just stops the visual menu.
		var menu = new ContextMenu();
		menu.hideBuiltInItems();
		stage.contextMenu = menu;

		addChild(new Game());
	}
}
