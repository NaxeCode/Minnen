package;

import flixel.FlxObject;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxMath;

class Level1 extends FlxState
{
	//public var player:Player;

	var collider:FlxSpriteGroup;
	var background:FlxSpriteGroup;

	public var noah:NPC;
	public var npcs:FlxTypedGroup<NPC>;
	
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
		for (level in project.levels)
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

	function createEntities(entityLayer:LdtkProject.Layer_Entities)
	{
		var x:Int;
		var y:Int;

		x = entityLayer.all_Noah[0].pixelX;
		y = entityLayer.all_Noah[0].pixelY;

		npcs = new FlxTypedGroup<NPC>();

		noah = new NPC(x, y);
		noah.text = entityLayer.all_Noah[0].f_string;
		noah.loadGraphic(AssetPaths.Noah__png, false, 32, 64);
		trace(noah.width);
		trace(noah.height);
		noah.setFacingFlip(FlxObject.LEFT, true, false);
		noah.setFacingFlip(FlxObject.RIGHT, false, false);

		npcs.add(noah);
		add(noah);

		noah.facing = FlxObject.LEFT;

		x = entityLayer.all_Player[0].pixelX;
		y = entityLayer.all_Player[0].pixelY;

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