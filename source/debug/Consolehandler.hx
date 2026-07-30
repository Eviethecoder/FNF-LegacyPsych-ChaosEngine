package debug;

import debug.ConsolePlugin;
import debug.ConsoleLogType;

class Consolehandler {
	public static function print(text:String, ?pos:haxe.PosInfos)
	{
		var location = pos.className;
		if (ConsolePlugin.instance != null && ConsolePlugin.instance.ui != null) {
			ConsolePlugin.instance.ui.print('$location: $text', NORMAL);
			ConsolePlugin.instance.togglevisible(true);
		}
		trace('[$location] $text');
	}

	public static function warn(text:String, ?pos:haxe.PosInfos)
	{
		var location = pos.className;
		if (ConsolePlugin.instance != null && ConsolePlugin.instance.ui != null) {
			ConsolePlugin.instance.ui.printFromClass(location,' $text', 0xFFFF44, WARNING);
			ConsolePlugin.instance.togglevisible(true);
		}
		trace('[WARN][$location] $text');
	}

	public static function error(text:String, ?pos:haxe.PosInfos)
	{
		var location = pos.className;
		if (ConsolePlugin.instance != null && ConsolePlugin.instance.ui != null) {
			ConsolePlugin.instance.ui.print('$location: $text', ERROR);
			ConsolePlugin.instance.togglevisible(true);
		}
		trace('[ERROR][$location] $text');
	}
}