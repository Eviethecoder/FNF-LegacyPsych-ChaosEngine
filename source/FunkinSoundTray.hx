package;

import flixel.system.ui.FlxSoundTray;
import openfl.display.Bitmap;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import flixel.FlxG;
import MathUtil;
import json2object.JsonParser;
import openfl.geom.ColorTransform;

typedef VolumeBar =
{
	var folder:String;
	var soundlist:Array<String>;
	var barOffsets:Array<Float>;
	@default(0.30)
	var graphicScale:Float;
	@:optional
	var color:Array<Int>;
}

/**
 *  Extends the default flixel soundtray, but with some art
 *  and lil polish!
 *
 *  Gets added to the game in Main.hx, right after FlxGame is new'd
 *  since it's a Sprite rather than Flixel related object
 */
class FunkinSoundTray extends FlxSoundTray
{
	var graphicScale:Float = 0.30;
	var lerpYPos:Float = 0;
	var curloadedbar:String = '';
	var alphaTarget:Float = 0;

	var bg:Bitmap;
	var trayConfig:VolumeBar;

	public static var instance:FunkinSoundTray;

	var volumeMaxSound:String;

	public function new()
	{
		super();
		instance = this;
		resetBar('default');
		trace('Custom tray added!');
	}

	public function loadTrayConfig(json:String):VolumeBar
	{
		curloadedbar = json;
		var rawJson = Paths.getcontent(Paths.json('soundbars/' + json));
		var jsonParser:JsonParser<VolumeBar> = new JsonParser<VolumeBar>();
		jsonParser.fromJson(rawJson, json);
		return jsonParser.value;
	}

	public function resetBar(json:String, red:Float = 255, green:Float = 0, blue:Float = 0):Void
	{
		trayConfig = loadTrayConfig(json);
		graphicScale = trayConfig.graphicScale;

		volumeUpSound = Paths.vslicesound('soundtray/' + trayConfig.soundlist[0]);
		volumeDownSound = Paths.vslicesound('soundtray/' + trayConfig.soundlist[1]);
		volumeMaxSound = Paths.vslicesound('soundtray/' + trayConfig.soundlist[2]);

		removeChildren();
		bg = new Bitmap(Assets.getBitmapData(Paths.vsliceimage('soundtray/' + trayConfig.folder + '/volumebox')));
		bg.scaleX = graphicScale;
		bg.scaleY = graphicScale;
		bg.smoothing = true;
		addChild(bg);

		_bars = [];
		var colorTransform = new ColorTransform();
		var color = trayConfig.color != null ? trayConfig.color : [Std.int(red), Std.int(green), Std.int(blue)];
		colorTransform.redMultiplier = color[0] / 255;
		colorTransform.greenMultiplier = color[1] / 255;
		colorTransform.blueMultiplier = color[2] / 255;

		for (i in 1...11)
		{
			var bar:Bitmap = new Bitmap(Assets.getBitmapData(Paths.vsliceimage('soundtray/' + trayConfig.folder + '/bars_' + i)));
			bar.x = bg.x + trayConfig.barOffsets[0];
			bar.y = bg.y + trayConfig.barOffsets[1];
			bar.scaleX = graphicScale;
			bar.scaleY = graphicScale;
			bar.transform.colorTransform = colorTransform;
			bar.smoothing = true;
			bar.visible = false;
			addChild(bar);
			_bars.push(bar);
		}

		screenCenter();
		y = -height - 10;
		lerpYPos = y;
		alpha = 0;
		alphaTarget = 0;
		visible = false;
	}

	public function swapBar(jsontoload)
	{
		if (curloadedbar != jsontoload)
			resetBar(jsontoload);
	}

	override public function update(ms:Float):Void
	{
		var elapsed = ms / 1000.0;

		// If it has volume, we want to auto-hide after 1 second (1000ms), we simply decrement a timer
		var hasVolume:Bool = (!FlxG.sound.muted && FlxG.sound.volume > 0);

		if (hasVolume)
		{
			// Animate sound tray thing
			if (_timer > 0)
			{
				_timer -= elapsed;
				if (_timer <= 0)
				{
					lerpYPos = -height - 10;
					alphaTarget = 0;
				}
			}
			else if (y <= -height)
			{
				visible = false;
				active = false;
			}
		}
		else if (!visible)
		{
			showTray();
		}

		y = MathUtil.smoothLerpPrecision(y, lerpYPos, elapsed, 0.768);
		alpha = MathUtil.smoothLerpPrecision(alpha, alphaTarget, elapsed, 0.307);
		screenCenter();
	}

	override function showIncrement():Void
	{
		moveTrayMakeVisible(true);
		saveVolumePreferences();
	}

	override function showDecrement():Void
	{
		moveTrayMakeVisible(false);
		saveVolumePreferences();
	}

	function moveTrayMakeVisible(up:Bool = false):Void
	{
		showTray();

		if (!silent)
		{
			// This is a String currently, but there is or was a Flixel PR to change this to a FlxSound or a Sound bject
			var sound:Null<String> = FlxG.sound.volume == 1 ? volumeMaxSound : (up ? volumeUpSound : volumeDownSound);
			if (sound != null && Assets.exists(sound, AssetType.SOUND))
				FlxG.sound.play(sound);
		}
	}

	function showTray():Void
	{
		_timer = 1;
		lerpYPos = 10;
		visible = true;
		active = true;
		alphaTarget = 1;

		updateBars();
	}

	function updateBars():Void
	{
		var globalVolume:Int = FlxG.sound.muted || FlxG.sound.volume == 0 ? 0 : Math.round(FlxG.sound.logToLinear(FlxG.sound.volume) * 10);

		for (i in 0..._bars.length)
			_bars[i].visible = i < globalVolume;
	}

	function saveVolumePreferences():Void
	{
		// Actually save when the volume is changed / modified
		#if FLX_SAVE
		// Save sound preferences
		if (FlxG.save.isBound)
		{
			FlxG.save.data.mute = FlxG.sound.muted;
			FlxG.save.data.volume = FlxG.sound.volume;
			FlxG.save.flush();
		}
		#end
	}
}
