package data;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end
import json2object.JsonParser;
import Song;

using StringTools;

typedef StageFile =
{
	/**
	 * The default zoom level of the stage's camera
	 * @default 1.0
	 */
	@:optional
	@:default(1.0)
	var defaultZoom:Float;

	@:default(false)
	var isPixelStage:Bool;
	@:default('')
	var directory:String;

	@:default([0, 0])
	var focusOffsets:Array<Float>;

	var characters:CharList;

	/**
	 *  whether or not the stage has a gf, defaults to true
	 */
	@:optional
	@:default(true)
	var hide_girlfriend:Bool;

	var props:Array<PropData>;

	/**
	 *  what the stage will focus on initaly, can be a prop or a character
	 */
	@default('boyfriend')
	var camera_focus:String;

	var camera_speed:Null<Float>;
}

typedef CharList =
{
	var boyfriend:CharacterData;
	@:optional
	var girlfriend:CharacterData;
	var dad:CharacterData;
}

typedef PropData =
{
	/**
	 * A number determining the stack order of the prop, relative to characters and other props in the stage.
	 * Just like CSS.
	 * @default 0
	 */
	@:optional
	@:default(0)
	var zIndex:Int;

	/**
	 * The name of the prop. Optional.. usefull for identifying
	 * @default unknown
	 */
	@:optional
	@:default('unknown')
	var name:String;

	/**
	 * The name of the prop. Optional.. usefull for identifying
	 * @default unknown
	 */
	@:optional
	@:default('unknown')
	var path:String;

	/**
	 * The blend mode of the prop
	 */
	@:optional
	@:default('nan')
	var blend:String;

	/**
	 * The scale of the prop
	 */
	@:optional
	@:default([1, 1])
	var scale:Array<Float>;

	/**
	 * the assets animation data. optional -- if not present, it will use a static image
	 */
	@:optional
	var animations:Null<Array<Character.AnimArray>>;

	/**
	 * The type of prop. This corresponds to a prop or sprite class, Defaults to BGSprite
	 * @default 0
	 */
	@:optional
	@:default("BGSprite")
	var PropType:String;

	/**
	 * The Axis the backdrop repeats on. Only used for FunkinBackdrop props.
	 * @default 0
	 */
	@:optional
	@:default("X")
	var repeatAxes:String;

	/**
	 * The X And Y position of the prop on the stage.
	 */
	@:default([0, 0])
	var position:Array<Float>;

	/**
	 * The velocity of the prop, used for flxbackdrops to make them scroll automatically.
	 */
	@:default([0, 0])
	var velocity:Array<Float>;

	/**
	 * The X And Y spacing of the prop on the stage, only used for FunkinBackdrop props.
	 */
	@:optional
	@:default([0, 0])
	var spacing:Array<Float>;

	/**
	 * How much the prop scrolls relative to the camera. Used to create a parallax effect.
	 * Represented as an [x, y] array of two floats.
	 * [1, 1] means the prop moves 1:1 with the camera.
	 * [0.5, 0.5] means the prop moves half as much as the camera.
	 * [0, 0] means the prop is not moved.
	 * @default [1, 1]
	 */
	@:optional
	@:default([1, 1])
	var scroll:Array<Float>;

	/**
	 * The alpha of the prop, as a float.
	 * @default 1.0
	 */
	@:optional
	@:default(1.0)
	var alpha:Float;

	/**
	 * The angle of the prop, as a float.
	 * @default 0.0
	 */
	@:optional
	@:default(0.0)
	var angle:Float;
}

typedef CharacterData =
{
	/**
	 * A number determining the stack order of the character, relative to props and other characters in the stage.
	 * Again, just like CSS.
	 * @default 0
	 */
	@:optional
	@:default(0)
	var zIndex:Int;

	/**
	 * The X And Y position of the character on the stage.
	 */
	@:default([0, 0])
	var position:Array<Float>;

	/**
	 * How much the character scrolls relative to the camera. Used to create a parallax effect.
	 * Represented as an [x, y] array of two floats.
	 * [1, 1] means the character moves 1:1 with the camera.
	 * [0.5, 0.5] means the character moves half as much as the camera.
	 * [0, 0] means the character is not moved.
	 * @default [1, 1]
	 */
	@:optional
	@:default([1, 1])
	var scroll:Array<Float>;

	/**
	 * The alpha of the character, as a float.
	 * @default 1.0
	 */
	@:optional
	@:default(1.0)
	var alpha:Float;

	/**
	 * The angle of the character, as a float.
	 * @default 0.0
	 */
	@:optional
	@:default(0.0)
	var angle:Float;

	@:default(false)
	var flipx:Bool;
}

class StageData
{
	public static var forceNextDirectory:String = null;

	public static function loadDirectory(SONG:SwagSong)
	{
		var stage:String = '';
		if (SONG.stage != null)
		{
			stage = SONG.stage;
		}
		else if (SONG.song != null)
		{
			switch (SONG.song.toLowerCase().replace(' ', '-'))
			{
				case 'spookeez' | 'south' | 'monster':
					stage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					stage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					stage = 'limo';
				case 'cocoa' | 'eggnog':
					stage = 'mall';
				case 'winter-horrorland':
					stage = 'mallEvil';
				case 'senpai' | 'roses':
					stage = 'school';
				case 'thorns':
					stage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					stage = 'tank';
				default:
					stage = 'test';
			}
		}
		else
		{
			stage = 'test';
		}

		var stageFile:StageFile = getStageFile(stage);
	}

	public static function getStageFile(stage:String):StageFile
	{
		var rawJson:String = null;
		var path:String = Paths.getPreloadPath('data/stages/' + stage + '.json');

		var modPath = Paths.modFolders('data/stages/' + stage + '.json');

		if (modPath != null && FileSystem.exists(modPath))
		{
			rawJson = File.getContent(modPath);
		}
		else if (FileSystem.exists(path))
		{
			rawJson = File.getContent(path);
		}
		else if (Assets.exists(path))
		{
			rawJson = Assets.getText(path);
		}
		else
		{
			return null;
		}

		var parser = new JsonParser<StageFile>();
		parser.fromJson(rawJson, path);

		if (parser.errors.length > 0)
		{
			for (e in parser.errors)
				trace(e);
		}

		return parser.value;
	}
}
