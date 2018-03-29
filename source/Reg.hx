package;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class Reg 
{
    // Colors
    public static var mainColor:FlxColor = FlxColor.fromInt(0xFFFFFFFF);
    public static var subColor:FlxColor = FlxColor.fromInt(0xFFFFFFFF);
    public static var BGColor:FlxColor = FlxColor.fromInt(0xFF000000);

    // Fonts
    public static var mainFont:String = AssetPaths.youmurdererbb_reg__otf;
    public static var subFont:String = AssetPaths.vermin_vibes_1989__ttf;
    public static var creditsFont:String = AssetPaths.VCR_OSD_MONO_1__001__ttf;

    // Settings
    public static var sfxVolume:Float = 0.5;
    public static var musicVolume:Float = 0.5;

    public static var _canMove:Bool = true;
	public static var _speed:Int = 230;
	public static var _dragX:Int = 1500;
	public static var _jumpPower:Int = 500;
	public static var _jumpCount:Int = 2;
	public static var _gravity:Int = 1350;

    // Game Data
    public static var difficulty:Float = 0.0;
    public static var playerSpawn:FlxPoint = FlxPoint.get(0, 0);

    public static function switchState():Void
    {
        FlxG.switchState(new Level2());
    }

    public static function create():Void
    {
        FlxG.log.redirectTraces = true;
        debug();
    }

    public static function tracePlayer(plr:Player):Void
    {
        trace(Std.int(plr.x));
		trace(Std.int(plr.y));
    }

    public static function debug():Void
    {
        FlxG.watch.add(FlxG, "elapsed");
    }

    public static function toggleAntiAliasaing():Void
    {
        if (FlxG.keys.justPressed.A)
            FlxG.camera.antialiasing = !FlxG.camera.antialiasing;
    }

    public static function update(elapsed:Float):Void
    {
        toggleAntiAliasaing();
    }
}