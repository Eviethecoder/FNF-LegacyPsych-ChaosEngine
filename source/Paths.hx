package;

import animateatlas.AtlasFrameMaker;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import openfl.geom.Rectangle;
import flixel.math.FlxRect;
import openfl.display3D.textures.RectangleTexture;
import haxe.xml.Access;
import openfl.system.System;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import debug.Consolehandler;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import haxe.Json;
import flash.media.Sound;
import objects.FunkinMemory;

using StringTools;
class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";
	public static var ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];

	public static function returnGraphic(key:String):flixel.graphics.FlxGraphic  //a passthreough for eas
	{
		return FunkinMemory.returnGraphic(key);
	}


	static public var currentModDirectory:String = '';
	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, ?type:AssetType = TEXT,  ?modsAllowed:Bool = true):String
	{
		
		if(modsAllowed)
		{
			var customFile:String = file;
			var modded:String = modFolders(customFile);
			if(FileSystem.exists(modded)) return modded;
		}
	

		return getPreloadPath(file);
	}

	static var _assetsBasePath:Null<String>;
	static var assetsBasePath(get, never):String;

	static function get_assetsBasePath():String
	{
		if (_assetsBasePath != null) return _assetsBasePath;

		// Keep logical asset IDs stable for OpenFL/Lime asset lookup.
		// Debug filesystem redirection is handled by helper functions in this class
		// for code paths that use FileSystem / File directly.
		_assetsBasePath = 'assets';

		return _assetsBasePath;
	}

	inline static function buildAssetsPath(file:String):String
	{
		return (file == null || file.length < 1) ? assetsBasePath : '$assetsBasePath/$file';
	}

	#if sys
	public static function resolveAssetPath(path:String):String
	{
		#if debug
		var normalized = path.replace('\\', '/');
		var assetIndex = normalized.indexOf('assets/');
		if (assetIndex < 0)
			return path;

		normalized = normalized.substr(assetIndex + 7);

		var candidates:Array<String> = [
			'../../../../assets/$normalized',
			'../../../../../assets/$normalized',
			'assets/$normalized'
		];

		for (candidate in candidates)
		{
			if (FileSystem.exists(candidate))
				trace('redirecting asset path from $path to $candidate');
				return candidate;
		}
		#end

		return path;
	}

	public static function resolveAssetDirectory(path:String):String
	{
		return resolveAssetPath(path);
	}
	#end



	inline static function getLibraryPathForce(file:String)
	{
		return buildAssetsPath(file);
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return buildAssetsPath(file);
	}
	inline public static function getPreloadimagePath(file:String = '')
	{
		return buildAssetsPath('images/$file');
	}

	inline static public function file(file:String, type:AssetType = TEXT)
	{
		return getPath(file, type);
	}

	inline static public function txt(key:String)
	{
		return getPath('data/$key.txt', TEXT);
	}

	inline static public function xml(key:String)
	{
		return getPath('data/$key.xml', TEXT);
	}

	inline static public function json(key:String)
	{
		return getPath('data/$key.json', TEXT);
	}

	
	inline static public function hudjson(key:String)
	{
		return getPath('data/hudstyles/$key.json', TEXT);
	}

	inline static public function shaderFragment(key:String)
	{
		return getPath('shaders/$key.frag', TEXT);
	}
	inline static public function shaderVertex(key:String)
	{
		return getPath('shaders/$key.vert', TEXT);
	}
	inline static public function hscript(key:String)
	{
		return getPath('$key.hx', TEXT);
	}

	public static function soundExists(path:String, key:String):Bool{ // for Vocals.hx
	
		var file:String = modsSounds(path, key);
		if(FileSystem.exists(file)) {
			return true;
		}
	
		
		var folder:String = '';
		trace(folder + getPath('$path/$key.$SOUND_EXT', SOUND));
		return OpenFlAssets.exists(folder + getPath('$path/$key.$SOUND_EXT', SOUND));
	}


	/**
	 * so these 2 functions are v slice ports for the soundtray
	 */
	 public static function vsliceimage(key:String):String
		{
		  return getPath('images/$key.png', IMAGE);
		}

	public static function vslicesound(key:String):String
		{
			return getPath('sounds/$key.ogg', SOUND);
		}

	static public function video(key:String)
	{
		
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) {
			return file;
		}
	
		return getPreloadPath('videos/$key.$VIDEO_EXT');
	}

	static public function sound(key:String):Sound
	{
		var sound:Sound = returnSound('sounds', key);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int)
	{
		return sound(key + FlxG.random.int(min, max));
	}

	inline static public function music(key:String):Sound
	{
		var file:Sound = returnSound('music', key);
		return file;
	}

	inline static public function voices(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		var voices = returnSound('songs', songKey);
		return voices;
	}

	inline static public function inst(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		var inst = returnSound('data/' +Constants.cursongfolder, songKey);
		trace('getting inst with key: ' + songKey + ' and path: ' + 'data/' +Constants.cursongfolder + '/' + songKey + '.' + SOUND_EXT);
		return inst;
	}

	static public function image(key:String):flixel.graphics.FlxGraphic
	{
	
		var modFile:String = modsImages(key);
		if (FileSystem.exists(modFile))
		{
			if (!FunkinMemory.permanentImages.exists(modFile) && !FunkinMemory.currentTrackedImages.exists(modFile))
				FunkinMemory.temporaryCacheTexture(modFile);
			return returnGraphic(modFile);
		}
		else{
			var assetPath:String = getPath('images/$key.png', IMAGE);
			if (FileSystem.exists(modFile)){
			if (!FunkinMemory.permanentImages.exists(assetPath) && !FunkinMemory.currentTrackedImages.exists(assetPath))
				FunkinMemory.temporaryCacheTexture(assetPath);
		}
			return returnGraphic(assetPath);
		}
		trace('image not found: ' + key);
		return null;
	}
	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys

		if (!ignoreMods && FileSystem.exists(modFolders(key)))
			return File.getContent(modFolders(key));

		var resolvedPreload = resolveAssetPath(getPreloadPath(key));
		if (FileSystem.exists(resolvedPreload))
			return File.getContent(resolvedPreload);
		#end

		var levelPath = getLibraryPathForce(key);
		if (FileSystem.exists(levelPath))
			return File.getContent(levelPath);
		return Assets.getText(getPath(key, TEXT));
	}

	inline static public function font(key:String)
	{
		
		var file:String = modsFont(key);
		if(FileSystem.exists(file)) {
			return file;
		}
	
		return getPreloadPath('fonts/$key');
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false)
	{
		
		if(FileSystem.exists(mods(currentModDirectory + '/' + key)) || FileSystem.exists(mods(key))) {
			return true;
		}

		if(FileSystem.exists(getPath(key, type))) {
			return true;
		}
	
		if(OpenFlAssets.exists(getPath(key, type))) {
			return true;
		}
		return false;
	}

	inline static public function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		var imageLoaded = returnGraphic(vsliceimage(key));


		var xml:String = modsXml(key);
		if(FileSystem.exists(xml))
			return FlxAtlasFrames.fromSparrow(imageLoaded, File.getContent(xml));
	

		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath('images/$key.xml', TEXT));
	}


	static public function getPackerAtlas(key:String):FlxAtlasFrames
	{
		var useMod = false;
		var imageLoaded:flixel.graphics.FlxGraphic = image(key);
		var myXml:Dynamic = getPath('images/$key.xml', TEXT, true);
		if(OpenFlAssets.exists(myXml) || (FileSystem.exists(myXml) && (useMod = true)) )
		{
			return FlxAtlasFrames.fromSparrow(imageLoaded, (useMod ? File.getContent(myXml) : myXml));
		}
		return getPackerAtlas(key);
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	public static inline function returnSound(path:String, key:String):Sound
		return FunkinMemory.returnSound(path, key);
	inline static public function getcontent(key:String)
	{
		return File.getContent(key);
	}


	inline static public function mods(key:String = '') {
		return 'mods/' + key;
	}

	inline static public function modsFont(key:String) {
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String) {
		return modFolders('data/' + key + '.json');
	}
	inline static public function modshudJson(key:String) {
		trace('looking for hud json at: ' + 'mods/hudstyles/' + key + '.json');
		return modFolders('hudstyles/' + key + '.json');
	}

	inline static public function modsVideo(key:String) {
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsSounds(path:String, key:String) {
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}
	inline static public function modspath(key:String) {
		return modFolders(key);
	}


	inline static public function modsImages(key:String) {
		return modFolders('images/' + key + '.png');
	}

	inline static public function modsXml(key:String) {
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String) {
		return modFolders('images/' + key + '.txt');
	}

	

	inline static public function modsShaderFragment(key:String)
	{
		return modFolders('shaders/'+key+'.frag');
	}
	inline static public function modsShaderVertex(key:String)
	{
		return modFolders('shaders/'+key+'.vert');
	}
	inline static public function modsAchievements(key:String) {
		return modFolders('achievements/' + key + '.json');
	}

	static public function modFolders(key:String) {
		if(currentModDirectory != null && currentModDirectory.length > 0) {
			var fileToCheck:String = mods(currentModDirectory + '/' + key);
			
			if(FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		for(mod in getGlobalMods()){
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;

		}
		return 'mods/' + key;
	}

	public static var globalMods:Array<String> = [];

	static public function getGlobalMods()
		return globalMods;

	static public function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path))
		{
			var list:Array<String> = CoolUtil.coolTextFile(path);
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1")
				{
					var folder = dat[0];
					var path = Paths.mods(folder + '/pack.json');
					if(FileSystem.exists(path)) {
						try{
							var rawJson:String = File.getContent(path);
							if(rawJson != null && rawJson.length > 0) {
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = true;
								if(global)globalMods.push(dat[0]);
							}
						} catch(e:Dynamic){
							trace(e);
						}
					}
				}
			}
		}
		return globalMods;
	}

	static public function getModDirectories():Array<String> {
		var list:Array<String> = [];
		var modsFolder:String = mods();
		if(FileSystem.exists(modsFolder)) {
			for (folder in FileSystem.readDirectory(modsFolder)) {
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder)) {
					list.push(folder);
				}
			}
		}
		return list;
	}

}
