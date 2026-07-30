package debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import openfl.Lib;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import Alphabet;
import Paths;
import TitleState;

// taken from legacy Nightmare vision. support their shit tOOOO
class CrashReportSubstate extends FlxState
{
	var underText:FlxText;

	public var error:String;
	public var errorName:String;
	public var prevStateClass:FlxState;

	public function new(prevStateClass:FlxState, error:String, errorName:String):Void
	{
		this.prevStateClass = prevStateClass;
		this.error = error;
		this.errorName = errorName;
		super();
	}

	override public function create()
	{
		super.create();

		FlxG.state.persistentUpdate = false;
		FlxG.state.persistentDraw = true;

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		bg.scrollFactor.set();
		bg.alpha = 0;
		var scaleXRatio:Float = Lib.current.stage.stageWidth / bg.width;
		var scaleYRatio:Float = Lib.current.stage.stageHeight / bg.height;
		bg.loadGraphic(Paths.image("uhoh"));
		bg.scale.set(scaleXRatio, scaleYRatio);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		var coolText:Alphabet = new Alphabet(0, 32, "UNCATCHABLE ERROR", true);
		coolText.screenCenter(X);
		coolText.color = FlxColor.RED;
		add(coolText);

		var formattedErrorMessage:String = 'Your game has crashed! \nError caught: ${errorName}\n\n${error}\n\nPlease report this error to Team Eternal ';

		var report:FlxText = new FlxText(0, 0, FlxG.width / 1.5, formattedErrorMessage);
		report.setFormat(Paths.font('vcr.ttf'), 32, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		report.screenCenter(XY);
		report.borderSize = 1.5;
		add(report);

		underText = new FlxText(0, FlxG.height - 64, FlxG.width, "Press SPACE to return to the Menu Screen.");
		underText.setFormat(Paths.font('vcr.ttf'), 24, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		underText.y = FlxG.height - underText.height - 16;
		underText.borderSize = 1;
		underText.screenCenter(X);
		add(underText);

		FlxTween.tween(bg, {alpha: 0.6}, 0.6, {ease: FlxEase.cubeOut});

		this.camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE)
		{
			FlxG.switchState(prevStateClass);
		}
	}
}
