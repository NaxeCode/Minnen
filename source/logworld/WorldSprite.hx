package logworld;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.math.FlxRect;
import logworld.LogCamera.Projection;

/**
	A sprite that lives on the flat world but is drawn upright on the curved log.

	Its hitbox (x, y, width, height) is the footprint on the ground and is what
	collision uses. The graphic is drawn as a billboard: bottom-centre (or `anchorY`)
	pinned to the projected centre of the footprint, scaled by distance, fogged,
	and clipped against the horizon when it's rolling out of view.
**/
class WorldSprite extends FlxSprite
{
	public var proj(default, null) = new Projection();

	/** Fraction of the graphic's width centred over the ground point (mirrored when flipX). **/
	public var anchorX:Float = 0.5;

	/** Fraction of the graphic's height that sits on the ground point. 1 = feet. **/
	public var anchorY:Float = 1;

	/** Height above the ground in world pixels (hops, bobbing). **/
	public var lift:Float = 0;

	/** Use this instead of `alpha`; the fog pass rewrites the colour transform every draw. **/
	public var opacity:Float = 1;

	var clipBuffer = FlxRect.get();

	public function new(wx:Float, wy:Float, graphic:FlxGraphicAsset, footprintW:Float, footprintH:Float, frameW = 0, frameH = 0)
	{
		super();
		loadGraphic(graphic, frameW > 0, frameW, frameH);
		antialiasing = true;
		scrollFactor.set(0, 0);
		offset.set(0, 0);
		width = footprintW;
		height = footprintH;
		setGroundPosition(wx, wy);
	}

	public inline function groundX():Float
	{
		return x + width / 2;
	}

	public inline function groundY():Float
	{
		return y + height / 2;
	}

	public function setGroundPosition(wx:Float, wy:Float):Void
	{
		x = wx - width / 2;
		y = wy - height / 2;
	}

	public function refreshProjection():Void
	{
		LogCamera.project(groundX(), groundY(), proj);
	}

	override public function draw():Void
	{
		if (!proj.visible)
			return;

		var fog = LogCamera.fog(proj.forward);
		if (fog >= 1 || opacity <= 0)
			return;

		var s = proj.scale;
		origin.set(frameWidth * (flipX ? 1 - anchorX : anchorX), frameHeight * anchorY);

		var baseY = proj.sy - lift * s;
		if (proj.beyondHorizon)
		{
			// Only the part poking above the horizon line is visible
			var visibleRows = frameHeight * anchorY - (baseY - LogCamera.horizonY) / (s * scale.y);
			if (visibleRows <= 0)
				return;
			clipRect = clipBuffer.set(0, 0, frameWidth, Math.min(visibleRows, frameHeight));
		}
		else if (clipRect != null)
		{
			clipRect = null;
		}

		var oldX = x;
		var oldY = y;
		var oldScaleX = scale.x;
		var oldScaleY = scale.y;

		scale.set(oldScaleX * s, oldScaleY * s);
		x = proj.sx - origin.x;
		y = baseY - origin.y;

		var keep = 1 - fog;
		setColorTransform(keep, keep, keep, opacity, Std.int(LogGroundShader.FOG_R * 255 * fog), Std.int(LogGroundShader.FOG_G * 255 * fog),
			Std.int(LogGroundShader.FOG_B * 255 * fog), 0);

		super.draw();

		x = oldX;
		y = oldY;
		scale.set(oldScaleX, oldScaleY);
	}

	override public function destroy():Void
	{
		clipBuffer.put();
		super.destroy();
	}
}

/**
	A flat blob shadow that follows another WorldSprite's footprint.
**/
class WorldShadow extends WorldSprite
{
	var owner:WorldSprite;

	public function new(owner:WorldSprite, graphic:FlxGraphic)
	{
		super(owner.groundX(), owner.groundY(), graphic, 1, 1);
		this.owner = owner;
		anchorY = 0.5;
		solid = false;
	}

	override public function refreshProjection():Void
	{
		LogCamera.project(owner.groundX(), owner.groundY(), proj);
	}
}
