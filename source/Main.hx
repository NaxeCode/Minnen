package;

import openfl.Lib;
import flixel.FlxG;
import flixel.FlxGame;
import menu.MenuState;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import tools.Reg;

class Main extends Sprite
{
	public function new()
	{
		super();

		#if !FLX_NO_DEBUG
		stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_onKeyDown);
		#end

		// Build with -Dskipmenu to boot straight into the log world prototype
		addChild(new FlxGame(1920, 1080, #if skipmenu planes.LogWorld #else MenuState #end, 60, 60, true, true));

		Reg.setupRegistry();
	}

	private function stage_onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.F:
				FlxG.fullscreen = !FlxG.fullscreen;
			case Keyboard.A:
				FlxG.camera.antialiasing = !FlxG.camera.antialiasing;
			#if (!flash && !html5)
			case Keyboard.ESCAPE:
				Sys.exit(1);
			#end
		}
	}
}
