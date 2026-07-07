package debug;

import debug.ConsolePlugin;
import debug.ConsoleLogType;

class Consolehandler {
	public static function print(text:String)
	{
		if (ConsolePlugin.instance != null && ConsolePlugin.instance.ui != null)
			ConsolePlugin.instance.ui.print(text, NORMAL);
            ConsolePlugin.instance.togglevisible(true);
		trace(text);
	}

	public static function warn(text:String)
	{
		if (ConsolePlugin.instance != null && ConsolePlugin.instance.ui != null)
			ConsolePlugin.instance.ui.print(text, WARNING);
            ConsolePlugin.instance.togglevisible(true);
		trace('[WARN] $text');
	}

	public static function error(text:String)
	{
		if (ConsolePlugin.instance != null && ConsolePlugin.instance.ui != null)
			ConsolePlugin.instance.ui.print(text, ERROR);
            ConsolePlugin.instance.togglevisible(true);
		trace('[ERROR] $text');
	}
}