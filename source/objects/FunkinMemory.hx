package objects;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFlAssets;
import openfl.utils.AssetType;
import lime.utils.Assets;
import flash.media.Sound;
import ClientPrefs;
#if sys
import sys.FileSystem;
#end

using StringTools;


@:access(openfl.display.BitmapData)
@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
class FunkinMemory
{



	public static var dumpExclusions:Array<String> = [
		'assets/music/freakyMenu.' + Paths.SOUND_EXT,
		'assets/shared/music/breakfast.' + Paths.SOUND_EXT,
		'assets/shared/music/tea-time.' + Paths.SOUND_EXT,
	];

	public static function excludeAsset(key:String):Void
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	


	public static var currentTrackedImages:Map<String, FlxGraphic> = [];


	public static var permanentImages:Map<String, FlxGraphic> = [];


	public static var localTrackedImages:Array<String> = [];

	inline static function trackLocalImageKey(key:String):Void
	{
		if (key != null && !localTrackedImages.contains(key))
			localTrackedImages.push(key);
	}



	/** Every sound that has been loaded this session. */
	public static var currentTrackedSounds:Map<String, Sound> = [];

	/** Keys of sounds used in the current scene; reset each transition. */
	public static var localTrackedSounds:Array<String> = [];


	/** Frees images that are no longer needed in the current scene. */
	public static function clearUnusedMemory():Void
	{
		for (key in currentTrackedImages.keys())
		{
			if (!localTrackedImages.contains(key)
				&& !dumpExclusions.contains(key)
				&& !permanentImages.exists(key))
			{
				destroyGraphic(currentTrackedImages.get(key));
				currentTrackedImages.remove(key);
			}
		}
		cpp.vm.Gc.run(true);
	}

