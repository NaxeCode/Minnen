package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.effects.particles.FlxEmitter;

class Player extends FlxSprite
{
	// Controls
	private var left:Bool = false;
	private var right:Bool = false;
	private var jump:Bool = false;
	private var releaseJump:Bool = false;

	// Current State
	private var state:FlxState;

    public function new(?X:Float = 0, ?Y:Float = 0, STATE:FlxState)
    {
        super(X, Y);

		state = STATE;

		initGraphics();
		initPhysics();

		//debug();
    }

	private function initGraphics():Void
	{
		loadGraphic(AssetPaths.CharSpriteSheet_WHITE__png, true, 200, 200);

		setFacingFlip(FlxObject.LEFT, true, false);
		setFacingFlip(FlxObject.RIGHT, false, false);

		//scale.scale(2);
		//updateHitbox();

		width -= 16;
		centerOffsets();
		height -= 12;

		animation.add("idle", [0, 1, 2], 5, true);
		animation.add("up", [3, 4, 5], 5, true);
		animation.add("down", [6, 7, 8], 5, true);
		animation.add("jump", [9, 10, 11], 5, true);
		animation.add("run", [12, 13, 14, 15, 16, 17, 18, 19], 10, true);

		animation.play("idle");

		FlxG.camera.follow(this, PLATFORMER, 0.1);
	}

	private function initPhysics():Void
	{
		maxVelocity.set(Reg._speed / 1.2, Reg._jumpPower * 1.5);
		acceleration.y = Reg._gravity;
		drag.set(Reg._dragX, 0);
	}

	override public function update(elapsed:Float):Void
	{
		if (Reg._canMove)
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
			Reg._jumpCount = 2;
		if (jump && Reg._jumpCount > 0)
		{
			velocity.y -= maxVelocity.y / 1.5;
			Reg._jumpCount--;
		}
		else if (releaseJump)
		{
			if (velocity.y < -30)
				velocity.y = -100;
		}
	}

	private function handlePhysics():Void
	{
		maxVelocity.set(Reg._speed / 1.2, Reg._jumpPower * 1.5);
		acceleration.y = Reg._gravity;
		drag.set(Reg._dragX, 0);
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

		if (this.justTouched(FlxObject.FLOOR))
		{
			state.forEachOfType(FlxEmitter, emitParticles);
		}
	}

	private function emitParticles(emitter:FlxEmitter):Void
	{
		emitter.setPosition(this.x + (this.width / 2), this.y + this.height);
		emitter.start(true, 0, 10);
	}
}