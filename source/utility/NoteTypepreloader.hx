package utility;

import haxe.Json;
import json2object.JsonParser;
import utility.NoteSkinHelper.NoteData;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

/*
 * Scans the custom_notetypes folder tree (base assets + every mod folder, including
 * subdirectories) for custom note type definitions, mirroring how NoteSkinpreloader
 * discovers and caches NoteSkin jsons. Supports .json note type data files in addition
 * to the existing .hx/.lua note type scripts.
 */
class NoteTypepreloader
{
	public static var notetypejsonmap:Map<String, NoteData> = [];

	/**
	 * Returns every unique custom note type name found in custom_notetypes (.json/.hx/.lua),
	 * searching the base assets folder as well as the current mod and every global mod.
	 * Also preloads/caches any .json note type data it finds along the way.
	 */
	public static function customNoteTypeLookup():Array<String>
	{
		var directories:Array<String> = [
			Paths.getPreloadPath('data/custom_notetypes/'),
			Paths.mods('data/custom_notetypes/'),
		];
		for (mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/data/custom_notetypes/'));

		trace(directories);

		var found:Map<String, Bool> = new Map<String, Bool>();
		lookup(directories, found);

		var names:Array<String> = [for (name in found.keys()) name];
		return names;
	}

	static function lookup(directories:Array<String>, found:Map<String, Bool>):Void
	{
		#if sys
		var i:Int = 0;
		while (i < directories.length)
		{
			var directory:String = Paths.resolveAssetDirectory(directories[i]);
			i++;

			if (!FileSystem.exists(directory))
				continue;

			for (file in FileSystem.readDirectory(directory))
			{
				var path:String = haxe.io.Path.join([directory, file]);
				trace('Found file: $path');
				if (FileSystem.isDirectory(path))
				{
					directories.push(haxe.io.Path.addTrailingSlash(path));
					continue;
				}

				trace('Processing file: $file' + ' isJson: ' + file.endsWith('.json'));

				if (file.endsWith('.json'))
				{
					var name:String = file.substr(0, file.length - 5);
					trace('Adding note type to map: $name' + ' files: ' + file);
					if (!found.exists(name))
					{
						found.set(name, true);
					}
					if (!notetypejsonmap.exists(name))
						addnotetypetomap(path, file);
				}
				else if (file.endsWith('.hx') || file.endsWith('.lua'))
				{
					var extLength:Int = file.endsWith('.hx') ? 3 : 4;
					var name:String = file.substr(0, file.length - extLength);
					if (!found.exists(name))
						found.set(name, true);
				}
			}
		}
		#end
	}

	static function addnotetypetomap(path:String, file:String):Void
	{
		#if sys
		try
		{
			var rawJson:String = File.getContent(path);
			var parser:JsonParser<NoteData> = new JsonParser<NoteData>();
			parser.fromJson(rawJson, path);
			validatejson(parser.value, file, rawJson);
		}
		catch (e:Dynamic)
		{
			trace('NoteTypepreloader: failed to parse custom note type json "$file": $e');
		}
		#end
	}

	public static function validatejson(input:NoteData, file:String, ?rawJson:String):Void
	{
		var key:String = file.replace('.json', '');
		if (input == null)
		{
			if (rawJson != null)
			{
				try
				{
					var parsed:Dynamic = Json.parse(rawJson);
					notetypejsonmap.set(key, cast parsed);
				}
				catch (e:Dynamic)
				{
					trace('NoteTypepreloader: Failed to parse custom note type json "$key": $e');
				}
			}
			return;
		}

		notetypejsonmap.set(key, input);
	}

	public static function grabNoteTypeJson(name:String):NoteData
	{
		return notetypejsonmap.exists(name) ? notetypejsonmap.get(name) : null;
	}

	public static function clearCache():Void
	{
		notetypejsonmap.clear();
	}
}
