package data;
import objects.NoteSplash;

import haxe.Json;
import Character.AnimArray as AnimArray;
import ClientPrefs;
import utility.Scripthandler;
import utility.NoteSkinHelper;
import utility.NoteSkinHelper.NoteSkin;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

// because huds use flxcolors for note rgb, we cant use json2object, if anyone knows a better way to do this please tell me -
typedef Hudstyle =
{
	var healthbar:BarInfo;
	var timeBar:BarInfo;
	@:optional
	var iconP1pos:Array<Float>;
	@:optional
	var iconP2pos:Array<Float>;
	@:optional
	var iconP2visible:Bool;
	@:optional
	var iconP1visible:Bool;
	@:optional
	var scorpos:Array<Float>;
	@:optional
	var noteskin:String;
	var soundbar:String;
}

typedef BarInfo =
{
	@:optional
	var animations:Array<AnimArray>;
	var image:Array<String>;
	var scale:Float;
	var barStyle:String;
	var position:Array<Float>;
	var barOffsets:Array<Float>;
	var no_antialiasing:Bool;
}

class HudstyleData
{
	public var bars:Hudstyle;
	public var iconp1overide:Array<Float>;
	public var iconp1vis:Bool = true;
	public var iconp2vis:Bool = true;
	public var iconp2overide:Array<Float>;
	public var scorposs:Array<Float> = [0, 0];
	public var script:HaxeScript = null;
	public var hudscriptpath:String;
	public var hasscript:Bool = false;
	public var soundbar:String;
	public var noteskindata:NoteSkin;

	public function new()
	{
	}

	public function loadFromJson(location:String, scriptpath:String):Bool
	{
		var path:String = null;
		if (sys.FileSystem.exists(Paths.hudjson(location)))
		{
			path = Paths.hudjson(location);
			trace('loading hud json from: ' + path);
		}
		else if (sys.FileSystem.exists(Paths.modshudJson(location)))
		{
			path = Paths.modshudJson(location);
			trace('loading hud json from: ' + path);
		}
		else
		{
			trace('no hud json found at: ' + location);
			return false;
		}

		hudscriptpath = scriptpath;
		bars = cast Json.parse(File.getContent(path));

		applyDefaults();
		noteskindata = NoteSkinHelper.grabNoteskinjson(bars.noteskin);

		return true;
	}

	private function applyDefaults():Void
	{
		if (bars == null)
		{
			return;
		}
		if (bars.iconP1pos != null)
		{
			iconp1overide = bars.iconP1pos;
		}
		if (bars.iconP2pos != null)
		{
			iconp2overide = bars.iconP2pos;
			trace('iconp2overide is: ' + iconp2overide);
		}
		if (bars.soundbar != null)
		{
			soundbar = bars.soundbar;
		}
		if (bars.iconP1visible != null)
		{
			iconp1vis = bars.iconP1visible;
		}
		if (bars.iconP2visible != null)
		{
			iconp2vis = bars.iconP2visible;
		}
		if (bars.scorpos != null)
		{
			scorposs = bars.scorpos;
		}
		if (bars.noteskin == null)
		{
			bars.noteskin = 'default';
		}
	}

	public function detectscript(parent:Dynamic)
	{
		trace('detecting hud script at: ' + hudscriptpath);
		script = Scripthandler.setupScripts(hudscriptpath, parent, true);
		if (script != null)
		{
			trace('script loaded successfully');
			hasscript = true;
		}
		else
		{
			hasscript = false;
		}
	}

	public function gethealthbaroffsets():Array<Float>
	{
		if (script != null)
		{
			trace('Running script function gethealthbaroffsets with bar number');
			var func = script.variables.get("gethealthbaroffsets");
			if (func != null)
			{
				var offset:Array<Float> = cast Reflect.callMethod(null, func, []);
				if (offset != null)
				{
					return offset;
				}
				return bars.healthbar.barOffsets;
			}
			return bars.healthbar.barOffsets;
		}
		return bars.healthbar.barOffsets;
	}

	public function getsoundbar():String
	{
		if (script != null)
		{
			trace('Running script function getsoundbar with bar number');
			var func = script.variables.get("getsoundbar");
			if (func != null)
			{
				var bar:String = cast Reflect.callMethod(null, func, []);
				if (bar != null)
				{
					return bar;
				}
				return soundbar;
			}
			return soundbar;
		}
		return soundbar;
	}

