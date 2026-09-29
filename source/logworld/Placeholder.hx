package logworld;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRandom;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

/**
	Procedurally drawn stand-in art so the log-world prototype needs no assets.
	Swap any of these for real images later; WorldSprite only needs an FlxGraphic.
**/
class Placeholder
{
	public static inline var TILE:Int = 64;

	/** Ground texture pixels per world pixel. The shader maps world to texture proportionally,
		so a lower-res texture lets the world grow without blowing up memory. **/
	public static inline var TEX_SCALE:Float = 0.5;

	static inline var ROAD_EDGE:Float = 74;
	static inline var ROAD_SURFACE:Float = 58;

	/** Cross streets, as fractions of the map height. **/
	static var CROSS_STREETS = [0.3, 0.62];

	public static var PONDS = [
		{x: 1400.0, y: 1600.0, rx: 260.0, ry: 170.0},
		{x: 6300.0, y: 1500.0, rx: 340.0, ry: 200.0},
		{x: 2300.0, y: 5800.0, rx: 300.0, ry: 190.0},
		{x: 6700.0, y: 6700.0, rx: 220.0, ry: 150.0},
		{x: 1100.0, y: 3900.0, rx: 180.0, ry: 260.0},
	];

	/** The winding main road that runs up the length of the map. **/
	public static function roadX(worldW:Float, y:Float):Float
	{
		return worldW * 0.5 + Math.sin(y / 1300) * 500 + Math.sin(y / 260) * 220 + Math.sin(y / 97) * 40;
	}

	public static function crossStreetY(worldH:Float, index:Int, x:Float):Float
	{
		return worldH * CROSS_STREETS[index] + Math.sin(x / 340 + index * 2) * 140;
	}

	public static function crossStreetCount():Int
	{
		return CROSS_STREETS.length;
	}

	public static function nearRoad(worldW:Float, worldH:Float, x:Float, y:Float, margin:Float):Bool
	{
		if (Math.abs(x - roadX(worldW, y)) < margin)
			return true;
		for (i in 0...CROSS_STREETS.length)
			if (Math.abs(y - crossStreetY(worldH, i, x)) < margin)
				return true;
		return false;
	}

	public static function nearPond(x:Float, y:Float, margin:Float):Bool
	{
		for (p in PONDS)
		{
			var nx = (x - p.x) / (p.rx + margin);
			var ny = (y - p.y) / (p.ry + margin);
			if (nx * nx + ny * ny < 1)
				return true;
		}
		return false;
	}

	public static function ground(worldW:Int, worldH:Int):FlxGraphic
	{
		var texW = Std.int(worldW * TEX_SCALE);
		var texH = Std.int(worldH * TEX_SCALE);
		return paint("lw_ground_" + worldW + "x" + worldH, texW, texH, false, TEX_SCALE, function(bmp:BitmapData, g:Graphics)
		{
			var rand = new FlxRandom(7);
			var rect = new Rectangle();
			var tile = TILE * TEX_SCALE;

			// Checkerboard grass so the curvature reads clearly (drawn directly in texture pixels)
			for (ty in 0...Std.int(texH / tile) + 1)
				for (tx in 0...Std.int(texW / tile) + 1)
				{
					rect.setTo(tx * tile, ty * tile, tile, tile);
					bmp.fillRect(rect, (tx + ty) % 2 == 0 ? 0xFF1C211D : 0xFF20251F);
				}

			// Grass speckles
			for (i in 0...Std.int(texW * texH / 470))
			{
				rect.setTo(rand.int(0, texW), rand.int(0, texH), 2, 2);
				bmp.fillRect(rect, rand.bool() ? 0xFF2A2E26 : 0xFF141714);
			}

			// Everything below is drawn in world coordinates; paint() scales it to the texture

			// Dead, patchy grass
			for (i in 0...Std.int(worldW * worldH / 90000))
			{
				g.beginFill(rand.bool(60) ? 0x121512 : 0x2A251E, rand.float(0.35, 0.8));
				var bw = rand.float(40, 260);
				g.drawEllipse(rand.float(0, worldW), rand.float(0, worldH), bw, bw * rand.float(0.4, 0.9));
				g.endFill();
			}
			for (pass in 0...2)
			{
				var colour = pass == 0 ? 0x221C18 : 0x2E2620;
				var radius = pass == 0 ? ROAD_EDGE : ROAD_SURFACE;
				g.beginFill(colour);
				var y = 0.0;
				while (y < worldH)
				{
					g.drawCircle(roadX(worldW, y), y, radius);
					y += 12;
				}
				for (i in 0...CROSS_STREETS.length)
				{
					var x = 0.0;
					while (x < worldW)
					{
						g.drawCircle(x, crossStreetY(worldH, i, x), radius);
						x += 12;
					}
				}
				g.endFill();
			}

			// Dark rust stains and drag marks along the main road
			var sy = 300.0;
			while (sy < worldH)
			{
				if (rand.bool(35))
				{
					var sx = roadX(worldW, sy) + rand.float(-40, 40);
					g.beginFill(0x3A1715, rand.float(0.45, 0.8));
					g.drawEllipse(sx, sy, rand.float(20, 60), rand.float(12, 30));
					g.endFill();
					if (rand.bool(40))
					{
						g.beginFill(0x2E1210, 0.6);
						g.drawRect(sx + rand.float(-4, 4), sy, rand.float(4, 8), rand.float(60, 180));
						g.endFill();
					}
				}
				sy += 180;
			}

			// Black ponds with a dead shoreline
			for (p in PONDS)
			{
				g.beginFill(0x161B17);
				g.drawEllipse(p.x - p.rx - 16, p.y - p.ry - 16, (p.rx + 16) * 2, (p.ry + 16) * 2);
				g.endFill();
				g.beginFill(0x040506);
				g.drawEllipse(p.x - p.rx, p.y - p.ry, p.rx * 2, p.ry * 2);
				g.endFill();
			}

			// Dark hedge around the edge of the map
			g.beginFill(0x050605);
			g.drawRect(0, 0, worldW, 40);
			g.drawRect(0, worldH - 40, worldW, 40);
			g.drawRect(0, 0, 40, worldH);
			g.drawRect(worldW - 40, 0, 40, worldH);
			g.endFill();
		});
	}

