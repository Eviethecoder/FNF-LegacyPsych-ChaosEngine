package chorus.backend.chartevents;

import chorus.backend.base.BaseEvent;
import chorus.backend.debug.Consolehandler;
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
import chorus.backend.utils.Conductor;
import chorus.objects.game.HealthIcon;
import chorus.states.PlayState;

class PlayAnim extends BaseEvent
{
	public function new()
	{
		super();
		eventName = "PlayAnim";
	}

	override public function triggerEvent():Void
	{
		var shouldforce:Bool = grabeventBool("Force");
		var value1:String = grabeventString("AnimToPlay");
		var spritefocus:String = grabeventString("Character");
		var propname:String = grabeventString("PropName");

		try
		{
			switch (spritefocus)
			{
				case "Dad":
					PlayState.instance.stage.dad.playAnim(value1, shouldforce);
				case "GF":
					PlayState.instance.stage.gf.playAnim(value1, shouldforce);
				case "BF":
					PlayState.instance.stage.boyfriend.playAnim(value1, shouldforce);
				case "Prop":
					PlayState.instance.stage.grabProp(propname).animation.play(value1, shouldforce);
			}
		}
		catch (e:Dynamic)
		{
			Consolehandler.error('Error triggering PlayAnim event: ' + e);
		}
	}
}
