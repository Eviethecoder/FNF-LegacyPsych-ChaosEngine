package states;

import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.text.FlxText;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import debug.*;
import MathUtil;
import utility.Freeplayutils;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.sound.FlxSound;
import editors.ChartingState;
import PlayState;
import objects.FunkinSprite;
import objects.RenderSprite;
import objects.Freeplaypaper;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import utility.Scripthandler;
import flixel.FlxBasic;
import sys.FileSystem;
import haxe.io.Path;
import data.SongMetadata.Metadata;

using StringTools;

class Freeplay extends MusicBeatState
{
	var selectsound:FlxSound;
	var bg:FunkinSprite;
	var sidePaper:FunkinSprite;
	var highscore:FunkinSprite;

	var scoretext:FlxText;

	var renderIdleTime:Float = 0;

	var papers:Array<Freeplaypaper> = [];

	var startX = 70;
	var offsetX = 75;

	var centerY = FlxG.height * 0.3;
	var spacingY = 200;

	var render:RenderSprite;
	var renderTween:FlxTween = null;
	var renderTween2:FlxTween = null;

	var rendermap:Map<String, FunkinSprite> = new Map<String, FunkinSprite>();
	var ogrenderposition:FlxPoint;
	var metadata:Map<String, Metadata> = new Map<String, Metadata>();

	var curSelected:Int = 0;

	var curselectedpaper(get, never):Null<Freeplaypaper>;

	function get_curselectedpaper():Freeplaypaper
	{
		if (curSelected >= 0 && curSelected < papers.length)
			return papers[curSelected];
		return null;
	}

	override function create()
	{
		super.create();
		metadata = Freeplayutils.getSongFolders();
		trace('Freeplay metadata: ' + metadata);
		selectsound = FlxG.sound.load(Paths.sound('freeplay/songselect'), 0.5);

		ogrenderposition = new FlxPoint();
		bg = new FunkinSprite();
		bg.loadGraphic(Paths.image("menus/freeplay/paperBack"));
		add(bg);

		sidePaper = new FunkinSprite();
		sidePaper.loadGraphic(Paths.image("menus/freeplay/paperR"));
		sidePaper.screenCenter(Y);
		sidePaper.x = FlxG.width - sidePaper.width + 10;
		add(sidePaper);

		highscore = new FunkinSprite();
		highscore.loadGraphic(Paths.image("menus/freeplay/highscore"));
		highscore.x = sidePaper.x + 300;

		add(highscore);

		scoretext = new FlxText(highscore.x + 150, highscore.y + 40, 800, "0");
		scoretext.setFormat(Paths.font("Sketchy.ttf"), 68, FlxColor.BLACK, "center");
		scoretext.screenCenter(X);
		scoretext.x += 400;
		scoretext.y += 50;
		debug.Consolehandler.print(' ' + scoretext.x);
		add(scoretext);
		scoretext.angle = 10;
		render = new RenderSprite();
		render.loadGraphic(Paths.image("menus/freeplay/freeplay renders/ebot"));
		render.antialiasing = true;

		// Position roughly centered on the paper.
		render.x = sidePaper.x + (sidePaper.width - render.width);
		render.y = sidePaper.y + 380;

		ogrenderposition.set(render.x, render.y);

		add(render);

		var i:Int = 0;
		for (key in metadata.keys())
		{
			var songMeta = metadata.get(key);

			var paper = new Freeplaypaper(startX - (i - curSelected) * offsetX, centerY + (i - curSelected) * spacingY, songMeta);

			papers.push(paper);
			add(paper);

			paper.onclick = loadsong.bind();
			paper.songtoload = key;
			debug.Consolehandler.print('paper.songtoload: ' + paper.songtoload);

			if (!rendermap.exists(paper.metadata.renderdata.name))
			{
				var sprite = new FunkinSprite();
				sprite.loadGraphic(Paths.image('menus/freeplay/freeplay renders/' + paper.metadata.renderdata.rendergraphic));
				rendermap.set(paper.metadata.renderdata.name, sprite);
			}

			paper.toggleselected(i == curSelected);
			i++;
		}
		changeSelection(0);
	}

	function renderclick(sprite:FunkinSprite)
	{
	}

	function changeSelection(change:Int = 0)
	{
		if (papers.length == 0)
			return;

		curSelected = (curSelected + change + papers.length) % papers.length;
		if (change != 0)
			updateRender();

		selectsound.play(true);
		for (i in 0...papers.length)
		{
			var paper = papers[i];

			if (i > curSelected)
				paper.targetX = startX - (i - curSelected) * offsetX;
			else
				paper.targetX = startX;

			paper.targetY = centerY + (i - curSelected) * spacingY;

			paper.toggleselected(i == curSelected);
		}
	}

	function updateRender()
	{
		if (renderTween != null)
		{
			renderTween.cancel();
			renderTween = null;
			render.x = ogrenderposition.x;
			render.alpha = 1;
		}

		renderTween = FlxTween.tween(render, {
			alpha: 0,
			x: ogrenderposition.x + 200
		}, 0.45, {
			ease: FlxEase.quadIn,
			onComplete: function(_)
			{
				// Replace this later with the selected song's render.
				render.swapgraphicdata(rendermap.get(curselectedpaper.metadata.renderdata.name));

				// Reset before tweening back in.
				renderTween = null;

				renderTween = FlxTween.tween(render, {
					alpha: 1,
					x: ogrenderposition.x
				}, 0.45, {
					ease: FlxEase.quadOut,
					onComplete: function(_)
					{
						renderTween = null;
					}
				});
			}
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		renderIdleTime += elapsed;

		// Idle floating movement
		if (renderTween == null && curselectedpaper.dorendervibe)
		{
			var idleX = Math.sin(renderIdleTime * 2) * 5;
			var idleY = Math.cos(renderIdleTime * 1.5) * 5;

			render.x = MathUtil.smoothLerpPrecision(render.x, ogrenderposition.x + idleX, elapsed, 1);
			render.y = MathUtil.smoothLerpPrecision(render.y, ogrenderposition.y + idleY, elapsed, 1);
		}

		if (controls.UI_UP_P)
			changeSelection(-1);

		if (controls.UI_DOWN_P)
			changeSelection(1);

		var shiftMult:Int = 1;
		if (FlxG.keys.pressed.SHIFT)
			shiftMult = 3;

		if (FlxG.mouse.wheel != 0)
		{
			changeSelection(-shiftMult * FlxG.mouse.wheel);
		}
		if (controls.ACCEPT)
		{
			loadsong();
		}

		if (controls.BACK)
		{
			persistentUpdate = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	function loadsong()
	{
		var folder:String = '';
		var songLowercase:String = Paths.formatToSongPath(curselectedpaper.songtoload).toLowerCase();
		var poop:String = Highscore.formatSong(songLowercase, 1);

		for (i in 0...Constants.defaultsongtypes.length)
		{
			if (songLowercase.contains('-' + Constants.defaultsongtypes[i]))
			{
				folder = 'songs/' + Constants.defaultsongtypes[i];
				break;
			}
			else
			{
				folder = 'songs/default';
			}
		}
		trace(folder + '/' + songLowercase + '/' + songLowercase);
		Constants.cursongfolder = folder;
		PlayState.SONG = Song.loadFromJson(songLowercase, folder + '/' + songLowercase);
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = 1;
		if (FlxG.keys.pressed.SHIFT)
		{
			MusicBeatState.switchState(new ChartingState());
		}
		else
		{
			MusicBeatState.switchState(new PlayState());
		}
	}
}
