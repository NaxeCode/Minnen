package planes;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import logworld.CreepyFilter;
import logworld.LogCamera;
import logworld.LogGroundShader;
import logworld.LogPlayer;
import logworld.Placeholder;
import logworld.WorldSprite;
import menu.MenuState;

/**
	Prototype of the Animal Crossing style "rolling log" world, built from placeholder art.

	Debug keys:
	  1 / 2   radius (curvature)     3 / 4   camera height
	  5 / 6   camera distance        7 / 8   zoom
	  C       toggle curve on/off    H       toggle this help
	  BACKSPACE back to menu
**/
class LogWorld extends FlxState
{
	static inline var WORLD_W:Int = 8192;
	static inline var WORLD_H:Int = 8192;
	static inline var TREE_COUNT:Int = 1500;
	static inline var ROCK_COUNT:Int = 300;
	static inline var FOCUS_EASE:Float = 6;
	static inline var WATCHER_COUNT:Int = 8;
	static inline var WATCHER_VANISH_DIST:Float = 560;
	static inline var DEAD_LAMP_CHANCE:Int = 15;

	var groundShader:LogGroundShader;
	var shadows:FlxTypedGroup<WorldSprite>;
	var entities:FlxTypedGroup<WorldSprite>;
	var obstacles:FlxTypedGroup<WorldSprite>;
	var player:LogPlayer;
	var hud:FlxText;
	var creepy:CreepyFilter;
	var lamps:Array<{sprite:WorldSprite, dead:Bool, flickerLeft:Float}> = [];
	var watchers:Array<WorldSprite> = [];
	var rand = new FlxRandom(1337);

	#if demo
	/**
		Scripted walk for recording showcase footage: build with -Ddemo -Dskipmenu.
		Headings are compass degrees (0 = up the screen, 90 = right) and sweep smoothly
		from `from` to `to` over each step. `move: false` stands still.
	**/
	static var DEMO_ROUTE = [
		{until: 2.0, from: 0.0, to: 0.0, move: false, run: false}, // stand through the fade-in
		{until: 5.5, from: 0.0, to: 0.0, move: true, run: false}, // up the road toward the first watcher
		{until: 8.0, from: 0.0, to: 90.0, move: true, run: false}, // arc off to the right
		{until: 9.2, from: 90.0, to: 90.0, move: false, run: false}, // pause
		{until: 12.0, from: 90.0, to: -60.0, move: true, run: false}, // swing back round through up
		{until: 14.5, from: -60.0, to: -30.0, move: true, run: true}, // run up and to the left
		{until: 18.0, from: -30.0, to: 330.0, move: true, run: false}, // walk a full circle
		{until: 19.5, from: 135.0, to: 160.0, move: true, run: false}, // drift back toward the camera
		{until: 20.5, from: 160.0, to: 160.0, move: false, run: false}, // pause
		{until: 23.0, from: 0.0, to: 30.0, move: true, run: true}, // run up, weaving
		{until: 25.5, from: 30.0, to: -25.0, move: true, run: true},
		{until: 27.0, from: -25.0, to: -25.0, move: false, run: false},
	];

	var demoTime:Float = 0;
	#end

	override public function create():Void
	{
		super.create();

		FlxG.mouse.visible = false;
		FlxG.cameras.bgColor = FlxColor.BLACK;
		FlxG.worldBounds.set(-64, -64, WORLD_W + 128, WORLD_H + 128);

		groundShader = new LogGroundShader(WORLD_W, WORLD_H);
		var ground = new FlxSprite();
		ground.loadGraphic(Placeholder.ground(WORLD_W, WORLD_H));
		ground.setGraphicSize(FlxG.width, FlxG.height);
		ground.updateHitbox();
		ground.setPosition(0, 0);
		ground.scrollFactor.set(0, 0);
		ground.antialiasing = true;
		ground.shader = groundShader;
		add(ground);

		shadows = new FlxTypedGroup<WorldSprite>();
		entities = new FlxTypedGroup<WorldSprite>();
		obstacles = new FlxTypedGroup<WorldSprite>();
		add(shadows);
		add(entities);

		populate();

		var spawnY = WORLD_H - 300.0;
		player = new LogPlayer(Placeholder.roadX(WORLD_W, spawnY), spawnY);
		addEntity(player, Placeholder.shadow(64, 22, 0.8));

		spawnWatchers();

		LogCamera.focusX = player.groundX();
		LogCamera.focusY = player.groundY();

		// The world camera gets the found-footage filter; the debug text sits on a clean camera above it
		creepy = new CreepyFilter();
		FlxG.camera.filters = [creepy.filter];

		var hudCamera = new FlxCamera();
		hudCamera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(hudCamera, false);

		hud = new FlxText(16, 16, 0, "", 18);
		hud.scrollFactor.set(0, 0);
		hud.cameras = [hudCamera];
		add(hud);

		FlxG.camera.fade(FlxColor.BLACK, 1, true);

		#if demo
		FlxG.autoPause = false;
		hud.visible = false;
		player.scripted = true;
		#end
	}

