package;

import flixel.FlxG;
import animateatlas.AtlasFrameMaker;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import Note;
import flixel.util.FlxColor;
import debug.Consolehandler;
import utility.Characterpreloader;
import Section.SwagSection;
import sys.io.File;
import sys.FileSystem;
import utility.Scripthandler;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import json2object.JsonParser;
import objects.FunkinSprite;
import HaxeScript.AnyValue;
import utility.Scripthandler;

using StringTools;

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;

	var AnimType:String;
	var iconData:IconData;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	@:optional
	var animtype:String;
}

typedef IconData =
{
	var healthicon:String; // curently
	@:optional
	var posoffset:Array<Float>;
	var iconOffsets:Array<Iconoffsets>;
}

typedef Iconoffsets =
{
	var animname:String;
	var offsets:Array<Float>;
}

typedef AnimArray =
{
	var anim:String;
	@:optional
	var frames:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Float>;
	@:optional
	var offsets_flip:Array<Int>;
}

class Character extends FunkinSprite
{
	public var animOffsets:Null<Map<String, Array<Dynamic>>>;
	public var debugMode:Bool = false;
	public var spriteType:String = 'sparrow';
	public var charactertype:String = 'unknown';
	public var isPlayer:Bool = false;
	public var curCharacter:String = Constants.DEFAULT_CHARACTER;
	public var animstyle:String = 'v-slice';
	public var forceanim:Bool = false; // used for extra anims that arnt sing or dance.
	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;

	var reverttimer:FlxTimer;
	var timerhandled:Bool = false;
	var didswitch:Bool;

	public var pendingRevertAnim:Bool = false;

	var heldSustainNotes:Array<Note> = []; // Currently held sustain notes
	var prevTapAnim:String = null; // Last non-sustain animation
	var lockedSustainDir:String = null;

	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;

	var alt:String = '';

	public var icondata:IconData;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;
	public var animationsArray:Array<AnimArray> = [];

	var animtocheck:String;

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var hasMissAnimations:Bool = false;
	public var originalFlipX:Bool = false;

	var singHoldNote:Bool = false;
	var theFrames:FlxAtlasFrames;
	var hasscript:Bool;
	var offsethandler:Array<Float> = [];
	var characterscriptPath:String;
	var iconoffsets:Array<Iconoffsets> = [];
	var ogx:Float;
	var ogy:Float;

	/**
	 * The offset between the corner of the sprite and the origin of the sprite (at the character's feet).
	 * cornerPosition = stageData - characterOrigin
	 */
	public var characterOrigin(get, never):FlxPoint;

	// Frame-based logic helpers:
	var queuedSustainAnim:String = null;
	var activeSustainDir:String = null;

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;