	public static inline var TREE_VARIANTS:Int = 4;
	public static inline var STONE_VARIANTS:Int = 3;

	/** Bare, twisted dead tree. Each variant grows from its own seed. **/
	public static function deadTree(variant:Int):FlxGraphic
	{
		return paint("lw_deadtree_" + variant, 170, 240, true, 1, function(_, g:Graphics)
		{
			var rand = new FlxRandom(91 + variant * 17);
			branch(g, rand, 85, 240, -Math.PI / 2 + rand.float(-0.12, 0.12), rand.float(62, 78), 13, 5);
		});
	}

	static function branch(g:Graphics, rand:FlxRandom, x:Float, y:Float, angle:Float, length:Float, thickness:Float, depth:Int):Void
	{
		// Kinked limb: two segments with a slight bend
		var bend = angle + rand.float(-0.35, 0.35);
		var mx = x + Math.cos(angle) * length * 0.5;
		var my = y + Math.sin(angle) * length * 0.5;
		var ex = mx + Math.cos(bend) * length * 0.5;
		var ey = my + Math.sin(bend) * length * 0.5;

		g.lineStyle(thickness, 0x15120F, 1);
		g.moveTo(x, y);
		g.lineTo(mx, my);
		g.lineTo(ex, ey);
		g.lineStyle();

		if (depth <= 0)
			return;
		for (i in 0...rand.int(2, 3))
			branch(g, rand, ex, ey, bend + rand.float(-0.75, 0.75), length * rand.float(0.58, 0.76), Math.max(1.2, thickness * 0.6), depth - 1);
	}

	/** Crooked, weathered gravestone. **/
	public static function gravestone(variant:Int):FlxGraphic
	{
		return paint("lw_stone_" + variant, 70, 90, true, 1, function(_, g:Graphics)
		{
			var lean = [-6.0, 4.0, 9.0][variant % 3];
			var tone = [0x3E403D, 0x353734, 0x484A45][variant % 3];

			g.beginFill(tone);
			g.moveTo(14, 90);
			g.lineTo(14 + lean, 30);
			g.curveTo(35 + lean, 2, 56 + lean, 30);
			g.lineTo(56, 90);
			g.lineTo(14, 90);
			g.endFill();

			// Crack and worn inscription lines
			g.lineStyle(1.5, 0x1C1D1B, 1);
			g.moveTo(40 + lean * 0.6, 26);
			g.lineTo(34 + lean * 0.5, 44);
			g.lineTo(42 + lean * 0.4, 58);
			g.lineStyle(2, 0x2A2B29, 1);
			g.moveTo(24 + lean * 0.4, 50);
			g.lineTo(46 + lean * 0.4, 50);
			g.moveTo(26 + lean * 0.3, 60);
			g.lineTo(44 + lean * 0.3, 60);
			g.lineStyle();
		});
	}

