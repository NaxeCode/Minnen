package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxMath;

class Level1 extends FlxState
{
	public var level:TiledLevel;
	
	override public function create():Void
	{
		super.create();

        setProperties();
		initPlayer();
		addLevel();
	}

	private function setProperties():Void
	{
		FlxG.camera.antialiasing = true;
		FlxG.camera.fade(Reg.BGColor, 1, true);
		FlxG.mouse.visible = false;
		FlxG.cameras.bgColor = FlxColor.WHITE;
	}

	private function initPlayer():Void
	{
		Reg.player = new Player(0, 0, this);
	}

	private function addLevel():Void
	{
		addBG();
		addTiledLevel(AssetPaths.prototypeLvl__tmx, "assets/tiled/PrototypeLvl/", this);
	}

	private function addBG():Void
	{
		add(new FlxBackdrop(AssetPaths.LEVEL_1_BG__png));
	}

	private function addTiledLevel(lvlPath:String, ?lvlDirectory:String, state:FlxState):Void
	{
		/*
		#if !sys
		if (lvlDirectory == null)
			throw "You're required to provide a level directory if you're targetting Flash!";
		#else
		var path = new haxe.io.Path(lvlPath);
		lvlDirectory = path.dir;
		#end
		*/
		
		level = new TiledLevel(lvlPath, lvlDirectory, state);
		// Add backgrounds
		add(level.backgroundLayer);
		// Add static images
		add(level.imagesLayer);

		// Load player objects
		add(level.backgroundObjects);

		add(Reg.player);
		// Load player objects
		add(level.objectsLayer);
		// Load player objects
		add(level.foregroundObjects);

		// Add foreground tiles after adding level objects, so these tiles render on top of player
		add(level.foregroundTiles);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		level.collideWithLevel(level.objectsLayer);
	}
}