	#if demo
	function updateDemo(elapsed:Float):Void
	{
		demoTime += elapsed;
		var stepStart = 0.0;
		for (step in DEMO_ROUTE)
		{
			if (demoTime < step.until)
			{
				var t = (demoTime - stepStart) / (step.until - stepStart);
				var heading = (step.from + (step.to - step.from) * t) * Math.PI / 180;
				player.scriptX = step.move ? Math.sin(heading) : 0;
				player.scriptY = step.move ? -Math.cos(heading) : 0;
				player.scriptRun = step.run;
				return;
			}
			stepStart = step.until;
		}
		Sys.exit(0);
	}
	#end

	function populate():Void
	{

		// Spatial grid of placed objects so spacing checks stay cheap with thousands of props
		var cellSize = 256;
		var cols = Std.int(WORLD_W / cellSize) + 1;
		var rows = Std.int(WORLD_H / cellSize) + 1;
		var grid:Array<Array<FlxPoint>> = [for (i in 0...cols * rows) []];

		function clearOf(x:Float, y:Float, dist:Float):Bool
		{
			var cx = Std.int(x / cellSize);
			var cy = Std.int(y / cellSize);
			for (gy in cy - 1...cy + 2)
				for (gx in cx - 1...cx + 2)
				{
					if (gx < 0 || gy < 0 || gx >= cols || gy >= rows)
						continue;
					for (p in grid[gy * cols + gx])
						if ((p.x - x) * (p.x - x) + (p.y - y) * (p.y - y) < dist * dist)
							return false;
				}
			return true;
		}

		function place(sprite:WorldSprite, shadow:Null<FlxGraphic>):Void
		{
			addObstacle(sprite, shadow);
			var gx = Std.int(sprite.groundX() / cellSize);
			var gy = Std.int(sprite.groundY() / cellSize);
			grid[gy * cols + gx].push(FlxPoint.get(sprite.groundX(), sprite.groundY()));
		}

		function inBounds(x:Float, y:Float):Bool
		{
			return x > 120 && y > 120 && x < WORLD_W - 120 && y < WORLD_H - 120;
		}

		var palette = [
			{wall: 0x3A3B38, roof: 0x121212},
			{wall: 0x33302C, roof: 0x171413},
			{wall: 0x2E3230, roof: 0x0F1110},
			{wall: 0x403C38, roof: 0x1A1716},
		];
		var houseCount = 0;
		function tryHouse(x:Float, y:Float):Void
		{
			if (!inBounds(x, y) || Placeholder.nearPond(x, y, 180) || !clearOf(x, y, 260))
				return;
			// Keep houses off the other road too
			if (Placeholder.nearRoad(WORLD_W, WORLD_H, x, y, 160))
				return;
			var c = palette[houseCount % palette.length];
			var redWindow = houseCount % 3 == 1;
			houseCount++;
			place(new WorldSprite(x, y, Placeholder.house(c.wall, c.roof, redWindow), 200, 50), Placeholder.shadow(230, 40));
		}

		function tryLamp(x:Float, y:Float):Void
		{
			if (!inBounds(x, y) || Placeholder.nearPond(x, y, 40) || !clearOf(x, y, 140))
				return;
			var lamp = new WorldSprite(x, y, Placeholder.lamp(), 12, 10);
			place(lamp, Placeholder.shadow(26, 10));
			lamps.push({sprite: lamp, dead: rand.bool(DEAD_LAMP_CHANCE), flickerLeft: 0});
		}

		// Houses and lamps line the main road...
		var side = 1;
		var y = 400.0;
		while (y < WORLD_H - 200)
		{
			tryHouse(Placeholder.roadX(WORLD_W, y) + side * 250, y);
			y += 650;
			side = -side;
		}
		y = 200.0;
		while (y < WORLD_H - 150)
		{
			tryLamp(Placeholder.roadX(WORLD_W, y) + side * 105, y);
			y += 280;
			side = -side;
		}

		// ...and the cross streets
		for (i in 0...Placeholder.crossStreetCount())
		{
			var x = 500.0;
			while (x < WORLD_W - 300)
			{
				tryHouse(x, Placeholder.crossStreetY(WORLD_H, i, x) + side * 250);
				x += 800;
				side = -side;
			}
			x = 300.0;
			while (x < WORLD_W - 150)
			{
				tryLamp(x, Placeholder.crossStreetY(WORLD_H, i, x) + side * 105);
				x += 320;
				side = -side;
			}
		}

		// Trees and rocks scattered everywhere else
		var attempts = 0;
		var trees = 0;
		while (trees < TREE_COUNT && attempts < TREE_COUNT * 25)
		{
			attempts++;
			var tx = rand.float(120, WORLD_W - 120);
			var ty = rand.float(120, WORLD_H - 120);
			if (Placeholder.nearRoad(WORLD_W, WORLD_H, tx, ty, 150) || Placeholder.nearPond(tx, ty, 60) || !clearOf(tx, ty, 110))
				continue;
			var tree = Placeholder.deadTree(rand.int(0, Placeholder.TREE_VARIANTS - 1));
			place(new WorldSprite(tx, ty, tree, 26, 16), Placeholder.shadow(70, 22));
			trees++;
		}

		var rocks = 0;
		attempts = 0;
		while (rocks < ROCK_COUNT && attempts < ROCK_COUNT * 25)
		{
			attempts++;
			var rx = rand.float(120, WORLD_W - 120);
			var ry = rand.float(120, WORLD_H - 120);
			if (Placeholder.nearRoad(WORLD_W, WORLD_H, rx, ry, 100) || Placeholder.nearPond(rx, ry, 30) || !clearOf(rx, ry, 70))
				continue;
			var stone = Placeholder.gravestone(rand.int(0, Placeholder.STONE_VARIANTS - 1));
			place(new WorldSprite(rx, ry, stone, 44, 14), Placeholder.shadow(52, 14));
			rocks++;
		}

		for (cell in grid)
			for (p in cell)
				p.put();
	}

