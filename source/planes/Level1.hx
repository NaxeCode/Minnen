package planes;

import characters.NPC;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import players.Player;
import tools.AssetPaths;
import tools.LdtkProject;
import tools.Reg;

class Level1 extends FlxState
{
	// public var player:Player;
	var collider:FlxSpriteGroup;
	var background:FlxSpriteGroup;

	override public function create():Void
	{
		super.create();

		setProperties();
		addLevel();
	}

	private function setProperties():Void
	{
		FlxG.camera.antialiasing = true;
		FlxG.camera.fade(Reg.BGColor, 1, true);
		FlxG.mouse.visible = false;
		FlxG.cameras.bgColor = FlxColor.BLACK;
	}

	private function addLevel():Void
	{
		var project = new LdtkProject();

		// Create a FlxGroup for all level layers
		collider = new FlxSpriteGroup();

		background = new FlxSpriteGroup();
		add(background);

		// Iterate all world levels
		for (level in project.all_worlds.Default.levels)
		{
			// Place it using level world coordinates (in pixels)
			collider.setPosition(level.worldX, level.worldY);
			background.setPosition(level.worldX, level.worldY);

			createEntities(level.l_Entities);

			// Attach level background image, if any
			if (level.hasBgImage())
				background.add(level.getBgSprite());

			// Render layer "Background"
			level.l_Background.render(background);

			// Render layer "Collisions"
			level.l_Collisions.render(collider);
		}

		for (tile in collider)
		{
			tile.immovable = true;
		}
		add(collider);
	}

	function createEntities(entityLayer:tools.LdtkProject.Layer_Entities)
	{
		var x = entityLayer.all_Player[0].pixelX;
		var y = entityLayer.all_Player[0].pixelY;

		Reg.player = new Player(x, y, this);
		add(Reg.player);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		FlxG.collide(collider, Reg.player);
	}
	/*
		function handleMotion() {
			 * # Example Data
			x = sample(-100:100, 50)

			#Normalized Data
			normalized = (x-min(x))/(max(x)-min(x))
			
			trace(Reg.player.x);
			// This is what needs to be operated on.
			//level.foregroundTiles
			for (tile in tileCoords)
			{
				//trace();
				var minX = -(tile.x - 500);
				var maxX = (tile.x + 500);
				var normalized = (Reg.player.x - minX) / (maxX - minX);
				//trace(normalized);
				//tile.alpha  = ((Reg.player.x - 0) / (1 - 0) * (255 - 0) + 0);
				//trace("Close to Tile.X " + tile.x + " Tile.Y: " + tile.y);
				//trace();
				//trace(tile.y);
				if (FlxMath.distanceToPoint(Reg.player, new FlxPoint(tile.x, tile.y)) <= 200)
				{
					
				}
			}
		}
	 */
}
