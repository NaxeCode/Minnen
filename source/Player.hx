package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.gamepad.FlxGamepad;

class Player extends FlxSprite
{
	// Physics related attributes
	public static var _speed:Int = 230;
	public static var _dragX:Int = 1500;
	public static var _dragY:Int = 1500;
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
		acceleration.set(0, 0);

		Reg.gamepad = FlxG.gamepads.lastActive;

		if (Reg.gamepad != null)
			handleGamepad(Reg.gamepad);

		// Left movement
		if (Reg.left_Pressed() && !Reg.right_Pressed())
			move("left");
		
		// Right movement
		if (Reg.right_Pressed() && !Reg.left_Pressed())
			move("right");

		// Up movement
		if (Reg.up_Pressed() && !Reg.down_Pressed())
			move("up");
		
		// Down movement
		if (Reg.down_Pressed() && !Reg.up_Pressed())
			move("down");
	}

	private function move(direction:String):Void
	{
		var multiFactor:Int = 5;
		
		switch (direction)
		{
			case "left": 
				facing = FlxObject.LEFT;
				acceleration.x = -maxVelocity.x * multiFactor;
			case "right":
				facing = FlxObject.RIGHT;
				acceleration.x = maxVelocity.x * multiFactor;
			
			case "up":
				facing = FlxObject.UP;
				acceleration.y = -maxVelocity.y * multiFactor;
			case "down":
				facing = FlxObject.DOWN;
				acceleration.y = maxVelocity.y * multiFactor;
		}
	}

	private function handleGamepad(gamepad:FlxGamepad):Void
	{
		var value = gamepad.analog.value;
		gamepad.deadZone = 0.35;

		FlxG.watch.addQuick("leftStick", value.LEFT_STICK_X);

		if (value.LEFT_STICK_X < 0)
			move("left");
		if (value.LEFT_STICK_X > 0)
			move("right");
	}

	private function handlePhysics():Void
	{
		maxVelocity.set(_speed * 1.2, _speed * 1.5);
		drag.set(_dragX, _dragY);
	}

	private function handleAnimation():Void
	{
		if (velocity.x != 0 || velocity.y != 0)
			animation.play("run");
		else
			animation.play("idle");
	}
}