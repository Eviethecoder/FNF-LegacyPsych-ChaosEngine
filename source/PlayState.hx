package;

import flixel.graphics.FlxGraphic;
#if hxdiscord_rpc
import Discord.DiscordClient;
import StrumNote.SustainSplash;
#end
import Section;
import Song;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import objects.FunkinMemory;
import objects.FunkinCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import eventhelpers.*;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import FunkinSoundTray;
import openfl.events.KeyboardEvent;
import flixel.util.FlxSave;
import animateatlas.AtlasFrameMaker;
import objects.Stage;
import HaxeScript;
import DialogueBoxPsych;
import scriptobjects.ScriptableMusicBeatSubState;
#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import objects.VideoSprite;
import HaxeScript.AnyValue;
import utility.*;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69% ....nice
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();

	public var songSpeedTween:FlxTween;
	public var songSpeedTween2:FlxTween;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var stageBackground:FlxSpriteGroup;
	public var stageForground:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public var steptyype:String = 'ms';

	public static var curStage:String = '';

	public var stage:Stage;

	public static var SONG:SwagSong = null;

	var songName:String;

	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var vocals:Vocals;

	public var startedCountdown:Bool = false;

	// ── Strumlines (own arrows + notes for each lane) ───────────────────────

	/** Opponent (CPU) strumline. */
	public var opponentStrumline:objects.Strumline;

	/** Player strumline. */
	public var playerStrumline:objects.Strumline;

	/**
	 * Combined strum arrows from both lanes.
	 * Populated once during setup so it can be iterated without per-frame allocation.
	 */
	public var strumLineNotes:FlxTypedGroup<StrumNote>;

	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	// Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var hscriptArray:Array<HaxeScript.HaxeScript> = [];
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var grpSustainSplashes:FlxTypedGroup<SustainSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;

	private var curSong:String = "";

	public var health:Float = 1;

	public var combo:Int = 0;

	public static var songfolder:String = "";

	public var hud:HudHandler;

	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = [];
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	public var splashoveride:String;

	public var generatedMusic:Bool = false;

	public var sustainSplashSetting:Int = 2; // ClientPrefs.data.holdSplashSetting == "On" ? 2 : ClientPrefs.data.holdSplashSetting == "Only Covers" ? 1 : 0;

	public var endingSong:Bool = false;
	public var startingSong:Bool = false;

	private var updateTime:Bool = true;

	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;

	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	/**
	 * The displayed value of the player's health.
	 * Used to provide smooth animations based on linear interpolation of the player's health.
	 */
	var healthLerp:Float = 1;

	var songLerp:Float = 0;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FunkinCamera;
	public var camNotes:FunkinCamera;
	public var camGame:FunkinCamera;
	public var camOther:FunkinCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;

	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	// Stores HUD Elements in a Group
	public var uiGroup:FlxSpriteGroup;
	// Stores Ratings and Combo Sprites in a group
	public var comboGroup:FlxSpriteGroup;
	// Stores Note Elements in a Group
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.02;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	var songLength:Float = 0;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	// Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Hscript shit
	public static var instance:PlayState;

	public var introSoundsSuffix:String = '';
	public var pauseScript:String = '';
	public var gameoverScript:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	var precacheList:Map<String, String> = new Map<String, String>();

	override public function create()
	{
		// trace('Playback Rate: ' + playbackRate);
		FunkinMemory.clearStoredMemory();
		Scripthandler.gamescriptArray = [];
		EventHandler.cleareventlist();

		// for hscript
		instance = this;

		debugKeysChart = ClientPrefs.keyBinds.get('debug_1').copy();
		debugKeysCharacter = ClientPrefs.keyBinds.get('debug_2').copy();
		PauseSubState.songName = null; // Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);

		keysArray = [
			ClientPrefs.keyBinds.get('note_left').copy(),
			ClientPrefs.keyBinds.get('note_down').copy(),
			ClientPrefs.keyBinds.get('note_up').copy(),
			ClientPrefs.keyBinds.get('note_right').copy()
		];

		controlArray = ['NOTE_LEFT', 'NOTE_DOWN', 'NOTE_UP', 'NOTE_RIGHT'];

		// Ratings
		ratingsData = Rating.getDefaultList();

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
			keysPressed.push(false);

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		camGame = new FunkinCamera();

		camNotes = new FunkinCamera();
		camHUD = new FunkinCamera();
		camOther = new FunkinCamera();
		camHUD.bgColor.alpha = 0;
		camNotes.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camNotes, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpSustainSplashes = new FlxTypedGroup<SustainSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);

		curStage = SONG.stage;
		stage = new Stage(curStage, SONG.player1, SONG.player2, SONG.gfVersion);
		add(stage);

		MusicBeatState.debugGroup.cameras = [camOther];

		// "GLOBAL" SCRIPTS

		Scripthandler.checkDirectoryScripts([Paths.getPreloadPath('scripts/'), Paths.modFolders('scripts/')], instance);

		var camPos:FlxPoint = new FlxPoint(0, 0);
		if (stage.gf != null)
		{
			camPos.x += stage.gf.getGraphicMidpoint().x + stage.gf.cameraPosition[0];
			camPos.y += stage.gf.getGraphicMidpoint().y + stage.gf.cameraPosition[1];
		}

		comboGroup = new FlxSpriteGroup();
		add(comboGroup);
		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(noteGroup);
		uiGroup = new FlxSpriteGroup();

		var file:String = Paths.json(songName + '/dialogue'); // Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); // Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000 / Conductor.songPosition;

		strumLine = new FlxSprite(ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 20).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.data.downScroll)
			strumLine.y = FlxG.height - 450;
		strumLine.scrollFactor.set();
		hud = new HudHandler(PlayState.SONG.hudSkin, PlayState.SONG.hudSkin, SONG.song); ///do this before song is generated for noteskins

		opponentStrumline = new objects.Strumline(0, strumLine.y, false);
		playerStrumline = new objects.Strumline(0, strumLine.y, true);

		// Note-hit logic is owned by Strumline.
		playerStrumline.onNoteMiss = function(note:Note)
		{
			noteMiss(note);
		};

		// Build the combined strumLineNotes group for backward compat (Lua/HScript)
		strumLineNotes = new FlxTypedGroup<StrumNote>();

		// Add strumlines to noteGroup so their update() runs in the right order
		noteGroup.add(opponentStrumline);
		noteGroup.add(playerStrumline);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		generateSong(SONG.song);

		noteGroup.add(grpSustainSplashes);
		noteGroup.add(grpNoteSplashes);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);
		FlxG.camera.followLerp = 0.4;
		FlxG.camera.follow(camFollowPos, LOCKON, 0.4);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		add(hud);
		add(uiGroup);
		hud.cameras = [camHUD];

		iconP1 = new HealthIcon(stage.boyfriend.icondata, true);
		iconP1.y = hud.healthBar.y - 75;
		if (hud.hudData.iconp1overide != null)
		{
			iconP1.x = hud.healthBar.x + hud.hudData.geticonP1Pos(0);
			iconP1.y += hud.healthBar.y + hud.hudData.geticonP1Pos(1);
			trace(iconP1.x + ' ' + iconP1.y);
		}
		else
		{
			iconP1.y = hud.healthBar.y - 75;
		}
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;

		iconP1.visible = hud.hudData.iconp1vis;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(stage.dad.icondata, false);
		if (hud.hudData.iconp2overide != null)
		{
			iconP2.x += hud.hudData.geticonP2Pos(0);
			iconP2.y += hud.healthBar.y + hud.hudData.geticonP2Pos(1);
			trace(iconP2.x + ' ' + iconP2.y);
		}
		else
		{
			iconP2.y = hud.healthBar.y - 75;
		}

		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP2);
		hud.reloadHealthBarColors();

		scoreTxt = new FlxText(0, hud.healthBar.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.x += hud.hudData.scorposs[0];
		scoreTxt.y += hud.hudData.scorposs[1];
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		uiGroup.add(scoreTxt);

		botplayTxt = new FlxText(400, hud.timeTxt.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		uiGroup.add(botplayTxt);
		if (ClientPrefs.data.downScroll)
			botplayTxt.y = hud.timeTxt.y - 78;

		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];
		comboGroup.cameras = [camHUD];

		startingSong = true;

		for (event in eventPushedMap.keys())
		{
			// var hxToLoad:String = 'custom_events/' + event + '.hx';
			// Scripthandler.setupScripts(hxToLoad, instance,);
		}
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// SONG SPECIFIC SCRIPTS

		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [
			Paths.getPreloadPath('data/' + songfolder + Paths.formatToSongPath(SONG.song) + '/')
		];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + songfolder + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + songfolder + Paths.formatToSongPath(SONG.song) + '/'));

		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0,
				Paths.mods(mod + '/data/' + songfolder + Paths.formatToSongPath(SONG.song) +
					'/')); // using push instead of insert because these should run after everything else
		#end

		Scripthandler.checkDirectoryScripts(foldersToCheck, instance);

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			setFunctionOnScripts('PreSong', []);
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(stage.dad.getMidpoint().x + 150, stage.dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if (stage.gf != null)
						stage.gf.playAnim('scared', true);
					stage.boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if (daSong == 'roses')
						FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();

		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.data.hitsoundVolume > 0)
		{
			precacheList.set('hitsound', 'sound');
			precacheList.set('missnote1', 'sound');
			precacheList.set('missnote2', 'sound');
			precacheList.set('missnote3', 'sound');
		}

		if (PauseSubState.songName != null)
		{
			precacheList.set(PauseSubState.songName, 'music');
		}
		else if (ClientPrefs.data.pauseMusic != 'None')
		{
			precacheList.set(Paths.formatToSongPath(ClientPrefs.data.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", SONG.mettadata.Discordrpc, iconP2.getCharacter());
		#end

		if (!controls.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		stage.handlecamerafocus();
		playerStrumline.charlist = [stage.boyfriend];
		opponentStrumline.charlist = [stage.dad];
		setFunctionOnScripts('onCreatePost', []);

		utility.SignalDispatcher.addtoSignal('beatHit', Scripthandler.onBeatHit);
		utility.SignalDispatcher.addtoSignal('stepHit', Scripthandler.onBeatHit);

		super.create();

		cacheCountdown();
		cachePopUpScore();
		for (key => type in precacheList)
		{
			// trace('Key $key is type $type');
			switch (type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}
		FunkinMemory.clearUnusedMemory();

		// FunkinSoundTray.instance.resetBar('default',
		// 	FlxColor.fromRGB(PlayState.instance.stage.dad.healthColorArray[0], PlayState.instance.stage.dad.healthColorArray[1],
		// 		PlayState.instance.stage.dad.healthColorArray[2]));

		CustomFadeTransition.nextCamera = camOther;
	}

	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if (generatedMusic)
		{
			if (vocals != null)
				vocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		trace('Anim speed: ' + FlxG.animationTimeScale);
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		#end
		return playbackRate;
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					stage.startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);

					newDad.alpha = 0.00001;
				}

			case 2:
				if (stage.gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					stage.startCharacterPos(newGf);
					newGf.alpha = 0.00001;
				}
		}
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		if (modchartSprites.exists(tag))
			return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag))
			return modchartTexts.get(tag);
		if (variables.exists(tag))
			return variables.get(tag);
		return null;
	}

	public var videoCutscene:VideoSprite = null;

	public function startVideo(name:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
	{
		#if VIDEOS_ALLOWED
		inCutscene = !forMidSong;
		canPause = forMidSong;

		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile)
		{
			videoCutscene = new VideoSprite(fileName, forMidSong, canSkip, loop);
			if (forMidSong)
				videoCutscene.videoSprite.bitmap.rate = playbackRate;

			// Finish callback
			if (!forMidSong)
			{
				function onVideoEnd()
				{
					if (!isDead
						&& generatedMusic
						&& PlayState.SONG.notes[Std.int(curStep / 16)] != null
						&& !endingSong
						&& !isCameraOnForcedPos)
					{
						FlxG.camera.snapToTarget();
					}
					videoCutscene = null;
					canPause = true;
					inCutscene = false;
					startAndEnd();
				}
				videoCutscene.finishCallback = onVideoEnd;
				videoCutscene.onSkip = onVideoEnd;
			}
			if (GameOverSubstate.instance != null && isDead)
				GameOverSubstate.instance.add(videoCutscene);
			else
				add(videoCutscene);

			if (playOnLoad)
				videoCutscene.play();
			return videoCutscene;
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		else
			addTextToDebug("Video not found: " + fileName, FlxColor.RED);
		#else
		else
			FlxG.log.error("Video not found: " + fileName);
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		#end
		return null;
	}

	function startAndEnd()
	{
		if (endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	// You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong)
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong)
			{
				endSong();
			}
			else
			{
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);
		introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

		var introAlts:Array<String> = introAssets.get('default');
		if (stage.isPixelStage)
			introAlts = introAssets.get('pixel');

		for (asset in introAlts)
			Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
		setFunctionOnScripts('cacheCountdown', []);
	}

	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			return;
		}

		inCutscene = false;

		setFunctionOnScripts('startCountdown', []);

		if (skipCountdown || startOnTime > 0)
			skipArrowStartTween = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		startedCountdown = true;
		Conductor.songPosition = -Conductor.crochet * 5;

		var swagCounter:Int = 0;

		if (startOnTime < 0)
			startOnTime = 0;

		if (startOnTime > 0)
		{
			clearNotesBefore(startOnTime);
			setSongTime(startOnTime - 350);
			return;
		}
		else if (skipCountdown)
		{
			setSongTime(0);
			return;
		}

		startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
		{
			stage.characterBopper(tmr.loopsLeft);

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', 'set', 'go']);
			introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var antialias:Bool = ClientPrefs.data.globalAntialiasing;
			if (stage.isPixelStage)
			{
				introAlts = introAssets.get('pixel');
				antialias = false;
			}

			// head bopping for bg characters on Mall
			if (curStage == 'mall')
			{
				if (!ClientPrefs.data.lowQuality)
					upperBoppers.dance(true);

				bottomBoppers.dance(true);
				santa.dance(true);
			}

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
				case 1:
					countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					countdownReady.cameras = [camHUD];
					countdownReady.scrollFactor.set();
					countdownReady.updateHitbox();

					if (stage.isPixelStage)
						countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

					countdownReady.screenCenter();
					countdownReady.antialiasing = antialias;
					insert(members.indexOf(noteGroup), countdownReady);
					FlxTween.tween(countdownReady, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							remove(countdownReady);
							countdownReady.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
				case 2:
					countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					countdownSet.cameras = [camHUD];
					countdownSet.scrollFactor.set();

					if (stage.isPixelStage)
						countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

					countdownSet.screenCenter();
					countdownSet.antialiasing = antialias;
					insert(members.indexOf(noteGroup), countdownSet);
					FlxTween.tween(countdownSet, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							remove(countdownSet);
							countdownSet.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
				case 3:
					countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					countdownGo.cameras = [camHUD];
					countdownGo.scrollFactor.set();

					if (stage.isPixelStage)
						countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

					countdownGo.updateHitbox();

					countdownGo.screenCenter();
					countdownGo.antialiasing = antialias;
					insert(members.indexOf(noteGroup), countdownGo);
					FlxTween.tween(countdownGo, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							remove(countdownGo);
							countdownGo.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
				case 4:
			}

			// Set note alpha for both lanes during countdown
			var _applyCountdownAlpha = function(note:Note)
			{
				if (ClientPrefs.data.opponentStrums || note.mustPress)
				{
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if (ClientPrefs.data.middleScroll && !note.mustPress)
						note.alpha *= 0.35;
				}
			};
			playerStrumline.notes.forEachAlive(_applyCountdownAlpha);
			opponentStrumline.notes.forEachAlive(_applyCountdownAlpha);
			setFunctionOnScripts('onCountdownTick', [swagCounter]);

			swagCounter += 1;
		}, 5);
	}

	public function clearNotesBefore(time:Float)
	{
		if (playerStrumline != null)
			playerStrumline.clearNotesBefore(time);
		if (opponentStrumline != null)
			opponentStrumline.clearNotesBefore(time);
	}

	public dynamic function updateScore(miss:Bool = false)
	{
		var str:String = ratingName;
		if (ratingName != '?')
		{
			str = '${ratingName} (${Highscore.floorDecimal(ratingPercent * 100, 2)}%)' + (ratingFC != null && ratingFC != "" ? ' - ${ratingFC}' : '');
		}

		var tempScore:String = 'Score: ${songScore}' + (!instakillOnMiss ? ' | Misses: ${songMisses}' : "") + ' | Rating: ${str}';
		scoreTxt.text = '${tempScore}\n';

		if (ClientPrefs.data.scoreZoom && !miss && !cpuControlled)
		{
			if (scoreTxtTween != null)
			{
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween)
				{
					scoreTxtTween = null;
				}
			});
		}

		setFunctionOnScripts('onUpdateScore', [miss]);
	}

	public dynamic function fullComboFunction():Void
	{
		// Rating FC
		ratingFC = "";
		if (songMisses == 0)
		{
			if (sicks > 0)
				ratingFC = "SFC";
			if (goods > 0)
				ratingFC = "GFC";
			if (bads > 0 || shits > 0)
				ratingFC = "FC";
		}
		else
		{
			if (songMisses < 10)
				ratingFC = "SDCB";
			else
				ratingFC = "Clear";
		}
	}

	public function setSongTime(time:Float)
	{
		if (time < 0)
			time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
		}
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue()
	{
		dialogueCount++;
		setFunctionOnScripts('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue()
	{
		setFunctionOnScripts('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Float = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();

		if (startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if (paused)
		{
			// trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(hud.timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(hud.timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", SONG.mettadata.Discordrpc, iconP2.getCharacter(), true,
			songLength);
		#end
		setFunctionOnScripts('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	inline function makeEventNote(data:Song.EventData):EventNote
	{
		return {
			strumTime: data.strumTime + ClientPrefs.data.noteOffset,
			event: data.name,
			valuearray: data.values
		};
	}

	inline function getEventStringValue(event:EventNote, index:Int):String
	{
		if (event == null || event.valuearray == null || index < 0 || index >= event.valuearray.length)
			return '';
		var value:Dynamic = event.valuearray[index];
		return value == null ? '' : Std.string(value);
	}

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');

		switch (songSpeedType)
		{
			case "multiplicative":
				playerStrumline.songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
				opponentStrumline.songSpeed = playerStrumline.songSpeed;
			case "constant":
				playerStrumline.songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
				opponentStrumline.songSpeed = playerStrumline.songSpeed;
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new Vocals(PlayState.SONG.song); // FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new Vocals(null);

		#if FLX_PITCH vocals.pitch = playbackRate; #end

		// Notes are now owned by playerStrumline / opponentStrumline.
		// (The notes FlxTypedGroup getter points to playerStrumline.notes for compat.)

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		switch (songData.usealtcamspeed)
		{
			case true:
				steptyype = 'sec';
			case false:
				steptyype = 'step';
		}

		// Load Camera Events JSON
		var cameraFile:String = Paths.json(Constants.cursongfolder + songName + '/cameraevents');

		trace('looking for camera json at: ' + Paths.modsJson(Constants.cursongfolder + songName + '/cameraevents'));
		if (FileSystem.exists(Paths.modsJson(Constants.cursongfolder + '/' + songName + '/cameraevents')) || FileSystem.exists(cameraFile))
		{
			trace('loading camera events at location: ' + songfolder + songName + '/cameraevents');

			var cameraEventsData:Array<EventData> = Song.loadFromJson('cameraevents', Constants.cursongfolder + '/' + songName).cameraevents;

			for (cameraEvent in cameraEventsData)
			{
				if (cameraEvent == null)
					continue;

				var subCameraEvent:EventNote = makeEventNote(cameraEvent);

				subCameraEvent.strumTime -= eventNoteEarlyTrigger(subCameraEvent);

				eventNotes.push(subCameraEvent);
				trace('Pushing camera event: ' + subCameraEvent.event + ' at time: ' + subCameraEvent.strumTime);
				eventPushed(subCameraEvent);
			}
		}

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songfolder + songName + '/events');
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file))
		{
			trace('Loading event notes from:  ' + songfolder + songName);
			var eventsData:Array<EventData> = Song.loadFromJson('events', songfolder + songName).events;
			for (event in eventsData) // Event Notes
			{
				if (event == null)
					continue;

				var subEvent:EventNote = makeEventNote(event);
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// ── Note objects are now built inside each Strumline ──────────────────
		// Pass noteTypeMap so note-type scripts can be preloaded as before.
		var ghostNotesCleared:Int = 0; // kept for the trace below (strumlines clear internally)
		opponentStrumline.generateNotes(songData.notes, noteTypeMap);
		playerStrumline.generateNotes(songData.notes, noteTypeMap);

		for (event in songData.cameraevents) // Event Notes
		{
			if (event == null)
				continue;

			var subEvent:EventNote = makeEventNote(event);
			subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
			eventNotes.push(subEvent);
			eventPushed(subEvent);
		}

		for (event in songData.events) // Event Notes
		{
			if (event == null)
				continue;

			var subEvent:EventNote = makeEventNote(event);
			subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
			eventNotes.push(subEvent);
			eventPushed(subEvent);
		}
		trace('["${SONG.song.toUpperCase()}" CHART INFO]: Notes generated via Strumline instances (player + opponent).');
		// unspawnNotes are sorted inside each Strumline.generateNotes()
		if (eventNotes.length > 1)
		{ // No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote)
	{
		trace('Pushing event: ' + event.event);
		EventHandler.setupevents(event);
		if (!eventPushedMap.exists(event.event))
		{
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float
	{
		var returnedValue:Float = 0;

		setFunctionOnScripts('earlyTrigger', [event.event, returnedValue]);
		if (returnedValue != 0)
		{
			return returnedValue;
		}

		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; // for lua

	/**
	 * Delegates to the appropriate Strumline instance.
	 * Kept for Lua/HScript backward compat (player=0 → opponent, player=1 → player).
	 */
	private function generateStaticArrows(player:Int):Void
	{
		var strumline:objects.Strumline = (player == 1) ? playerStrumline : opponentStrumline;
		strumline.generateArrows(isStoryMode, skipArrowStartTween);

		// Register the sustain-splash sprites with the shared splash group
		for (babyArrow in strumline.strumNotes.members)
			grpSustainSplashes.add(babyArrow.sustainSplash);
	}

	public function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if (carTimer != null)
				carTimer.active = false;

			var chars:Array<Character> = [stage.boyfriend, stage.gf, stage.dad];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens)
			{
				tween.active = false;
			}
			for (timer in modchartTimers)
			{
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			if (carTimer != null)
				carTimer.active = true;

			var chars:Array<Character> = [stage.boyfriend, stage.gf, stage.dad];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens)
			{
				tween.active = true;
			}
			for (timer in modchartTimers)
			{
				timer.active = true;
			}
			paused = false;
			setFunctionOnScripts('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song
					+ " ("
					+ storyDifficultyText
					+ ")", SONG.mettadata.Discordrpc, iconP2.getCharacter(),
					true, songLength
					- Conductor.songPosition
					- ClientPrefs.data.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", SONG.mettadata.Discordrpc, iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song
					+ " ("
					+ storyDifficultyText
					+ ")", SONG.mettadata.Discordrpc, iconP2.getCharacter(),
					true, songLength
					- Conductor.songPosition
					- ClientPrefs.data.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", SONG.mettadata.Discordrpc, iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", SONG.mettadata.Discordrpc, iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		vocals.pause();

		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
		}
		vocals.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;

	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	/**
	 * Updates the values of the health bar.
	 */
	function updateHealth():Void
	{
		healthLerp = FlxMath.lerp(healthLerp, health, 0.15);
	}

	override public function update(elapsed:Float)
	{
		if (Constants.isdebug)
		{
			if (FlxG.keys.justPressed.SIX)
			{
				cpuControlled = !cpuControlled;
				botplayTxt.visible = !botplayTxt.visible;
				playerStrumline.cpuControlled = botplayTxt.visible;
				trace('CPU CONTROLLED: ' + playerStrumline.cpuControlled);
			}
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				Highscore.saveScore(SONG.song, songScore, storyDifficulty);
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO)
			{
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		if (camNotes.zoom != camHUD.zoom)
		{
			camNotes.zoom = camHUD.zoom;
		}
		setFunctionOnScripts('onUpdate', [elapsed]);
		updateHealth();
		hud.updatehealth(healthLerp);
		hud.updateTime(songPercent);

		if (!inCutscene)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if (!startingSong
				&& !endingSong
				&& stage.boyfriend.animation.curAnim != null
				&& stage.boyfriend.animation.curAnim.name.startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;
				if (boyfriendIdleTime >= 0.15)
				{ // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			}
			else
			{
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		if (botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Bool = false;
			setFunctionOnScripts('pause', [ret]);
			if (ret != true)
				openPauseMenu();
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
			openChartEditor();

		if (health > 2)
		{
			health = 2;
		}

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startedCountdown)
		{
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if (!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if (hud.showTime)
				{
					var curTime:Float = Conductor.songPosition - ClientPrefs.data.noteOffset;
					if (curTime < 0)
						curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if (ClientPrefs.data.timeBarType == 'Time Elapsed')
						songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if (secondsTotal < 0)
						secondsTotal = 0;

					if (ClientPrefs.data.timeBarType != 'Song Name')
						hud.timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		// ── Note spawning, movement and killing are handled inside each Strumline's update() ──
		// Strumlines are added to noteGroup so their update() is called automatically.

		if (generatedMusic && !inCutscene)
		{
			if (!cpuControlled)
				keyShit();
			else if (!startedCountdown)
			{
				// Before countdown starts, disable hit-detection on every active note
				playerStrumline.notes.forEachAlive(function(daNote:Note)
				{
					daNote.canBeHit = false;
					daNote.wasGoodHit = false;
				});
				opponentStrumline.notes.forEachAlive(function(daNote:Note)
				{
					daNote.canBeHit = false;
					daNote.wasGoodHit = false;
				});
			}
		}

		// Sustain-splash strumLine reset is now handled inside Strumline._resetSustainSplashes()

		checkEventNote();
		if (Constants.isdebug)
		{
			if (!endingSong && !startingSong)
			{
				if (FlxG.keys.justPressed.ONE)
				{
					KillNotes();
					FlxG.sound.music.onComplete();
				}
				if (FlxG.keys.justPressed.TWO)
				{ // Go 10 seconds into the future :O
					setSongTime(Conductor.songPosition + 10000);
					clearNotesBefore(Conductor.songPosition);
				}
			}
		}
		setFunctionOnScripts('onUpdatePost', [elapsed]);
	}

	function openPauseMenu()
	{
		setFunctionOnScripts('onGamePause', []);
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}
		if (pauseScript != '')
		{
			// openSubState(new ScriptableMusicBeatSubState(pauseScript));
		}
		else
		{
			openSubState(new PauseSubState(stage.boyfriend.getScreenPosition().x, stage.boyfriend.getScreenPosition().y));
		}

		#if hxdiscord_rpc
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", SONG.mettadata.Discordrpc, iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if hxdiscord_rpc
		DiscordClient.changePresence("Chart Editor", null, SONG.mettadata.Discordrpc, null, true);
		#end
	}

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = false;
			for (script in hscriptArray)
			{
				var func = script.variables.get("onGameOver");
				if (func != null)
				{
					ret = cast Reflect.callMethod(null, func, []);
				}
			}
			if (ret != true)
			{
				FlxG.animationTimeScale = 1;
				stage.boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens)
				{
					tween.active = true;
				}
				for (timer in modchartTimers)
				{
					timer.active = true;
				}
				openSubState(new GameOverSubstate(stage.boyfriend.getScreenPosition().x - stage.boyfriend.positionArray[0],
					stage.boyfriend.getScreenPosition().y - stage.boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(stage.boyfriend.getScreenPosition().x, stage.boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", SONG.mettadata.Discordrpc,
					iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
			{
				break;
			}

			triggerEventNote(eventNotes[0].event, eventNotes[0].valuearray);
			eventNotes.shift();
		}
	}

	public function getControl(key:String)
	{
		var pressed:Bool = Reflect.getProperty(controls, key);
		// trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, ?valuearray:Array<Note.Eventsvalue>)
	{
		EventHandler.callEvent(eventName, valuearray);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.
		var func:Dynamic = null;

		if (ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset)
		{
			finishCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer)
			{
				finishCallback();
			});
		}
	}

	public var transitioning = false;

	public function endSong():Void
	{
		// Should kill you if you tried to cheat
		if (!startingSong)
		{
			var _cheatCheck = function(daNote:Note)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;
			};
			playerStrumline.notes.forEach(_cheatCheck);
			opponentStrumline.notes.forEach(_cheatCheck);
			for (daNote in playerStrumline.unspawnNotes)
				_cheatCheck(daNote);
			for (daNote in opponentStrumline.unspawnNotes)
				_cheatCheck(daNote);

			if (doDeathCheck())
			{
				return;
			}
		}

		hud.timeBar.visible = false;
		hud.timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		#end

		setFunctionOnScripts('onSongEnd', []);
		if (!transitioning)
		{
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent))
					percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					WeekData.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelMusicFadeTween();
					if (FlxTransitionableState.skipNextTransIn)
					{
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if (!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false))
					{
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, songfolder + PlayState.storyPlaylist[0]); // quickfix
					FlxG.sound.music.stop();

					if (winterHorrorlandNext)
					{
						new FlxTimer().start(1.5, function(tmr:FlxTimer)
						{
							cancelMusicFadeTween();
							MusicBeatState.switchState(new LoadingState(new PlayState()));
						});
					}
					else
					{
						cancelMusicFadeTween();
						MusicBeatState.switchState(new LoadingState(new PlayState()));
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				WeekData.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if (FlxTransitionableState.skipNextTransIn)
				{
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new states.Freeplay());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	public function KillNotes()
	{
		if (playerStrumline != null)
			playerStrumline.killAllNotes();
		if (opponentStrumline != null)
			opponentStrumline.killAllNotes();
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function cachePopUpScore()
	{
		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';
		if (stage.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		Paths.image(pixelShitPart1 + "sick" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "good" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "bad" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "shit" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "combo" + pixelShitPart2);

		for (i in 0...10)
		{
			Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2);
		}
	}

	public function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.unmutePlayer();

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		// tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if (!note.ratingDisabled)
			daRating.increase();
		note.rating = daRating.name;
		score = daRating.score;

		if (daRating.noteSplash && !note.noteSplashDisabled)
			spawnNoteSplashOnNote(note);

		if (!practiceMode && !cpuControlled)
		{
			songScore += score;
			if (!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 1)
		{
			for (spr in comboGroup.members)
			{
				spr.destroy();
				comboGroup.remove(spr, true);
			}
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (stage.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		comboGroup.add(rating);

		if (!stage.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.data.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.data.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if (combo >= 1000)
		{
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
			comboGroup.add(comboSpr);

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.data.comboOffset[2];
			numScore.y -= ClientPrefs.data.comboOffset[3];

			if (!stage.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.data.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;

			// if (combo >= 10 || combo == 0)
			if (showComboNum)
				comboGroup.add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if (numScore.x > xThing)
				xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;

		coolText.text = Std.string(seperatedScore);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		if (!FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
			return;
		var key:Int = getKeyFromEvent(eventKey);

		if (cpuControlled || paused || key < 0)
			return;
		if (!generatedMusic || endingSong || stage.boyfriend.stunned)
			return;

		// had to name it like this else it'd break older scripts lol
		var ret:Bool = false;
		setFunctionOnScripts('onKeyPressCheck', [key, ret]);
		if (ret == true)
			return;

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if (Conductor.songPosition >= 0)
			Conductor.songPosition = FlxG.sound.music.time;

		// obtain notes that the player can hit (from the player strumline only)
		final plrInputNotes:Array<Note> = playerStrumline.notes.members.filter(function(n:Note):Bool
		{
			var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			return n != null && canHit && !n.isSustainNote && n.noteData == key;
		});
		plrInputNotes.sort(sortHitNotes);

		var shouldMiss:Bool = !ClientPrefs.data.ghostTapping;

		if (plrInputNotes.length != 0)
		{ // slightly faster than doing `> 0` lol
			final funnyNote:Note = plrInputNotes[0]; // front note
			// trace('✡⚐🕆☼ 💣⚐💣');
			playerStrumline.hitNote(funnyNote);
		}
		else
		{
			if (shouldMiss && !stage.boyfriend.stunned)
			{
				setFunctionOnScripts('onGhostTap', [key]);
				noteMissPress(key);
			}
		}

		// Needed for the  "Just the Two of Us" achievement.
		//									- Shadow Mario
		keysPressed[key] = true;

		// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;

		var spr:StrumNote = playerStrumline.strumNotes.members[key];
		if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
		setFunctionOnScripts('onKeyPress', [key]);
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		if (!FlxG.keys.checkStatus(eventKey, JUST_RELEASED))
			return;
		var key:Int = getKeyFromEvent(eventKey);
		if (!cpuControlled && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = playerStrumline.strumNotes.members[key];
			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			setFunctionOnScripts('onKeyRelease', [key]);
		}
		// trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key == NONE)
			return -1;
		for (i in 0...keysArray.length)
		{
			for (j in 0...keysArray[i].length)
				if (key == keysArray[i][j])
					return i;
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (controls.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] && strumsBlocked[i] != true)
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !stage.boyfriend.stunned && generatedMusic)
		{
			// Hold note hit-detection on the player strumline only
			playerStrumline.notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (strumsBlocked[daNote.noteData] != true
					&& daNote.isSustainNote
					&& parsedHoldArray[daNote.noteData]
					&& daNote.canBeHit
					&& daNote.mustPress
					&& !daNote.tooLate
					&& !daNote.wasGoodHit
					&& !daNote.blockHit)
				{
					playerStrumline.hitNote(daNote);
				}
			});
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (controls.controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}
		return ret;
	}

	public function noteMiss(daNote:Note):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note removal is delegated to the Strumline
		playerStrumline.removeDupeNotes(daNote);
		combo = 0;

		health -= daNote.missHealth * healthLoss;

		if (instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		// For testing purposes
		// trace(daNote.missHealth);
		songMisses++;
		vocals.mutePlayer();
		if (!practiceMode)
			songScore -= 10;

		totalPlayed++;
		RecalculateRating(true);

		var char:Character = stage.boyfriend;
		if (daNote.gfNote)
		{
			char = stage.gf;
		}

		if (char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daNote.animSuffix;
			char.playSingAnim(daNote, animToPlay, true);
		}
		setFunctionOnScripts('noteMiss', [playerStrumline.notes.members.indexOf(daNote), daNote]);
	}

	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.data.ghostTapping)
			return; // fuck it

		if (!stage.boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if (instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (combo > 5 && stage.gf != null && stage.gf.animOffsets.exists('sad'))
			{
				stage.gf.playAnim('sad');
			}
			combo = 0;

			if (!practiceMode)
				songScore -= 10;
			if (!endingSong)
			{
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating(true);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			if (stage.boyfriend.hasMissAnimations)
			{
				stage.boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.mutePlayer();
		}
		setFunctionOnScripts('noteMissPress', [direction]);
	}

	public function opponentNoteHit(note:Note):Void
	{
		opponentStrumline.hitNote(note);
	}

	public function goodNoteHit(note:Note):Void
	{
		playerStrumline.hitNote(note);
	}

	public inline function getSingAnimationByData(noteData:Int):String
	{
		return singAnimations[Std.int(Math.abs(noteData))];
	}

	public function invalidateNote(note:Note)
	{
		var strumline = note.mustPress ? playerStrumline : opponentStrumline;
		strumline.invalidateNote(note);
	}

	public function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.data.noteSplashes && note != null)
		{
			var strum:StrumNote = playerStrumline.strumNotes.members[note.noteData];
			if (strum != null)
			{
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var skin:String = 'noteSplashes';
		if (hud.hudData.getNotesplash() != null || hud.hudData.getNotesplash() != '')
		{
			skin = hud.hudData.getNotesplash();
		}

		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;
		if (data > -1 && data < ClientPrefs.data.arrowHSV.length)
		{
			hue = ClientPrefs.data.arrowHSV[data][0] / 360;
			sat = ClientPrefs.data.arrowHSV[data][1] / 100;
			brt = ClientPrefs.data.arrowHSV[data][2] / 100;
			if (note != null)
			{
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		if (splashoveride != null)
		{
			skin = splashoveride;
		}
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;

	function fastCarDrive()
	{
		// trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;
	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (stage.gf != null)
			{
				stage.gf.playAnim('hairBlow');
				stage.gf.specialAnim = true;
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		if (stage.gf != null)
		{
			stage.gf.danced = false; // Sets head to the correct position once the animation ends
			stage.gf.playAnim('hairFall');
			stage.gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if (!ClientPrefs.data.lowQuality)
			halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (stage.boyfriend.animOffsets.exists('scared'))
		{
			stage.boyfriend.playAnim('scared', true);
		}

		if (stage.gf != null && stage.gf.animOffsets.exists('scared'))
		{
			stage.gf.playAnim('scared', true);
		}

		if (ClientPrefs.data.camZooms)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if (!camZooming)
			{ // Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if (ClientPrefs.data.flashing)
		{
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	override function destroy()
	{
		if (!controls.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		FlxG.animationTimeScale = 1;
		#if FLX_PITCH FlxG.sound.music.pitch = 1; #end
		utility.SignalDispatcher.removefromSignal('beatHit', Scripthandler.onBeatHit);
		utility.SignalDispatcher.removefromSignal('stepHit', Scripthandler.onBeatHit);
		super.destroy();
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
		{
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
		{
			resyncVocals();
		}

		if (curStep == lastStepHit)
		{
			return;
		}

		lastStepHit = curStep;
		setFunctionOnScripts('onStepHit', [curStep]);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
		{
			// trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			playerStrumline.notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
			opponentStrumline.notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		stage.characterBopper(curBeat);
		lastBeatHit = curBeat;
		setFunctionOnScripts('onBeatHit', [curBeat]);
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}
		}
		if (SONG.notes[curSection].changeBPM)
		{
			Conductor.bpm = SONG.notes[curSection].bpm;
		}
		setFunctionOnScripts('onSectionHit', []);
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float)
	{
		var spr:StrumNote = null;
		if (isDad)
		{
			spr = strumLineNotes.members[id];
		}
		else
		{
			spr = playerStrumline.strumNotes.members[id];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating(badHit:Bool = false)
	{
		if (totalPlayed < 1) // Prevent divide by 0
			ratingName = '?';
		else
		{
			// Rating Percent
			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
			// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

			// Rating Name
			if (ratingPercent >= 1)
			{
				ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
			}
			else
			{
				for (i in 0...ratingStuff.length - 1)
				{
					if (ratingPercent < ratingStuff[i][1])
					{
						ratingName = ratingStuff[i][0];
						break;
					}
				}
			}
		}

		setFunctionOnScripts('onRecalculateRating', [badHit]);
		fullComboFunction();

		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
	}

	public function setFunctionOnScripts(name:String, params:Array<AnyValue>, ?playStateScriptsOnly:Bool = false)
	{
		Scripthandler.dispatchevent(name, params);
	}

	var curLight:Int = -1;
	var curLightEvent:Int = -1;
}
