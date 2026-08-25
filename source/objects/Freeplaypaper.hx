package objects;

import objects.FunkinSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import Paths;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import json2object.JsonParser;
import flash.media.Sound;
import MathUtil;
import flixel.input.mouse.FlxMouseEvent;
import data.SongMetadata.Metadata;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Freeplaypaper extends FlxSpriteGroup
{
	public var songname:FlxText;

	public var targetY:Float;
	public var selected:Bool = false;
	public var targetX:Float;

	public var backing:FunkinSprite;

	var scaletolerp:Float = 1;

	public var songtoload:String;

	var backingWidth:Float = 0;
	var backingHeight:Float = 0;

	public var metadata:Metadata = null;

	public var dorendervibe:Bool = true;

	public var onclick:Void->Void = null;

	public function new(x:Float = 0, y:Float = 0, metadata:Metadata = null)
	{
		super(x, y);
		attemptmetadata(metadata);
		backing = new FunkinSprite(0, 0);
		backing.loadGraphic(Paths.image('menus/freeplay/songpaper'));
		add(backing);
		backingWidth = backing.width;
		backingHeight = backing.height;
		backing.color = FlxColor.GRAY;
		songname = new FlxText(0, 0, 0, metadata != null ? metadata.name : "Unknown");
		songname.setFormat(Paths.font("Sketchy.ttf"), 42, FlxColor.GRAY, CENTER);
		add(songname);
		songname.x = backing.getGraphicMidpoint().x - (songname.width / 2);
		songname.y = backing.getGraphicMidpoint().y - (songname.height / 2);

		FlxMouseEvent.add(this, onMouseDown, null, onMouseOver, onMouseOut);
	}

	function attemptmetadata(metadata:Metadata)
	{
		this.metadata = metadata;

		dorendervibe = metadata.dorendervibe;
		debug.Consolehandler.print(dorendervibe);
		debug.Consolehandler.print(true);
	}

	function onMouseDown(sprite:FlxSpriteGroup)
	{
		if (onclick != null && selected)
			onclick();
	}

	function onMouseOver(sprite:FlxSpriteGroup)
	{
		if (selected == false)
			return;
		scaletolerp = 1.105;
	}

	function onMouseOut(sprite:FlxSpriteGroup)
	{
		scaletolerp = 1;
	}

	public function toggleselected(isSelected:Bool)
	{
		selected = isSelected;
		if (isSelected)
		{
			songname.color = FlxColor.GRAY;
			backing.color = FlxColor.WHITE;
		}
		else
		{
			songname.color = FlxColor.BLACK;
			backing.color = FlxColor.GRAY;
		}
	}

	override function update(elapsed:Float)
	{
		scale.x = MathUtil.smoothLerpPrecision(scale.x, scaletolerp, elapsed, 0.5);
		scale.y = MathUtil.smoothLerpPrecision(scale.y, scaletolerp, elapsed, 0.5);

		var desiredX:Float = targetX - ((backingWidth * scale.x) - backingWidth) * 0.5;
		var desiredY:Float = targetY - ((backingHeight * scale.y) - backingHeight) * 0.5;

		x = MathUtil.smoothLerpPrecision(x, desiredX, elapsed, 0.9);
		y = MathUtil.smoothLerpPrecision(y, desiredY, elapsed, 0.9);
		super.update(elapsed);
	}
}
