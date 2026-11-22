package chorus.backend.utils;

import haxe.ds.List;
import haxe.zip.Entry;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;

using StringTools;

class Ziputil
{
	public static function readStage(entries:List<Entry>):Map<String, Dynamic>
	{
		var results:Array<Entry> = new Array<Entry>();

		var assetsMap:Map<String, Dynamic> = new Map();
		for (entry in entries)
		{
			if (entry.compressed)
			{
				entry.data = haxe.zip.Reader.unzip(entry);
			}

			results.push(entry);
		}

		for (r in results)
		{
			if (r.fileName.endsWith('.png'))
			{
				var fileName = haxe.io.Path.withoutDirectory(r.fileName);
				var byteArray:ByteArray = ByteArray.fromBytes(r.data);
				var bitmapData:BitmapData = BitmapData.fromBytes(byteArray);
				trace(bitmapData.height);
				assetsMap.set(fileName, bitmapData);
			}
			else
				switch (haxe.io.Path.extension(r.fileName))
				{
					case "json":
						var fileName = haxe.io.Path.withoutDirectory(r.fileName);
						var jsonData = r.data;
						assetsMap.set('json', jsonData);
					case "hx":
						var fileName = haxe.io.Path.withoutDirectory(r.fileName);
						var scriptdata = r.data;
						assetsMap.set('script', scriptdata);
					case "xml":
						assetsMap.set(haxe.io.Path.withoutDirectory(r.fileName), r.data.toString());
				}
		}
		trace(assetsMap);
		return assetsMap;
	}
}
