package;

import flixel.util.FlxDirectionFlags;
import flixel.util.FlxDirection;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledImageLayer;
import flixel.addons.editors.tiled.TiledImageTile;
import flixel.addons.editors.tiled.TiledLayer.TiledLayerType;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledTileSet;
import flixel.addons.editors.tiled.TiledTilePropertySet;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import flixel.addons.tile.FlxTilemapExt;
import flixel.addons.tile.FlxTileSpecial;
import haxe.io.Path;
import flixel.FlxBasic;
import flixel.util.FlxColor;

/**
 * @author Samuel Batista
 */
class TiledLevel extends TiledMap {
	// For each "Tile Layer" in the map, you must define a "tileset" property which contains the name of a tile sheet image
	// used to draw tiles in that layer (without file extension). The image file must be located in the directory specified bellow.
	private static var c_PATH_LEVEL_TILESHEETS = "assets/tiled/";

	// Array of tilemaps used for collision
	public var foregroundTiles:FlxGroup;
	public var backgroundLayer:FlxGroup;

	private var collidableTileLayers:Array<FlxTilemap>;

	public var foregroundObjects:FlxGroup;
	public var objectsLayer:FlxGroup;
	public var backgroundObjects:FlxGroup;

	// Sprites of images layers
	public var imagesLayer:FlxGroup;

	public function new(tiledLevel:Dynamic, directory:Dynamic, state:FlxState) {
		super(tiledLevel);

		c_PATH_LEVEL_TILESHEETS = directory;

		imagesLayer = new FlxGroup();
		foregroundTiles = new FlxGroup();
		backgroundLayer = new FlxGroup();

		foregroundObjects = new FlxGroup();
		objectsLayer = new FlxGroup();
		backgroundObjects = new FlxGroup();

		FlxG.camera.setScrollBoundsRect(0, 0, fullWidth, fullHeight, true);

		loadImages();
		loadObjects(state);

		// Load Tile Maps
		for (layer in layers) {
			if (layer.type != TiledLayerType.TILE)
				continue;
			var tileLayer:TiledTileLayer = cast layer;

			var tileSheetName:String = tileLayer.properties.get("tileset");

			if (tileSheetName == null)
				throw "'tileset' property not defined for the '" + tileLayer.name + "' layer. Please add the property to the layer.";

			var tileSet:TiledTileSet = null;
			for (ts in tilesets) {
				if (ts.name == tileSheetName) {
					tileSet = ts;
					break;
				}
			}

			if (tileSet == null)
				throw "Tileset '" + tileSheetName + " not found. Did you misspell the 'tilesheet' property in " + tileLayer.name + "' layer?";

			var imagePath = new Path(tileSet.imageSource);
			var processedPath = c_PATH_LEVEL_TILESHEETS + imagePath.file + "." + imagePath.ext;

			// could be a regular FlxTilemap if there are no animated tiles
			var tilemap = new FlxTilemapExt();
			tilemap.loadMapFromArray(tileLayer.tileArray, width, height, processedPath, tileSet.tileWidth, tileSet.tileHeight, OFF, tileSet.firstGID, 1, 1);

			if (tileLayer.properties.contains("animated")) {
				var tileset = tilesets["level"];
				var specialTiles:Map<Int, TiledTilePropertySet> = new Map();
				for (tileProp in tileset.tileProps) {
					if (tileProp != null && tileProp.animationFrames.length > 0) {
						specialTiles[tileProp.tileID + tileset.firstGID] = tileProp;
					}
				}
				var tileLayer:TiledTileLayer = cast layer;
				tilemap.setSpecialTiles([
					for (tile in tileLayer.tiles)
						if (tile != null && specialTiles.exists(tile.tileID)) getAnimatedTile(specialTiles[tile.tileID], tileset) else null
				]);
			}

			if (tileLayer.properties.contains("nocollide")) {
				backgroundLayer.add(tilemap);
			} else {
				switch (tileLayer.properties.get("collide")) {
					case "UP":
						tilemap.allowCollisions = FlxDirectionFlags.UP;
					case "DOWN":
						tilemap.allowCollisions = FlxDirectionFlags.DOWN;
					case "LEFT":
						tilemap.allowCollisions = FlxDirectionFlags.LEFT;
					case "RIGHT":
						tilemap.allowCollisions = FlxDirectionFlags.RIGHT;
					default:
						tilemap.allowCollisions = FlxDirectionFlags.ANY;
				}

				if (collidableTileLayers == null)
					collidableTileLayers = new Array<FlxTilemap>();

				foregroundTiles.add(tilemap);
				collidableTileLayers.push(tilemap);
			}
		}
	}

