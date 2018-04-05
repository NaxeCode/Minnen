package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;

class Player extends FlxSprite
{
	// Controls
	private var left:Bool = false;
	private var right:Bool = false;
	private var jump:Bool = false;
	private var releaseJump:Bool = false;

	// Physics related attributes
	public static var _canMove:Bool = true;
	public static var _speed:Int = 230;
	public static var _dragX:Int = 1500;
	public static var _jumpPower:Int = 500;
	public static var _jumpCount:Int = 2;
	public static var _gravity:Int = 1350;

	// Current State
	private var state:FlxState;

    public function new(?X:Float = 0, ?Y:Float = 0, STATE:FlxState)
    {
        super(X, Y);

		initGraphics();
		initAnimation();

		initPhysics();

		//debug();
    }

	private function initGraphics():Void
	{
		loadGraphic(AssetPaths.CharSpriteSheet_WHITE__png, true, 200, 200);

		set_width(184);
		set_height(188);
		centerOffsets();

		setFacingFlip(FlxObject.LEFT, true, false);
		setFacingFlip(FlxObject.RIGHT, false, false);

		FlxG.camera.follow(this, PLATFORMER, 0.1);
	}

	private function initAnimation():Void
	{
		var frameRate:Int = 5;

		animation.add("idle", [0, 1, 2], frameRate, true);
		animation.add("up", [3, 4, 5], frameRate, true);
		animation.add("down", [6, 7, 8], frameRate, true);
		animation.add("jump", [9, 10, 11], frameRate, true);
		animation.add("run", [12, 13, 14, 15, 16, 17, 18, 19], frameRate * 2, true);

		animation.play("idle");
	}

	private function initPhysics():Void
	{
		handlePhysics();
	}

	override public function update(elapsed:Float):Void
	{
		handleMovement();
		handlePhysics();
		handleAnimation();
		super.update(elapsed);
	}

	private function handleMovement():Void
	{
		acceleration.x = 0;

		left = FlxG.keys.pressed.LEFT;
		right = FlxG.keys.pressed.RIGHT;
		jump = FlxG.keys.justPressed.S;
		releaseJump = FlxG.keys.justReleased.S;
		
		// Left movement
		if (left && !right)
		{
			facing = FlxObject.LEFT;
			if (isTouching(FlxObject.FLOOR))
				acceleration.x = -maxVelocity.x * 6;
			else
				acceleration.x = -maxVelocity.x * 4;
		}
		// Right movement
		if (right && !left)
		{
			facing = FlxObject.RIGHT;
			if (isTouching(FlxObject.FLOOR))
				acceleration.x = maxVelocity.x * 6;
			else
				acceleration.x = maxVelocity.x * 4;
		}

		if (isTouching(FlxObject.FLOOR))
			_jumpCount = 2;
		if (jump && _jumpCount > 0)
		{
			velocity.y -= maxVelocity.y / 1.5;
			_jumpCount--;
		}
		else if (releaseJump)
		{
			if (velocity.y < -30)
				velocity.y = -100;
		}
	}

	private function handlePhysics():Void
	{
		maxVelocity.set(_speed / 1.2, _jumpPower * 1.5);
		acceleration.y = _gravity;
		drag.set(_dragX, 0);
	}

	private function handleAnimation():Void
	{
		if (isTouching(FlxObject.FLOOR))
		{
			if (velocity.x != 0)
				animation.play("run");
			else
				animation.play("idle");
		}
		else
		{
			if (velocity.y != 0)
				animation.play("jump");
		}
	}
}