package events;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import json2object.JsonParser;
import sys.FileSystem;
import sys.io.File;
import Conductor;
import HealthIcon;
import PlayState;

typedef LyricFormat =
{
	@:optional var font:String;
	@:optional var color:String;
	@:optional var borderColor:String;
	@:optional var size:Int;
}

class LyricEvent extends BaseEvent
{
	var dedunText:FlxText = null;
	var dedunOpponentIcon:HealthIcon = null;
	var dedunTimer:FlxTimer = null;
	var dedunFadeTween:FlxTween = null;
	var dedunFadeIcon:FlxTween = null;
	var iconmanualchange:Bool = false;
	var descBox:FlxSprite = null;
	var lyricFormatParser:JsonParser<LyricFormat>;
	var lyricFormat:LyricFormat;
	var previcon:String;

	// converted from empty eyes
	public function new()
	{
		super();
		eventName = "Lyrics";
	}

	override public function precacheEvent(daevent:Note.EventNote):Void
	{
		var songName:String = PlayState.SONG != null ? PlayState.SONG.song : '';
		grabjson(Paths.getPreloadPath('data/' + Constants.cursongfolder + Paths.formatToSongPath(songName) + '/lyrics.json'));
		createlyrics();
	}

	override public function triggerEvent():Void
	{
		var value1:String = grabeventString("Text");
		var value2:Float = grabeventFloat("DurationSteps");
		handleEvent(value1, value2);

		var iconValue:String = grabeventString("IconOverride");
		var resetValue:Bool = grabeventBool("ResetIcon");
		if (iconValue.length > 0)
			iconedits(iconValue, resetValue);
	}

	function grabjson(jsonpath:String):Void
	{
		if (!FileSystem.exists(jsonpath))
		{
			trace("Lyrics JSON not found at: " + jsonpath + 'running with default paramaters');

			lyricFormat = makeDefaultLyricFormat();
			return;
		}

		var raw = File.getContent(jsonpath);

		// Create parser for your typedef
		lyricFormatParser = new JsonParser<LyricFormat>();
		lyricFormatParser.fromJson(raw, jsonpath);

		if (lyricFormatParser.errors.length > 0)
		{
			trace("JSON parse errors: ");
			for (e in lyricFormatParser.errors)
				trace(e);
		}

		// SUCCESS — result stored here
		lyricFormat = lyricFormatParser.value;

		trace("Loaded Lyric Format:");
		trace("Font: " + lyricFormat.font);
		trace("Color: " + lyricFormat.color);
		trace("Border: " + lyricFormat.borderColor);
		if (lyricFormat.font == null)
		{
			lyricFormat.font = 'pixel';
		}
		if (lyricFormat.color == null)
		{
			lyricFormat.color = 'white';
		}
		if (lyricFormat.borderColor == null)
		{
			lyricFormat.borderColor = 'black';
		}
		if (lyricFormat.size == null)
		{
			lyricFormat.size = 60;
		}
	}

	function createlyrics():Void
	{
		if (lyricFormat == null)
			lyricFormat = makeDefaultLyricFormat();

		if (dedunText != null && dedunText.exists)
			return;

		dedunText = new FlxText(0, FlxG.height * 0.75, FlxG.width, "", 60);

		dedunText.setFormat(Paths.font(lyricFormat.font), lyricFormat.size, FlxColor.fromString(lyricFormat.color), CENTER, FlxTextBorderStyle.OUTLINE,
			FlxColor.fromString(lyricFormat.borderColor));
		dedunText.borderSize = 4;
		dedunText.screenCenter(XY);
		dedunText.y += 210;
		dedunText.cameras = [PlayState.instance.camOther];
		dedunText.alpha = 0;
		addtoGame(dedunText);
		dedunOpponentIcon = new HealthIcon(PlayState.instance.stage.dad.icondata, false);
		dedunOpponentIcon.autoUpdate = false;
		previcon = PlayState.instance.stage.dad.icondata.healthicon;
		dedunOpponentIcon.scrollFactor.set(0, 0);
		dedunOpponentIcon.animation.curAnim.curFrame = 0;
		dedunOpponentIcon.cameras = [PlayState.instance.camOther];
		dedunOpponentIcon.alpha = 0;
		addtoGame(dedunOpponentIcon);
	}

	function makeDefaultLyricFormat():LyricFormat
	{
		return {
			font: "pixel",
			color: "white",
			borderColor: "black",
			size: 60
		};
	}

	function returniconformat(icon:String):Character.IconData
	{
		return {
			healthicon: icon,
			iconOffsets: []
		};
	}

	public function iconedits(Value1:String, Value2:Bool):Void
	{
		if (dedunOpponentIcon == null)
			return;

		var valuearray:Array<String> = Value1.split(',');

		if (valuearray[0] != null)
		{
			iconmanualchange = true;
			dedunOpponentIcon.changeIcon(returniconformat(valuearray[0]));
		}
		if (valuearray[1] != null)
		{
			dedunOpponentIcon.animation.curAnim.curFrame = Std.parseInt(valuearray[1]);
		}
		else
		{
			iconmanualchange = true;
			dedunOpponentIcon.changeIcon(returniconformat(Value1));
		}
		if (Value2 != false)
		{
			iconmanualchange = false;
			dedunOpponentIcon.changeIcon(PlayState.instance.stage.dad.icondata);
		}
	}

	public function handleEvent(Value1:String, Value2:Float):Void
	{
		var text:String = Value1;
		var steps:Float = Conductor.stepCrochet;
		var stepLength:Float = Value2;
		if (stepLength <= 0)
			stepLength = 8;

		if (dedunText == null)
		{
			createlyrics();
		}

		if (previcon != PlayState.instance.stage.dad.icondata.healthicon)
		{
			if (iconmanualchange)
			{
			}
			else
			{
				dedunOpponentIcon.changeIcon(PlayState.instance.stage.dad.icondata);
				previcon = PlayState.instance.stage.dad.icondata.healthicon;
			}
		}
		dedunOpponentIcon.alpha = 1; // make sure visible

		if (dedunFadeTween != null)
		{
			dedunFadeTween.cancel();
			dedunFadeTween = null;
		}
		if (dedunFadeIcon != null)
		{
			dedunFadeIcon.cancel();
			dedunFadeIcon = null;
		}
		if (dedunTimer != null)
		{
			dedunTimer.cancel();
			dedunTimer = null;
		}

		dedunText.text = text;
		dedunFadeTween = FlxTween.tween(dedunText, {alpha: 1}, 0.2);
		dedunFadeIcon = FlxTween.tween(dedunOpponentIcon, {alpha: 1}, 0.2);

		var textVisibleLeftX = dedunText.x + (dedunText.width / 2) - (dedunText.textField.textWidth / 2);
		dedunOpponentIcon.x = textVisibleLeftX - dedunOpponentIcon.width - 5;
		dedunOpponentIcon.y = dedunText.y + (dedunText.height / 2) - (dedunOpponentIcon.height / 2);

		dedunTimer = new FlxTimer().start(stepLength * steps / 1000, function(tmr:FlxTimer)
		{
			dedunFadeTween = FlxTween.tween(dedunText, {alpha: 0}, 0.5);
			dedunFadeIcon = FlxTween.tween(dedunOpponentIcon, {alpha: 0}, 0.5);
		});
	}

	function addtoGame(obj:FlxObject):Void
	{
		PlayState.instance.add(obj);
	}
}
