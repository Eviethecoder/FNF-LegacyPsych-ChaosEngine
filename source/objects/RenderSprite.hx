package objects;

import objects.FunkinSprite;
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

class RenderSprite extends FunkinSprite
{
	var scaletolerp:Array<Float> = [1, 1];
	var angletolerp:Float = 0;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		FlxMouseEvent.add(this, onMouseDown, onMouseUp, null, null);
	}

	function onMouseDown(sprite:RenderSprite)
	{
		scaletolerp = [0.6, 1.4];
		angletolerp = FlxG.random.float(-30, 30);
	}

	function onMouseUp(sprite:RenderSprite)
	{
		scaletolerp = [1, 1];
		angletolerp = 0;
	}

	public function swapgraphicdata(newGraphic:FunkinSprite)
	{
		if (newGraphic.frames != null)
		{
			this.frames = newGraphic.frames;
		}
		else
		{
			loadGraphicFromSprite(newGraphic);
		}
	}

	override function update(elapsed:Float)
	{
		if (scale.x != scaletolerp[0])
		{
			scale.x = MathUtil.smoothLerpPrecision(scale.x, scaletolerp[0], elapsed, 0.5);
		}
		if (scale.y != scaletolerp[1])
		{
			scale.y = MathUtil.smoothLerpPrecision(scale.y, scaletolerp[1], elapsed, 0.5);
		}
		if (angle != angletolerp)
		{
			angle = MathUtil.smoothLerpPrecision(angle, angletolerp, elapsed, 0.5);
		}
		super.update(elapsed);
	}
}
