package debug;

import debug.ConsolePlugin;
import debug.ConsoleLogType;
import HaxeScript.AnyValue;

class Consolehandler
{
	public static function print(value:AnyValue, ?pos:haxe.PosInfos)
	{
		var location = pos.className;
		var text = Std.string(value);
		if (ConsolePlugin.instance != null && ConsolePlugin.instance.ui != null)
		{
			ConsolePlugin.instance.ui.print('$location: $text', NORMAL);
			ConsolePlugin.instance.togglevisible(true);
		}
		trace('[$location] $text');
	}

	public static function warn(value:AnyValue, ?pos:haxe.PosInfos)
	{
		var location = pos.className;
		var text = Std.string(value);
		if (ConsolePlugin.instance != null && ConsolePlugin.instance.ui != null)
		{
			ConsolePlugin.instance.ui.printFromClass(location, ' $text', 0xFFFF44, WARNING);
			ConsolePlugin.instance.togglevisible(true);
		}
		trace('[WARN][$location] $text');
	}

	public static function error(value:AnyValue, ?pos:haxe.PosInfos)
	{
		var location = pos.className;
		var text = Std.string(value);
		if (ConsolePlugin.instance != null && ConsolePlugin.instance.ui != null)
		{
			ConsolePlugin.instance.ui.print('$location: $text', ERROR);
			ConsolePlugin.instance.togglevisible(true);
		}
		trace('[ERROR][$location] $text');
	}
}