	function spawnWatchers():Void
	{
		for (i in 0...WATCHER_COUNT)
		{
			var watcher = new WorldSprite(0, 0, Placeholder.watcher(), 16, 10);
			watchers.push(watcher);
			entities.add(watcher);
			relocateWatcher(watcher, i == 0);
		}
	}

	/** Put a watcher somewhere out in the mist ahead of the player, so it rises into view. **/
	function relocateWatcher(watcher:WorldSprite, nearFirst = false):Void
	{
		for (attempt in 0...30)
		{
			var ahead = nearFirst ? rand.float(900, 1100) : rand.float(1300, 2600);
			var wx = player.groundX() + rand.float(-900, 900);
			var wy = player.groundY() - ahead;
			if (attempt >= 20)
			{
				// Nowhere ahead (near the top of the map): anywhere on the map will do
				wx = rand.float(200, WORLD_W - 200);
				wy = rand.float(200, WORLD_H - 200);
			}
			if (wx < 200 || wy < 200 || wx > WORLD_W - 200 || wy > WORLD_H - 200)
				continue;
			if (Placeholder.nearRoad(WORLD_W, WORLD_H, wx, wy, 90) || Placeholder.nearPond(wx, wy, 40))
				continue;
			watcher.setGroundPosition(wx, wy);
			return;
		}
	}

	function updateWatchers():Void
	{
		for (watcher in watchers)
		{
			var dx = watcher.groundX() - player.groundX();
			var dy = watcher.groundY() - player.groundY();
			if (dx * dx + dy * dy < WATCHER_VANISH_DIST * WATCHER_VANISH_DIST)
			{
				relocateWatcher(watcher);
				creepy.glitch(0.35, 1);
			}
		}
	}

