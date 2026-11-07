package chorus.backend.base;
import chorus.objects.game.Note.EventNote;
import chorus.objects.game.Note.Eventsvalue;

import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import chorus.states.PlayState;
import flixel.FlxBasic;
import chorus.backend.scripting.HaxeScript;

using StringTools;

typedef EventSchematic =
{
	var eventLogic:Array<EventData>;
}

typedef EventData =
{
	var name:String;
	var title:String;
	var type:SongEventTypes;
	@:optional
	var list:Array<String>;
	var rownum:Int;
}

typedef Eventdata =
{
	var name:String;
	var uitype:String;
	var value:Array<EventUnion>;
}

class BaseEvent extends FlxBasic
{
	public var earlyTriggerTime:Float = 0;
	public var eventName:String = "";
	public var eventScript:HaxeScript;

	public var eventData:Array<Eventsvalue> = [];

	public function new()
	{
		super();
	}

	public function triggerEvent():Void
	{
	}

	public function precacheEvent(daevent:EventNote):Void
	{
	}

	private function getEventValue(name:String):Null<EventUnion>
	{
		for (event in eventData)
		{
			if (event.name == name)
				return event.value;
		}
		return null;
	}

	// we gota make sure the cast is corect, otherwise it dies
	public function grabeventFloat(name:String):Float
	{
		var v = getEventValue(name);
		if (v == null)
			return 0;

		var raw:Dynamic = cast v;
		if (Std.isOfType(raw, Float))
			return cast(raw, Float);
		return 0;
	}

	public function grabeventBool(name:String):Bool
	{
		var v = getEventValue(name);
		if (v == null)
			return false;

		var raw:Dynamic = cast v;
		if (Std.isOfType(raw, Bool))
			return cast(raw, Bool);
		return false;
	}

	public function grabeventString(name:String):String
	{
		var v = getEventValue(name);
		if (v == null)
			return '';

		var raw:Dynamic = cast v;

		if (Std.isOfType(raw, String))
			return cast(raw, String);
		return '';
	}
}

/**
 * The available field types for a song event schema.
 */
enum abstract SongEventTypes(String) from String to String
{
	/**
	 * The STRING type will display as a text field.
	 */
	public var STRING = "STRING";

	/**
	 * The FLOAT type will display as a text field that only accepts numbers.
	 */
	public var FLOAT = "FLOAT";

	/**
	 * The BOOL type will display as a checkbox.
	 */
	public var BOOL = "BOOL";

	/**
	 * The DropDown type will display as a dropdown.
	 * Make sure to specify the `list` field in the schema.
	 */
	public var DROPDOWN = "DROPDOWN";
}