	public static function lamp():FlxGraphic
	{
		return paint("lw_lamp", 90, 190, true, 1, function(_, g:Graphics)
		{
			// Sickly pale halo
			var r = 44.0;
			while (r > 8)
			{
				g.beginFill(0xCFE6C8, 0.06);
				g.drawCircle(45, 42, r);
				g.endFill();
				r -= 4;
			}
			// Bent pole
			g.lineStyle(7, 0x0F0F0F, 1);
			g.moveTo(45, 190);
			g.lineTo(45, 90);
			g.lineTo(52, 50);
			g.lineStyle();
			g.beginFill(0xE4F2DC);
			g.drawCircle(45, 42, 8);
			g.endFill();
		});
	}

	/** Grey house, boarded door. `redWindow` gives it one dim red window. **/
	public static function house(wall:Int, roof:Int, redWindow:Bool):FlxGraphic
	{
		return paint("lw_house_" + wall + "_" + roof + "_" + redWindow, 240, 240, true, 1, function(_, g:Graphics)
		{
			g.beginFill(wall);
			g.drawRect(20, 110, 200, 130);
			g.endFill();

			// Sagging roof
			g.beginFill(roof);
			g.moveTo(0, 114);
			g.lineTo(108, 14);
			g.lineTo(126, 22);
			g.lineTo(240, 114);
			g.lineTo(0, 114);
			g.endFill();

			// Windows: black, or one dim red
			g.beginFill(0x070707);
			g.drawRect(40, 140, 40, 36);
			g.endFill();
			g.beginFill(redWindow ? 0x5C1414 : 0x070707);
			g.drawRect(160, 140, 40, 36);
			g.endFill();

			// Boarded-up door
			g.beginFill(0x0C0B0A);
			g.drawRect(100, 170, 40, 70);
			g.endFill();
			g.lineStyle(5, 0x2E2720, 1);
			g.moveTo(94, 182);
			g.lineTo(146, 196);
			g.moveTo(94, 214);
			g.lineTo(146, 204);
			g.lineStyle();
		});
	}

	/** Tall, thin, faceless figure. **/
	public static function watcher():FlxGraphic
	{
		return paint("lw_watcher", 70, 260, true, 1, function(_, g:Graphics)
		{
			// Legs
			g.lineStyle(5, 0x050505, 1);
			g.moveTo(31, 260);
			g.lineTo(33, 170);
			g.moveTo(39, 260);
			g.lineTo(37, 170);
			// Overlong arms hanging past the knees
			g.lineStyle(4, 0x050505, 1);
			g.moveTo(26, 78);
			g.lineTo(14, 150);
			g.lineTo(12, 205);
			g.moveTo(44, 78);
			g.lineTo(56, 150);
			g.lineTo(58, 205);
			g.lineStyle();
			// Torso
			g.beginFill(0x050505);
			g.moveTo(24, 72);
			g.lineTo(46, 72);
			g.lineTo(42, 176);
			g.lineTo(28, 176);
			g.lineTo(24, 72);
			g.endFill();
			// Blank pale face
			g.beginFill(0xD9D8CF);
			g.drawEllipse(24, 28, 22, 34);
			g.endFill();
		});
	}

	public static function shadow(w:Int, h:Int, darkness = 0.45):FlxGraphic
	{
		return paint("lw_shadow_" + w + "x" + h + "_" + darkness, w, h, true, 1, function(_, g:Graphics)
		{
			// Stacked ellipses: soft edge, dense core
			var steps = 6;
			for (i in 0...steps)
			{
				var t = i / steps;
				g.beginFill(0x000000, darkness / steps * 1.6);
				g.drawEllipse(w * t / 2, h * t / 2, w * (1 - t), h * (1 - t));
				g.endFill();
			}
		});
	}

	static function paint(key:String, w:Int, h:Int, transparent:Bool, shapeScale = 1.0, draw:BitmapData->Graphics->Void):FlxGraphic
	{
		var cached = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		var bmp = new BitmapData(w, h, transparent, 0);
		var shape = new Shape();
		draw(bmp, shape.graphics);
		var matrix = new Matrix();
		matrix.scale(shapeScale, shapeScale);
		bmp.draw(shape, matrix, null, null, null, true);

		var graphic = FlxG.bitmap.add(bmp, false, key);
		graphic.persist = true;
		return graphic;
	}
}