	/** Clears everything that isn't in the tracked maps, then resets locals. */
	public static function clearStoredMemory():Void
	{
		// images — remove anything Flixel knows about that we aren't tracking
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedImages.exists(key) && !permanentImages.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		// sounds — release every non-permanent cached sound
		for (key in currentTrackedSounds.keys())
		{
			if (!dumpExclusions.contains(key))
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		localTrackedImages = [];
		localTrackedSounds = [];
		// Avoid resetting bitmap cache here: it can invalidate permanent textures.
		// #if !html5 openfl.Assets.cache.clear("songs"); #end
		cpp.vm.Gc.run(true);
	}



	/**
	 * Permanently caches an image by asset path so it is never evicted.
	 */
	public static function permanentCacheTexture(key:String, ?allowGPU:Bool = true):Void
	{
		
		if (key == null)
		{
			trace('FunkinMemory Failed to permanently cache graphic: $key');
			return;
		}

		if (permanentImages.exists(key))
			return;

		var graphic:FlxGraphic = currentTrackedImages.get(key);
		if (graphic == null)
			graphic = createGraphic(key, allowGPU);

		if (graphic == null)
		{
			trace('FunkinMemory Failed to permanently cache graphic: $key');
			return;
		}

		graphic.persist = true;
		graphic.destroyOnNoUse = false;
		currentTrackedImages.remove(key);
		localTrackedImages.remove(key);
		permanentImages.set(key, graphic);
	}

	/**
	 * Temporarily caches an image by asset path so it survives until memory cleanup.
	 */
	public static function temporaryCacheTexture(key:String, ?allowGPU:Bool = true):FlxGraphic
	{
	
		if (key == null)
		{
			trace('FunkinMemory Failed to temporarily cache graphic: $key');
			return null;
		}

		if (permanentImages.exists(key))
		{
			trackLocalImageKey(key);
			return permanentImages.get(key);
		}

		if (currentTrackedImages.exists(key))
		{
			trackLocalImageKey(key);
			return currentTrackedImages.get(key);
		}

		var graphic:FlxGraphic = createGraphic(key, allowGPU);
		if (graphic == null)
		{
			trace('FunkinMemory Failed to temporarily cache graphic: $key');
			return null;
		}

		currentTrackedImages.set(key, graphic);
		trackLocalImageKey(key);

		return graphic;
	}


	static function loadBitmapForKey(key:String):BitmapData
	{
		#if sys
		if (FileSystem.exists(key))
			return BitmapData.fromFile(key);
		#end

		if (OpenFlAssets.exists(key, IMAGE))
			return OpenFlAssets.getBitmapData(key);

		return null;
	}

	static function prepareBitmapForGPU(bitmap:BitmapData, allowGPU:Bool):Void
	{
		if (!allowGPU || !ClientPrefs.data.cacheOnGPU || bitmap == null || bitmap.image == null || FlxG.stage == null || FlxG.stage.context3D == null)
			return;

		bitmap.lock();
		if (bitmap.__texture == null)
		{
			bitmap.image.premultiplied = true;
			bitmap.getTexture(FlxG.stage.context3D);
		}
		bitmap.getSurface();
		bitmap.disposeImage();
		bitmap.image.data = null;
		bitmap.image = null;
		bitmap.readable = true;
	}

	static function createGraphic(key:String, allowGPU:Bool):FlxGraphic
	{
		var bitmap:BitmapData = loadBitmapForKey(key);
		if (bitmap == null)
			return null;

		prepareBitmapForGPU(bitmap, allowGPU);

		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graphic.persist = true;
		graphic.destroyOnNoUse = false;
		return graphic;
	}



	inline static function destroyGraphic(graphic:FlxGraphic):Void
	{
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	public static function cacheBitmap(key:String, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		

		if (bitmap == null)
		{
			bitmap = loadBitmapForKey(key);
			if (bitmap == null)
			{
				trace('FunkinMemory: Bitmap not found: $key');
				return null;
			}
		}

		prepareBitmapForGPU(bitmap, allowGPU);

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graph.persist = true;
		graph.destroyOnNoUse = false;
		currentTrackedImages.set(key, graph);
		return graph;
	}

	public static function returnGraphic(key:String):FlxGraphic
	{
		var modKey:String = Paths.modsImages(key);
		if (FileSystem.exists(modKey))
		{
			if (permanentImages.exists(modKey))
			{
				trackLocalImageKey(modKey);
				return permanentImages.get(modKey);
			}

			if (!currentTrackedImages.exists(modKey))
			{
				var newBitmap:BitmapData = BitmapData.fromFile(modKey);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, modKey);
				newGraphic.persist = true;
				currentTrackedImages.set(modKey, newGraphic);
			}
			trackLocalImageKey(modKey);
			return currentTrackedImages.get(modKey);
		}



		if (permanentImages.exists(key))
		{
			if (permanentImages.get(key) == null || permanentImages.get(key).bitmap == null)
			{
				permanentImages.remove(key);
				permanentCacheTexture(key);
			}
			trackLocalImageKey(key);
			return permanentImages.get(key);
		}
		if (currentTrackedImages.exists(key))
		{
		
			trackLocalImageKey(key);
			return currentTrackedImages.get(key);
		}

		var path:String = key;
		if (!OpenFlAssets.exists(path, IMAGE))
			path = Paths.getPath('images/$key.png', IMAGE);

		if (permanentImages.exists(path))
		{
			if (permanentImages.get(path) == null || permanentImages.get(path).bitmap == null)
			{
				permanentImages.remove(path);
				permanentCacheTexture(path);
			}
			trackLocalImageKey(path);
			return permanentImages.get(path);
		}

		if (currentTrackedImages.exists(path))
		{
			trackLocalImageKey(path);
			return currentTrackedImages.get(path);
		}

		if (OpenFlAssets.exists(path, IMAGE))
		{
			if (!currentTrackedImages.exists(path))
			{
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);
				newGraphic.persist = true;
				currentTrackedImages.set(path, newGraphic);
			}
			trackLocalImageKey(path);
			return currentTrackedImages.get(path);
		}
		trace('FunkinMemory Failed to return graphic for key: $key adding to cache now');
		var graphic:FlxGraphic = createGraphic(key, ClientPrefs.data.cacheOnGPU);
		if (graphic == null)
		{
			trace('FunkinMemory Failed to temporarily cache graphic: $key');
			return null;
		}

		currentTrackedImages.set(key, graphic);
		trackLocalImageKey(key);
		return graphic;
	}

