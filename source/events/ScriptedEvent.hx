package events;

import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import utility.Scripthandler;
import PlayState;
import flixel.FlxBasic;
import HaxeScript;

using StringTools;

class ScriptedEvent extends BaseEvent
{
	public var script:HaxeScript;

	public function new(name:String)
	{
		super();
		eventName = name;
		script = Scripthandler.setupScripts("data/events/" + name + ".hx", this, "eventscript", true);
		debug.Consolehandler.print("script for event: " + name + " is: " + script);
	}

	public override function triggerEvent():Void
	{
		runfunction('TriggerEvent', []);
	}

	public override function precacheEvent(daevent:Note.EventNote):Void
	{
		runfunction('precacheEvent', [daevent]);
	}

	public function runfunctionOnScripts(funcname:String, params:Array<HaxeScript.AnyValue>):Void
	{
		if (script != null)
		{
			script.runFunction(funcname, params);
		}
	}

	public function runfunction(funcname:String, params:Array<Dynamic>):Void
	{
		if (script != null)
		{
			script.runFunction(funcname, params);
		}
	}
}
