package chorus.backend.debug;

class Consolehandler
{
	public static function print(value:Dynamic, ?pos:haxe.PosInfos):Void
	{
		GameConsole.print(formatMessage(value, pos));
		openConsole();
	}

	public static function warn(value:Dynamic, ?pos:haxe.PosInfos):Void
	{
		GameConsole.warn(Std.string(value), pos);
		openConsole();
	}

	public static function error(value:Dynamic, ?pos:haxe.PosInfos):Void
	{
		GameConsole.error(Std.string(value), pos);
	}

	static function formatMessage(value:Dynamic, ?pos:haxe.PosInfos):String
	{
		var location = pos != null ? pos.className : "?";
		return '$location: ${Std.string(value)}';
	}

	static function openConsole():Void
	{
		if (GameConsole.instance != null)
			GameConsole.instance.open();
	}
}
