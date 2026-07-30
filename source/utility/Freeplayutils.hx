package utility;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import data.SongMetadata.Metadata;
import json2object.JsonParser;

using StringTools;

class Freeplayutils
{
	public static function getSongFolders():Map<String, Metadata>
	{
		var baseFolder = 'assets/data/songs/default';
		var result:Map<String, Metadata> = new Map<String, Metadata>();

		if (!FileSystem.exists(baseFolder) || !FileSystem.isDirectory(baseFolder))
			debug.Consolehandler.print('Base folder missing or invalid, skipping base scan: ' + baseFolder);
		else
		{
			for (entry in FileSystem.readDirectory(baseFolder))
			{
				var songFolder = Path.join([baseFolder, entry]);
				if (!FileSystem.isDirectory(songFolder))
					continue;

				var metadataPath = Path.join([songFolder, 'metadata.json']);
				if (FileSystem.exists(metadataPath) && !FileSystem.isDirectory(metadataPath))
				{
					try
					{
						var rawJson:String = File.getContent(metadataPath);
						if (rawJson != null && rawJson.trim().length > 0)
						{
							var parser:JsonParser<Metadata> = new JsonParser<Metadata>();
							parser.fromJson(rawJson, metadataPath);

							if (parser.errors != null && parser.errors.length > 0)
							{
								for (error in parser.errors)
									trace(error);
							}

							if (parser.value != null)
							{
								var songName:String = parser.value.name != null
									&& parser.value.name.trim().length > 0 ? parser.value.name : entry;
								result.set(songName, parser.value);
							}
						}
					}
					catch (e:Dynamic)
					{
						trace('Failed to read metadata at ' + metadataPath + ': ' + e);
					}
				}
			}
		}
		for (mod in Paths.getGlobalMods())
		{
			var modFolder = Paths.mods(mod + '/data/songs/default');
			// debug.Consolehandler.print('Mod folder: ' + modFolder);

			if (!FileSystem.exists(modFolder) || !FileSystem.isDirectory(modFolder))
			{
				// debug.Consolehandler.print('Skipping invalid mod folder: ' + modFolder);
				continue;
			}

			for (entry in FileSystem.readDirectory(modFolder))
			{
				var songFolder = Path.join([modFolder, entry]);
				if (!FileSystem.isDirectory(songFolder))
					continue;

				var metadataPath = Path.join([songFolder, 'metadata.json']);
				if (FileSystem.exists(metadataPath) && !FileSystem.isDirectory(metadataPath))
				{
					try
					{
						var rawJson:String = File.getContent(metadataPath);
						if (rawJson != null && rawJson.trim().length > 0)
						{
							var parser:JsonParser<Metadata> = new JsonParser<Metadata>();
							parser.fromJson(rawJson, metadataPath);

							if (parser.errors != null && parser.errors.length > 0)
							{
								for (error in parser.errors)
									trace(error);
							}

							if (parser.value != null)
							{
								var songName:String = parser.value.name != null
									&& parser.value.name.trim().length > 0 ? parser.value.name : entry;
								result.set(songName, parser.value);
							}
						}
					}
					catch (e:Dynamic)
					{
						trace('Failed to read metadata at ' + metadataPath + ': ' + e);
					}
				}
			}
		}
		return result;
	}
}
