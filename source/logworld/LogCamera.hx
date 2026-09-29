package logworld;

import flixel.FlxG;

/**
	Result of projecting a flat world ground point onto the screen.
**/
class Projection
{
	public var sx:Float = 0;
	public var sy:Float = 0;
	public var scale:Float = 1;
	public var depth:Float = 0;

	/** Distance along the ground from the focus point, positive = away from the viewer. **/
	public var forward:Float = 0;

	public var visible:Bool = false;
	public var beyondHorizon:Bool = false;

	public function new() {}
}

/**
	The "rolling log" camera. Gameplay happens on a flat 2D world (x right, y down).
	For rendering, the world is wrapped around a cylinder whose axis runs along world x:
	walking "up" the screen rolls you over the top of the log, so distant ground curves
	down behind a horizon.

	3D space used for projection: X right, Y up, Z forward (away from viewer).
	The focus point sits on top of the cylinder at the origin. The camera is behind
	(-camBack on Z) and above (camHeight on Y) it, looking at a point lookAhead in front.

	The ground shader (LogGroundShader) runs the inverse of `project` per pixel,
	so keep the two in sync.
**/
class LogCamera
{
	// Tunables
	public static var radius:Float = 1600;
	public static var camHeight:Float = 900;
	public static var camBack:Float = 200;
	public static var lookAhead:Float = 200;
	public static var zoom:Float = 1.0;
	public static var curved:Bool = true;

	// World point the camera is centred on (usually eases toward the player)
	public static var focusX:Float = 0;
	public static var focusY:Float = 0;

	// Derived each frame by `refresh`
	public static var fy(default, null):Float;
	public static var fz(default, null):Float;
	public static var uy(default, null):Float;
	public static var uz(default, null):Float;
	public static var zoomFocal(default, null):Float;
	public static var screenCX(default, null):Float;
	public static var screenCY(default, null):Float;
	public static var horizonTheta(default, null):Float;
	public static var horizonY(default, null):Float;
	public static var fogStart(default, null):Float;
	public static var fogEnd(default, null):Float;

	static inline var NEAR:Float = 40;
	static inline var BEHIND_CULL:Float = -1.0;
	static inline var FLAT_FOG_START:Float = 900;
	static inline var FLAT_FOG_END:Float = 2400;

	static var scratch = new Projection();

	public static function refresh():Void
	{
		// Forward view direction (in the Y/Z plane) and its perpendicular "up"
		var dy = -camHeight;
		var dz = lookAhead + camBack;
		var len = Math.sqrt(dy * dy + dz * dz);
		fy = dy / len;
		fz = dz / len;
		uy = fz;
		uz = -fy;

		// Focal length chosen so the focus point is drawn at 1:1 (times zoom)
		zoomFocal = zoom * (-camHeight * fy + camBack * fz);

		screenCX = FlxG.width / 2;
		screenCY = FlxG.height / 2;

		if (curved)
		{
			// Tangent from the camera to the cylinder: (h + R)cos(t) - b sin(t) = R
			var a = camHeight + radius;
			var b = -camBack;
			var l = Math.sqrt(a * a + b * b);
			horizonTheta = Math.atan2(b, a) + Math.acos(radius / l);
			// Full fog a little past the horizon, so things rise over it before fading
			fogEnd = horizonTheta * radius * 1.25;
			fogStart = horizonTheta * radius * 0.5;

			project(focusX, focusY - horizonTheta * radius, scratch, true);
			horizonY = scratch.sy;
		}
		else
		{
			horizonTheta = Math.POSITIVE_INFINITY;
			horizonY = Math.NEGATIVE_INFINITY;
			fogStart = FLAT_FOG_START;
			fogEnd = FLAT_FOG_END;
		}
	}

	public static function project(wx:Float, wy:Float, out:Projection, ignoreHorizon = false):Projection
	{
		var x = wx - focusX;
		var f = focusY - wy;
		var y:Float;
		var z:Float;
		var behind = false;

		if (curved)
		{
			var theta = f / radius;
			// Far enough back to have rolled under the log; past this the projection
			// wraps around and would draw ghosts back on screen
			behind = theta < BEHIND_CULL;
			z = radius * Math.sin(theta);
			y = radius * Math.cos(theta) - radius;
			out.beyondHorizon = !ignoreHorizon && theta > horizonTheta;
		}
		else
		{
			z = f;
			y = 0;
			out.beyondHorizon = false;
		}

		var vy = y - camHeight;
		var vz = z + camBack;
		var depth = vy * fy + vz * fz;
		var up = vy * uy + vz * uz;

		out.forward = f;
		out.depth = depth;
		out.visible = depth > NEAR && !behind;
		if (!out.visible)
			return out;

		out.scale = zoomFocal / depth;
		out.sx = screenCX + x * out.scale;
		out.sy = screenCY - up * out.scale;
		return out;
	}

	/** 0 = clear, 1 = fully fogged. Matches the ground shader. **/
	public static function fog(forward:Float):Float
	{
		var t = (forward - fogStart) / (fogEnd - fogStart);
		t = t < 0 ? 0 : (t > 1 ? 1 : t);
		return t * t * (3 - 2 * t);
	}
}