	public var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public function new(x:Float, y:Float, ?character:String = 'bf', charactertype:String = 'unknown', ?isPlayer:Bool = false,)
	{
		super(x, y);

		this.charactertype = charactertype;

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		curCharacter = character;
		#if FEATURE_DEBUG_TRACY
		cpp.vm.tracy.TracyProfiler.zoneScoped('Character.create(${this.curCharacter})');
		#end
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.data.globalAntialiasing;
		var library:String = null;

		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode them instead':

			default:
				characterscriptPath = 'data/characters/' + curCharacter + '.hx';

				var json:CharacterFile = Characterpreloader.charmap.get(curCharacter);

				// sparrow
				// packer
				// texture
				#if MODS_ALLOWED
				var modTxtToFind:String = Paths.modsTxt(json.image);
				var txtToFind:String = Paths.getPath('images/' + json.image + '.txt', TEXT);

				// var modTextureToFind:String = Paths.modFolders("images/"+json.image);
				// var textureToFind:String = Paths.getPath('images/' + json.image, new AssetType();

				if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT)))
				#end
				{
					spriteType = "packer";
				}

				#if MODS_ALLOWED
				var modAnimToFind:String = Paths.modFolders('images/' + json.image + '/Animation.json');
				var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);

				// var modTextureToFind:String = Paths.modFolders("images/"+json.image);
				// var textureToFind:String = Paths.getPath('images/' + json.image, new AssetType();

				if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)))
				#end
				{
					spriteType = "texture";
				}

				switch (spriteType)
				{
					case "packer":
						frames = Paths.getPackerAtlas(json.image);

					case "sparrow":
						Consolehandler.print("SPARROW ATLAS LOADED: " + json.image);
						frames = Paths.getSparrowAtlas(json.image);

					case "texture":
						frames = AtlasFrameMaker.construct(json.image);
				}
				imageFile = json.image;

				if (json.scale != 1)
				{
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				icondata = json.iconData;
				trace('icon data from json is: ' + json.iconData);
				if (icondata == null)
				{
					icondata = {healthicon: Constants.DEFAULT_HEALTH_ICON, iconOffsets: []};
				}

				if (json.animtype != null)
				{
					animstyle = json.animtype;
				}
				singDuration = json.sing_duration;
				if (json.no_antialiasing)
				{
					antialiasing = false;
					noAntialiasing = true;
				}

				if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if (!ClientPrefs.data.globalAntialiasing)
					antialiasing = false;

				animationsArray = json.animations;
				if (animationsArray != null && animationsArray.length > 0)
				{
					for (anims in animationsArray)
					{
						var animAnim:String = '' + anims.anim;
						var animName:String = '' + anims.name;
						var animFps:Int = anims.fps;
						var animLoop:Bool = !!anims.loop; // Bruh
						var animIndices:Array<Int> = anims.indices;

						switch (spriteType)
						{
							case 'packer' | 'sparrow' | 'texture': // edited for future use
								trace('SPARROW OR PACKER');
								if (animIndices != null && animIndices.length > 0)
								{
									animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop, false, false,);
								}
								else
								{
									animation.addByPrefix(animAnim, animName, animFps, animLoop);
								}
						}
						if (anims.offsets != null && anims.offsets.length > 1)
						{
							addOffset(anims.anim, anims.offsets);
						}
					}
				}
				else
				{
					quickAnimAdd('idle', 'BF idle dance');
				}
				// trace('Loaded file to character ' + curCharacter);
		}

		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss'))
			hasMissAnimations = true;
		recalculateDanceIdle();
		dance();
		var classname:String = Type.getClassName(Type.getClass(FlxG.state));

		if (classname == 'PlayState')
		{
			__hscript = Scripthandler.setupScripts(characterscriptPath, this, true);
			trace('Character Script loaded: ' + __hscript);
			if (__hscript != null)
			{
				hasscript = true;
			}
		}
	}

	override function update(elapsed:Float)
	{
		FlxG.watch.addQuick('alt:', alt);

		if (!debugMode && animation.curAnim != null)
		{
			if (heyTimer > 0)
			{
				heyTimer -= elapsed * PlayState.instance.playbackRate;
				if (heyTimer <= 0)
				{
					if (specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			}
			else if (specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			if (animation.curAnim.name.startsWith('sing'))
			{
				holdTimer += elapsed;
			}

			if (holdTimer >= Conductor.stepCrochet * (0.0011 / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * singDuration)
			{
				dance();
				holdTimer = 0;
			}

			if (animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			{
				playAnim(animation.curAnim.name + '-loop');
			}
		}
		super.update(elapsed);
	}

	override function onAnimationFinished(name:String)
	{
		setFunctionOnScripts('onAnimationFinished', [name]);
		if (forceanim)
		{
			forceanim = false;
		}
	}

	function get_characterOrigin():FlxPoint
	{
		var xPos = (width / 2); // Horizontal center
		var yPos = (height); // Vertical bottom
		return new FlxPoint(xPos, yPos);
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	override function dance(?forceplay:Bool = false)
	{
		setFunctionOnScripts('dance', []);
		if (!debugMode && !skipDance && !specialAnim && !forceanim)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if (animation.getByName('idle' + idleSuffix) != null)
			{
				playAnim('idle' + idleSuffix);
			}
		}
	}

	public function setFunctionOnScripts(name:String, params:Array<AnyValue>)
	{
		if (hasscript)
		{
			__hscript.runFunction(name, params);
		}
	}

	public function playSingAnim(note:Note, AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		setFunctionOnScripts('playSingAnim', [note, AnimName, Force, Reversed, Frame]);

		if (note.noAnimation)
			return;

		if (forceanim)
		{
			heldSustainNotes = [];
			activeSustainDir = null;
			return;
		}

		var baseAnim:String = AnimName + note.animSuffix;
		var curAnim:String = getCurrentAnimation();

		var treatAsSustain:Bool = note.isSustainNote || (note.sustainLength > 0);

		if (animstyle == "psych")
		{
			playAnim(baseAnim, Force, Reversed, Frame);
			return;
		}

		if (!note.isSustainNote)
		{
			playAnim(baseAnim, Force, Reversed, Frame);
		}

		if (treatAsSustain)
		{
			if (heldSustainNotes.indexOf(note) == -1)
				heldSustainNotes.push(note);

			// ====== V-SLICE STYLE ======
			if (animstyle == "v-slice")
			{
				// Prevent switching directions mid-hold
				if (!note.endnote && activeSustainDir != null && activeSustainDir != AnimName)
				{
					if (!isAnimationFinished())
						return;
					// allow fallthrough once finished
				}

				// --- END NOTE ---
				if (note.endnote)
				{
					var endAnim = AnimName + alt + "-end";
					var hasEnd = animation.getByName(endAnim) != null;

					activeSustainDir = null;

					// Play end animation if available
					if (hasEnd)
					{
						if (curAnim != endAnim)
						{
							playAnim(endAnim, Force, Reversed, Frame);
							return;
						}
						if (!isAnimationFinished())
							return;
					}

					// remove sustain from stack
					var idx = heldSustainNotes.indexOf(note);
					if (idx != -1)
						heldSustainNotes.splice(idx, 1);

					return;
				}

				// --- HOLD ANIMATION ---
				var holdAnim = AnimName + alt + "-hold";
				if (animation.getByName(holdAnim) != null)
				{
					if (isAnimationFinished() && curAnim != holdAnim)
						playAnim(holdAnim, Force, Reversed, Frame);
				}

				return;
			}

			// Other styles (not v-slice) sustain notes don't break flow yet
		}

		// --------------------------------------------------------------
		//  PAUSE STYLE LOGIC
		// --------------------------------------------------------------
		if (animstyle == "pause")
		{
			// Start singing
			if (!isSinging() || curAnim != baseAnim)
				playAnim(baseAnim, Force, Reversed, Frame);

			// Pause until release (endnote)
			if (isSinging() && curAnim == baseAnim)
				animation.curAnim.paused = !note.endnote;

			return;
		}
	}

	public function isSinging():Bool
	{
		return getCurrentAnimation().startsWith('sing');
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		setFunctionOnScripts('playAnim', [AnimName, Force, Reversed, Frame]);
		specialAnim = false;
		if (AnimName.startsWith('sing'))
		{
		}
		else
		{
			forceanim = Force;
			if (forceanim == true)
			{
				animation.stop();
			}
		}
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		var x:Float = 0;
		var y:Float = 0;

		switch (flipX)
		{
			case true:
				if (daOffset[2] != null)
				{
					x = daOffset[2];
				}
				if (daOffset[3] != null)
				{
					y = daOffset[3];
				}
			case false:
				if (daOffset[0] != null)
				{
					x = daOffset[0];
				}
				if (daOffset[1] != null)
				{
					y = daOffset[1];
				}
		}

		offset.set(x, y);

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	function chartloader(chartName:String):Void
	{
		var noteData:Array<SwagSection> = Song.loadFromJson(chartName, Paths.formatToSongPath(PlayState.SONG.song)).notes;
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				animationNotes.push(songNotes);
			}
		}
		animationNotes.sort(sortAnims);
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if (settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public override function destroy():Void
	{
		setFunctionOnScripts('destroy', []);
		super.destroy();
	}

	public function addOffset(name:String,
			offsets:Array<Float>) // we need to edit this, but make sure if their is no extra offsets then it defaults to 0, 0 instead of null, which causes errors
	{
		if (offsets == null)
			offsets = [0, 0];

		animOffsets[name] = offsets;
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}
}
