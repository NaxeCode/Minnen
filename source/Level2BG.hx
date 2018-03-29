package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;

class Level2BG extends FlxGroup
{
    public function new()
    {
        super();

        var animatedBG = new FlxSprite();
		animatedBG.scrollFactor.set(0, 0);
		animatedBG.loadGraphic(AssetPaths.LEVEL_2_BG__png, true, 1280, 750);
		animatedBG.animation.add("idle", [0, 1, 2, 3], 5, true);
		animatedBG.animation.play("idle");
		add(animatedBG);
    }
}