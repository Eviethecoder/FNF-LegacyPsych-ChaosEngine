package utility;

import ClientPrefs;
import PlayState;
import data.HudstyleData;

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

	public static function getNoteskin(player:Bool, ?hudData:HudstyleData):String
	{
		var data = resolveHudData(hudData);
		return data != null ? data.getNoteskin(player) : DEFAULT_NOTESKIN;
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
		return data != null && data.bars != null && data.bars.noteskin != null && data.bars.noteskin.usergbshader != null ? data.bars.noteskin.usergbshader : true;
	}

	public static function getAlphaOverride(?hudData:HudstyleData):Float
	{
		var data = resolveHudData(hudData);
		return data != null && data.bars != null && data.bars.noteskin != null && data.bars.noteskin.alphaoveride != null ? data.bars.noteskin.alphaoveride : DEFAULT_ALPHA;
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

		var targetHud:String = 'default';
		if (fallbackData == null || fallbackHudName != targetHud)
		{
			setupfallback(targetHud);
		}

		return fallbackData;
	}


}