	private function getAnimatedTile(props:TiledTilePropertySet, tileset:TiledTileSet):FlxTileSpecial {
		var special = new FlxTileSpecial(1, false, false, 0);
		var n:Int = props.animationFrames.length;
		var offset = Std.random(n);
		special.addAnimation([
			for (i in 0...n)
				props.animationFrames[(i + offset) % n].tileID + tileset.firstGID
		], (1000 / props.animationFrames[0].duration));
		return special;
	}

	public function loadObjects(state:FlxState) {
		for (layer in layers) {
			if (layer.type != TiledLayerType.OBJECT)
				continue;
			var objectLayer:TiledObjectLayer = cast layer;

			// collection of images layer
			if (layer.name == "images") {
				for (o in objectLayer.objects) {
					loadImageObject(o);
				}
			}

			// objects layer
			switch (layer.name) {
				case "images":
					for (o in objectLayer.objects) {
						loadImageObject(o);
					}

				case "backgroundObj":
					for (o in objectLayer.objects) {
						loadObject(state, "backgroundObj", o, objectLayer, objectsLayer);
					}

				case "objects":
					for (o in objectLayer.objects) {
						loadObject(state, "objects", o, objectLayer, objectsLayer);
					}

				case "foregroundObj":
					for (o in objectLayer.objects) {
						loadObject(state, "foregroundObj", o, objectLayer, objectsLayer);
					}
			}
		}
	}

	private function loadImageObject(object:TiledObject) {
		var tilesImageCollection:TiledTileSet = this.getTileSet("imageCollection");
		var tileImagesSource:TiledImageTile = tilesImageCollection.getImageSourceByGid(object.gid);

		// decorative sprites
		var levelsDir:String = "assets/tiled/";

		var decoSprite:FlxSprite = new FlxSprite(0, 0, levelsDir + tileImagesSource.source);
		if (decoSprite.width != object.width || decoSprite.height != object.height) {
			decoSprite.antialiasing = true;
			decoSprite.setGraphicSize(object.width, object.height);
		}
		if (object.flippedHorizontally) {
			decoSprite.flipX = true;
		}
		if (object.flippedVertically) {
			decoSprite.flipY = true;
		}
		decoSprite.setPosition(object.x, object.y - decoSprite.height);
		decoSprite.origin.set(0, decoSprite.height);
		if (object.angle != 0) {
			decoSprite.angle = object.angle;
			decoSprite.antialiasing = true;
		}

		// Custom Properties
		if (object.properties.contains("depth")) {
			var depth = Std.parseFloat(object.properties.get("depth"));
			decoSprite.scrollFactor.set(depth, depth);
		}

		backgroundLayer.add(decoSprite);
	}

	private function loadObject(state:FlxState, objType:String, o:TiledObject, g:TiledObjectLayer, group:FlxGroup) {
		var x:Int = o.x;
		var y:Int = o.y;

		// objects in tiled are aligned bottom-left (top-left in flixel)
		if (o.gid != -1)
			y -= g.map.getGidOwner(o.gid).tileHeight;

		switch (objType) {
			case "backgroundObj":
				switch (o.name) {
					case "cave":
						backgroundObjects.add(new FlxSprite(x, y, AssetPaths.Cave_Background__png));
				}
			case "objects":
				switch (o.name) {
					case "player":
						objectsLayer.add(new Player(x, y, state));
				}
			case "foregroundObj":
				switch (o.name) {
					case "cave":
						foregroundObjects.add(new FlxSprite(x, y, AssetPaths.Cave_Foreground__png));
				}
		}
	}

	public function loadImages() {
		for (layer in layers) {
			if (layer.type != TiledLayerType.IMAGE)
				continue;

			var image:TiledImageLayer = cast layer;
			var sprite = new FlxSprite(image.x, image.y, c_PATH_LEVEL_TILESHEETS + image.imagePath);
			imagesLayer.add(sprite);
		}
	}

	public function collideWithLevel(obj:FlxBasic, ?notifyCallback:FlxObject->FlxObject->Void, ?processCallback:FlxObject->FlxObject->Bool):Bool {
		if (collidableTileLayers == null)
			return false;

		for (map in collidableTileLayers) {
			// IMPORTANT: Always collide the map with objects, not the other way around.
			//            This prevents odd collision errors (collision separation code off by 1 px).
			if (FlxG.overlap(map, obj, notifyCallback, processCallback != null ? processCallback : FlxObject.separate)) {
				return true;
			}
		}
		return false;
	}
}
