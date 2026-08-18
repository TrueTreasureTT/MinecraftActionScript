package ui
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	/**
	 * Minimal single-screen-at-a-time manager: holds the root container
	 * and swaps children in and out. No transition animation, no
	 * navigation stack -- every screen has its own explicit "Back" button
	 * rather than needing history/back-stack semantics, so this stays
	 * intentionally simple.
	 */
	public class ScreenManager
	{
		private var root:Sprite;
		private var current:DisplayObject;

		public function ScreenManager(root:Sprite)
		{
			this.root = root;
		}

		public function show(screen:DisplayObject):void
		{
			if (current != null && root.contains(current))
			{
				root.removeChild(current);
			}
			current = screen;
			root.addChild(current);
		}
	}
}
