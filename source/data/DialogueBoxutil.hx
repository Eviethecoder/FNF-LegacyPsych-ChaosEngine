package data;

import haxe.Json;
import Character.AnimArray;
import ClientPrefs;
import json2object.JsonParser;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

typedef DialogueData =
{
	var charlist:Array<CharJsonData>;
	var textlist:Array<TextData>;
}

typedef TextData =
{
	var text:String;
	var chardata:CharJsonData;
	var boxdata:BoxData;
}

typedef BoxData =
{
	@:optional
	var animtoplay:String;
	var functiontorun:String;
	var rgbdata:RGBArray;
	var parameters:Array<Dynamic>;
}

typedef CharData =
{
	@:optional
	var chartoshow:String;
	var animtoplay:String;
	var posoffset:Array<Float>;
}

typedef CharJsonData =
{
	var jsonname:String;
	var charType:String;
}

typedef DialogueBoxData =
{
	@default('speech_bubble')
	var sprite:String;
	var basergb:RGBArray;
	@default([0, 0])
	var textoffset:Array<Float>;
	var animationdata:Array<AnimArray>;
};

typedef RGBArray =
{
	r:Array<Int>,
	g:Array<Int>,
	b:Array<Int>,
}

class DialogueBoxutil
{
	public static function loadFromJson(location:String):DialogueBoxData
	{
		var path:String = null;
		if (sys.FileSystem.exists(Paths.json(location)))
		{
			path = Paths.json(location);
			trace('loading dialoguebox json from: ' + path);
		}
		else if (sys.FileSystem.exists(Paths.modsJson(location)))
		{
			path = Paths.modsJson(location);
			trace('loading dialoguebox json from: ' + path);
		}
		else
		{
			trace('no dialoguebox json found at: ' + location + ', loading default');
			path = Paths.json('DialogueBox/default');
		}

		var rawJson:String = File.getContent(path);
		var parser:JsonParser<DialogueBoxData> = new JsonParser<DialogueBoxData>();
		parser.fromJson(rawJson, path);

		if (parser.errors != null && parser.errors.length > 0)
		{
			for (error in parser.errors)
			{
				trace(error);
			}
		}

		return parser.value;
	}
}
