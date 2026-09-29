package logworld;

import flixel.FlxG;
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;

/**
	Full-screen "found footage" pass for the log world: CRT barrel, edge colour
	fringing, desaturated sickly grade, grain, scanlines, a rolling VHS tracking
	band, a breathing vignette, and occasional signal-tear glitch bursts.

	Add `filter` to a camera's `filters` and call `update` every frame.
**/
class CreepyFilter
{
	static inline var SOURCE:String = "
		#pragma header

		uniform float uTime;
		uniform float uGlitch;
		uniform float uPulse;

		float hash(vec2 p)
		{
			return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
		}

		vec2 barrel(vec2 uv)
		{
			vec2 c = uv - 0.5;
			return 0.5 + c * (1.0 + 0.09 * dot(c, c));
		}

		void main(void)
		{
			vec2 screenUV = openfl_TextureCoordv;
			vec2 uv = barrel(screenUV);
			if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0)
			{
				gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
				return;
			}

			// VHS tracking band rolling slowly down the screen
			float band = smoothstep(0.035, 0.0, abs(uv.y - fract(uTime * 0.06)));
			uv.x += band * 0.004 * sin(uTime * 40.0 + uv.y * 300.0);

			// Signal tears during glitch bursts
			if (uGlitch > 0.0)
			{
				float row = floor(uv.y * 36.0);
				float tick = floor(uTime * 24.0);
				float tear = step(0.65, hash(vec2(row, tick)));
				uv.x += tear * (hash(vec2(row + 7.0, tick)) - 0.5) * 0.09 * uGlitch;
			}

			// Colour fringing, stronger toward the edges and during glitches
			vec2 c = uv - 0.5;
			float split = 0.0012 + dot(c, c) * 0.007 + uGlitch * 0.012;
			vec3 col = vec3(
				texture2D(bitmap, uv + vec2(split, 0.0)).r,
				texture2D(bitmap, uv).g,
				texture2D(bitmap, uv - vec2(split, 0.0)).b
			);

			// Drain the colour and push it toward a sick green-grey
			float lum = dot(col, vec3(0.299, 0.587, 0.114));
			col = mix(col, vec3(lum), 0.55) * vec3(0.94, 1.0, 0.9);
			col = pow(col, vec3(1.12));

			// Scanlines and grain
			col *= 0.93 + 0.07 * sin(screenUV.y * openfl_TextureSize.y * 3.14159);
			col += (hash(screenUV * openfl_TextureSize + fract(uTime) * 91.0) - 0.5) * 0.085;
			col += band * 0.06 * (hash(vec2(uv.y * 600.0, uTime)) - 0.5);

			// Vignette that slowly breathes in and out
			float vignette = smoothstep(0.9, 0.22, length(c) * (1.12 + uPulse * 0.18));
			col *= vignette;

			gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
		}
	";

	static inline var MIN_GLITCH_GAP:Float = 7;
	static inline var MAX_GLITCH_GAP:Float = 20;

	public var filter(default, null):ShaderFilter;

	var shader:FlxRuntimeShader;
	var time:Float = 0;
	var glitchLeft:Float = 0;
	var glitchStrength:Float = 0;
	var nextGlitch:Float;

	public function new()
	{
		shader = new FlxRuntimeShader(SOURCE);
		filter = new ShaderFilter(shader);
		nextGlitch = FlxG.random.float(MIN_GLITCH_GAP, MAX_GLITCH_GAP);
		push();
	}

	/** Kick off a burst right now, e.g. when something vanishes. **/
	public function glitch(duration = 0.25, strength = 1.0):Void
	{
		glitchLeft = duration;
		glitchStrength = strength;
	}

	public function update(elapsed:Float):Void
	{
		time += elapsed;

		nextGlitch -= elapsed;
		if (nextGlitch <= 0)
		{
			glitch(FlxG.random.float(0.08, 0.3), FlxG.random.float(0.4, 1));
			nextGlitch = FlxG.random.float(MIN_GLITCH_GAP, MAX_GLITCH_GAP);
		}
		if (glitchLeft > 0)
			glitchLeft -= elapsed;

		push();
	}

	function push():Void
	{
		shader.setFloat("uTime", time);
		shader.setFloat("uGlitch", glitchLeft > 0 ? glitchStrength : 0);
		shader.setFloat("uPulse", 0.5 + 0.5 * Math.sin(time * 0.45));
	}
}
