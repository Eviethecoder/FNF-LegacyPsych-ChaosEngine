package utility;

import HaxeScript;
import Paths;
import StringTools;
import sys.FileSystem;
import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.utils.Assets as OpenFlAssets;
import Std;

class Scripthandler
{
	public static var gamescriptArray:Array<HaxeScript> = [];

	public static function checkDirectoryScripts(directorys:Array<String>, obj:Dynamic, type:String = "gamescript"):Void
	{
		var filesPushed:Array<String> = [];
		for (i in 0...directorys.length)
		{
			var folder = directorys[i];
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (StringTools.endsWith(file, '.hx') && !filesPushed.contains(file))
					{
						try
						{
							trace('script found!! ' + folder + file);
							var script = HaxeScript.FromFile(folder + file, obj);
							script.onError = MusicBeatState.hscriptError;
							switch (type)
							{
								case "gamescript":
									gamescriptArray.push(script);
								default:
									// add other script types here later
							}
							filesPushed.push(file);
						}
						catch (e:Dynamic)
						{
							MusicBeatState.addTextToDebug("   ...  " + Std.string(e), FlxColor.fromRGB(240, 166, 38));
							MusicBeatState.addTextToDebug("[ ERROR ] Could not load script " + file, FlxColor.RED);
						}
					}
				}
			}
		}
		filesPushed = [];
	}

	public static function setupScripts(scriptpath:String, obj:Dynamic, type:String = "gamescript", returnscript:Bool = false):Dynamic
	{
		var assetpath = Paths.getPreloadPath(scriptpath);
		var modpath = Paths.mods(scriptpath);
		trace('modpath is: ' + modpath);
		trace('assetpath is: ' + assetpath);
		var script:Dynamic = null;
		if (FileSystem.exists(assetpath))
		{
			try
			{
				trace('script found ' + assetpath);
				script = HaxeScript.FromFile(assetpath, obj);
				script.onError = MusicBeatState.hscriptError;
				switch (type)
				{
					case "gamescript":
						gamescriptArray.push(script);
					default:
				}
			}
			catch (e:Dynamic)
			{
				MusicBeatState.addTextToDebug("   ...  " + Std.string(e), FlxColor.fromRGB(240, 166, 38));
				MusicBeatState.addTextToDebug("[ ERROR ] Could not load Event script " + scriptpath, FlxColor.RED);
			}
		}

		for (mod in Paths.getGlobalMods())
		{
			var fileToCheck:String = Paths.mods(mod + '/' + scriptpath);
			if (FileSystem.exists(fileToCheck))
			{
				try
				{
					trace('script found ' + fileToCheck);
					script = HaxeScript.FromFile(fileToCheck, obj);
					script.onError = MusicBeatState.hscriptError;
					switch (type)
					{
						case "gamescript":
							gamescriptArray.push(script);
						default:
							// add other script types here later
					}
				}
				catch (e:Dynamic)
				{
					MusicBeatState.addTextToDebug("   ...  " + Std.string(e), FlxColor.fromRGB(240, 166, 38));
					MusicBeatState.addTextToDebug("[ ERROR ] Could not load Event script " + fileToCheck, FlxColor.RED);
				}
			}
		}

		if (returnscript)
		{
			return script;
		}
		else
		{
			return null;
		}
	}

	public static function dispatchevent(name:String, params:Array<Dynamic>):Void
	{
		for (script in gamescriptArray)
		{
			script.runFunction(name, params);
		}
	}
}