	public function gethealthbarposition():Array<Float>
	{
		if (script != null)
		{
			trace('Running script function gethealthbarposition with bar number');
			var func = script.variables.get("gethealthbarposition");
			if (func != null)
			{
				var offset:Array<Float> = cast Reflect.callMethod(null, func, []);
				if (offset != null)
				{
					return offset;
				}
				return bars.healthbar.position;
			}
			return bars.healthbar.position;
		}
		return bars.healthbar.position;
	}

	public function gethealthbargraphics(barnum:Int):Null<String>
	{
		if (script != null)
		{
			trace('Running script function getbargraphics with bar number: ' + barnum);
			var func = script.variables.get("gethealthbargraphics");
			if (func != null)
			{
				var bargraphics:String = cast Reflect.callMethod(null, func, [barnum]);
				trace('bargraphics is: ' + bargraphics);
				if (bargraphics != null)
				{
					return bargraphics;
				}
				trace('Script returned null, falling back to JSON image.');
				return bars.healthbar.image[barnum];
			}
			trace('Script function getbargraphics not found, using fallback.');
			return bars.healthbar.image[barnum];
		}
		return bars.healthbar.image[barnum];
	}

	public function getnotesplashoffsets():Array<Float>
	{
		if (script != null)
		{
			var func = script.variables.get("getnotesplashoffsets");
			if (func != null)
			{
				var offsets:Array<Float> = cast Reflect.callMethod(null, func, []);
				if (offsets != null)
				{
					return offsets;
				}
			}
		}
		if (noteskindata != null && noteskindata.notesplash != null && noteskindata.notesplash.notesplashoffsets != null)
		{
			return noteskindata.notesplash.notesplashoffsets;
		}
		return [-20, -100];
	}

	public function getNoteskinnotes(player:Bool):String
	{
		if (script != null)
		{
			var func = script.variables.get("getNoteskinnotes");
			if (func != null)
			{
				var noteskin:String = cast Reflect.callMethod(null, func, [player]);
				if (noteskin != null)
				{
					return noteskin;
				}
			}
		}
		if (noteskindata != null)
		{
			if (noteskindata.notes != null && noteskindata.notes.frames != null && noteskindata.notes.frames.length > 0)
			{
				return noteskindata.notes.frames;
			}
			if (noteskindata.frames != null && noteskindata.frames.length > 0)
			{
				return noteskindata.frames;
			}
			if (noteskindata.strumline != null && noteskindata.strumline.frames != null && noteskindata.strumline.frames.length > 0)
			{
				return noteskindata.strumline.frames + '-notes';
			}
		}
		return 'Huds/Noteskins/NOTE_assets-notes';
	}

	public function getNoteskinrgb(player:Bool):Array<Array<Int>>
	{
		if (script != null)
		{
			var func = script.variables.get("getNoteskinrgb");
			if (func != null)
			{
				var rgbvalues:Array<Array<Int>> = cast Reflect.callMethod(null, func, [player]);
				if (rgbvalues != null)
				{
					return rgbvalues;
				}
			}
		}
		return ClientPrefs.data.arrowRGB;
	}

	public function getNoteskinFrames(player:Bool):String
	{
		if (script != null)
		{
			var func = script.variables.get("getNoteskinFrames");
			if (func != null)
			{
				var noteskin:String = cast Reflect.callMethod(null, func, [player]);
				if (noteskin != null)
				{
					return noteskin;
				}
			}
		}
		if (noteskindata != null)
		{
			if (noteskindata.strumline != null && noteskindata.strumline.frames != null && noteskindata.strumline.frames.length > 0)
			{
				return noteskindata.strumline.frames;
			}
			if (noteskindata.frames != null && noteskindata.frames.length > 0)
			{
				return noteskindata.frames;
			}
		}
		return 'Huds/Noteskins/NOTE_assets';
	}

