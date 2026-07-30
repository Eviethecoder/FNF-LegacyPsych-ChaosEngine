package;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import debug.FPSCounter;
import debug.ConsoleCore;
import debug.ConsolePlugin;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import winapi.WindowsAPI;
// crash handler stuff
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#if hxdiscord_rpc
import Discord.DiscordClient;
#end
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import debug.FunkinDebugDisplay;

using StringTools;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).

	public static var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.

	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var fpsVar:FPSCounter;

	/**
	 * The debug display at the top left.
	 */
	public static var debugDisplay:FunkinDebugDisplay;

	// You can pretty much ignore everything from here on - your code should go in your states.

	static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		var game:FlxGame = new FlxGame(gameWidth, gameHeight, InitState, #if (flixel < "5.0.0") zoom, #end framerate, framerate, skipSplash, startFullscreen);
		objects.Cursor.registerHaxeUICursors();
		@:privateAccess
		game._customSoundTray = FunkinSoundTray;
		FlxG.signals.postUpdate.add(function()
		{
			if (FlxG.keys.justPressed.F1)
			{
				trace('window');
				WindowsAPI.allocConsole();
			}
		});
		addChild(game);

		untyped FlxG.cameras = new graphics.FunkinCameraFrontEnd();
		#if !mobile
		// addChild gets called by the user settings code.
		debugDisplay = new FunkinDebugDisplay(10, 10, 0xFFFFFF);
		addChild(debugDisplay);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		ConsoleCore.instance = new ConsoleCore();
		FlxG.plugins.add(new ConsolePlugin());
	}

	private final function onCrash(e:UncaughtErrorEvent):Void
	{
		var emsg:String = "";
		for (stackItem in haxe.CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					emsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
					trace(stackItem);
			}
		}

		FlxG.switchState(new debug.CrashReportSubstate(FlxG.state, emsg, e.error));
	}
}
