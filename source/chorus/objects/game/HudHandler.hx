package chorus.objects.game;

import chorus.backend.assets.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import chorus.backend.assets.data.HudstyleData;
import chorus.backend.assets.data.HudstyleData.Hudstyle;
import chorus.objects.misc.Bar;
import chorus.backend.utils.ClientPrefs;
import chorus.backend.scripting.Scripthandler;
import chorus.backend.scripting.HaxeScript;
import chorus.states.PlayState;
import chorus.backend.utils.Conductor;
import chorus.backend.save.Rating;
import chorus.backend.scripting.scriptevents.Gameplayevents.NoteHitEvent;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import chorus.objects.game.Note;

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

	public var comboGroup:FlxSpriteGroup;
	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

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
			cachePopUpScore();
			runScriptFunction('BarCreatePost', []);
		}
	}

	private function cachePopUpScore()
	{
		var folder:String = 'Huds/Combo/';
		var suffix:String = '';
		folder += hudData.getpopUpScoreFolder() + '/';
		suffix = hudData.getpopUpScoreSufix();

		Paths.image(folder + "sick" + suffix);
		Paths.image(folder + "good" + suffix);
		Paths.image(folder + "bad" + suffix);
		Paths.image(folder + "shit" + suffix);
		Paths.image(folder + "combo" + suffix);

		for (i in 0...10)
		{
			Paths.image(folder + 'num' + i + suffix);
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

	public function popUpScore(note:Note = null, event:NoteHitEvent):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		PlayState.instance.vocals.unmutePlayer();

		var placement:String = Std.string(PlayState.instance.combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;

		var daRating:Rating = event.ranking;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		PlayState.instance.totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if (!note.ratingDisabled)
			daRating.increase();
		note.rating = daRating.name;
		score = daRating.score;

		if (daRating.noteSplash && !note.noteSplashDisabled)
			PlayState.instance.spawnNoteSplashOnNote(note);

		if (!PlayState.instance.practiceMode && !PlayState.instance.cpuControlled)
		{
			PlayState.instance.songScore += score;
			if (!note.ratingDisabled)
			{
				PlayState.instance.songHits++;
				PlayState.instance.totalPlayed++;
				PlayState.instance.RecalculateRating(false);
			}
		}

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 1)
		{
			for (spr in comboGroup.members)
			{
				spr.destroy();
				comboGroup.remove(spr, true);
			}
		}

		var folder:String = 'Huds/Combo/';
		var suffix:String = '';
		folder += hudData.getpopUpScoreFolder() + '/';
		suffix = hudData.getpopUpScoreSufix();

		rating.loadGraphic(Paths.image(folder + daRating.image + suffix));
		rating.cameras = [PlayState.instance.camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * PlayState.instance.playbackRate * PlayState.instance.playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * PlayState.instance.playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * PlayState.instance.playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(folder + 'combo' + suffix));
		comboSpr.cameras = [PlayState.instance.camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * PlayState.instance.playbackRate * PlayState.instance.playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * PlayState.instance.playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * PlayState.instance.playbackRate;
		comboGroup.add(rating);

		if (!PlayState.instance.stage.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.data.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.data.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * PlayState.daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * PlayState.daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if (PlayState.instance.combo >= 1000)
		{
			seperatedScore.push(Math.floor(PlayState.instance.combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(PlayState.instance.combo / 100) % 10);
		seperatedScore.push(Math.floor(PlayState.instance.combo / 10) % 10);
		seperatedScore.push(PlayState.instance.combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
			comboGroup.add(comboSpr);

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(folder + 'num' + Std.int(i) + suffix));
			numScore.cameras = [PlayState.instance.camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.data.comboOffset[2];
			numScore.y -= ClientPrefs.data.comboOffset[3];

			if (!PlayState.instance.stage.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.data.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * PlayState.daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * PlayState.instance.playbackRate * PlayState.instance.playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * PlayState.instance.playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * PlayState.instance.playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;

			if (showComboNum)
				comboGroup.add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / PlayState.instance.playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / PlayState.instance.playbackRate
			});

			daLoop++;
			if (numScore.x > xThing)
				xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;

		coolText.text = Std.string(seperatedScore);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / PlayState.instance.playbackRate, {
			startDelay: Conductor.crochet * 0.001 / PlayState.instance.playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / PlayState.instance.playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / PlayState.instance.playbackRate
		});
	}
}