	public function getNotesplash():String
	{
		if (script != null)
		{
			var func = script.variables.get("getNotesplash");
			if (func != null)
			{
				var notesplash:String = cast Reflect.callMethod(null, func, []);
				if (notesplash != null)
				{
					return notesplash;
				}
			}
		}
		if (noteskindata != null
			&& noteskindata.notesplash != null
			&& noteskindata.notesplash.notesplash != null
			&& noteskindata.notesplash.notesplash.length > 0)
		{
			return noteskindata.notesplash.notesplash;
		}
		return 'Huds/NoteSplashes/noteSplashes';
	}

	public function useRgbShader():Bool
	{
		if (script != null)
		{
			var func = script.variables.get("useRgbShader");
			if (func != null)
			{
				var res:Dynamic = Reflect.callMethod(null, func, []);
				if (res != null)
				{
					return cast res;
				}
			}
		}
		if (noteskindata != null)
		{
			if (noteskindata.usergbshader != null)
				return noteskindata.usergbshader;
			if (noteskindata.notesplash != null && noteskindata.notesplash.usergbshader != null)
				return noteskindata.notesplash.usergbshader;
		}
		return true;
	}

	public function getAlphaOverride():Float
	{
		if (script != null)
		{
			var func = script.variables.get("getAlphaOverride");
			if (func != null)
			{
				var res:Dynamic = Reflect.callMethod(null, func, []);
				if (res != null)
				{
					return cast res;
				}
			}
		}
		if (noteskindata != null)
		{
			if (noteskindata.alphaoveride != null)
				return noteskindata.alphaoveride;
			if (noteskindata.notesplash != null && noteskindata.notesplash.alphaoveride != null)
				return noteskindata.notesplash.alphaoveride;
		}
		return 0.6;
	}

	public function gettimebargraphics(barnum:Int):String
	{
		if (script != null)
		{
			trace('Running script function getbargraphics with bar number: ' + barnum);
			var func = script.variables.get("gettimebargraphics");
			if (func != null)
			{
				var bargraphics:String = cast Reflect.callMethod(null, func, [barnum]);
				trace('bargraphics is: ' + bargraphics);
				if (bargraphics != null)
				{
					return bargraphics;
				}
				trace('Script returned null, falling back to JSON image.');
				return bars.timeBar.image[barnum];
			}
			trace('Script function getbargraphics not found, using fallback.');
			return bars.timeBar.image[barnum];
		}
		return bars.healthbar.image[barnum];
	}

	public function geticonP1Pos(arraynum:Int):Float
	{
		if (bars.iconP1pos != null)
		{
			if (script != null)
			{
				var func = script.variables.get("geticonP1Pos");
				if (func != null)
				{
					var pos:Dynamic = cast Reflect.callMethod(null, func, [arraynum]);
					if (pos != null)
					{
						return pos;
					}
					trace('Script returned null, falling back to JSON iconP1pos.');
					return bars.iconP1pos[arraynum];
				}
				trace('Script function geticonP1Pos not found, falling back to JSON.');
				return bars.iconP1pos[arraynum];
			}
			trace('No script loaded, using JSON iconP1pos.');
			return bars.iconP1pos[arraynum];
		}
		var defaultPos:Array<Float> = [0, 0];
		return defaultPos[arraynum];
	}

	public function geticonP2Pos(arraynum:Int):Float
	{
		if (bars.iconP2pos != null)
		{
			if (script != null)
			{
				var func = script.variables.get("geticonP2Pos");
				if (func != null)
				{
					var pos:Dynamic = cast Reflect.callMethod(null, func, [arraynum]);
					if (pos != null)
					{
						return pos;
					}
					trace('Script returned null, falling back to JSON iconP1pos.');
					return bars.iconP2pos[arraynum];
				}
				trace('Script function geticonP1Pos not found, falling back to JSON.');
				return bars.iconP2pos[arraynum];
			}
			trace('No script loaded, using JSON iconP1pos.');
			return bars.iconP2pos[arraynum];
		}
		var defaultPos:Array<Float> = [0, 0];
		return defaultPos[arraynum];
	}

	public function addvar(name:String, value:Dynamic)
	{
		if (script != null)
		{
			script.variables.set(name, value);
		}
	}

	public function runScriptFunction(id:String, params:Array<Dynamic>):Dynamic
	{
		if (script == null)
			return null;
		return script.runFunction(id, params);
	}
}
