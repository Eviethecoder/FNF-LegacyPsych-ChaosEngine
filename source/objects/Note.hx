package objects;
import shaders.ColorSwap;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flash.display.BitmapData;
import editors.ChartingState;
import objects.FunkinSprite;
import haxe.ds.StringMap;
import utility.Scripthandler;
import Character.AnimArray;
import HaxeScript;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

using StringTools;

typedef EventNote =
{
	strumTime:Float,
	event:String,
	valuearray:Array<Eventsvalue>
}

typedef Eventsvalue =
{
	name:String,
	value:events.EventUnion
}

typedef NoteSplashData =
{
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, // breaks r/g/b but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

class Note extends FlxSpriteGroup
{
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var notegraphic:FunkinSprite;

	public var animOffsets:Null<Map<String, Array<Dynamic>>>;

	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;

	public static var globalRgbShaders:Array<RGBPalette> = [];

	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;
	public var isEvent:Bool = false;
	public var isCameraEvent:Bool = false;
	public var rgbShader:RGBShaderReference;

	public static var isplayer:Bool = false;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var endnote:Bool = false;
	public var noteType(default, set):String = 'default';

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var colorSwap:ColorSwap;
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var forceBf:Bool = false;
	public var earlyHitMult:Float = 0.5;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var swagWidth:Float = 160 * 0.7;

	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];

	private var scrollAnimation:String;
	private var holdEndAnimation:String;
	private var holdAnimation:String;

	private var pixelInt:Array<Int> = [0, 1, 2, 3];

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var directionMod:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var special:Bool = false;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;
	public var invalid:Bool = false;

	public var texture(default, set):String = null;
	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: true,
		useGlobalShader: false,
		useRGBShader: true,
		r: -1,
		g: -1,
		b: -1,
		a: 1
	};
	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; // plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var script:HaxeScript = null;
	public var songSpeed:Float;

	private function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		// trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) // haha funny twitter shit
	{
		if (isSustainNote && !notegraphic.animation.curAnim.name.endsWith('end'))
		{
			notegraphic.scale.y *= ratio;
			notegraphic.updateHitbox();
		}
	}

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			ogloadNote('', value);
		}
		texture = value;
		return value;
	}

	public function defaultRGB()
	{
		var arr:Array<Dynamic> = utility.NoteSkinHelper.getNoteskinRgb(mustPress)[noteData];

		if (arr != null && noteData > -1 && noteData <= arr.length)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
		else
		{
			rgbShader.r = 0xFFFF0000;
			rgbShader.g = 0xFF00FF00;
			rgbShader.b = 0xFF0000FF;
		}
	}

	private function set_noteType(value:String):String
	{
		defaultRGB();
		noteSplashTexture = utility.NoteSkinHelper.getNotesplash();
		var danotetype = utility.NoteTypepreloader.notetypejsonmap.get(value);
		if (danotetype != null)
		{
			reloadNote(value);
		}
		if (noteData > -1 && noteType != value)
		{
			switch (value)
			{
				case 'special':
					this.special = true;
					notegraphic.shader = null;
				// reloadNote('Huds/NoteTypes/', 'SpecialNOTE_assets-notes');
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'GF Sing':
					gfNote = true;
			}
			noteType = value;
		}

		if (PlayState.instance != null)
		{
			loadNoteScript(this);
		}
		if (PlayState.instance == null)
		{
			loadNoteScriptchart(this);
		}
		return value;
	}

	function ogloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '')
	{
		if (prefix == null)
			prefix = '';
		if (texture == null)
			texture = '';
		if (suffix == null)
			suffix = '';

		var skin:String = texture;
		if (texture.length < 1)
		{
			skin = utility.NoteSkinHelper.getNoteskinNotes(mustPress);
		}

		var animName:String = null;
		if (notegraphic.animation.curAnim != null)
		{
			animName = notegraphic.animation.curAnim.name;
		}

		var lastScaleY:Float = notegraphic.scale.y;

		notegraphic.frames = Paths.getSparrowAtlas(skin);

		loadNoteAnims();
		notegraphic.antialiasing = ClientPrefs.data.globalAntialiasing;

		if (isSustainNote)
		{
			notegraphic.scale.y = lastScaleY;
		}
		notegraphic.updateHitbox();

		if (animName != null)
		{
			playAnim(animName, true);
		}

		if (inEditor)
		{
			notegraphic.setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			notegraphic.updateHitbox();
		}
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?player:Bool, ?sustainNote:Bool = false, ?inEditor:Bool = false)
	{
		super();
		notegraphic = new FunkinSprite();
		add(notegraphic);

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		isSustainNote = sustainNote;
		if (player != null)
		{
			mustPress = player;
			isplayer = player;
		}
		this.inEditor = inEditor;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if (!inEditor)
			this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if (noteData > -1)
		{
			rgbShader = new RGBShaderReference(notegraphic, initializeGlobalRGBShader(noteData, mustPress));
			texture = '';

			x += swagWidth * (noteData);
			if (!isSustainNote && noteData < colArray.length)
			{ // Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % 4];

				playAnim(animToPlay + 'Scroll', true);
			}
		}

		// trace(prevNote);

		if (prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if (ClientPrefs.data.downScroll)
				notegraphic.flipY = true;

			offsetX += notegraphic.width / 2;
			copyAngle = false;

			playAnim(colArray[noteData] + 'holdend');

			notegraphic.updateHitbox();

			offsetX -= notegraphic.width / 2;

			if (PlayState.instance.stage.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.playAnim(colArray[prevNote.noteData] + 'hold');

				prevNote.notegraphic.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if (PlayState.instance != null)
				{
					switch (isplayer)
					{
						case true:
							prevNote.notegraphic.scale.y *= PlayState.instance.playerStrumline.songSpeed;
						case false:
							prevNote.notegraphic.scale.y *= PlayState.instance.opponentStrumline.songSpeed;
					}
				}

				if (PlayState.instance.stage.isPixelStage)
				{
					prevNote.notegraphic.scale.y *= 1.19;
					prevNote.notegraphic.scale.y *= (6 / notegraphic.height); // Auto adjust note size
				}
				prevNote.notegraphic.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if (PlayState.instance.stage.isPixelStage)
			{
				notegraphic.scale.y *= PlayState.daPixelZoom;
				notegraphic.updateHitbox();
			}
		}
		else if (!isSustainNote)
		{
			earlyHitMult = 1;
		}
		x += offsetX;

		runScriptFunction('new', []);
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		var daOffset = animOffsets.get(anim);
		trace('Animation: ' + anim + ' Offset: ' + daOffset);
		var thisx:Float = 0;
		var thisy:Float = 0;
		if (daOffset != null && daOffset.length > 1)
		{
			thisx += daOffset[0];
			thisy += daOffset[1];
			if (thisx != 0 && thisy != 0)
				notegraphic.offset.set(thisx, thisy);
		}
		trace('Playing animation: ' + anim + ' with offset:  ' + notegraphic.offset);
		notegraphic.animation.play(anim, force);
	}

	public static function initializeGlobalRGBShader(noteData:Int, ?isPlayer:Bool = false)
	{
		var truenotedata:Int = noteData;
		if (isPlayer)
		{
			truenotedata += 4;
		}

		if (globalRgbShaders[truenotedata] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();

			var arr:Array<Dynamic> = utility.NoteSkinHelper.getNoteskinRgb(isPlayer)[noteData];
			// ClientPrefs.data.arrowRGB[noteData];

			if (arr != null && noteData > -1 && noteData <= arr.length)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
			else
			{
				newRGB.r = 0xFFFF0000;
				newRGB.g = 0xFF00FF00;
				newRGB.b = 0xFF0000FF;
			}

			globalRgbShaders[truenotedata] = newRGB;
		}
		return globalRgbShaders[truenotedata];
	}

	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	var lastNoteScaleToo:Float = 1;

	public var originalHeightForCalcs:Float = 6;

	function reloadNote(notetype:String)
	{
		var animName:String = null;
		if (notegraphic.animation.curAnim != null)
		{
			animName = notegraphic.animation.curAnim.name;
		}

		var lastScaleY:Float = notegraphic.scale.y;

		loadNoteAnims(true, notetype);
		notegraphic.antialiasing = ClientPrefs.data.globalAntialiasing;

		if (isSustainNote)
		{
			notegraphic.scale.y = lastScaleY;
		}
		notegraphic.updateHitbox();

		if (animName != null)
		{
			playAnim(animName, true);
		}

		if (special)
			playAnim('note-Special', true);
	}

	public function addOffset(name:String,
			offsets:Array<Float>) // we need to edit this, but make sure if their is no extra offsets then it defaults to 0, 0 instead of null, which causes errors
	{
		if (offsets == null)
			offsets = [0, 0];

		animOffsets[name] = offsets;
	}

	function loadNoteAnims(isnotetype:Bool = false, noteType:String = '')
	{
		var noteSkinData:Dynamic;

		switch (isnotetype)
		{
			case true:
				noteSkinData = utility.NoteSkinHelper.getNoteTypeData(noteType);

				notegraphic.frames = Paths.getSparrowAtlas(noteSkinData.frames);

			case false:
				noteSkinData = utility.NoteSkinHelper.getNoteData();
		}

		if (noteSkinData != null)
		{
			switch (noteData)
			{
				case 0:
					scrollAnimation = addAnimation(noteSkinData.purple, colArray[noteData] + 'Scroll');
					holdEndAnimation = addAnimation(noteSkinData.purpleholdend, colArray[noteData] + 'holdend');
					holdAnimation = addAnimation(noteSkinData.purplehold, colArray[noteData] + 'hold');
				case 1:
					scrollAnimation = addAnimation(noteSkinData.blue, colArray[noteData] + 'Scroll');
					holdEndAnimation = addAnimation(noteSkinData.blueholdend, colArray[noteData] + 'holdend');
					holdAnimation = addAnimation(noteSkinData.bluehold, colArray[noteData] + 'hold');
				case 2:
					scrollAnimation = addAnimation(noteSkinData.green, colArray[noteData] + 'Scroll');
					holdEndAnimation = addAnimation(noteSkinData.greenholdend, colArray[noteData] + 'holdend');
					holdAnimation = addAnimation(noteSkinData.greenhold, colArray[noteData] + 'hold');
				case 3:
					scrollAnimation = addAnimation(noteSkinData.yellow, colArray[noteData] + 'Scroll');
					holdEndAnimation = addAnimation(noteSkinData.yellowholdend, colArray[noteData] + 'holdend');
					holdAnimation = addAnimation(noteSkinData.yellowhold, colArray[noteData] + 'hold');
			}
		}
		if (noteSkinData.special != null)
		{
			addAnimation(noteSkinData.special, 'note-Special');
		}

		if (HaxeScript.isInPlayState())
		{
			notegraphic.setGraphicSize(Std.int(notegraphic.width * 0.7));
			notegraphic.updateHitbox();
		}
	}

	function addAnimation(data:AnimArray, fallback:String):String
	{
		if (data == null)
			return fallback;

		var animationName:String = data.anim;
		if (fallback != null)
		{
			animationName = fallback;
		}
		if (data.indices != null && data.indices.length > 0)
			notegraphic.animation.addByIndices(animationName, data.name, data.indices, '', data.fps, data.loop);
		else
			notegraphic.animation.addByPrefix(animationName, data.name, data.fps, data.loop);

		if (data.offsets != null && data.offsets.length > 1)
			addOffset(animationName, data.offsets);
		return animationName;
	}

	function loadPixelNoteAnims()
	{
		if (isSustainNote)
		{
			notegraphic.animation.add(colArray[noteData] + 'holdend', [pixelInt[noteData] + 4]);
			notegraphic.animation.add(colArray[noteData] + 'hold', [pixelInt[noteData]]);
		}
		else
		{
			notegraphic.animation.add(colArray[noteData] + 'Scroll', [pixelInt[noteData] + 4]);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			// ok river
			if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}

		if (isSustainNote && notegraphic.animation.curAnim.name.endsWith('end') && endnote == false)
		{
			endnote = true;
		}
		runScriptFunction('updateLate', [elapsed]);
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		var center:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		if (isSustainNote && (mustPress || !ignoreNote) && (!mustPress || (wasGoodHit || (prevNote.wasGoodHit && !canBeHit))))
		{
			var swagRect:flixel.math.FlxRect = notegraphic.clipRect;
			if (swagRect == null)
				swagRect = new flixel.math.FlxRect(0, 0, notegraphic.frameWidth, notegraphic.frameHeight);

			if (myStrum.downScroll)
			{
				if (y - notegraphic.offset.y * notegraphic.scale.y + notegraphic.height >= center)
				{
					swagRect.width = notegraphic.frameWidth;
					swagRect.height = (center - y) / notegraphic.scale.y;
					swagRect.y = notegraphic.frameHeight - swagRect.height;
				}
			}
			else if (y + notegraphic.offset.y * notegraphic.scale.y <= center)
			{
				swagRect.y = (center - y) / notegraphic.scale.y;
				swagRect.width = notegraphic.width / notegraphic.scale.x;
				swagRect.height = (notegraphic.height / notegraphic.scale.y) - swagRect.y;
			}
			notegraphic.clipRect = swagRect;
		}
	}

	public function loadNoteScriptchart(note:Note):HaxeScript
	{
		// Paths.getPreloadPath('custom_notetypes/'), Paths.modFolders('custom_notetypes/')

		var type:String = note.noteType;
		if (type.length == 0)
			type = 'Note';
		var path = Paths.getPreloadPath('custom_notetypes/' + type + '.hx');

		try
		{
			if (sys.FileSystem.exists(path))
				__hscript = HaxeScript.FromFile(path, note);
			else
			{
				path = Paths.modFolders('custom_notetypes/' + type + '.hx');
				if (sys.FileSystem.exists(path))
					__hscript = HaxeScript.FromFile(path, note);
			}
		}
		catch (e)
		{
			trace(e);
		}

		return __hscript;
	}

	public function loadNoteScript(note:Note):HaxeScript
	{
		// Paths.getPreloadPath('custom_notetypes/'), Paths.modFolders('custom_notetypes/')

		var type:String = note.noteType;
		if (type.length == 0)
			type = 'Note';
		var path = Paths.getPreloadPath('custom_notetypes/' + type + '.hx');

		try
		{
			if (sys.FileSystem.exists(path))
			{
				script = HaxeScript.FromFile(path, note);
				Scripthandler.gamescriptArray.push(script);
			}
			else
			{
				path = Paths.modFolders('custom_notetypes/' + type + '.hx');
				if (sys.FileSystem.exists(path))
					script = HaxeScript.FromFile(path, note);
			}
		}
		catch (e)
		{
			MusicBeatState.addTextToDebug("   ...  " + Std.string(e), FlxColor.fromRGB(240, 166, 38));
			MusicBeatState.addTextToDebug("[ ERROR ] Could not load note script " + path, FlxColor.RED);
		}

		if (script != null)
			script.onError = MusicBeatState.hscriptError;

		return script;
	}

	public function runScriptFunction(id:String, params:Array<Dynamic>):Dynamic
	{
		if (__hscript == null)
			return null;

		return __hscript.runFunction(id, params);
	}
}
