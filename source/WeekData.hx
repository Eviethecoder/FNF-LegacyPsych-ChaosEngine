package;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;
import haxe.format.JsonParser;
import flixel.util.FlxColor;

using StringTools;

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;
}

class WeekData
{
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];

	public var folder:String = '';

	// JSON variables
	public var weekfile:WeekFile;
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var songlist:Array<Dynamic>;
	public var weekName:String;
	public var freeplayColor:Array<Int>;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var difficulties:String;
	public var script:HaxeScript = null;

	public var fileName:String;

	public static function createWeekFile():WeekFile
	{
		var weekFile:WeekFile = {
			songs: [
				["Bopeebo", "dad", [146, 113, 253]],
				["Fresh", "dad", [146, 113, 253]],
				["Dad Battle", "dad", [146, 113, 253]]
			],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			freeplayColor: [146, 113, 253],
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: ''
		};
		return weekFile;
	}

	// HELP: Is there any way to convert a WeekFile to WeekData without having to put all variables there manually? I'm kind of a noob in haxe lmao
	public function new(weekFile:WeekFile, fileName:String)
	{
		var modsDirectories:Array<String> = Paths.getModDirectories();
		this.weekfile = weekFile;
		songlist = weekFile.songs;
		this.fileName = fileName;

		var scriptpath:String = 'data/weeks/' + fileName + '.hx';
		if (FileSystem.exists('assets/' + scriptpath))
		{
			try
			{
				trace('script found ' + scriptpath);
				script = HaxeScript.FromFile(scriptpath, this);
				script.onError = MusicBeatState.hscriptError;
			}
			catch (e:Dynamic)
			{
				MusicBeatState.addTextToDebug("   ...  " + Std.string(e), FlxColor.fromRGB(240, 166, 38));
				MusicBeatState.addTextToDebug("[ ERROR ] Could not load Event script " + scriptpath, 0xFF0000);
			}
		}
		else
		{
			for (folder in modsDirectories)
			{
				var modscriptpath:String = haxe.io.Path.join([Paths.mods(), folder, 'data/weeks/', fileName + '.hx']);
				if (FileSystem.exists(modscriptpath))
				{
					try
					{
						trace('script found ' + modscriptpath);
						script = HaxeScript.FromFile(modscriptpath, this);
						script.onError = MusicBeatState.hscriptError;
					}
					catch (e:Dynamic)
					{
						MusicBeatState.addTextToDebug("   ...  " + Std.string(e), FlxColor.fromRGB(240, 166, 38));
						MusicBeatState.addTextToDebug("[ ERROR ] Could not load Event script " + modscriptpath, 0xFF0000);
					}
				}
			}
		}
	}

	public function getsonglist():Array<Dynamic>
	{
		if (script != null)
		{
			trace('Running script function getsonglist');

			// Grab the function from the script
			var func = script.variables.get("getsonglist");

			if (func != null)
			{
				var songlist:Array<Dynamic> = cast Reflect.callMethod(null, func, []);
				if (songlist != null)
				{
					return songlist;
				}
				else
				{
					trace('Script returned null, falling back to JSON data.');
					return songs;
				}
			}
			else
			{
				trace('Script function getsonglist not found, using fallback.');
				return songs;
			}
		}
		else
		{
			// No script loaded, use fallback
			return songs;
		}
	}

	public function getweekcharacters():Array<String>
	{
		if (script != null)
		{
			trace('Running script function getweekcharacters');
			var func = script.variables.get("getweekcharacters");
			if (func != null)
			{
				var value:Array<String> = cast Reflect.callMethod(null, func, []);
				if (value != null)
				{
					return value;
				}
				return weekCharacters;
			}
			return weekCharacters;
		}
		return weekCharacters;
	}

	public function getweekbackground():String
	{
		if (script != null)
		{
			trace('Running script function getweekbackground');
			var func = script.variables.get("getweekbackground");
			if (func != null)
			{
				var value:String = cast Reflect.callMethod(null, func, []);
				if (value != null)
				{
					return value;
				}
				return weekBackground;
			}
			return weekBackground;
		}
		return weekBackground;
	}

	public function getweekbefore():String
	{
		if (script != null)
		{
			trace('Running script function getweekbefore');
			var func = script.variables.get("getweekbefore");
			if (func != null)
			{
				var value:String = cast Reflect.callMethod(null, func, []);
				if (value != null)
				{
					return value;
				}
				return weekBefore;
			}
			return weekBefore;
		}
		return weekBefore;
	}

	public function getstoryname():String
	{
		if (script != null)
		{
			trace('Running script function getstoryname');
			var func = script.variables.get("getstoryname");
			if (func != null)
			{
				var value:String = cast Reflect.callMethod(null, func, []);
				if (value != null)
				{
					return value;
				}
				return storyName;
			}
			return storyName;
		}
		return storyName;
	}

	public function getweekname():String
	{
		if (script != null)
		{
			trace('Running script function getweekname');
			var func = script.variables.get("getweekname");
			if (func != null)
			{
				var value:String = cast Reflect.callMethod(null, func, []);
				if (value != null)
				{
					return value;
				}
				return weekName;
			}
			return weekName;
		}
		return weekName;
	}

	public function getfreeplaycolor():Array<Int>
	{
		if (script != null)
		{
			trace('Running script function getfreeplaycolor');
			var func = script.variables.get("getfreeplaycolor");
			if (func != null)
			{
				var value:Array<Int> = cast Reflect.callMethod(null, func, []);
				if (value != null)
				{
					return value;
				}
				return freeplayColor;
			}
			return freeplayColor;
		}
		return freeplayColor;
	}

	public function getstartunlocked():Bool
	{
		if (script != null)
		{
			trace('Running script function getstartunlocked');
			var func = script.variables.get("getstartunlocked");
			if (func != null)
			{
				var value:Dynamic = Reflect.callMethod(null, func, []);
				if (value != null)
				{
					return cast value;
				}
				return startUnlocked;
			}
			return startUnlocked;
		}
		return startUnlocked;
	}

	public function gethiddenuntilunlocked():Bool
	{
		if (script != null)
		{
			trace('Running script function gethiddenuntilunlocked');
			var func = script.variables.get("gethiddenuntilunlocked");
			if (func != null)
			{
				var value:Dynamic = Reflect.callMethod(null, func, []);
				if (value != null)
				{
					return cast value;
				}
				return hiddenUntilUnlocked;
			}
			return hiddenUntilUnlocked;
		}
		return hiddenUntilUnlocked;
	}

	public function gethidestorymode():Bool
	{
		if (script != null)
		{
			trace('Running script function gethidestorymode');
			var func = script.variables.get("gethidestorymode");
			if (func != null)
			{
				var value:Dynamic = Reflect.callMethod(null, func, []);
				if (value != null)
				{
					return cast value;
				}
				return hideStoryMode;
			}
			return hideStoryMode;
		}
		return hideStoryMode;
	}

	public function gethidefreeplay():Bool
	{
		if (script != null)
		{
			trace('Running script function gethidefreeplay');
			var func = script.variables.get("gethidefreeplay");
			if (func != null)
			{
				var value:Dynamic = Reflect.callMethod(null, func, []);
				if (value != null)
				{
					return cast value;
				}
				return hideFreeplay;
			}
			return hideFreeplay;
		}
		return hideFreeplay;
	}

	public function getdifficulties():String
	{
		if (script != null)
		{
			trace('Running script function getdifficulties');
			var func = script.variables.get("getdifficulties");
			if (func != null)
			{
				var value:String = cast Reflect.callMethod(null, func, []);
				if (value != null)
				{
					return value;
				}
				return difficulties;
			}
			return difficulties;
		}
		return difficulties;
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false)
	{
		weeksList = [];
		weeksLoaded.clear();
		#if MODS_ALLOWED
		var disabledMods:Array<String> = [];
		var modsListPath:String = 'modsList.txt';
		var directories:Array<String> = [Paths.mods(), Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		if (FileSystem.exists(modsListPath))
		{
			var stuff:Array<String> = CoolUtil.coolTextFile(modsListPath);
			for (i in 0...stuff.length)
			{
				var splitName:Array<String> = stuff[i].trim().split('|');
				if (splitName[1] == '0') // Disable mod
				{
					disabledMods.push(splitName[0]);
				}
				else // Sort mod loading order based on modsList.txt file
				{
					var path = haxe.io.Path.join([Paths.mods(), splitName[0]]);
					// trace('trying to push: ' + splitName[0]);
					if (sys.FileSystem.isDirectory(path)
						&& !Paths.ignoreModFolders.contains(splitName[0])
						&& !disabledMods.contains(splitName[0])
						&& !directories.contains(path + '/'))
					{
						directories.push(path + '/');
						// trace('pushed Directory: ' + splitName[0]);
					}
				}
			}
		}

		var modsDirectories:Array<String> = Paths.getModDirectories();
		for (folder in modsDirectories)
		{
			var pathThing:String = haxe.io.Path.join([Paths.mods(), folder]) + '/';
			if (!disabledMods.contains(folder) && !directories.contains(pathThing))
			{
				directories.push(pathThing);
				// trace('pushed Directory: ' + folder);
			}
		}
		#else
		var directories:Array<String> = [Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		#end

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('data/weeks/weekList.txt'));
		for (i in 0...sexList.length)
		{
			for (j in 0...directories.length)
			{
				var fileToCheck:String = directories[j] + 'data/weeks/' + sexList[i] + '.json';
				if (!weeksLoaded.exists(sexList[i]))
				{
					var week:WeekFile = getWeekFile(fileToCheck);
					if (week != null)
					{
						var weekFile:WeekData = new WeekData(week, sexList[i]);

						#if MODS_ALLOWED
						if (j >= originalLength)
						{
							weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length - 1);
						}
						#end

						if (weekFile != null
							&& (isStoryMode == null
								|| (isStoryMode && !weekFile.hideStoryMode)
								|| (!isStoryMode && !weekFile.hideFreeplay)))
						{
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length)
		{
			var directory:String = directories[i] + 'data/weeks/';
			if (FileSystem.exists(directory))
			{
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
				for (daWeek in listOfWeeks)
				{
					var path:String = directory + daWeek + '.json';
					if (sys.FileSystem.exists(path))
					{
						addWeek(daWeek, path, directories[i], i, originalLength);
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
					}
				}
			}
		}
		#end
	}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if (!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path);
			if (week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if (i >= originalLength)
				{
					#if MODS_ALLOWED
					weekFile.folder = directory.substring(Paths.mods().length, directory.length - 1);
					#end
				}
				if ((PlayState.isStoryMode && !weekFile.hideStoryMode) || (!PlayState.isStoryMode && !weekFile.hideFreeplay))
				{
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile
	{
		var rawJson:String = null;
		#if MODS_ALLOWED
		if (FileSystem.exists(path))
		{
			rawJson = File.getContent(path);
		}
		#else
		if (OpenFlAssets.exists(path))
		{
			rawJson = Assets.getText(path);
		}
		#end

		if (rawJson != null && rawJson.length > 0)
		{
			return cast Json.parse(rawJson);
		}

		return null;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE
	// To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String
	{
		return weeksList[PlayState.storyWeek];
	}

	// Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():WeekData
	{
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null)
	{
		Paths.currentModDirectory = '';
		if (data != null && data.folder != null && data.folder.length > 0)
		{
			Paths.currentModDirectory = data.folder;
		}
	}

	public static function loadTheFirstEnabledMod()
	{
		Paths.currentModDirectory = '';

		#if MODS_ALLOWED
		if (FileSystem.exists("modsList.txt"))
		{
			var list:Array<String> = CoolUtil.listFromString(File.getContent("modsList.txt"));
			var foundTheTop = false;
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1" && !foundTheTop)
				{
					foundTheTop = true;
					Paths.currentModDirectory = dat[0];
				}
			}
		}
		#end
	}
}
