package utility;

import flixel.FlxBasic;
import flixel.util.FlxSignal;

class SignalDispatcher extends FlxBasic
{
	public static var signalmap:Map<String, Dynamic>;

	public static var defaultsignallisteners:Array<String> = ['onPause', 'onResume'];

	public function new()
	{
		super();
	}

	public static function initializesignals():Void
	{
		if (signalmap == null)
			signalmap = new Map<String, Dynamic>();

		for (name in defaultsignallisteners)
		{
			adddefaultSignal(name);
		}
	}

	public static function addSignal<T>(name:String, signal:FlxTypedSignal<T>):Void
	{
		signalmap.set(name, signal);
	}

	public static function adddefaultSignal(name:String):Void
	{
		if (signalmap == null)
			signalmap = new Map<String, Dynamic>();
		if (!signalmap.exists(name))
			signalmap.set(name, new FlxSignal());
	}

	public static function dispatch(name:String, param:Dynamic = null):Void
	{
		if (signalmap != null && signalmap.exists(name))
		{
			if (param != null)
				signalmap.get(name).dispatch(param);
			else
				signalmap.get(name).dispatch();
		}
	}

	public static function addtoSignal(name:String, listener:Dynamic):Void
	{
		if (signalmap == null)
			signalmap = new Map<String, FlxSignal>();
		if (!signalmap.exists(name))
			signalmap.set(name, new FlxSignal());
		signalmap.get(name).add(listener);
	}

	public static function removefromSignal(name:String, listener:Dynamic):Void
	{
		if (signalmap != null && signalmap.exists(name))
		{
			signalmap.get(name).remove(listener);
		}
	}
}
