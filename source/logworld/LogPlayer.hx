package logworld;

import flixel.FlxG;
import tools.AssetPaths;
import tools.Reg;

/**
	Top-down walker on the flat world. "Up" walks away from the camera, over the log.
	Uses the spiral-head Minnen sheet: 200x200 frames, drawn facing right.
**/
class LogPlayer extends WorldSprite
{
	static inline var SPEED:Float = 280;
	static inline var RUN_SPEED:Float = 620;
	static inline var ACCEL:Float = 2400;
	static inline var DRAG:Float = 2000;

	/** 200px frames drawn at half size, so Minnen stands about 90 world px tall. **/
	static inline var ART_SCALE:Float = 0.5;

	/** When true, input comes from the fields below instead of the keyboard (demo recording). **/
	public var scripted:Bool = false;

	public var scriptX:Float = 0;
	public var scriptY:Float = 0;
	public var scriptRun:Bool = false;

	public function new(wx:Float, wy:Float)
	{
		super(wx, wy, AssetPaths.CharSpriteSheet_WHITE__png, 28, 16, 200, 200);
		scale.set(ART_SCALE, ART_SCALE);

		// Character is centred at x=96 with feet on y=190 inside each frame
		anchorX = 96 / 200;
		anchorY = 190 / 200;

		animation.add("idle", [0, 1, 2], 5, true);
		animation.add("walk", [12, 13, 14, 15, 16, 17, 18, 19], 10, true);
		animation.play("idle");

		maxVelocity.set(SPEED, SPEED);
		drag.set(DRAG, DRAG);
	}

	override public function update(elapsed:Float):Void
	{
		acceleration.set(0, 0);

		var inputX:Float = 0;
		var inputY:Float = 0;
		var run = false;
		if (scripted)
		{
			inputX = scriptX;
			inputY = scriptY;
			run = scriptRun;
		}
		else
		{
			if (Reg.left_Pressed() && !Reg.right_Pressed())
				inputX = -1;
			else if (Reg.right_Pressed() && !Reg.left_Pressed())
				inputX = 1;

			if (Reg.up_Pressed() && !Reg.down_Pressed())
				inputY = -1;
			else if (Reg.down_Pressed() && !Reg.up_Pressed())
				inputY = 1;

			run = FlxG.keys.pressed.SHIFT;
		}

		var speed = run ? RUN_SPEED : SPEED;
		maxVelocity.set(speed, speed);
		acceleration.set(inputX * ACCEL, inputY * ACCEL);

		super.update(elapsed);

		if (acceleration.x < 0)
			flipX = true;
		else if (acceleration.x > 0)
			flipX = false;

		animation.play(velocity.x != 0 || velocity.y != 0 ? "walk" : "idle");
	}
}
