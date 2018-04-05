package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxMath;

class Level1 extends FlxState
{
	public var level:TiledLevel;

	private var tooth:FlxSprite;

	// Handles Particle Generation
	public var _emitter:FlxEmitter;

	// INITIALIZATION FUNCTIONS START HERE ---------------
	override public function create():Void
	{
		super.create();

        setProperties();
		addLevel();
	}

	private function setProperties():Void
	{
		FlxG.camera.antialiasing = true;
		FlxG.camera.fade(Reg.BGColor, 1, true);
		FlxG.mouse.visible = false;
		FlxG.cameras.bgColor = FlxColor.WHITE;// Reg.BGColor;
		//FlxG.sound.playMusic(AssetPaths.Dimensions__mp3, Reg.musicVolume, true);
	}

	private function addLevel():Void
	{
		addBG();
		addTiledLevel(AssetPaths.level1__tmx, "assets/tiled/Level1/", this);
		addEmitter();
		createTooth();
	}

	private function addBG():Void
	{
		add(new FlxBackdrop(AssetPaths.LEVEL_1_BG__png));
	}

	private function addTiledLevel(lvlPath:String, lvlDirectory:String, state:FlxState):Void
	{
		level = new TiledLevel(lvlPath, lvlDirectory, state);
		// Add backgrounds
		add(level.backgroundLayer);
		// Add static images
		add(level.imagesLayer);

		// Load player objects
		add(level.backgroundObjects);
		// Load player objects
		add(level.objectsLayer);
		// Load player objects
		add(level.foregroundObjects);

		// Add foreground tiles after adding level objects, so these tiles render on top of player
		add(level.foregroundTiles);
	}
	
	private function addEmitter():Void
	{
		var particles:Int = 200;
		var colors:Array<Int> = [Reg.mainColor, Reg.BGColor];
		_emitter = new FlxEmitter(FlxG.width / 2 , FlxG.height / 2, particles);
		_emitter.acceleration.start.min.y = -50;
		_emitter.acceleration.start.max.y = -100;
		_emitter.acceleration.end.min.y = -700;
		_emitter.acceleration.end.max.y = -900;

		for (i in 0...particles)
		{
			var particle = new FlxParticle();
			particle.makeGraphic(2, 2, FlxG.random.getObject(colors));
			particle.exists = false;
			_emitter.add(particle);
		}

		add(_emitter);
	}

	private function createTooth():Void
	{
		tooth = new FlxSprite(0, 0).makeGraphic(640, 360);
		tooth.screenCenter();
		tooth.alpha = 0.0;
		tooth.scrollFactor.set(0, 0);
		add(tooth);
	}
	// INITIALIZATION FUNCTIONS END HERE


	// =====================================================


	// UPDATE RELATED FUNCTIONS
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

        handleInput();

		level.collideWithLevel(level.objectsLayer);

		level.objectsLayer.forEachOfType(Player, checkEndLevel);
	}

	private function checkEndLevel(plr:Player):Void
	{
		if (FlxMath.isDistanceToPointWithin(plr, FlxPoint.get(3121, 1668), 200))
		{
			updateTooth();
		}
	}

	private function updateTooth():Void
	{
		tooth.alpha = 1.0;
		if (FlxG.keys.anyJustPressed([SPACE, Z]))
		{
			FlxG.keys.enabled = false;
            FlxG.camera.fade(FlxColor.WHITE, 5, false, transitionToNextLvl);
		}
	}

	private function handleInput():Void
	{
		if (FlxG.keys.justPressed.BACKSPACE)
			FlxG.switchState(new MenuState());
	}
}