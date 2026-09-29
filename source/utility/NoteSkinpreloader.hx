package utility;

import flixel.util.FlxColor;
import flixel.FlxG;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import json2object.JsonParser;
import flixel.sound.FlxSound;
import haxe.Json;
import utility.NoteSkinHelper.NoteSkin;
import utility.NoteSkinHelper.NoteData;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

using StringTools;

/*
 * A class used to preload any NoteSkin JSON data.
 * Will be autoloaded into a map to be used anywhere it's needed.
 */
class NoteSkinpreloader
{
	public static var noteskinmap:Map<String, NoteSkin> = [];

	public static var notetypeSkinmap:Map<String, NoteData> = [];

	public static function addnoteskintomap(path:String, file:String)
	{
		#if sys
		if (!FileSystem.exists(path))
		{
			trace('NoteSkinpreloader: could not find noteskin json "$file" at $path');
			return;
		}
		#end

		try
		{
			#if sys
			var rawJson = File.getContent(path);
			#else
			var rawJson = Assets.getText(path);
			#end

			var parser:JsonParser<NoteSkin> = new JsonParser<NoteSkin>();
			parser.fromJson(rawJson, path);
			validatejson(parser.value, file, rawJson);
		}
		catch (e:Dynamic)
		{
			trace('NoteSkinpreloader: failed to parse noteskin "$file": $e');
		}
	}

	public static function grabnoteskindata(noteskin:String):NoteSkin
	{
		if (noteskin != null && noteskinmap.exists(noteskin))
			return noteskinmap.get(noteskin);

		return noteskinmap.get('default');
	}

	public static function validatejson(input:NoteSkin, file:String, ?rawJson:String)
	{
		var key:String = file.replace('.json', '');
		if (input == null)
		{
			if (rawJson != null)
			{
				try
				{
					var parsed:Dynamic = Json.parse(rawJson);
					noteskinmap.set(key, parsed);
				}
				catch (e:Dynamic)
				{
					trace('NoteSkinpreloader: Failed to parse noteskin json "$file": $e');
				}
			}
			return;
		}
		else
		{
			noteskinmap.set(key, input);
		}
	}

	public static function noteskinLookup()
	{
		var directories:Array<String> = [Paths.getPreloadPath('data/NoteSkins')];
		for (mod in Paths.getGlobalMods())
		{
			directories.push(Paths.mods(mod + '/data/NoteSkins/'));
		}
		lookup(directories);
	}

	public static function noteSkinLookup()
	{
		noteskinLookup();
	}

	public static function lookup(directories:Array<String>)
	{
		for (i in 0...directories.length)
		{
			var directory = directories[i];
			#if sys
			directory = Paths.resolveAssetDirectory(directory);
			if (sys.FileSystem.exists(directory))
			{
				for (file in sys.FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path))
					{
						if (path.endsWith('.json'))
						{
							addnoteskintomap(path, file);
						}
					}
					else
					{
						var subDirectory = haxe.io.Path.addTrailingSlash(path);
						directories.push(subDirectory);
					}
				}
			}
			#end
		}
	}

	/**
	 * Preloads a list of noteskin JSONs into the cache.
	 * @param skins Array of noteskin names to preload
	 */
	public static function preloadNoteSkins(skins:Array<String>):Void
	{
		for (skin in skins)
		{
			preloadNoteSkin(skin);
		}
	}

	/**
	 * Preloads a single noteskin JSON into the cache.
	 * @param skin The name of the noteskin to preload
	 */
	public static function preloadNoteSkin(skin:String):Void
	{
		if (skin == null || skin.length < 1)
			return;

		if (noteskinmap.exists(skin))
			return;

		var path:String = Paths.getPath('data/NoteSkins/$skin.json', TEXT);
		#if sys
		path = Paths.resolveAssetPath(path);
		#end
		addnoteskintomap(path, '$skin.json');
	}

	/**
	 * Clears the entire noteskin cache. Useful when switching states
	 * or freeing memory.
	 */
	public static function clearCache():Void
	{
		noteskinmap.clear();
	}

	/**
	 * Removes a single noteskin from the cache.
	 * @param skin The name of the noteskin to remove
	 */
	public static function removeFromCache(skin:String):Void
	{
		if (noteskinmap.exists(skin))
			noteskinmap.remove(skin);
	}
}

typedef NoteSkinPreloader = NoteSkinpreloader;