	#if sys
	static function permanentCacheImageFolder(relativeFolder:String):Void
	{
		// var rootPath:String = Paths.getPreloadPath('images/' + relativeFolder);
		// if (!FileSystem.exists(rootPath))
		// {
		// 	trace('FunkinMemory: Folder not found for permanent precache: ' + rootPath);
		// 	return;
		// }

		// CoolUtil.recursiveLoop(haxe.io.Path.addTrailingSlash(rootPath), function(path:String, file:String, _)
		// {
		// 	if (file.toLowerCase().endsWith('.png'))
		// 	{
		// 		var relativeToImages:String = StringTools.replace(path, Paths.getPreloadPath('images/'), '');
		// 		relativeToImages = StringTools.replace(relativeToImages, '\\', '/');
		// 		var noExt:String = relativeToImages.substr(0, relativeToImages.length - 4);
		// 		permanentCacheTexture(Paths.vsliceimage(noExt));
		// 	}
		// });
	}
	#end

    public static function loadPerminateAssets(){
        // permanentCacheTexture(Paths.vsliceimage('menus/newfreeplay/freeplayBacking'));
        // permanentCacheTexture(Paths.vsliceimage('menus/newfreeplay/scoreBox'));
        // permanentCacheTexture(Paths.vsliceimage('menus/newfreeplay/idle-catagorybutton'));
        // permanentCacheTexture(Paths.vsliceimage('menus/newfreeplay/select-catagorybutton'));
        // permanentCacheTexture(Paths.vsliceimage('menus/pause/scrollingSpikes'));
        // permanentCacheTexture(Paths.vsliceimage('menus/newfreeplay/scoreBox'));
        // permanentCacheTexture(Paths.vsliceimage('menus/newfreeplay/scoreBox'));
        // permanentCacheTexture(Paths.vsliceimage('menus/newfreeplay/scoreBox')); 
		// #if sys
		// permanentCacheImageFolder('menus/newfreeplay/songrenders');
		// permanentCacheImageFolder('menus/newfreeplay/renders');
		// #end



    }
	public static function returnSound(path:String, key:String):Sound
	{
		var file:String = Paths.modsSounds(path, key);
		if (FileSystem.exists(file))
		{
			if (!currentTrackedSounds.exists(file))
				currentTrackedSounds.set(file, Sound.fromFile(file));
			return currentTrackedSounds.get(file);
		}

		var gottenPath:String = Paths.getPath('$path/$key.${Paths.SOUND_EXT}', SOUND);

		if (currentTrackedSounds.exists(gottenPath))
		{
			return currentTrackedSounds.get(gottenPath);
		}

		var assetKeys:Array<String> = [gottenPath];
		if (gottenPath.startsWith('assets/'))
		{
			assetKeys.push(gottenPath.substr('assets/'.length));
		}
		if (path == 'songs')
		{
			assetKeys.push('songs:' + gottenPath);
			if (gottenPath.startsWith('assets/'))
			{
				assetKeys.push('songs:' + gottenPath.substr('assets/'.length));
			}
		}

		for (assetKey in assetKeys)
		{
			if (OpenFlAssets.exists(assetKey, SOUND))
			{
				var loadedSound:Sound = OpenFlAssets.getSound(assetKey);
				if (loadedSound != null)
				{
					currentTrackedSounds.set(gottenPath, loadedSound);
					return loadedSound;
				}
			}
		}

		if (FileSystem.exists(gottenPath))
		{
			var diskSound:Sound = Sound.fromFile(gottenPath);
			currentTrackedSounds.set(gottenPath, diskSound);
			return diskSound;
		}

		trace('FunkinMemory: Failed to load sound: ' + gottenPath);
		return null;
	}
}
