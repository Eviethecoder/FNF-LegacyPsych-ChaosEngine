package data;

import haxe.Json;
import Character.AnimArray as AnimArray;
import ClientPrefs;
import utility.Scripthandler;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

//because huds use flxcolors for note rgb, we cant use json2object, if anyone knows a better way to do this please tell me -
typedef Hudstyle = {
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
	var noteskin:NoteskinInfo;
	@:optional
	var notesplash:String;
	@:optional
	var falback:String;
}

typedef NoteskinInfo = {
	var strumlinegraphic:String;
	@:optional
	var notegraphic:String;
	@:optional
	var samenamenotes:Bool;
	@:optional
	var notesplash:String;
	@:optional
	var notesplashoffsets:Array<Float>;
	@:optional
	var usergbshader:Bool;
	@:optional
	var alphaoveride:Float;
}

typedef BarInfo = {
	@:optional
	var animations:Array<AnimArray>;
	var image:Array<String>;
	var scale:Float;
	var barStyle:String;
	var position:Array<Float>;
	var barOffsets:Array<Float>;
	var no_antialiasing:Bool;
}

class HudstyleData {
	public var bars:Hudstyle;
	public var iconp1overide:Array<Float>;
	public var iconp1vis:Bool = true;
	public var iconp2vis:Bool = true;
	public var iconp2overide:Array<Float>;
	public var scorposs:Array<Float> = [0, 0];
	public var script:HaxeScript = null;
    public var hudscriptpath:String;
    public var hasscript:Bool = false;

	public function new() {}

	public function loadFromJson(location:String, scriptpath:String):Bool {
		var path:String = null;
		if (sys.FileSystem.exists(Paths.hudjson(location))) {
			path = Paths.hudjson(location);
			trace('loading hud json from: ' + path);
		} else if (sys.FileSystem.exists(Paths.modshudJson(location))) {
			path = Paths.modshudJson(location);
			trace('loading hud json from: ' + path);
		} else {
			trace('no hud json found at: ' + location);
			return false;
		}

        hudscriptpath = scriptpath;
		bars = cast Json.parse(File.getContent(path));

        

		applyDefaults();
		return true;
	}

	private function applyDefaults():Void {
		if (bars == null) {
			return;
		}
		if (bars.iconP1pos != null) {
			iconp1overide = bars.iconP1pos;
		}
		if (bars.iconP2pos != null) {
			iconp2overide = bars.iconP2pos;
			trace('iconp2overide is: ' + iconp2overide);
		}
		if (bars.iconP1visible != null) {
			iconp1vis = bars.iconP1visible;
		}
		if (bars.iconP2visible != null) {
			iconp2vis = bars.iconP2visible;
		}
		if (bars.scorpos != null) {
			scorposs = bars.scorpos;
		}
		if (bars.noteskin == null) {
			bars.noteskin = { strumlinegraphic: 'Huds/Noteskins/NOTE_assets', samenamenotes: true, notesplash: 'Huds/NoteSplashes/noteSplashes', notesplashoffsets: [-10, -10], usergbshader: true, alphaoveride: 0.6 };
		}
	}

    public function detectscript(parent:Dynamic){
        trace('detecting hud script at: ' + hudscriptpath);
         script = Scripthandler.setupScripts(hudscriptpath, parent, true);
         if(script != null){
             trace('script loaded successfully');
             hasscript = true;
         }
         else{
             hasscript = false;
         }

    }

	public function gethealthbaroffsets():Array<Float> {
		if (script != null) {
			trace('Running script function gethealthbaroffsets with bar number');
			var func = script.iris.get("gethealthbaroffsets");
			if (func != null) {
				var offset:Array<Float> = cast Reflect.callMethod(null, func, []);
				if (offset != null) {
					return offset;
				}
				return bars.healthbar.barOffsets;
			}
			return bars.healthbar.barOffsets;
		}
		return bars.healthbar.barOffsets;
	}

	public function gethealthbarposition():Array<Float> {
		if (script != null) {
			trace('Running script function gethealthbarposition with bar number');
			var func = script.iris.get("gethealthbarposition");
			if (func != null) {
				var offset:Array<Float> = cast Reflect.callMethod(null, func, []);
				if (offset != null) {
					return offset;
				}
				return bars.healthbar.position;
			}
			return bars.healthbar.position;
		}
		return bars.healthbar.position;
	}

