package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import data.HudstyleData;
import data.HudstyleData.Hudstyle;
import objects.Bar;
import ClientPrefs;
import utility.Scripthandler;

using StringTools;

class HudHandler extends FlxGroup
{
	public var bars:Hudstyle;
	public var hudData:HudstyleData;
	public var healthBar:Bar;
	public var timebg:FlxSprite;
	public var bg:FlxSprite;
	public var timeBar:Bar;
	public var script:HaxeScript = null;

	var hudscriptpath:String;
	var songname:String;

	public var timeTxt:FlxText;
	public var showTime:Bool = false;
	public var hasscript:Bool = false;

	public function new(json:String, hudname:String, songname:String)
	{
		super();
		hudData = new HudstyleData();
		hudscriptpath = 'data/hudstyles/' + hudname + '.hx';
		hudData.loadFromJson(json, hudscriptpath);
		bars = hudData.bars;
		trace('hudname is: ' + hudname);

		this.songname = Paths.formatToSongPath(songname);
		trace('song name is' + songname);
		if (HaxeScript.isInPlayState())
		{
			hudData.detectscript(this);
		}
		barsetup();
	}

	public function barsetup()
	{
		if (bars == null)
		{
			trace("No JSON data found for HudHandler.");
			return;
		}
		else
		{
			showTime = (ClientPrefs.data.timeBarType != 'Disabled');
			timeTxt = new FlxText(42 + (FlxG.width / 2) - 248, 19, 400, "", 32);
			timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.scrollFactor.set();
			timeTxt.alpha = 0;
			timeTxt.borderSize = 2;
			timeTxt.visible = showTime;
			if (ClientPrefs.data.downScroll)
				timeTxt.y = FlxG.height - 44;
			if (ClientPrefs.data.timeBarType == 'Song Name')
				timeTxt.text = songname;
			if (bars.healthbar.barStyle == 'png')
			{
				var offsets:Array<Float> = hudData.gethealthbaroffsets();
				var position:Array<Float> = hudData.gethealthbarposition();
				healthBar = new Bar(-200, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), bars.healthbar.barStyle,
					hudData.gethealthbargraphics(1), function() return PlayState.instance.health, 0, 2);
				healthBar.leftToRight = false;
				healthBar.scrollFactor.set();
				healthBar.x += offsets[0];
				healthBar.y += offsets[1];
				healthBar.scale.set(bars.healthbar.scale, bars.healthbar.scale);
				healthBar.visible = !ClientPrefs.data.hideHud;
				healthBar.alpha = ClientPrefs.data.healthBarAlpha;
				if (hudData.gethealthbargraphics(0) != null)
				{
					bg = new FlxSprite().loadGraphic(Paths.image(hudData.gethealthbargraphics(0)));
					bg.antialiasing = true;
					bg.scale.set(bars.healthbar.scale, bars.healthbar.scale);
					bg.x = healthBar.x + position[0];
					bg.y = healthBar.y + position[1];
					trace(bg);
					reloadHealthBarColors();
					add(healthBar);
					add(bg);
				}
			}
			else
			{
				healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.11 : 0.89), bars.healthbar.barStyle, hudData.gethealthbargraphics(0),
					function() return PlayState.instance.health, 0, 2);
				healthBar.screenCenter(X);
				healthBar.x += bars.healthbar.barOffsets[0];
				healthBar.y += bars.healthbar.barOffsets[1];
				healthBar.leftToRight = false;
				healthBar.scrollFactor.set();
				healthBar.visible = !ClientPrefs.data.hideHud;
				healthBar.alpha = ClientPrefs.data.healthBarAlpha;
				reloadHealthBarColors();
				add(healthBar);
			}

			if (bars.timeBar.barStyle == 'png')
			{
				timebg = new FlxSprite().loadGraphic(Paths.image(hudData.gettimebargraphics(0)));
				timebg.antialiasing = true;
				timebg.scale.set(bars.timeBar.scale, bars.timeBar.scale);
				timebg.x = timeBar.x + bars.timeBar.position[0];
				timebg.y = timeBar.y + bars.timeBar.position[1];
				trace(timebg);

				timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), bars.timeBar.barStyle, hudData.gettimebargraphics(1), function() return 0, 0, 1);
				timeBar.scrollFactor.set();
				timeBar.screenCenter(X);
				timeBar.alpha = 0;
				timeBar.x += bars.timeBar.barOffsets[0];
				timeBar.y += bars.timeBar.barOffsets[1];
				timeBar.visible = showTime;
				add(timeBar);
				add(timebg);
			}
			else
			{
				timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), bars.timeBar.barStyle, hudData.gettimebargraphics(0), function() return 0, 0, 1);
				timeBar.scrollFactor.set();
				timeBar.screenCenter(X);
				timeBar.alpha = 0;
				timeBar.x += bars.timeBar.barOffsets[0];
				timeBar.y += bars.timeBar.barOffsets[1];
				timeBar.visible = showTime;
				timeBar.setColors(FlxColor.WHITE, FlxColor.BLACK);
				add(timeBar);
			}
			if (ClientPrefs.data.timeBarType == 'Song Name')
			{
				timeTxt.size = 24;
				timeTxt.y += 3;
			}
			add(timeTxt);
			runScriptFunction('BarCreatePost', []);
		}
	}

	public function updatehealth(health:Float)
	{
		if (healthBar != null)
		{
			healthBar.valueFunction = function() return health;
			healthBar.updateBar();
		}
		runScriptFunction('updatehealth', [health]);
	}

	public function updateTime(time:Float)
	{
		if (timeBar != null)
		{
			timeBar.valueFunction = function() return time;
			timeBar.updateBar();
		}
		runScriptFunction('updateTime', [time]);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		runScriptFunction('update', [elapsed]);
	}

	public function addvar(name:String, value:Dynamic)
	{
		return hudData.addvar(name, value);
	}

	public function runScriptFunction(id:String, params:Array<Dynamic>):Dynamic
	{
		return hudData.runScriptFunction(id, params);
	}

	public function reloadHealthBarColors()
	{
		healthBar.setColors(FlxColor.fromRGB(PlayState.instance.stage.dad.healthColorArray[0], PlayState.instance.stage.dad.healthColorArray[1],
			PlayState.instance.stage.dad.healthColorArray[2]),
			FlxColor.fromRGB(PlayState.instance.stage.boyfriend.healthColorArray[0], PlayState.instance.stage.boyfriend.healthColorArray[1],
				PlayState.instance.stage.boyfriend.healthColorArray[2]));

		healthBar.updateBar();
	}
}
