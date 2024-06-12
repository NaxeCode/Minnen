package menu;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import planes.Level1;
import tools.Reg;

class MenuState extends FlxState
{
	private var titleGroup:FlxTypedGroup<FlxText>;
	private var textGroup:FlxTypedGroup<FlxText>;

	private var title:FlxText;
	private var text:FlxText;

	override public function create():Void
	{
		super.create();

		setProperties();
		initBG();
		initText();
	}

	private function setProperties():Void
	{
		set_bgColor(Reg.BGColor);
		FlxG.camera.antialiasing = true;
	}

	private function initBG():Void
	{
		/*
			var bgSprite = new FlxSprite(0, 0, AssetPaths.menubg__png);
			add(bgSprite);
		 */
	}

	private function initText():Void
	{
		titleGroup = new FlxTypedGroup<FlxText>();

		title = new FlxText();
		title.text = "Minnen";
		formatTitle(title);
		title.y -= 150;
		titleGroup.add(title);

		add(titleGroup);

		textGroup = new FlxTypedGroup<FlxText>();

		text = new FlxText();
		text.text = "Press ENTER";
		formatText(text);
		textGroup.add(text);

		text = new FlxText();
		text.text = "Design / Art - Lily (@Lileaves)";
		formatCredText(text);
		text.y += 90;
		text.y += 60;
		textGroup.add(text);

		text = new FlxText();
		text.text = "Design / Programming - Naxe (@NaxeCode)";
		formatCredText(text);
		text.y += (100 + 35);
		text.y += 60;
		textGroup.add(text);

		/*
			text = new FlxText();
			text.text = "Music - Logan Hart (@LHartMusic)";
			formatText(text);
			text.y += (110 + 35 * 2);
			textGroup.add(text);
		 */

		add(textGroup);
	}

	private function formatTitle(txt:FlxText):Void
	{
		txt.setFormat(Reg.mainFont, 55, Reg.mainColor, CENTER);
		txt.screenCenter();
	}

	private function formatText(txt:FlxText):Void
	{
		txt.setFormat(Reg.subFont, 30, Reg.subColor, CENTER);
		txt.screenCenter();
	}

	private function formatCredText(txt:FlxText):Void
	{
		txt.setFormat(Reg.creditsFont, 25, Reg.subColor, CENTER);
		txt.screenCenter();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		handleInput();
	}

	private function handleInput():Void
	{
		if (FlxG.keys.justPressed.ENTER)
		{
			FlxG.keys.enabled = false;
			FlxG.camera.fade(FlxColor.WHITE, 1, false, playGame);
		}
	}

	private function playGame():Void
	{
		FlxG.keys.enabled = true;
		FlxG.switchState(new Level1());
	}
}