	public function gethealthbargraphics(barnum:Int):String {
		if (script != null) {
			trace('Running script function getbargraphics with bar number: ' + barnum);
			var func = script.iris.get("gethealthbargraphics");
			if (func != null) {
				var bargraphics:String = cast Reflect.callMethod(null, func, [barnum]);
				trace('bargraphics is: ' + bargraphics);
				if (bargraphics != null) {
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

	public function getnotesplashoffsets():Array<Float> {
		if (script != null) {
			var func = script.iris.get("getnotesplashoffsets");
			if (func != null) {
				var offsets:Array<Float> = cast Reflect.callMethod(null, func, []);
				if (offsets != null) {
					return offsets;
				}
				return bars.noteskin.notesplashoffsets != null ? bars.noteskin.notesplashoffsets : [0, 0];
			}
			return bars.noteskin.notesplashoffsets != null ? bars.noteskin.notesplashoffsets : [0, 0];
		}
		return bars.noteskin.notesplashoffsets != null ? bars.noteskin.notesplashoffsets : [0, 0];
	}

	public function getNoteskinnotes(player:Bool):String {
		if (script != null) {
			var func = script.iris.get("getNoteskinnotes");
			if (func != null) {
				var noteskin:String = cast Reflect.callMethod(null, func, [player]);
				if (noteskin != null) {
					return noteskin;
				}
				if (bars.noteskin.samenamenotes) {
					return bars.noteskin.strumlinegraphic + '-notes';
				}
				return bars.noteskin.notegraphic;
			}
			if (bars.noteskin.samenamenotes) {
				return bars.noteskin.strumlinegraphic + '-notes';
			}
			return bars.noteskin.notegraphic;
		}
		if (bars.noteskin.samenamenotes) {
			return bars.noteskin.strumlinegraphic + '-notes';
		}
		return bars.noteskin.notegraphic;
	}

	public function getNoteskinrgb(player:Bool):Array<Array<Int>> {
		if (script != null) {
			var func = script.iris.get("getNoteskinrgb");
			if (func != null) {
				var rgbvalues:Array<Array<Int>> = cast Reflect.callMethod(null, func, [player]);
				if (rgbvalues != null) {
					return rgbvalues;
				}
				return ClientPrefs.data.arrowRGB;
			}
			return ClientPrefs.data.arrowRGB;
		}
		return ClientPrefs.data.arrowRGB;
	}

	public function getNoteskin(player:Bool):String {
		if (script != null) {
			var func = script.iris.get("getNoteskin");
			if (func != null) {
				var noteskin:String = cast Reflect.callMethod(null, func, [player]);
				if (noteskin != null) {
					return noteskin;
				}
				return bars.noteskin.strumlinegraphic;
			}
			return bars.noteskin.strumlinegraphic;
		}
		return bars.noteskin.strumlinegraphic;
	}

	public function getNotesplash():String {
		if (script != null) {
			var func = script.iris.get("getNotesplash");
			if (func != null) {
				var notesplash:String = cast Reflect.callMethod(null, func, []);
				if (notesplash != null) {
					return notesplash;
				}
				return bars.noteskin.notesplash;
			}
			return bars.noteskin.notesplash;
		}
		return bars.noteskin.notesplash;
	}

	public function gettimebargraphics(barnum:Int):String {
		if (script != null) {
			trace('Running script function getbargraphics with bar number: ' + barnum);
			var func = script.iris.get("gettimebargraphics");
			if (func != null) {
				var bargraphics:String = cast Reflect.callMethod(null, func, [barnum]);
				trace('bargraphics is: ' + bargraphics);
				if (bargraphics != null) {
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

	public function geticonP1Pos(arraynum:Int):Float {
		if (bars.iconP1pos != null) {
			if (script != null) {
				var func = script.iris.get("geticonP1Pos");
				if (func != null) {
					var pos:Dynamic = cast Reflect.callMethod(null, func, [arraynum]);
					if (pos != null) {
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

	public function geticonP2Pos(arraynum:Int):Float {
		if (bars.iconP2pos != null) {
			if (script != null) {
				var func = script.iris.get("geticonP2Pos");
				if (func != null) {
					var pos:Dynamic = cast Reflect.callMethod(null, func, [arraynum]);
					if (pos != null) {
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
    public function addvar(name:String, value:Dynamic) {
        if (script != null) {
            script.iris.set(name, value);
        }
    }

    public function runScriptFunction(id:String, params:Array<Dynamic>):Dynamic {
		if(script == null) 
			return null;
 
		return script.runFunction(id, params);
	}

}

