package utility;
import objects.Note;
import objects.NoteSplash;

import ClientPrefs;
import PlayState;
import data.HudstyleData;
import Character.AnimArray;

typedef NoteSkin =
{
	var frames:Null<String>;
	var strumline:Null<StrumlineData>;
	var notes:Null<NoteData>;
	@:optional
	var notesplash:Null<NoteSplashData>;
	@:optional
	var usergbshader:Null<Bool>;
	@:optional
	var alphaoveride:Null<Float>;
	@:default(false)
	var dojitter:Null<Bool>;
}

typedef NoteSplashData =
{
	var notesplash:Null<String>;
	var notesplashoffsets:Null<Array<Float>>;
	var usergbshader:Null<Bool>;
	var alphaoveride:Null<Float>;
}

typedef StrumlineData =
{
	var frames:Null<String>;
	var leftstatic:Null<AnimArray>;
	var downstatic:Null<AnimArray>;
	var upstatic:Null<AnimArray>;
	var rightstatic:Null<AnimArray>;
	var leftpressed:Null<AnimArray>;
	var downpressed:Null<AnimArray>;
	var uppressed:Null<AnimArray>;
	var rightpressed:Null<AnimArray>;
	var rightconfirm:Null<AnimArray>;
	var leftconfirm:Null<AnimArray>;
	var downconfirm:Null<AnimArray>;
	var upconfirm:Null<AnimArray>;
}

typedef NoteData =
{
	var frames:Null<String>;
	var purple:Null<AnimArray>;
	var blue:Null<AnimArray>;
	var green:Null<AnimArray>;
	@:optional
	var special:Null<AnimArray>;
	var yellow:Null<AnimArray>;
	var purpleholdend:Null<AnimArray>;
	var blueholdend:Null<AnimArray>;
	var greenholdend:Null<AnimArray>;
	var yellowholdend:Null<AnimArray>;
	var purplehold:Null<AnimArray>;
	var bluehold:Null<AnimArray>;
	var greenhold:Null<AnimArray>;
	var yellowhold:Null<AnimArray>;
}

class NoteSkinHelper
{
	static inline var DEFAULT_NOTESKIN:String = 'Huds/Noteskins/NOTE_assets';
	static inline var DEFAULT_NOTESPLASH:String = 'Huds/NoteSplashes/noteSplashes';
	static inline var DEFAULT_ALPHA:Float = 0.6;
	static var fallbackData:HudstyleData = null;
	static var fallbackHudName:String = null;

	public static function setupfallback(?hudName:String):Void
	{
		var selectedHud:String = hudName;
		if (hudName == null || selectedHud.length < 1)
		{
			selectedHud = 'default';
		}

		if (fallbackData != null && fallbackHudName == selectedHud)
		{
			return;
		}

		utility.NoteSkinpreloader.preloadNoteSkin('default');
		var data:HudstyleData = new HudstyleData();
		var hudscriptpath:String = 'data/hudstyles/' + selectedHud + '.hx';
		if (data.loadFromJson(selectedHud, hudscriptpath))
		{
			fallbackData = data;
			fallbackHudName = selectedHud;
			return;
		}

		if (selectedHud != 'default')
		{
			setupfallback('default');
			return;
		}
		fallbackData = null;
		fallbackHudName = null;
	}

	public static function grabNoteskinjson(noteskin:String):NoteSkin
	{
		var noteskin = utility.NoteSkinpreloader.grabnoteskindata(noteskin);
		return noteskin;
	}

	public static function getNoteskinNotes(player:Bool, ?hudData:HudstyleData):String
	{
		var data = resolveHudData(hudData);
		if (data != null)
		{
			return data.getNoteskinnotes(player);
		}

		return DEFAULT_NOTESKIN + '-notes';
	}

	public static function getNoteskinRgb(player:Bool, ?hudData:HudstyleData):Array<Array<Int>>
	{
		var data = resolveHudData(hudData);
		return data != null ? data.getNoteskinrgb(player) : ClientPrefs.data.arrowRGB;
	}

	public static function getNoteskinFrames(player:Bool, ?hudData:HudstyleData):String
	{
		var data = resolveHudData(hudData);
		return data != null ? data.getNoteskinFrames(player) : DEFAULT_NOTESKIN;
	}

	public static function getStrumlineData(?hudData:HudstyleData):StrumlineData
	{
		var data = resolveHudData(hudData);
		return data != null && data.noteskindata != null ? data.noteskindata.strumline : null;
	}

	public static function getNoteData(?hudData:HudstyleData):NoteData
	{
		var data = resolveHudData(hudData);
		return data != null && data.noteskindata != null ? data.noteskindata.notes : null;
	}

	public static function getNoteTypeData(notetype:String):NoteData
	{
		var noteTypeData:NoteData = utility.NoteTypepreloader.grabNoteTypeJson(notetype);
		if (noteTypeData == null)
		{
			var data = resolveHudData();
			return data != null && data.noteskindata != null ? data.noteskindata.notes : null;
		}
		return noteTypeData;
	}

	public static function getNotesplash(?hudData:HudstyleData):String
	{
		var data = resolveHudData(hudData);
		return data != null ? data.getNotesplash() : DEFAULT_NOTESPLASH;
	}

	public static function getNotesplashOffsets(?hudData:HudstyleData):Array<Float>
	{
		var data = resolveHudData(hudData);
		return data != null ? data.getnotesplashoffsets() : [-10, -10];
	}

	public static function useRgbShader(?hudData:HudstyleData):Bool
	{
		var data = resolveHudData(hudData);
		return data != null ? data.useRgbShader() : true;
	}

	public static function getAlphaOverride(?hudData:HudstyleData):Float
	{
		var data = resolveHudData(hudData);
		return data != null ? data.getAlphaOverride() : DEFAULT_ALPHA;
	}

	static function resolveHudData(?hudData:HudstyleData):HudstyleData
	{
		if (HaxeScript.isInPlayState() && PlayState.instance != null && PlayState.instance.hud != null)
		{
			return PlayState.instance.hud.hudData;
		}

		if (hudData != null)
		{
			return hudData;
		}

		var targetHud:String = fallbackHudName != null ? fallbackHudName : 'default';
		if (fallbackData == null || fallbackHudName != targetHud)
		{
			setupfallback(targetHud);
		}

		return fallbackData;
	}
}
