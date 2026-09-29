package logworld;

import flixel.FlxG;
import flixel.addons.display.FlxRuntimeShader;

/**
	Applied to a full-screen sprite whose bitmap is the whole flat ground map.
	For every screen pixel it casts a ray from the LogCamera, intersects the
	cylinder, and samples the ground map at the matching world position.
**/
class LogGroundShader extends FlxRuntimeShader
{
	static inline var SOURCE:String = "
		#pragma header

		uniform float uScreenW;
		uniform float uScreenH;
		uniform float uWorldW;
		uniform float uWorldH;
		uniform float uFocusX;
		uniform float uFocusY;
		uniform float uRadius;
		uniform float uCurved;
		uniform float uCamHeight;
		uniform float uCamBack;
		uniform float uZoomFocal;
		uniform float uFy;
		uniform float uFz;
		uniform float uUy;
		uniform float uUz;
		uniform float uFogStart;
		uniform float uFogEnd;
		uniform float uHorizonY;

		const vec3 SKY_TOP = vec3(0.005, 0.006, 0.006);
		const vec3 SKY_LOW = vec3(0.15, 0.16, 0.145);
		const vec3 FOG = vec3(0.15, 0.16, 0.145);
		const vec3 VOID = vec3(0.01, 0.01, 0.01);

		vec3 sky(vec2 px)
		{
			// Near-black sky thickening into a grey mist band just above the horizon
			float mist = smoothstep(uHorizonY - 280.0, uHorizonY, px.y);
			return mix(SKY_TOP, SKY_LOW, mist * mist);
		}

		void main(void)
		{
			vec2 px = openfl_TextureCoordv * vec2(uScreenW, uScreenH);
			float dx = px.x - uScreenW * 0.5;
			float dUp = uScreenH * 0.5 - px.y;
			vec3 dir = normalize(vec3(dx, uUy * dUp + uFy * uZoomFocal, uUz * dUp + uFz * uZoomFocal));

			bool hit = false;
			float worldX = 0.0;
			float forward = 0.0;

			if (uCurved > 0.5)
			{
				// Cylinder axis along X at (Y = -R, Z = 0); ray origin relative to that axis
				float oY = uCamHeight + uRadius;
				float oZ = -uCamBack;
				float a = dir.y * dir.y + dir.z * dir.z;
				float b = 2.0 * (oY * dir.y + oZ * dir.z);
				float c = oY * oY + oZ * oZ - uRadius * uRadius;
				float disc = b * b - 4.0 * a * c;
				if (disc >= 0.0)
				{
					float t = (-b - sqrt(disc)) / (2.0 * a);
					if (t > 0.0)
					{
						forward = atan(oZ + t * dir.z, oY + t * dir.y) * uRadius;
						worldX = t * dir.x;
						hit = true;
					}
				}
			}
			else if (dir.y < 0.0)
			{
				float t = -uCamHeight / dir.y;
				forward = -uCamBack + t * dir.z;
				worldX = t * dir.x;
				hit = true;
			}

			if (!hit)
			{
				gl_FragColor = vec4(sky(px), 1.0);
				return;
			}

			vec2 w = vec2(uFocusX + worldX, uFocusY - forward);
			vec3 col = VOID;
			if (w.x >= 0.0 && w.y >= 0.0 && w.x <= uWorldW && w.y <= uWorldH)
				col = texture2D(bitmap, w / vec2(uWorldW, uWorldH)).rgb;

			float fog = smoothstep(uFogStart, uFogEnd, forward);
			gl_FragColor = vec4(mix(col, FOG, fog), 1.0);
		}
	";

	public static inline var FOG_R:Float = 0.15;
	public static inline var FOG_G:Float = 0.16;
	public static inline var FOG_B:Float = 0.145;

	public function new(worldW:Float, worldH:Float)
	{
		super(SOURCE);
		setFloat("uWorldW", worldW);
		setFloat("uWorldH", worldH);
	}

	/** Push the current LogCamera state. Call after LogCamera.refresh(). **/
	public function sync():Void
	{
		setFloat("uScreenW", FlxG.width);
		setFloat("uScreenH", FlxG.height);
		setFloat("uFocusX", LogCamera.focusX);
		setFloat("uFocusY", LogCamera.focusY);
		setFloat("uRadius", LogCamera.radius);
		setFloat("uCurved", LogCamera.curved ? 1 : 0);
		setFloat("uCamHeight", LogCamera.camHeight);
		setFloat("uCamBack", LogCamera.camBack);
		setFloat("uZoomFocal", LogCamera.zoomFocal);
		setFloat("uFy", LogCamera.fy);
		setFloat("uFz", LogCamera.fz);
		setFloat("uUy", LogCamera.uy);
		setFloat("uUz", LogCamera.uz);
		setFloat("uFogStart", LogCamera.fogStart);
		setFloat("uFogEnd", LogCamera.fogEnd);
		setFloat("uHorizonY", LogCamera.curved ? LogCamera.horizonY : 0);
	}
}