	function updateLamps(elapsed:Float):Void
	{
		for (lamp in lamps)
		{
			if (lamp.dead)
			{
				lamp.sprite.opacity = 0.22;
				continue;
			}
			if (lamp.flickerLeft > 0)
			{
				lamp.flickerLeft -= elapsed;
				lamp.sprite.opacity = lamp.flickerLeft > 0 ? rand.float(0.15, 1) : 1;
			}
			else if (rand.float() < elapsed * 0.25)
			{
				lamp.flickerLeft = rand.float(0.1, 0.7);
			}
		}
	}

	function addEntity(sprite:WorldSprite, shadowGraphic:Null<FlxGraphic>):Void
	{
		if (shadowGraphic != null)
			shadows.add(new WorldShadow(sprite, shadowGraphic));
		entities.add(sprite);
	}

	function addObstacle(sprite:WorldSprite, shadowGraphic:Null<FlxGraphic>):Void
	{
		sprite.immovable = true;
		obstacles.add(sprite);
		addEntity(sprite, shadowGraphic);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if demo
		updateDemo(elapsed);
		#else
		FlxG.collide(obstacles, player);
		#end
		player.x = FlxMath.bound(player.x, 40, WORLD_W - 40 - player.width);
		player.y = FlxMath.bound(player.y, 40, WORLD_H - 40 - player.height);

		updateWatchers();
		updateLamps(elapsed);
		creepy.update(elapsed);

		var ease = Math.min(1, elapsed * FOCUS_EASE);
		LogCamera.focusX += (player.groundX() - LogCamera.focusX) * ease;
		LogCamera.focusY += (player.groundY() - LogCamera.focusY) * ease;

		handleDebugKeys(elapsed);
	}

	function handleDebugKeys(elapsed:Float):Void
	{
		var rate = 1 + elapsed * 1.5;
		if (FlxG.keys.pressed.ONE)
			LogCamera.radius = Math.max(250, LogCamera.radius / rate);
		if (FlxG.keys.pressed.TWO)
			LogCamera.radius = Math.min(20000, LogCamera.radius * rate);
		if (FlxG.keys.pressed.THREE)
			LogCamera.camHeight = Math.max(60, LogCamera.camHeight / rate);
		if (FlxG.keys.pressed.FOUR)
			LogCamera.camHeight = Math.min(3000, LogCamera.camHeight * rate);
		if (FlxG.keys.pressed.FIVE)
			LogCamera.camBack = Math.max(60, LogCamera.camBack / rate);
		if (FlxG.keys.pressed.SIX)
			LogCamera.camBack = Math.min(3000, LogCamera.camBack * rate);
		if (FlxG.keys.pressed.SEVEN)
			LogCamera.zoom = Math.max(0.3, LogCamera.zoom / rate);
		if (FlxG.keys.pressed.EIGHT)
			LogCamera.zoom = Math.min(4, LogCamera.zoom * rate);
		if (FlxG.keys.justPressed.C)
			LogCamera.curved = !LogCamera.curved;
		if (FlxG.keys.justPressed.H)
			hud.visible = !hud.visible;
		if (FlxG.keys.justPressed.BACKSPACE)
			FlxG.switchState(MenuState.new);

		if (hud.visible)
			hud.text = 'LOG WORLD PROTOTYPE   arrows: walk   SHIFT: run   pos ${Math.round(player.groundX())}, ${Math.round(player.groundY())}\n'
				+ '1/2 radius ${Math.round(LogCamera.radius)}   3/4 cam height ${Math.round(LogCamera.camHeight)}   '
				+ '5/6 cam distance ${Math.round(LogCamera.camBack)}   7/8 zoom ${FlxMath.roundDecimal(LogCamera.zoom, 2)}\n'
				+ 'C curve ${LogCamera.curved ? "on" : "off"}   H hide   BACKSPACE menu';
	}

	override public function draw():Void
	{
		LogCamera.refresh();
		groundShader.sync();

		for (s in shadows)
			s.refreshProjection();
		for (e in entities)
			e.refreshProjection();

		// Far things first so near things overlap them
		entities.members.sort((a, b) -> a.proj.depth > b.proj.depth ? -1 : (a.proj.depth < b.proj.depth ? 1 : 0));

		super.draw();
	}
}
