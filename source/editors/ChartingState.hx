package editors;

#if hxdiscord_rpc
import Discord.DiscordClient;
#end
import flash.geom.Rectangle;
import haxe.Json;
import haxe.format.JsonParser;
import haxe.io.Bytes;
import Conductor.BPMChangeEvent;
import Section.SwagSection;
import events.BaseEvent;
import Song.SwagSong;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import debug.Consolehandler;
import objects.Cursor;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import backend.ui.PsychUIBox;
import backend.ui.PsychUICheckBox;
import backend.ui.PsychUIInputText;
import backend.ui.Prompt;
import backend.ui.PsychUINumericStepper;
import backend.ui.PsychUISlider;
import backend.ui.PsychUIButton;
import backend.ui.PsychUIDropDownMenu;
import backend.ui.PsychUIEventHandler.PsychUIEvent;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.FunkinSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import lime.media.AudioBuffer;
import lime.utils.Assets;
import openfl.events.Event;
import flixel.util.FlxTimer;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;
import openfl.utils.ByteArray;
import editors.ChartHelpSubstate;
#if desktop
import lime.app.Application;
import lime.ui.FileDialog;
#end

using StringTools;

#if sys
import flash.media.Sound;
import sys.FileSystem;
import sys.io.File;
#end

@:access(flixel.system.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)
class ChartingState extends MusicBeatState implements PsychUIEvent
{
	public static var noteTypeList:Array<String> = // Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
		['', 'Alt Animation', 'Hey!', 'Hurt Note', 'GF Sing', 'invisible', 'No Animation'];

	private var noteTypeIntMap:Map<Int, String> = new Map<Int, String>();
	private var noteTypeMap:Map<String, Null<Int>> = new Map<String, Null<Int>>();

	public var ignoreWarnings = false;
	public var notetypeoveride:Bool = false;

	var undos = [];
	var redos = [];
	var eventStuff:Array<Dynamic> = [
		['', "Nothing. Yep, that's right."],
		[
			'Camera Movment',
			"Value 1: Value 1 includes the character to focus on, and the offset of the camera \nValue 2: is the easing tyoe and tween time, easing can be ignored for just time. tho it will use liniar"
		],
		['Camera Snap', "Value 1: Character to focous (Dad, BF, GF)"],
		[
			'Camera Zoom',
			"Value 1:ease \nValue 2: time first, zoom second. if no zoom then itl default to defaultcamzoom"
		],
		[
			'Hey!',
			"Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"
		],
		[
			'Set GF Speed',
			"Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"
		],
		[
			'Add Camera Zoom',
			"Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."
		],
		[
			'Run Stage Function',
			'Value 1 is the desired function name in script\nValue 2 is the value'
		],
		[
			'lyrics',
			'Value 1 is the desired text\nValue 2 is the length of the dialogue in Steps'
		],
		[
			'lyrics icon overide',
			'Value 1 is the desired icon, use icon name without icon-. seperated by a , is the animation frame.\nValue 2: no matter what this is itl reset the icon to its default'
		],
		[
			'Play Animation',
			"Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"
		],
		[
			'Camera Follow Pos',
			"Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."
		],
		[
			'Alt Idle Animation',
			"Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"
		],
		[
			'Screen Shake',
			"Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."
		],
		[
			'Change Character',
			"Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"
		],
		[
			'Change Scroll Speed',
			"Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."
		],
		['Set Property', "Value 1: Variable name\nValue 2: New value"]
	];

	var _file:FileReference;
	#if desktop
	var _savingDialog:Bool = false;
	#end

	var mainBox:PsychUIBox;

	public var camPrompt:FlxCamera;
	public var camhud:FlxCamera;

	public static var goToPlayState:Bool = false;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSec:Int = 0;

	public static var lastSection:Int = 0;
	private static var lastSong:String = '';

	var exstentionnum:Int = 4;

	var bpmTxt:FlxText;

	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var quant:AttachedSprite;
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var curSong:String = 'Test';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	public static var GRID_SIZE:Int = 40;

	var CAM_OFFSET:Int = 360;

	var opponentlocation:Array<Float>;
	var playerlocation:Array<Float>;
	var dummyArrow:FlxSprite;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedNoteType:FlxTypedGroup<FlxText>;

	var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	var nextRenderedNotes:FlxTypedGroup<Note>;

	var prevRenderedSustains:FlxTypedGroup<FlxSprite>;
	var prevRenderedNotes:FlxTypedGroup<Note>;

	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;
	var prevGridBG:FlxSprite;

	var daquantspot = 0;
	var curEventSelected:Int = 0;
	var curUndoIndex = 0;
	var curRedoIndex = 0;
	var _song:SwagSong;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Dynamic = null;

	var vocals:Vocals = null; // var vocals:FlxSound = null;

	var upperBox:PsychUIBox;

	var tempBpm:Float = 0;
	var playbackSpeed:Float = 1;

	var leftIcon:FunkinSprite;
	var altcamspeed:PsychUICheckBox;
	var rightIcon:FunkinSprite;

	var eventsobjects:Array<Dynamic> = [];
	var eventBindings:Array<Dynamic> = [];
	var eventValueInputBindings:Array<Dynamic> = [];

	var value1InputText:Dynamic;
	var value2InputText:Dynamic;
	var currentSongName:String;
	var tab_group_note:FlxSpriteGroup;
	var tab_group_event:FlxSpriteGroup;
	var tab_group_song:FlxSpriteGroup;
	var tab_group_section:FlxSpriteGroup;
	var tab_group_chart:FlxSpriteGroup;

	var zoomTxt:FlxText;

	var zoomList:Array<Float> = [0.25, 0.5, 1, 2, 3, 4, 6, 8, 12, 16, 24];
	var curZoom:Int = 2;

	private var blockPressWhileTypingOn:Array<PsychUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<PsychUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<PsychUIDropDownMenu> = [];

	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	public var quantizations:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

	var text:String = "";

	public static var vortex:Bool = false;

	public var mouseQuant:Bool = false;

	var justChanged:Bool;
	var lilStage:FlxSprite;
	var lilBf:FlxSprite;
	var lilOpp:FlxSprite;

	override function create()
	{
		camPrompt = new FlxCamera();
		Cursor.show();
		camhud = new FlxCamera();
		camPrompt.bgColor.alpha = 0;
		camhud.bgColor.alpha = 0;

		FlxG.cameras.reset(camhud);
		FlxG.cameras.add(camPrompt, false);
		FlxG.cameras.setDefaultDrawTarget(camhud, true);
		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

			_song = {
				song: 'soulbound',
				notes: [],
				events: [],
				cameraevents: [],
				bpm: 150.0,
				needsVoices: true,
				arrowSkin: '',
				extradata: [],
				hudSkin: 'default',
				splashSkin: 'noteSplashes', // idk it would crash if i didn't
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				usealtcamspeed: false,
				speed: 1,
				stage: 'stage',
				validScore: false
			};
			addSection();
			PlayState.SONG = _song;
		}

		// Paths.clearMemory();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Chart Editor", StringTools.replace(_song.song, '-', ' '));
		#end

		vortex = FlxG.save.data.chart_vortex;
		ignoreWarnings = FlxG.save.data.ignoreWarnings;
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF222222;
		add(bg);

		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);

		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		add(waveformSprite);

		lilStage = new FlxSprite(20, 432).loadGraphic(Paths.image("chartEditor/lilStage"));
		lilStage.scrollFactor.set();

		lilBf = new FlxSprite(20, 432).loadGraphic(Paths.image("chartEditor/lilBf"), true, 300, 256);
		lilBf.animation.add("idle", [0, 1], 12, true);
		lilBf.animation.add("0", [3, 4, 5], 12, false);
		lilBf.animation.add("1", [6, 7, 8], 12, false);
		lilBf.animation.add("2", [9, 10, 11], 12, false);
		lilBf.animation.add("3", [12, 13, 14], 12, false);
		lilBf.animation.add("yeah", [17, 20, 23], 12, false);
		lilBf.animation.play("idle");
		lilBf.animation.onFinish.add(function(name:String)
		{
			lilBf.animation.play(name, true, false, lilBf.animation.getByName(name).numFrames - 2);
		});
		lilBf.scrollFactor.set();

		lilOpp = new FlxSprite(20, 432).loadGraphic(Paths.image("chartEditor/lilOpp"), true, 300, 256);
		lilOpp.animation.add("idle", [0, 1], 12, true);
		lilOpp.animation.add("0", [3, 4, 5], 12, false);
		lilOpp.animation.add("1", [6, 7, 8], 12, false);
		lilOpp.animation.add("2", [9, 10, 11], 12, false);
		lilOpp.animation.add("3", [12, 13, 14], 12, false);
		lilOpp.animation.play("idle");
		lilOpp.animation.onFinish.add(function(name:String)
		{
			lilOpp.animation.play(name, true, false, lilOpp.animation.getByName(name).numFrames - 2);
		});
		lilOpp.scrollFactor.set();

		add(lilStage);
		add(lilBf);
		add(lilOpp);
		resetIdle();
		var eventIcon:FlxSprite = new FlxSprite(-GRID_SIZE - 5, -90).loadGraphic(Paths.image('eventArrow'));
		var camIcon:FlxSprite = new FlxSprite(-GRID_SIZE - 50, -90).loadGraphic(Paths.image('cameraArrow'));
		leftIcon = new FunkinSprite(0, 0);
		leftIcon.loadGraphic(Paths.image("chartEditor/opponent"));
		rightIcon = new FunkinSprite(0, 0);
		rightIcon.loadGraphic(Paths.image("chartEditor/player"));
		eventIcon.scrollFactor.set(1, 1);
		camIcon.scrollFactor.set(1, 1);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		eventIcon.setGraphicSize(30, 30);
		camIcon.setGraphicSize(30, 30);
		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(eventIcon);
		add(camIcon);
		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(GRID_SIZE + 10, -100);
		opponentlocation = [leftIcon.x, leftIcon.y];
		rightIcon.setPosition(GRID_SIZE * 5.2, -100);
		playerlocation = [rightIcon.x, rightIcon.y];

		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedNoteType = new FlxTypedGroup<FlxText>();

		prevRenderedSustains = new FlxTypedGroup<FlxSprite>();
		prevRenderedNotes = new FlxTypedGroup<Note>();

		nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		nextRenderedNotes = new FlxTypedGroup<Note>();

		if (curSec >= _song.notes.length)
			curSec = _song.notes.length - 1;

		// FlxG.save.bind('funkin', CoolUtil.getSavePath());

		tempBpm = _song.bpm;

		addSection();

		// sections = _song.notes;

		currentSongName = Paths.formatToSongPath(_song.song);
		loadSong();
		reloadGridLayer();
		Conductor.bpm = _song.bpm;
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(-30, 50).makeGraphic(Std.int(GRID_SIZE * 10), 4);
		add(strumLine);

		quant = new AttachedSprite('chart_quant', 'chart_quant');
		quant.animation.addByPrefix('q', 'chart_quant', 0, false);
		quant.animation.play('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.xAdd = -32;
		quant.yAdd = 8;
		add(quant);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		for (i in 0...8)
		{
			var note:StrumNote = new StrumNote(GRID_SIZE * (i + 1), strumLine.y, i % 4, 0);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static', true);
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
		}
		add(strumLineNotes);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Charting", label: 'Charting'},
		];

		var tabNames:Array<String> = [];
		for (tab in tabs)
			tabNames.push(tab.name);

		upperBox = new PsychUIBox(0, 40, 200, 300, ['File', 'options']);
		upperBox.scrollFactor.set();
		upperBox.isMinimized = true;
		upperBox.minimizeOnFocusLost = true;
		upperBox.canMove = false;
		upperBox.bg.visible = false;
		add(upperBox);
		mainBox = new PsychUIBox(680 + GRID_SIZE / 2, 25, 380, 400, tabNames);
		mainBox.selectedName = 'Song';
		mainBox.scrollFactor.set();

		text = "W/S or Mouse Wheel - Change Conductor's strum time
		\nA/D - Go to the previous/next section
		\nLeft/Right - Change Snap
		\nUp/Down - Change Conductor's Strum Time with Snapping"
			+ #if FLX_PITCH "\nLeft Bracket / Right Bracket - Change Song Playback Rate (SHIFT to go Faster)
		\nALT + Left Bracket / Right Bracket - Reset Song Playback Rate"
			+ #end "\nHold Shift to move 4x faster
		\nHold Control and click on an arrow to select it
		\nZ/X - Zoom in/out
		\n
		\nright click to remove notes/events. left click to place
		\nEsc - Test your chart inside Chart Editor
		\nEnter - Play your chart
		\nQ/E - Decrease/Increase Note Sustain Length
		\nSpace - Stop/Resume song";

		var tipTextArray:Array<String> = text.split('\n');
		for (i in 0...tipTextArray.length)
		{
			// var tipText:FlxText = new FlxText(mainBox.x, mainBox.y + mainBox.height + 8, 0, tipTextArray[i], 16);
			// tipText.y += i * 12;
			// tipText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
			// //tipText.borderSize = 2;
			// tipText.scrollFactor.set();
			// add(tipText);
		}
		add(mainBox);
		addFileUi();
		addOptionsUi();
		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
		addChartingUI();
		updateHeads();
		updateWaveform();
		// mainBox.selectedName = 'Charting';

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);
		add(prevRenderedSustains);
		add(prevRenderedNotes);

		if (lastSong != currentSongName)
		{
			changeSection();
		}
		lastSong = currentSongName;

		zoomTxt = new FlxText(10, 10, 0, "Zoom: 1 / 1", 16);
		zoomTxt.scrollFactor.set();
		add(zoomTxt);

		updateGrid();
		strumLineUpdateY();
		for (i in 0...8)
		{
			strumLineNotes.members[i].y = strumLine.y;
		}
		camPos.y = strumLine.y;
		super.create();
	}

	var check_mute_inst:PsychUICheckBox = null;
	var check_vortex:PsychUICheckBox = null;
	var check_warnings:PsychUICheckBox = null;
	var playSoundBf:PsychUICheckBox = null;
	var playSoundDad:PsychUICheckBox = null;
	var UI_songTitle:PsychUIInputText;

	var hudSkinInputText:PsychUIInputText;

	var stageDropDown:PsychUIDropDownMenu;
	#if FLX_PITCH
	var sliderRate:PsychUISlider;
	#end

	function addOptionsUi():Void
	{
		var tab = upperBox.getTab('options');
		if (tab == null || tab.menu == null)
			return;

		var tab_group = tab.menu;
		var btnX:Int = Std.int(tab.x - upperBox.x);
		var btnY:Int = 1;
		var btnWid:Int = Std.int(tab.width);

		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Autosave Settings...', btnWid);
		btn.onClick = function()
		{
			upperBox.isMinimized = true;
			upperBox.bg.visible = false;
			openSubState(new BasePrompt(400, 160, 'Charting State scroll direction\n This will save and reload your chart', function(state:BasePrompt)
			{
				var btn:PsychUIButton = new PsychUIButton(state.bg.x + state.bg.width - 40, state.bg.y, 'X', state.close, 40);
				btn.cameras = state.cameras;
				var yes:PsychUIButton = new PsychUIButton(state.bg.x + state.bg.width - 40, state.bg.y, 'Uppscroll', function()
				{
					FlxG.save.data.chart_downscroll = true;
					updateGrid();
					state.close();
				}, 80);
				yes.cameras = state.cameras;
				CoolUtil.centerSpriteonSprite(yes, state.bg);
				yes.x += 100;
				yes.y += 50;
				var no:PsychUIButton = new PsychUIButton(state.bg.x + state.bg.width - 40, state.bg.y, 'Downscroll', function()
				{
					FlxG.save.data.chart_downscroll = false;
					updateGrid();
					state.close();
				}, 80);
				no.cameras = state.cameras;
				CoolUtil.centerSpriteonSprite(no, state.bg);
				no.x -= 100;
				no.y += 50;
				state.add(btn);
				state.add(yes);
				state.add(no);
			}));
		};
		tab_group.add(btn);
	}

	function addFileUi():Void
	{
		var tab = upperBox.getTab('File');
		if (tab == null || tab.menu == null)
			return;

		var tab_group = tab.menu;
		var btnX:Int = Std.int(tab.x - upperBox.x);
		var btnY:Int = 1;
		var btnWid:Int = Std.int(tab.width);

		var saveBtn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Save Chart', function()
		{
			saveLevel();
		}, btnWid);
		saveBtn.text.alignment = LEFT;
		tab_group.add(saveBtn);

		btnY += 20;
		var saveEventsBtn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Save Events', function()
		{
			saveEvents();
		}, btnWid);
		saveEventsBtn.text.alignment = LEFT;
		tab_group.add(saveEventsBtn);

		btnY += 20;
		var saveCamEventsBtn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Save CamEvents', function()
		{
			saveCameraEvents();
		}, btnWid);
		saveCamEventsBtn.text.alignment = LEFT;
		tab_group.add(saveCamEventsBtn);
		saveCamEventsBtn.text.fieldWidth + 30;

		btnY += 21;
		var reloadAudioBtn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Reload Audio', function()
		{
			currentSongName = Paths.formatToSongPath(UI_songTitle.text);
			loadSong();
			updateWaveform();
		}, btnWid);
		reloadAudioBtn.text.alignment = LEFT;
		tab_group.add(reloadAudioBtn);

		btnY += 20;
		var reloadJsonBtn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Reload JSON', function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', function()
			{
				this.persistentUpdate = false;
				loadJson(_song.song.toLowerCase());
			}));
		}, btnWid);
		reloadJsonBtn.text.alignment = LEFT;
		tab_group.add(reloadJsonBtn);

		btnY += 20;
		var loadAutosaveBtn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Load Autosave', function()
		{
			PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
			MusicBeatState.resetState();
		}, btnWid);
		loadAutosaveBtn.text.alignment = LEFT;
		tab_group.add(loadAutosaveBtn);

		btnY += 20;
		var loadEventsBtn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Load Events', function()
		{
			var songName:String = Paths.formatToSongPath(_song.song);
			var type:String = "default";
			var lowerSong = songName.toLowerCase();

			for (t in Constants.defaultsongtypes)
			{
				if (lowerSong.contains(t))
				{
					type = t;
					break;
				}
			}

			var foldertogo:String = 'songs/' + type;
			Constants.cursongfolder = foldertogo;
			var eventPath = foldertogo + "/" + songName;

			clearEvents();
			var events:SwagSong = Song.loadFromJson("events", eventPath);
			_song.events = events.events;
			changeSection(curSec);
		}, btnWid);
		loadEventsBtn.text.alignment = LEFT;
		tab_group.add(loadEventsBtn);

		btnY += 20;
		var loadCamEventsBtn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Load CamEvents', function()
		{
			var songName:String = Paths.formatToSongPath(_song.song);
			var type:String = "default";
			var lowerSong = songName.toLowerCase();

			for (t in Constants.defaultsongtypes)
			{
				if (lowerSong.contains(t))
				{
					type = t;
					break;
				}
			}

			var foldertogo:String = 'songs/' + type;
			Constants.cursongfolder = foldertogo;
			var eventPath = foldertogo + "/" + songName;

			clearcamEvents();
			var events:SwagSong = Song.loadFromJson('cameraevents', eventPath);
			_song.cameraevents = events.cameraevents;
			changeSection(curSec);
		}, btnWid);
		loadCamEventsBtn.text.alignment = LEFT;
		tab_group.add(loadCamEventsBtn);
	}

	function addSongUI():Void
	{
		UI_songTitle = new PsychUIInputText(10, 10, 70, _song.song, 8);
		blockPressWhileTypingOn.push(UI_songTitle);
		altcamspeed = new PsychUICheckBox(UI_songTitle.x + 188, UI_songTitle.y, 'Use Alt Camera Speed Math', 100);
		altcamspeed.checked = _song.usealtcamspeed;
		altcamspeed.onClick = function()
		{
			_song.usealtcamspeed = altcamspeed.checked;
		};
		var check_voices = new PsychUICheckBox(10, 25, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		check_voices.onClick = function()
		{
			_song.needsVoices = check_voices.checked;
		};

		var clear_events:PsychUIButton = new PsychUIButton(320, 310, 'Clear events', function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', clearEvents));
		}, 90, 20);

		var clear_notes:PsychUIButton = new PsychUIButton(320, clear_events.y + 30, 'Clear notes', function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', function()
			{
				for (sec in 0..._song.notes.length)
				{
					_song.notes[sec].sectionNotes = [];
				}
				updateGrid();
			}));
		}, 90, 20);

		var stepperBPM:PsychUINumericStepper = new PsychUINumericStepper(10, 70, 1, 1, 1, 400, 3);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		blockPressWhileTypingOnStepper.push(stepperBPM);

		var stepperSpeed:PsychUINumericStepper = new PsychUINumericStepper(10, stepperBPM.y + 35, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		blockPressWhileTypingOnStepper.push(stepperSpeed);

		var directories:Array<String> = [
			Paths.mods('data/characters/'),
			Paths.mods(Paths.currentModDirectory + '/data/characters/'),
			Paths.getPreloadPath('data/characters/')
		];
		for (mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/data/characters/'));

		var tempMap:Map<String, Bool> = new Map<String, Bool>();
		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));
		for (i in 0...characters.length)
		{
			tempMap.set(characters[i], true);
		}

		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			trace(directory);
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var charToCheck:String = file.substr(0, file.length - 5);
						trace(charToCheck);
						if (!charToCheck.endsWith('-dead') && !tempMap.exists(charToCheck))
						{
							tempMap.set(charToCheck, true);
							characters.push(charToCheck);
						}
					}
				}
			}
		}

		var player1DropDown = new PsychUIDropDownMenu(10, stepperSpeed.y + 45, characters, function(id:Int, character:String)
		{
			_song.player1 = characters[id];
			updateHeads();
		}, 130);
		player1DropDown.selectedLabel = _song.player1;
		blockPressWhileScrolling.push(player1DropDown);

		var gfVersionDropDown = new PsychUIDropDownMenu(player1DropDown.x, player1DropDown.y + 40, characters, function(id:Int, character:String)
		{
			_song.gfVersion = characters[id];
			updateHeads();
		}, 130);
		gfVersionDropDown.selectedLabel = _song.gfVersion;
		blockPressWhileScrolling.push(gfVersionDropDown);

		var player2DropDown = new PsychUIDropDownMenu(player1DropDown.x, gfVersionDropDown.y + 40, characters, function(id:Int, character:String)
		{
			_song.player2 = characters[id];
			updateHeads();
		}, 130);
		player2DropDown.selectedLabel = _song.player2;
		blockPressWhileScrolling.push(player2DropDown);

		var directories:Array<String> = [
			Paths.mods('data/stages/'),
			Paths.mods(Paths.currentModDirectory + '/data/stages/'),
			Paths.getPreloadPath('data/stages/')
		];
		for (mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/data/stages/'));

		tempMap.clear();
		var stageFile:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));
		var stages:Array<String> = [];
		for (i in 0...stageFile.length)
		{ // Prevent duplicates
			var stageToCheck:String = stageFile[i];
			if (!tempMap.exists(stageToCheck))
			{
				stages.push(stageToCheck);
			}
			tempMap.set(stageToCheck, true);
		}
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var stageToCheck:String = file.substr(0, file.length - 5);
						if (!tempMap.exists(stageToCheck))
						{
							tempMap.set(stageToCheck, true);
							stages.push(stageToCheck);
						}
					}
				}
			}
		}

		if (stages.length < 1)
			stages.push('stage');

		stageDropDown = new PsychUIDropDownMenu(player1DropDown.x + 190, player1DropDown.y, stages, function(id:Int, character:String)
		{
			_song.stage = stages[id];
		}, 140);
		stageDropDown.selectedLabel = _song.stage;
		blockPressWhileScrolling.push(stageDropDown);

		var skin = PlayState.SONG.arrowSkin;
		if (skin == null)
			skin = '';

		var hudskin = PlayState.SONG.hudSkin;
		hudSkinInputText = new PsychUIInputText(player2DropDown.x, player2DropDown.y + 50, 150, hudskin, 8);
		blockPressWhileTypingOn.push(hudSkinInputText);

		var reloadNotesButton:PsychUIButton = new PsychUIButton(hudSkinInputText.x + 5, hudSkinInputText.y + 20, 'Change Notes', function()
		{
			_song.hudSkin = hudSkinInputText.text;
			updateGrid();
		}, 100, 20);

		tab_group_song = new FlxSpriteGroup();
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(clear_events);
		tab_group_song.add(clear_notes);
		tab_group_song.add(altcamspeed);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(reloadNotesButton);
		tab_group_song.add(hudSkinInputText);
		tab_group_song.add(new FlxText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
		tab_group_song.add(new FlxText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));
		tab_group_song.add(new FlxText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
		tab_group_song.add(new FlxText(gfVersionDropDown.x, gfVersionDropDown.y - 15, 0, 'Girlfriend:'));
		tab_group_song.add(new FlxText(player1DropDown.x, player1DropDown.y - 15, 0, 'Boyfriend:'));
		tab_group_song.add(new FlxText(stageDropDown.x, stageDropDown.y - 15, 0, 'Stage:'));

		tab_group_song.add(new FlxText(hudSkinInputText.x, hudSkinInputText.y - 15, 0, 'Hud Texture:'));

		tab_group_song.add(player2DropDown);
		tab_group_song.add(gfVersionDropDown);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(stageDropDown);

		assignTabGroup('Song', tab_group_song);

		FlxG.camera.follow(camPos);
	}

	var stepperBeats:PsychUINumericStepper;
	var check_mustHitSection:PsychUICheckBox;
	var check_gfSection:PsychUICheckBox;
	var check_changeBPM:PsychUICheckBox;
	var stepperSectionBPM:PsychUINumericStepper;
	var check_altAnim:PsychUICheckBox;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;

	function addSectionUI():Void
	{
		tab_group_section = new FlxSpriteGroup();

		check_mustHitSection = new PsychUICheckBox(10, 15, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSec].mustHitSection;

		check_gfSection = new PsychUICheckBox(10, check_mustHitSection.y + 22, "GF section", 100);
		check_gfSection.name = 'check_gf';
		check_gfSection.checked = _song.notes[curSec].gfSection;

		check_altAnim = new PsychUICheckBox(check_gfSection.x + 120, check_gfSection.y, "Alt Animation", 100);
		check_altAnim.checked = _song.notes[curSec].altAnim;

		stepperBeats = new PsychUINumericStepper(10, 100, 1, 4, 1, 80, 2);
		stepperBeats.value = getSectionBeats();
		stepperBeats.name = 'section_beats';
		blockPressWhileTypingOnStepper.push(stepperBeats);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new PsychUICheckBox(10, stepperBeats.y + 30, 'Change BPM', 100);
		check_changeBPM.checked = _song.notes[curSec].changeBPM;
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new PsychUINumericStepper(10, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999, 1);
		if (check_changeBPM.checked)
		{
			stepperSectionBPM.value = _song.notes[curSec].bpm;
		}
		else
		{
			stepperSectionBPM.value = Conductor.bpm;
		}
		stepperSectionBPM.name = 'section_bpm';
		blockPressWhileTypingOnStepper.push(stepperSectionBPM);

		var check_eventsSec:PsychUICheckBox = null;
		var check_notesSec:PsychUICheckBox = null;
		var copyButton:PsychUIButton = new PsychUIButton(10, 190, "Copy Section", function()
		{
			notesCopied = [];
			sectionToCopy = curSec;
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				notesCopied.push(note);
			}

			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			for (event in _song.events)
			{
				var strumTime:Float = getEventTime(event);
				if (endThing > strumTime && strumTime >= startThing)
				{
					var copiedEventArray:Array<Array<Dynamic>> = cloneEventEntries(getSingleEventEntries(event));
					notesCopied.push([strumTime, -1, copiedEventArray]);
				}
			}
			for (event in _song.cameraevents)
			{
				var strumTime:Float = getEventTime(event);
				if (endThing > strumTime && strumTime >= startThing)
				{
					var copiedEventArray:Array<Array<Dynamic>> = cloneEventEntries(getSingleEventEntries(event));
					notesCopied.push([strumTime, -2, copiedEventArray]);
				}
			}
		}, 90, 20);

		var pasteButton:PsychUIButton = new PsychUIButton(copyButton.x + 100, copyButton.y, "Paste Section", function()
		{
			if (notesCopied == null || notesCopied.length < 1)
			{
				return;
			}

			var addToTime:Float = Conductor.stepCrochet * (getSectionBeats() * 4 * (curSec - sectionToCopy));
			// trace('Time to add: ' + addToTime);

			for (note in notesCopied)
			{
				var copiedNote:Array<Dynamic> = [];
				var newStrumTime:Float = note[0] + addToTime;
				if (note[1] < 0)
				{
					if (check_eventsSec.checked)
					{
						var copiedEventArray:Array<Array<Dynamic>> = cloneEventEntries(note[2]);
						if (note[1] == -2)
						{
							if (copiedEventArray.length < 1)
							{
								var defaultValues:Array<Dynamic> = ['', ''];
								_song.cameraevents.push(makeSongEvent(newStrumTime, '', defaultValues));
							}
							else
							{
								for (eventEntry in copiedEventArray)
								{
									var eventName:String = '';
									var eventValues:Array<Dynamic> = [];
									if (eventEntry != null && eventEntry.length > 0)
									{
										eventName = Std.string(eventEntry[0]);
										for (valueIndex in 1...eventEntry.length)
											eventValues.push(eventEntry[valueIndex]);
									}
									_song.cameraevents.push(makeSongEvent(newStrumTime, eventName, eventValues));
								}
							}
						}
						else
						{
							if (copiedEventArray.length < 1)
							{
								var defaultValues:Array<Dynamic> = ['', ''];
								_song.events.push(makeSongEvent(newStrumTime, '', defaultValues));
							}
							else
							{
								for (eventEntry in copiedEventArray)
								{
									var eventName:String = '';
									var eventValues:Array<Dynamic> = [];
									if (eventEntry != null && eventEntry.length > 0)
									{
										eventName = Std.string(eventEntry[0]);
										for (valueIndex in 1...eventEntry.length)
											eventValues.push(eventEntry[valueIndex]);
									}
									_song.events.push(makeSongEvent(newStrumTime, eventName, eventValues));
								}
							}
						}
					}
				}
				else
				{
					if (check_notesSec.checked)
					{
						if (note[4] != null)
						{
							copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
						}
						else
						{
							copiedNote = [newStrumTime, note[1], note[2], note[3]];
						}
						_song.notes[curSec].sectionNotes.push(copiedNote);
					}
				}
			}
			updateGrid();
		}, 90, 20);

		var clearSectionButton:PsychUIButton = new PsychUIButton(pasteButton.x + 100, pasteButton.y, "Clear", function()
		{
			if (check_notesSec.checked)
			{
				_song.notes[curSec].sectionNotes = [];
			}

			if (check_eventsSec.checked)
			{
				var i:Int = _song.events.length - 1;
				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);
				while (i > -1)
				{
					var event = _song.events[i];
					var eventTime:Float = getEventTime(event);
					if (event != null && endThing > eventTime && eventTime >= startThing)
					{
						_song.events.remove(event);
					}
					--i;
				}

				i = _song.cameraevents.length - 1;
				while (i > -1)
				{
					var cameraEvent = _song.cameraevents[i];
					var cameraEventTime:Float = getEventTime(cameraEvent);
					if (cameraEvent != null && endThing > cameraEventTime && cameraEventTime >= startThing)
					{
						_song.cameraevents.remove(cameraEvent);
					}
					--i;
				}
			}
			updateGrid();
			updateNoteUI();
		}, 90, 20);

		check_notesSec = new PsychUICheckBox(10, clearSectionButton.y + 25, "Notes", 100);
		check_notesSec.checked = true;
		check_eventsSec = new PsychUICheckBox(check_notesSec.x + 100, check_notesSec.y, "Events", 100);
		check_eventsSec.checked = true;

		var swapSection:PsychUIButton = new PsychUIButton(10, check_notesSec.y + 40, "Swap section", function()
		{
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSec].sectionNotes[i] = note;
			}
			updateGrid();
		}, 90, 20);

		var stepperCopy:PsychUINumericStepper = null;
		var copyLastButton:PsychUIButton = new PsychUIButton(10, swapSection.y + 30, "Copy last section", function()
		{
			var value:Int = Std.int(stepperCopy.value);
			if (value == 0)
				return;

			var daSec = FlxMath.maxInt(curSec, value);

			for (note in _song.notes[daSec - value].sectionNotes)
			{
				var strum = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);

				var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
				_song.notes[daSec].sectionNotes.push(copiedNote);
			}

			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);
			for (event in _song.events)
			{
				var strumTime:Float = getEventTime(event);
				if (endThing > strumTime && strumTime >= startThing)
				{
					strumTime += Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
					for (eventEntry in getSingleEventEntries(event))
					{
						if (eventEntry == null || eventEntry.length < 1)
							continue;
						var eventName:String = Std.string(eventEntry[0]);
						var eventValues:Array<Dynamic> = [];
						for (valueIndex in 1...eventEntry.length)
							eventValues.push(eventEntry[valueIndex]);
						_song.events.push(makeSongEvent(strumTime, eventName, eventValues));
					}
				}
			}
			updateGrid();
		}, 90, 30);

		stepperCopy = new PsychUINumericStepper(copyLastButton.x + 100, copyLastButton.y, 1, 1, -999, 999, 0);
		blockPressWhileTypingOnStepper.push(stepperCopy);

		var duetButton:PsychUIButton = new PsychUIButton(10, copyLastButton.y + 45, "Duet Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1];
				if (boob > 3)
				{
					boob -= 4;
				}
				else
				{
					boob += 4;
				}

				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				duetNotes.push(copiedNote);
			}

			for (i in duetNotes)
			{
				_song.notes[curSec].sectionNotes.push(i);
			}

			updateGrid();
		}, 90, 20);
		var mirrorButton:PsychUIButton = new PsychUIButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1] % 4;
				boob = 3 - boob;
				if (note[1] > 3)
					boob += 4;

				note[1] = boob;
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				// duetNotes.push(copiedNote);
			}

			for (i in duetNotes)
			{
				// _song.notes[curSec].sectionNotes.push(i);
			}

			updateGrid();
		}, 90, 20);

		tab_group_section.add(new FlxText(stepperBeats.x, stepperBeats.y - 15, 0, 'Beats per Section:'));
		tab_group_section.add(stepperBeats);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_gfSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(check_notesSec);
		tab_group_section.add(check_eventsSec);
		tab_group_section.add(swapSection);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(copyLastButton);
		tab_group_section.add(duetButton);
		tab_group_section.add(mirrorButton);

		assignTabGroup('Section', tab_group_section);
	}

	var strumTimeInputText:PsychUIInputText; // I wanted to use a stepper but we can't scale these as far as i know :(
	var noteTypeDropDown:PsychUIDropDownMenu;
	var currentType:Int = 0;

	function addNoteUI():Void
	{
		tab_group_note = new FlxSpriteGroup();

		strumTimeInputText = new PsychUIInputText(10, 65, 180, "0");
		tab_group_note.add(strumTimeInputText);
		blockPressWhileTypingOn.push(strumTimeInputText);

		var key:Int = 0;
		var displayNameList:Array<String> = [];
		while (key < noteTypeList.length)
		{
			displayNameList.push(noteTypeList[key]);
			noteTypeMap.set(noteTypeList[key], key);
			noteTypeIntMap.set(key, noteTypeList[key]);
			key++;
		}

		var directories:Array<String> = [];

		directories.push(Paths.mods('custom_notetypes/'));
		directories.push(Paths.getPreloadPath('custom_notetypes/'));
		directories.push(Paths.mods(Paths.currentModDirectory + '/custom_notetypes/'));
		for (mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/custom_notetypes/'));

		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.lua') || !FileSystem.isDirectory(path) && file.endsWith('.hx'))
					{
						if (file.endsWith('.hx'))
						{
							exstentionnum = 3;
						}
						else
						{
							exstentionnum = 4;
						}
						var fileToCheck:String = file.substr(0, file.length - exstentionnum);
						if (!noteTypeMap.exists(fileToCheck))
						{
							displayNameList.push(fileToCheck);
							noteTypeMap.set(fileToCheck, key);
							noteTypeIntMap.set(key, fileToCheck);
							key++;
						}
					}
				}
			}
		}

		for (i in 1...displayNameList.length)
		{
			displayNameList[i] = i + '. ' + displayNameList[i];
		}

		noteTypeDropDown = new PsychUIDropDownMenu(10, 105, displayNameList, function(id:Int, character:String)
		{
			currentType = id;
			if (curSelectedNote != null && curSelectedNote[1] > -1)
			{
				curSelectedNote[3] = noteTypeIntMap.get(currentType);
				updateGrid();
			}
		}, 180);
		blockPressWhileScrolling.push(noteTypeDropDown);

		tab_group_note.add(new FlxText(10, 50, 0, 'Strum time (in miliseconds):'));
		tab_group_note.add(new FlxText(10, 90, 0, 'Note type:'));

		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);

		assignTabGroup('Note', tab_group_note);
	}

	var eventDropDown:PsychUIDropDownMenu;
	var descText:FlxText;
	var selectedEventText:FlxText;

	function addEventsUI():Void
	{
		tab_group_event = new FlxSpriteGroup();
		utility.EventHandler.setupAllEventData();

		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [];

		eventPushedMap.clear();
		eventPushedMap = null;

		descText = new FlxText(20, 200, 0, eventStuff[0][0]);

		var leEvents:Array<String> = utility.EventHandler.eventList;

		var text:FlxText = new FlxText(20, 30, 0, "Event:");
		tab_group_event.add(text);

		eventDropDown = new PsychUIDropDownMenu(20, 50, leEvents, function(selectedEvent:Int, pressed:String)
		{
			if (selectedEvent >= 0 && selectedEvent < eventStuff.length)
				descText.text = eventStuff[selectedEvent][1];
			else
				descText.text = eventDropDown.selectedLabel;

			if (curSelectedNote != null && eventStuff != null)
			{
				if (isSelectableEvent(curSelectedNote))
				{
					var selectedName:String = eventDropDown.selectedLabel;
					setCurrentEventName(selectedName);
					trace('Event changed to: ' + selectedName);
					updateGrid();
				}
			}
			recycleeventvars(eventDropDown.selectedLabel);
		}, 160);
		blockPressWhileScrolling.push(eventDropDown);

		// Inputs

		// Helper to know if it's camera or normal event
		inline function isCameraEvent():Bool
		{
			return curSelectedNote != null && _song.cameraevents.contains(curSelectedNote);
		}

		// REMOVE BUTTON
		var removeButton:PsychUIButton = new PsychUIButton(eventDropDown.x + eventDropDown.width + 5, eventDropDown.y, '-', function()
		{
			if (curSelectedNote != null && isSelectableEvent(curSelectedNote))
			{
				var selectedEvent:Song.EventData = getSelectedEventData();
				if (selectedEvent != null)
				{
					var eventArray = isCameraEvent() ? _song.cameraevents : _song.events;
					var selectedTime:Float = selectedEvent.strumTime;
					eventArray.remove(selectedEvent);

					var remaining:Array<Song.EventData> = [];
					for (eventData in eventArray)
					{
						if (eventData != null && Math.abs(eventData.strumTime - selectedTime) < 0.0001)
							remaining.push(eventData);
					}

					if (remaining.length > 0)
					{
						curSelectedNote = remaining[0];
						if (curEventSelected >= remaining.length)
							curEventSelected = remaining.length - 1;
					}
					else
					{
						curSelectedNote = null;
						curEventSelected = 0;
					}
				}

				changeEventSelected();
				updateGrid();
			}
		}, 30, 30);

		tab_group_event.add(removeButton);

		// ADD BUTTON
		var addButton:PsychUIButton = new PsychUIButton(removeButton.x + 40, removeButton.y, '+', function()
		{
			if (curSelectedNote != null && isSelectableEvent(curSelectedNote))
			{
				var eventArray = isCameraEvent() ? _song.cameraevents : _song.events;
				var typed:Song.EventData = curSelectedNote;
				var defaultValues:Array<Dynamic> = ['', ''];
				var newEvent:Song.EventData = makeSongEvent(typed.strumTime, '', defaultValues);
				eventArray.push(newEvent);
				curSelectedNote = typed;
				curEventSelected = Std.int(getCurrentEventLength()) - 1;
				changeEventSelected();
				updateGrid();
			}
		}, 30, 30);

		var testbutton:PsychUIButton = new PsychUIButton(removeButton.x + 40, removeButton.y + 80, 'Test', function()
		{
		}, 30, 30);
		removeButton.normalStyle.bgColor = FlxColor.RED;
		removeButton.normalStyle.textColor = FlxColor.WHITE;
		addButton.normalStyle.bgColor = FlxColor.GREEN;
		addButton.normalStyle.textColor = FlxColor.WHITE;
		tab_group_event.add(addButton);
		tab_group_event.add(testbutton);

		// LEFT/RIGHT SELECT BUTTONS
		var moveLeftButton:PsychUIButton = new PsychUIButton(addButton.x + 60, addButton.y, '<', function()
		{
			changeEventSelected(-1);
		}, 20, 20);
		tab_group_event.add(moveLeftButton);

		var moveRightButton:PsychUIButton = new PsychUIButton(moveLeftButton.x + 30, moveLeftButton.y, '>', function()
		{
			changeEventSelected(1);
		}, 20, 20);
		tab_group_event.add(moveRightButton);

		selectedEventText = new FlxText(addButton.x - 100, addButton.y + 26, 186, 'Selected Event: None');
		selectedEventText.alignment = CENTER;
		tab_group_event.add(selectedEventText);

		tab_group_event.add(descText);
		tab_group_event.add(eventDropDown);

		if (value1InputText != null)
			registerEventValueInput(value1InputText, 1);
		if (value2InputText != null)
			registerEventValueInput(value2InputText, 2);

		assignTabGroup('Events', tab_group_event);
	}

	function recycleeventvars(eventname:String)
	{
		mainBox.disableupdate = true;

		// CLEAR OLD UI
		for (object in eventsobjects)
		{
			if (object == null)
				continue;

			var inputObject = Std.downcast(object, PsychUIInputText);
			if (inputObject != null)
				blockPressWhileTypingOn.remove(inputObject);

			var dropdownObject = Std.downcast(object, PsychUIDropDownMenu);
			if (dropdownObject != null)
				blockPressWhileScrolling.remove(dropdownObject);

			tab_group_event.remove(object, true);
			object.kill();
		}
		eventsobjects = [];
		eventBindings = [];

		// BUILD UI FROM SCHEMA ONLY
		var baseX:Float = 20;
		var baseY:Float = 110;
		var eventschema = utility.EventHandler.eventmapping.get(eventname);
		if (eventschema == null || eventschema.eventLogic == null)
		{
			mainBox.disableupdate = false;
			return;
		}

		var rowMappedEvents:Array<Dynamic> = [];
		for (i in 0...eventschema.eventLogic.length)
		{
			var mappedEvent:EventData = eventschema.eventLogic[i];
			var rowNumber:Int = mappedEvent.rownum;
			if (rowNumber < 1)
				rowNumber = i + 1;
			rowMappedEvents.push({event: mappedEvent, row: rowNumber, valueIndex: i + 1});
		}

		rowMappedEvents.sort(function(a:Dynamic, b:Dynamic)
		{
			return FlxSort.byValues(FlxSort.ASCENDING, a.row, b.row);
		});

		var rowColumnMap:Map<Int, Int> = new Map<Int, Int>();
		var rowXSpacing:Float = 130;
		var rowYSpacing:Float = 40;
		for (mapped in rowMappedEvents)
		{
			var currentRow:Int = mapped.row;
			var currentColumn:Int = 0;
			if (rowColumnMap.exists(currentRow))
				currentColumn = rowColumnMap.get(currentRow);

			mapped.x = baseX + (currentColumn * rowXSpacing);
			mapped.y = baseY + ((currentRow - 1) * rowYSpacing);

			rowColumnMap.set(currentRow, currentColumn + 1);
		}

		for (mapped in rowMappedEvents)
		{
			var event:EventData = mapped.event;
			var valueIndex:Int = mapped.valueIndex;

			inline function setSelectedEventValue(v:Dynamic):Void
			{
				if (curSelectedNote == null)
					return;
				if (curEventSelected < 0 || curEventSelected >= getCurrentEventLength())
					return;
				setCurrentEventValue(valueIndex, v);
				updateGrid();
			}

			inline function getSelectedEventValue():String
			{
				if (curSelectedNote == null)
					return '';
				if (curEventSelected < 0 || curEventSelected >= getCurrentEventLength())
					return '';

				var selectedValue:Dynamic = getCurrentEventValue(valueIndex);
				if (selectedValue == null)
					return '';
				return Std.string(selectedValue);
			}
			var posX:Float = mapped.x;
			var posY:Float = mapped.y;
			var ui:Dynamic = null;

			switch (event.type)
			{
				case STRING:
					var input = new PsychUIInputText(posX, posY, 150, getSelectedEventValue());
					input.onChange = function(_, text:String)
					{
						setSelectedEventValue(text);
					};
					ui = input;
					blockPressWhileTypingOn.push(input);
				case FLOAT:
					var parsed = Std.parseFloat(getSelectedEventValue());
					if (Math.isNaN(parsed))
						parsed = 1;
					var stepper = new PsychUINumericStepper(posX, posY, 1, parsed, -9999, 9999, 1);
					stepper.onValueChange = function()
					{
						setSelectedEventValue(Std.string(stepper.value));
					};
					ui = stepper;
					blockPressWhileTypingOnStepper.push(stepper);

				case BOOL:
					var boolValue = getSelectedEventValue().toLowerCase();
					var check = new PsychUICheckBox(posX, posY, event.title, 150);
					check.checked = (boolValue == 'true' || boolValue == '1' || boolValue == 'yes');
					check.onClick = function()
					{
						setSelectedEventValue(check.checked ? 'true' : 'false');
					};
					ui = check;

				case DROPDOWN:
					var items = event.list != null ? event.list : [];
					var dropDown = new PsychUIDropDownMenu(posX, posY, items, function(index:Int, label:String)
					{
						setSelectedEventValue(label);
					});
					dropDown.selectedLabel = getSelectedEventValue();
					ui = dropDown;
					blockPressWhileScrolling.push(dropDown);
			}

			if (ui != null)
			{
				ui.revive();
				var tittleText:FlxText = new FlxText(posX, posY - 10, 0, event.title);
				var dropDownIndex:Int = tab_group_event.members.indexOf(eventDropDown);
				tab_group_event.insert(dropDownIndex, tittleText);
				tab_group_event.insert(dropDownIndex, ui);

				eventsobjects.push(tittleText);
				eventsobjects.push(ui);
				eventBindings.push({ui: ui, valueIndex: valueIndex, type: event.type});
			}
		}

		mainBox.disableupdate = false;
	}

	function registerEventValueInput(input:PsychUIInputText, valueIndex:Int):Void
	{
		if (input == null)
			return;
		eventValueInputBindings.push({input: input, valueIndex: valueIndex});
	}

	function cloneEventEntry(entry:Array<Dynamic>):Array<Dynamic>
	{
		var copied:Array<Dynamic> = [];
		if (entry != null)
		{
			for (value in entry)
			{
				copied.push(value);
			}
		}
		return copied;
	}

	function isTypedSongEvent(event:Dynamic):Bool
	{
		if (event == null)
			return false;
		if (_song.events != null)
		{
			for (songEvent in _song.events)
				if (songEvent == event)
					return true;
		}
		if (_song.cameraevents != null)
		{
			for (songEvent in _song.cameraevents)
				if (songEvent == event)
					return true;
		}
		return false;
	}

	inline function isCameraSongEvent(event:Dynamic):Bool
	{
		return event != null && _song.cameraevents != null && _song.cameraevents.contains(event);
	}

	inline function isSelectableEvent(event:Dynamic):Bool
	{
		return isTypedSongEvent(event);
	}

	function cloneEventEntries(entries:Array<Array<Dynamic>>):Array<Array<Dynamic>>
	{
		var copied:Array<Array<Dynamic>> = [];
		if (entries != null)
		{
			for (entry in entries)
			{
				copied.push(cloneEventEntry(entry));
			}
		}
		return copied;
	}

	function getEventTime(event:Dynamic):Float
	{
		if (!isTypedSongEvent(event))
			return 0;
		var typed:Song.EventData = event;
		return typed.strumTime;
	}

	function getEventArrayForReference(event:Dynamic):Array<Song.EventData>
	{
		return isCameraSongEvent(event) ? _song.cameraevents : _song.events;
	}

	function getEventsAtTime(eventArray:Array<Song.EventData>, strumTime:Float):Array<Song.EventData>
	{
		var grouped:Array<Song.EventData> = [];
		if (eventArray == null)
			return grouped;

		for (eventData in eventArray)
		{
			if (eventData != null && Math.abs(eventData.strumTime - strumTime) < 0.0001)
				grouped.push(eventData);
		}

		return grouped;
	}

	function getEventEntryFromTyped(eventData:Song.EventData):Array<Dynamic>
	{
		var entry:Array<Dynamic> = [eventData.name];
		if (eventData.values == null)
			eventData.values = [];
		if (eventData.values != null)
		{
			for (value in eventData.values)
			{
				if (value == null)
				{
					entry.push('');
					continue;
				}

				if (Std.isOfType(value, String) || Std.isOfType(value, Int) || Std.isOfType(value, Float) || Std.isOfType(value, Bool))
					entry.push(value);
				else if (Reflect.hasField(value, 'value'))
					entry.push(Reflect.field(value, 'value'));
				else
					entry.push(Std.string(value));
			}
		}
		return entry;
	}

	function getSingleEventEntries(event:Dynamic):Array<Array<Dynamic>>
	{
		if (!isTypedSongEvent(event))
			return [];
		var typed:Song.EventData = event;
		return [getEventEntryFromTyped(typed)];
	}

	function getEventEntries(event:Dynamic):Array<Array<Dynamic>>
	{
		if (!isTypedSongEvent(event))
			return [];

		var typed:Song.EventData = event;
		var grouped:Array<Song.EventData> = getEventsAtTime(getEventArrayForReference(event), typed.strumTime);
		var entries:Array<Array<Dynamic>> = [];
		for (eventData in grouped)
		{
			entries.push(getEventEntryFromTyped(eventData));
		}
		return entries;
	}

	function getSelectedEventData():Song.EventData
	{
		if (curSelectedNote == null)
			return null;
		if (!isTypedSongEvent(curSelectedNote))
			return null;

		var typed:Song.EventData = curSelectedNote;
		var grouped:Array<Song.EventData> = getEventsAtTime(getEventArrayForReference(curSelectedNote), typed.strumTime);
		if (grouped.length < 1)
			return null;

		if (curEventSelected < 0)
			curEventSelected = 0;
		if (curEventSelected >= grouped.length)
			curEventSelected = grouped.length - 1;

		return grouped[curEventSelected];
	}

	function getCurrentEventEntries():Array<Array<Dynamic>>
	{
		if (curSelectedNote == null)
			return [];
		return getEventEntries(curSelectedNote);
	}

	function getCurrentEventName():String
	{
		var entries = getCurrentEventEntries();
		if (entries.length < 1 || entries[curEventSelected] == null || entries[curEventSelected].length < 1)
			return '';
		return Std.string(entries[curEventSelected][0]);
	}

	function setCurrentEventName(name:String):Void
	{
		var selectedEvent:Song.EventData = getSelectedEventData();
		if (selectedEvent == null)
			return;
		selectedEvent.name = name;

		if (selectedEvent.values == null)
			selectedEvent.values = [];
		for (i in 0...selectedEvent.values.length)
		{
			var schemaName:String = 'Value ' + (i + 1);
			var eventSchema = utility.EventHandler.eventmapping.get(selectedEvent.name);
			if (eventSchema != null && eventSchema.eventLogic != null && i < eventSchema.eventLogic.length && eventSchema.eventLogic[i] != null)
			{
				if (eventSchema.eventLogic[i].name != null && eventSchema.eventLogic[i].name.length > 0)
					schemaName = eventSchema.eventLogic[i].name;
				else if (eventSchema.eventLogic[i].title != null && eventSchema.eventLogic[i].title.length > 0)
					schemaName = eventSchema.eventLogic[i].title;
			}

			var currentValue:Dynamic = selectedEvent.values[i];
			if (currentValue == null)
			{
				selectedEvent.values[i] = {name: schemaName, value: ''};
			}
			else if (Std.isOfType(currentValue, String) || Std.isOfType(currentValue, Int) || Std.isOfType(currentValue, Float)
				|| Std.isOfType(currentValue, Bool))
			{
				selectedEvent.values[i] = {name: schemaName, value: cast currentValue};
			}
			else
			{
				var extractedValue:Dynamic = currentValue;
				if (Reflect.hasField(currentValue, 'value'))
					extractedValue = Reflect.field(currentValue, 'value');
				if (extractedValue == null)
					extractedValue = '';
				if (!(Std.isOfType(extractedValue, String)
					|| Std.isOfType(extractedValue, Int)
					|| Std.isOfType(extractedValue, Float)
					|| Std.isOfType(extractedValue, Bool)))
					extractedValue = Std.string(extractedValue);
				selectedEvent.values[i] = {name: schemaName, value: cast extractedValue};
			}
		}
	}

	function getCurrentEventValue(valueIndex:Int):Dynamic
	{
		if (valueIndex < 1)
			return '';
		var selectedEvent:Song.EventData = getSelectedEventData();
		if (selectedEvent == null)
			return '';
		if (selectedEvent.values == null || selectedEvent.values.length < valueIndex)
			return '';

		var selectedValue:Dynamic = selectedEvent.values[valueIndex - 1];
		if (selectedValue == null)
			return '';
		if (Std.isOfType(selectedValue, String) || Std.isOfType(selectedValue, Int) || Std.isOfType(selectedValue, Float) || Std.isOfType(selectedValue, Bool))
			return selectedValue;
		if (Reflect.hasField(selectedValue, 'value') && Reflect.field(selectedValue, 'value') != null)
			return Reflect.field(selectedValue, 'value');
		return '';
	}

	function setCurrentEventValue(valueIndex:Int, value:Dynamic):Void
	{
		var selectedEvent:Song.EventData = getSelectedEventData();
		if (selectedEvent == null)
			return;

		if (selectedEvent.values == null)
			selectedEvent.values = [];

		while (selectedEvent.values.length < valueIndex)
		{
			var fillIndex:Int = selectedEvent.values.length + 1;
			var fillName:String = 'Value ' + fillIndex;
			var fillSchema = utility.EventHandler.eventmapping.get(selectedEvent.name);
			if (fillSchema != null && fillSchema.eventLogic != null)
			{
				var fillMappedIndex:Int = fillIndex - 1;
				if (fillMappedIndex >= 0
					&& fillMappedIndex < fillSchema.eventLogic.length
					&& fillSchema.eventLogic[fillMappedIndex] != null)
				{
					if (fillSchema.eventLogic[fillMappedIndex].name != null && fillSchema.eventLogic[fillMappedIndex].name.length > 0)
						fillName = fillSchema.eventLogic[fillMappedIndex].name;
					else if (fillSchema.eventLogic[fillMappedIndex].title != null
						&& fillSchema.eventLogic[fillMappedIndex].title.length > 0)
						fillName = fillSchema.eventLogic[fillMappedIndex].title;
				}
			}
			selectedEvent.values.push({name: fillName, value: ''});
		}

		var parsedValue:Dynamic = parseEventValue(value);
		if (parsedValue == null)
			parsedValue = '';
		if (!(Std.isOfType(parsedValue, String) || Std.isOfType(parsedValue, Int) || Std.isOfType(parsedValue, Float) || Std.isOfType(parsedValue, Bool)))
			parsedValue = Std.string(parsedValue);

		var schemaName:String = 'Value ' + valueIndex;
		var eventSchema = utility.EventHandler.eventmapping.get(selectedEvent.name);
		if (eventSchema != null && eventSchema.eventLogic != null)
		{
			var mappedIndex:Int = valueIndex - 1;
			if (mappedIndex >= 0 && mappedIndex < eventSchema.eventLogic.length && eventSchema.eventLogic[mappedIndex] != null)
			{
				if (eventSchema.eventLogic[mappedIndex].name != null && eventSchema.eventLogic[mappedIndex].name.length > 0)
					schemaName = eventSchema.eventLogic[mappedIndex].name;
				else if (eventSchema.eventLogic[mappedIndex].title != null && eventSchema.eventLogic[mappedIndex].title.length > 0)
					schemaName = eventSchema.eventLogic[mappedIndex].title;
			}
		}

		selectedEvent.values[valueIndex - 1] = {
			name: schemaName,
			value: cast parsedValue
		};
	}

	function getCurrentEventLength():Int
	{
		if (curSelectedNote == null)
			return 0;
		if (isTypedSongEvent(curSelectedNote))
			return getCurrentEventEntries().length;
		return 0;
	}

	function makeSongEvent(strumTime:Float, name:String, values:Array<Dynamic>):Song.EventData
	{
		var copiedValues:Array<Song.EventValue> = [];
		if (values != null)
		{
			for (i in 0...values.length)
			{
				var schemaName:String = 'Value ' + (i + 1);
				var eventSchema = utility.EventHandler.eventmapping.get(name);
				if (eventSchema != null && eventSchema.eventLogic != null && i < eventSchema.eventLogic.length && eventSchema.eventLogic[i] != null)
				{
					if (eventSchema.eventLogic[i].name != null && eventSchema.eventLogic[i].name.length > 0)
						schemaName = eventSchema.eventLogic[i].name;
					else if (eventSchema.eventLogic[i].title != null && eventSchema.eventLogic[i].title.length > 0)
						schemaName = eventSchema.eventLogic[i].title;
				}

				var parsedValue:Dynamic = parseEventValue(values[i]);
				if (parsedValue == null)
					parsedValue = '';
				if (!(Std.isOfType(parsedValue, String) || Std.isOfType(parsedValue, Int) || Std.isOfType(parsedValue, Float)
					|| Std.isOfType(parsedValue, Bool)))
					parsedValue = Std.string(parsedValue);

				copiedValues.push({
					name: schemaName,
					value: cast parsedValue
				});
			}
		}

		return {
			strumTime: strumTime,
			name: name,
			values: copiedValues
		};
	}

	function getEventUiValues():Array<Dynamic>
	{
		var values:Array<Dynamic> = [];
		for (binding in eventBindings)
		{
			if (binding == null || binding.ui == null)
				continue;

			var value:Dynamic = '';
			switch (binding.type)
			{
				case STRING:
					value = binding.ui.text;
				case FLOAT:
					value = binding.ui.value;
				case BOOL:
					value = binding.ui.checked;
				case DROPDOWN:
					value = binding.ui.selectedLabel;
			}
			values.push({index: binding.valueIndex, value: value});
		}

		values.sort(function(a:Dynamic, b:Dynamic)
		{
			return FlxSort.byValues(FlxSort.ASCENDING, a.index, b.index);
		});

		var orderedValues:Array<Dynamic> = [];
		for (entry in values)
			orderedValues.push(entry.value);
		return orderedValues;
	}

	function changeEventSelected(change:Int = 0, ?noteData:Int)
	{
		if (curSelectedNote != null && (isSelectableEvent(curSelectedNote) || noteData == -1 || noteData == -2))
		{
			// Clamp and wrap current event index
			curEventSelected += change;

			if (getCurrentEventLength() <= 0)
			{
				curEventSelected = 0;
				selectedEventText.text = 'Selected Event: None';
				updateNoteUI();
				return;
			}

			if (curEventSelected < 0)
				curEventSelected = Std.int(getCurrentEventLength()) - 1;
			else if (curEventSelected >= getCurrentEventLength())
				curEventSelected = 0;

			// Label
			var label:String = (isCameraSongEvent(curSelectedNote) || noteData == -2) ? 'Selected Camera Event: ' : 'Selected Event: ';

			selectedEventText.text = label + (curEventSelected + 1) + ' / ' + getCurrentEventLength();
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}

		updateNoteUI();
	}

	var metronome:PsychUICheckBox;
	var mouseScrollingQuant:PsychUICheckBox;
	var metronomeStepper:PsychUINumericStepper;
	var metronomeOffsetStepper:PsychUINumericStepper;
	var disableAutoScrolling:PsychUICheckBox;
	#if desktop
	var waveformUseInstrumental:PsychUICheckBox;
	var waveformUseVoices:PsychUICheckBox;
	#end
	var instVolume:PsychUINumericStepper;
	var voicesVolume:PsychUINumericStepper;

	function addChartingUI()
	{
		tab_group_chart = new FlxSpriteGroup();

		#if desktop
		if (FlxG.save.data.chart_downscroll == null)
			FlxG.save.data.chart_downscroll == false;
		if (FlxG.save.data.chart_waveformInst == null)
			FlxG.save.data.chart_waveformInst = false;
		if (FlxG.save.data.chart_waveformVoices == null)
			FlxG.save.data.chart_waveformVoices = false;

		waveformUseInstrumental = new PsychUICheckBox(10, 90, "Waveform for Instrumental", 100);
		waveformUseInstrumental.checked = FlxG.save.data.chart_waveformInst;
		waveformUseInstrumental.onClick = function()
		{
			waveformUseVoices.checked = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformInst = waveformUseInstrumental.checked;
			updateWaveform();
		};

		waveformUseVoices = new PsychUICheckBox(waveformUseInstrumental.x + 120, waveformUseInstrumental.y, "Waveform for Voices", 100);
		waveformUseVoices.checked = FlxG.save.data.chart_waveformVoices;
		waveformUseVoices.onClick = function()
		{
			waveformUseInstrumental.checked = false;
			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformVoices = waveformUseVoices.checked;
			updateWaveform();
		};
		#end

		check_mute_inst = new PsychUICheckBox(10, 310, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.onClick = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};
		mouseScrollingQuant = new PsychUICheckBox(10, 200, "Mouse Scrolling Quantization", 100);
		if (FlxG.save.data.mouseScrollingQuant == null)
			FlxG.save.data.mouseScrollingQuant = false;
		mouseScrollingQuant.checked = FlxG.save.data.mouseScrollingQuant;

		mouseScrollingQuant.onClick = function()
		{
			FlxG.save.data.mouseScrollingQuant = mouseScrollingQuant.checked;
			mouseQuant = FlxG.save.data.mouseScrollingQuant;
		};

		check_vortex = new PsychUICheckBox(10, 160, "Vortex Editor (BETA)", 100);
		if (FlxG.save.data.chart_vortex == null)
			FlxG.save.data.chart_vortex = false;
		check_vortex.checked = FlxG.save.data.chart_vortex;

		check_vortex.onClick = function()
		{
			FlxG.save.data.chart_vortex = check_vortex.checked;
			vortex = FlxG.save.data.chart_vortex;
			reloadGridLayer();
		};

		check_warnings = new PsychUICheckBox(10, 120, "Ignore Progress Warnings", 100);
		if (FlxG.save.data.ignoreWarnings == null)
			FlxG.save.data.ignoreWarnings = false;
		check_warnings.checked = FlxG.save.data.ignoreWarnings;

		check_warnings.onClick = function()
		{
			FlxG.save.data.ignoreWarnings = check_warnings.checked;
			ignoreWarnings = FlxG.save.data.ignoreWarnings;
		};

		var check_mute_vocals = new PsychUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, "Mute Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.onClick = function()
		{
			if (vocals != null)
			{
				var vol:Float = 1;

				if (check_mute_vocals.checked)
					vol = 0;

				vocals.volume = vol;
			}
		};

		playSoundBf = new PsychUICheckBox(check_mute_inst.x, check_mute_vocals.y + 30, 'Play Sound (Boyfriend notes)', 100, function()
		{
			FlxG.save.data.chart_playSoundBf = playSoundBf.checked;
		});
		if (FlxG.save.data.chart_playSoundBf == null)
			FlxG.save.data.chart_playSoundBf = false;
		playSoundBf.checked = FlxG.save.data.chart_playSoundBf;

		playSoundDad = new PsychUICheckBox(check_mute_inst.x + 120, playSoundBf.y, 'Play Sound (Opponent notes)', 100, function()
		{
			FlxG.save.data.chart_playSoundDad = playSoundDad.checked;
		});

		var check_mute_bf = new PsychUICheckBox(playSoundBf.x, playSoundBf.y + 30, "Mute Boyfriend (in editor)", 100);
		check_mute_bf.checked = false;
		check_mute_bf.onClick = function()
		{
			var vol:Float = 1;

			if (check_mute_bf.checked)
				vol = 0;

			vocals.bfVolume = vol;
		};

		var check_mute_dad = new PsychUICheckBox(playSoundDad.x, check_mute_bf.y, "Mute Opponent (in editor)", 100);
		check_mute_dad.checked = false;
		check_mute_dad.onClick = function()
		{
			var vol:Float = 1;

			if (check_mute_dad.checked)
				vol = 0;

			vocals.dadVolume = vol;
		};

		if (FlxG.save.data.chart_playSoundDad == null)
			FlxG.save.data.chart_playSoundDad = false;
		playSoundDad.checked = FlxG.save.data.chart_playSoundDad;

		metronome = new PsychUICheckBox(10, 15, "Metronome Enabled", 100, function()
		{
			FlxG.save.data.chart_metronome = metronome.checked;
		});
		if (FlxG.save.data.chart_metronome == null)
			FlxG.save.data.chart_metronome = false;
		metronome.checked = FlxG.save.data.chart_metronome;

		metronomeStepper = new PsychUINumericStepper(15, 55, 5, _song.bpm, 1, 1500, 1);
		metronomeOffsetStepper = new PsychUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 1000, 1);
		blockPressWhileTypingOnStepper.push(metronomeStepper);
		blockPressWhileTypingOnStepper.push(metronomeOffsetStepper);

		disableAutoScrolling = new PsychUICheckBox(metronome.x + 120, metronome.y, "Disable Autoscroll (Not Recommended)", 120, function()
		{
			FlxG.save.data.chart_noAutoScroll = disableAutoScrolling.checked;
		});
		if (FlxG.save.data.chart_noAutoScroll == null)
			FlxG.save.data.chart_noAutoScroll = false;
		disableAutoScrolling.checked = FlxG.save.data.chart_noAutoScroll;

		instVolume = new PsychUINumericStepper(metronomeStepper.x, 270, 0.1, 1, 0, 1, 1);
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';
		blockPressWhileTypingOnStepper.push(instVolume);

		voicesVolume = new PsychUINumericStepper(instVolume.x + 100, instVolume.y, 0.1, 1, 0, 1, 1);
		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'voices_volume';
		blockPressWhileTypingOnStepper.push(voicesVolume);

		#if FLX_PITCH
		sliderRate = new PsychUISlider(120, 120, function(v:Float)
		{
			playbackSpeed = v;
		}, playbackSpeed, 0.5, 3, 150, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.label = 'Playback Rate';
		tab_group_chart.add(sliderRate);
		#end

		tab_group_chart.add(new FlxText(metronomeStepper.x, metronomeStepper.y - 15, 0, 'BPM:'));
		tab_group_chart.add(new FlxText(metronomeOffsetStepper.x, metronomeOffsetStepper.y - 15, 0, 'Offset (ms):'));
		tab_group_chart.add(new FlxText(instVolume.x, instVolume.y - 15, 0, 'Inst Volume'));
		tab_group_chart.add(new FlxText(voicesVolume.x, voicesVolume.y - 15, 0, 'Voices Volume'));
		tab_group_chart.add(metronome);
		tab_group_chart.add(disableAutoScrolling);
		tab_group_chart.add(metronomeStepper);
		tab_group_chart.add(metronomeOffsetStepper);
		#if desktop
		tab_group_chart.add(waveformUseInstrumental);
		tab_group_chart.add(waveformUseVoices);
		#end
		tab_group_chart.add(instVolume);
		tab_group_chart.add(voicesVolume);
		tab_group_chart.add(check_mute_inst);
		tab_group_chart.add(check_mute_vocals);
		tab_group_chart.add(check_vortex);
		tab_group_chart.add(mouseScrollingQuant);
		tab_group_chart.add(check_warnings);
		tab_group_chart.add(playSoundBf);
		tab_group_chart.add(playSoundDad);
		tab_group_chart.add(check_mute_bf);
		tab_group_chart.add(check_mute_dad);
		assignTabGroup('Charting', tab_group_chart);
	}

	function loadSong():Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		// If cursongfolder was never set by a PlayState load, auto-detect it from the song name
		if (!Constants.cursongfolder.contains('/'))
		{
			var lowerSong:String = currentSongName.toLowerCase();
			var type:String = "default";
			for (t in Constants.defaultsongtypes)
			{
				if (lowerSong.contains(t))
				{
					type = t;
					break;
				}
			}
			Constants.cursongfolder = 'songs/' + type;
			trace('ChartingState: auto-set cursongfolder to ' + Constants.cursongfolder);
		}

		vocals = new Vocals(currentSongName);
		generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;
	}

	function generateSong()
	{
		FlxG.sound.playMusic(Paths.inst(currentSongName), 0.6 /*, false*/);
		if (instVolume != null)
			FlxG.sound.music.volume = instVolume.value;
		if (check_mute_inst != null && check_mute_inst.checked)
			FlxG.sound.music.volume = 0;

		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			if (vocals != null)
			{
				vocals.pause();
				vocals.time = 0;
			}
			changeSection();
			curSec = 0;
			updateGrid();
			updateSectionUI();
			vocals.play();
		};
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(mainBox.x + 20, mainBox.y + 20, 0);
		bullshitUI.add(title);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == PsychUICheckBox.CLICK_EVENT)
		{
			var check:PsychUICheckBox = sender;
			var label = check.text.text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSec].mustHitSection = check.checked;

					updateGrid();
					updateHeads();

				case 'GF section':
					_song.notes[curSec].gfSection = check.checked;

					updateGrid();
					updateHeads();

				case 'Change BPM':
					_song.notes[curSec].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSec].altAnim = check.checked;
			}
		}
		else if (id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper))
		{
			var nums:PsychUINumericStepper = sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_beats')
			{
				_song.notes[curSec].sectionBeats = nums.value;
				reloadGridLayer();
			}
			else if (wname == 'song_speed')
			{
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = nums.value;
				Conductor.mapBPMChanges(_song);
				Conductor.bpm = nums.value;
			}
			else if (wname == 'note_susLength')
			{
				if (curSelectedNote != null && curSelectedNote[2] != null)
				{
					curSelectedNote[2] = nums.value;
					updateGrid();
				}
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[curSec].bpm = nums.value;
				updateGrid();
			}
			else if (wname == 'inst_volume')
			{
				FlxG.sound.music.volume = nums.value;
			}
			else if (wname == 'voices_volume')
			{
				vocals.volume = nums.value;
			}
		}
		else if (id == PsychUIInputText.CHANGE_EVENT && (sender is PsychUIInputText))
		{
			if (curSelectedNote != null)
			{
				if (sender == strumTimeInputText)
				{
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if (Math.isNaN(value))
						value = 0;
					if (isTypedSongEvent(curSelectedNote))
					{
						var typedEvent:Song.EventData = curSelectedNote;
						typedEvent.strumTime = value;
					}
					else
					{
						curSelectedNote[0] = value;
					}
					updateGrid();
				}
				else if (sender == value1InputText)
				{
					if (getCurrentEventLength() > 0)
					{
						setCurrentEventValue(1, value1InputText.text);
						updateGrid();
					}
				}
				else if (sender == value2InputText)
				{
					if (getCurrentEventLength() > 0)
					{
						setCurrentEventValue(2, value2InputText.text);
						updateGrid();
					}
				}
				else
				{
					for (binding in eventValueInputBindings)
					{
						if (binding != null && binding.input == sender)
						{
							if (getCurrentEventLength() > 0)
							{
								var valueIndex:Int = Std.int(binding.valueIndex);
								var inputSender:PsychUIInputText = sender;
								setCurrentEventValue(valueIndex, inputSender.text);
								updateGrid();
							}
							break;
						}
					}
				}
			}
		}
		else if (id == PsychUISlider.CHANGE_EVENT && (sender is PsychUISlider))
		{
			playbackSpeed = sliderRate.value;
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec + add)
		{
			if (_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM)
				{
					daBPM = _song.notes[i].bpm;
				}
				daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	var lastConductorPos:Float;
	var colorSine:Float = 0;

	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		if (FlxG.sound.music.time < 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = UI_songTitle.text;

		strumLineUpdateY();
		for (i in 0...8)
		{
			strumLineNotes.members[i].y = strumLine.y;
		}

		camPos.y = strumLine.y;
		if (!disableAutoScrolling.checked)
		{
			if (FlxG.save.data.chart_downscroll)
			{
				if (strumLine.y < -10)
				{
					if (_song.notes[curSec + 1] == null)
					{
						addSection();
					}

					changeSection(curSec + 1, false);
				}
				else if (Math.ceil(strumLine.y) >= gridBG.height)
				{
					changeSection(curSec - 1, false);
				}
			}
			else
			{
				if (Math.ceil(strumLine.y) >= gridBG.height)
				{
					if (_song.notes[curSec + 1] == null)
					{
						addSection();
					}

					changeSection(curSec + 1, false);
				}
				else if (strumLine.y < -10)
				{
					changeSection(curSec - 1, false);
				}
			}
		}

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
		{
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
			{
				var gridmult = GRID_SIZE / (quantization / 16);
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
			}
		}
		else
		{
			dummyArrow.visible = false;
		}
		if (FlxG.mouse.justPressedRight)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						deleteNote(note);
					}
				});
			}
		}

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.ALT)
						{
							selectNote(note);
							curSelectedNote[3] = noteTypeIntMap.get(currentType);
							updateGrid();
						}
						else
						{
							selectNote(note);
						}
					}
				});
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
				{
					FlxG.log.add('added note');
					if (FlxG.keys.pressed.CONTROL)
					{
						notetypeoveride = true;
					}
					else
					{
						notetypeoveride = false;
					}
					addNote();
				}
			}
		}
		// doCursorlogic();

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn)
		{
			if (PsychUIInputText.focusOn == inputText)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}

		if (!blockInput)
		{
			for (stepper in blockPressWhileTypingOnStepper)
			{
				if (PsychUIInputText.focusOn == stepper)
				{
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
			for (dropDownMenu in blockPressWhileScrolling)
			{
				if (PsychUIInputText.focusOn == dropDownMenu)
				{
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			if (FlxG.keys.justPressed.ESCAPE)
			{
				autosaveSong();
				MusicBeatState.switchState(new LoadingState(new editors.EditorPlayState(sectionStartTime())));
			}
			if (FlxG.keys.justPressed.ENTER)
			{
				autosaveSong();
				FlxG.mouse.visible = false;
				PlayState.SONG = _song;
				FlxG.sound.music.stop();
				if (vocals != null)
					vocals.stop();

				// if(_song.stage == null) _song.stage = stageDropDown.selectedLabel;
				data.StageData.loadDirectory(_song);
				MusicBeatState.switchState(new LoadingState(new PlayState()));
			}

			if (curSelectedNote != null && curSelectedNote[1] > -1)
			{
				if (FlxG.keys.justPressed.E)
				{
					changeNoteSustain(Conductor.stepCrochet);
				}
				if (FlxG.keys.justPressed.Q)
				{
					changeNoteSustain(-Conductor.stepCrochet);
				}
			}

			if (FlxG.keys.justPressed.BACKSPACE)
			{
				PlayState.chartingMode = false;
				MusicBeatState.switchState(new editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				FlxG.mouse.visible = false;
				return;
			}

			if (FlxG.keys.justPressed.Z && FlxG.keys.pressed.CONTROL)
			{
				undo();
			}

			if (FlxG.keys.justPressed.Z && curZoom > 0 && !FlxG.keys.pressed.CONTROL)
			{
				--curZoom;
				updateZoom();
			}
			if (FlxG.keys.justPressed.X && curZoom < zoomList.length - 1)
			{
				curZoom++;
				updateZoom();
			}

			if (FlxG.keys.justPressed.TAB)
			{
				var tabCount:Int = mainBox.tabs.length;
				if (tabCount <= 0)
					tabCount = 1;
				if (FlxG.keys.pressed.SHIFT)
				{
					mainBox.selectedIndex -= 1;
					if (mainBox.selectedIndex < 0)
						mainBox.selectedIndex = tabCount - 1;
				}
				else
				{
					mainBox.selectedIndex += 1;
					if (mainBox.selectedIndex >= tabCount)
						mainBox.selectedIndex = 0;
				}
			}

			if (FlxG.keys.justPressed.SPACE)
			{
				resetIdle();
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					if (vocals != null)
						vocals.pause();
				}
				else
				{
					if (vocals != null)
					{
						vocals.play();
						vocals.pause();
						vocals.time = FlxG.sound.music.time;
						vocals.play();
					}
					FlxG.sound.music.play();
				}
			}

			if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.music.pause();
				resetIdle();
				if (!mouseQuant)
				{
					var wheelDelta:Float = FlxG.mouse.wheel * Conductor.stepCrochet * 0.8;
					if (FlxG.save.data.chart_downscroll)
						FlxG.sound.music.time += wheelDelta;
					else
						FlxG.sound.music.time -= wheelDelta;
				}
				else
				{
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					var direction:Int = FlxG.mouse.wheel > 0 ? -1 : 1;
					if (FlxG.save.data.chart_downscroll)
						direction *= -1;
					var newBeat:Float = CoolUtil.quantize(beat, snap) + (increase * direction);
					FlxG.sound.music.time = Conductor.beatToSeconds(newBeat);
				}
				if (vocals != null)
				{
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
			}

			// ARROW VORTEX SHIT NO DEADASS

			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				FlxG.sound.music.pause();

				var holdingShift:Float = 1;
				if (FlxG.keys.pressed.CONTROL)
					holdingShift = 0.25;
				else if (FlxG.keys.pressed.SHIFT)
					holdingShift = 4;

				resetIdle();
				var daTime:Float = 700 * FlxG.elapsed * holdingShift;

				if (FlxG.keys.pressed.W)
				{
					FlxG.sound.music.time -= daTime;
				}
				else
					FlxG.sound.music.time += daTime;

				if (vocals != null)
				{
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
			}

			if (!vortex)
			{
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
				{
					FlxG.sound.music.pause();
					resetIdle();
					updateCurStep();
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase; // (Math.floor((beat+snap) / snap) * snap);
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
					else
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase; // (Math.floor((beat+snap) / snap) * snap);
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
			}

			var style = currentType;

			if (FlxG.keys.pressed.SHIFT)
			{
				style = 3;
			}

			var conductorTime = Conductor.songPosition; // + sectionStartTime();Conductor.songPosition / Conductor.stepCrochet;

			if (!blockInput)
			{
				if (FlxG.keys.justPressed.RIGHT)
				{
					curQuant++;
					if (curQuant > quantizations.length - 1)
						curQuant = 0;

					quantization = quantizations[curQuant];
				}

				if (FlxG.keys.justPressed.LEFT)
				{
					curQuant--;
					if (curQuant < 0)
						curQuant = quantizations.length - 1;

					quantization = quantizations[curQuant];
				}
				quant.animation.play('q', true, false, curQuant);
			}
			if (vortex && !blockInput)
			{
				var controlArray:Array<Bool> = [
					 FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR,
					FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT
				];

				if (controlArray.contains(true))
				{
					for (i in 0...controlArray.length)
					{
						if (controlArray[i])
							doANoteThing(conductorTime, i, style);
					}
				}

				var feces:Float;
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
				{
					FlxG.sound.music.pause();

					updateCurStep();
					// FlxG.sound.music.time = (Math.round(curStep/quants[curQuant])*quants[curQuant]) * Conductor.stepCrochet;

					// (Math.floor((curStep+quants[curQuant]*1.5/(quants[curQuant]/2))/quants[curQuant])*quants[curQuant]) * Conductor.stepCrochet;//snap into quantization
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
						feces = Conductor.beatToSeconds(fuck);
					}
					else
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase; // (Math.floor((beat+snap) / snap) * snap);
						feces = Conductor.beatToSeconds(fuck);
					}
					FlxTween.tween(FlxG.sound.music, {time: feces}, 0.1, {ease: FlxEase.circOut});
					if (vocals != null)
					{
						vocals.pause();
						vocals.time = FlxG.sound.music.time;
					}

					var dastrum = 0;

					if (curSelectedNote != null)
					{
						dastrum = curSelectedNote[0];
					}

					var secStart:Float = sectionStartTime();
					var datime = (feces - secStart) - (dastrum - secStart); // idk math find out why it doesn't work on any other section other than 0
					if (curSelectedNote != null)
					{
						var controlArray:Array<Bool> = [
							 FlxG.keys.pressed.ONE, FlxG.keys.pressed.TWO, FlxG.keys.pressed.THREE, FlxG.keys.pressed.FOUR,
							FlxG.keys.pressed.FIVE, FlxG.keys.pressed.SIX, FlxG.keys.pressed.SEVEN, FlxG.keys.pressed.EIGHT
						];

						if (controlArray.contains(true))
						{
							for (i in 0...controlArray.length)
							{
								if (controlArray[i])
									if (curSelectedNote[1] == i)
										curSelectedNote[2] += datime - curSelectedNote[2] - Conductor.stepCrochet;
							}
							updateGrid();
							updateNoteUI();
						}
					}
				}
			}
			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;

			if (FlxG.keys.justPressed.D)
				changeSection(curSec + shiftThing);
			if (FlxG.keys.justPressed.A)
			{
				if (curSec <= 0)
				{
					changeSection(_song.notes.length - 1);
				}
				else
				{
					changeSection(curSec - shiftThing);
				}
			}
		}
		else if (FlxG.keys.justPressed.ENTER)
		{
			for (i in 0...blockPressWhileTypingOn.length)
			{
				if (PsychUIInputText.focusOn == blockPressWhileTypingOn[i])
				{
					PsychUIInputText.focusOn = null;
				}
			}
		}

		_song.bpm = tempBpm;

		if (!justChanged)
		{
			curRenderedNotes.forEach(function(note:Note)
			{
				if (note.strumTime <= Conductor.songPosition)
				{
					var data:Int = note.noteData;
					if (note.strumTime >= lastConductorPos - 100 && FlxG.sound.music.playing && note.noteData > -1)
					{
						if (note.mustPress)
						{
							lilBf.animation.play("" + Std.string(data), false);
						}
						else if (!note.mustPress)
						{
							lilOpp.animation.play("" + Std.string(data), false);
						}
					}
				}
			});
		}

		justChanged = false;
		strumLineNotes.visible = quant.visible = vortex;

		if (FlxG.sound.music.time < 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		strumLineUpdateY();
		camPos.y = strumLine.y;
		for (i in 0...8)
		{
			strumLineNotes.members[i].y = strumLine.y;
			strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : 0.35;
		}

		#if FLX_PITCH
		// PLAYBACK SPEED CONTROLS //
		var holdingShift = FlxG.keys.pressed.SHIFT;
		var holdingLB = FlxG.keys.pressed.LBRACKET;
		var holdingRB = FlxG.keys.pressed.RBRACKET;
		var pressedLB = FlxG.keys.justPressed.LBRACKET;
		var pressedRB = FlxG.keys.justPressed.RBRACKET;

		if (!holdingShift && pressedLB || holdingShift && holdingLB)
			playbackSpeed -= 0.01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB)
			playbackSpeed += 0.01;
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB))
			playbackSpeed = 1;
		//

		if (playbackSpeed <= 0.5)
			playbackSpeed = 0.5;
		if (playbackSpeed >= 3)
			playbackSpeed = 3;

		FlxG.sound.music.pitch = playbackSpeed;
		vocals.pitch = playbackSpeed;
		#end

		bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
			+ "\nSection: "
			+ curSec
			+ "\n\nBeat: "
			+ Std.string(curDecBeat).substring(0, 4)
			+ "\n\nStep: "
			+ curStep
			+ "\n\nBeat Snap: "
			+ quantization
			+ "th";

		var playedSound:Array<Bool> = [false, false, false, false]; // Prevents ouchy GF sex sounds
		curRenderedNotes.forEachAlive(function(note:Note)
		{
			note.alpha = 1;
			if (curSelectedNote != null)
			{
				var noteDataToCheck:Int = note.noteData;
				var isonlycameraevent:Bool = false;
				FlxG.watch.addQuick('noteDataToCheck', noteDataToCheck);
				if (noteDataToCheck > -2 && note.mustPress != _song.notes[curSec].mustHitSection)
					noteDataToCheck += 4;

				if (curSelectedNote[0] == note.strumTime
					&& ((curSelectedNote[2] != null && curSelectedNote[2] != 'camera' && curSelectedNote[1] == noteDataToCheck)
						|| (curSelectedNote[2] == null && noteDataToCheck < 0)
						|| (curSelectedNote[2] == 'camera' && noteDataToCheck < 0)))
				{
					colorSine += elapsed;
					var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); // Alpha can't be 100% or the color won't be updated
				}
			}

			if (note.strumTime <= Conductor.songPosition)
			{
				note.alpha = 0.4;
				if (note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1)
				{
					var data:Int = note.noteData % 4;
					var noteDataToCheck:Int = note.noteData;
					if (noteDataToCheck > -2 && note.mustPress != _song.notes[curSec].mustHitSection)
						noteDataToCheck += 4;
					strumLineNotes.members[noteDataToCheck].playAnim('confirm', true);
					strumLineNotes.members[noteDataToCheck].resetAnim = (note.sustainLength / 1000) + 0.15;
					if (!playedSound[data])
					{
						if ((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress))
						{
							var soundToPlay = 'hitsound';
							if (_song.player1 == 'gf')
							{ // Easter egg
								soundToPlay = 'GF_' + Std.string(data + 1);
							}

							FlxG.sound.play(Paths.sound(soundToPlay)).pan = note.noteData < 4 ? -0.3 : 0.3; // would be coolio
							playedSound[data] = true;
						}

						data = note.noteData;
						if (note.mustPress != _song.notes[curSec].mustHitSection)
						{
							data += 4;
						}
					}
				}
			}
		});

		if (metronome.checked && lastConductorPos != Conductor.songPosition)
		{
			var metroInterval:Float = 60 / metronomeStepper.value;
			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);
			if (metroStep != lastMetroStep)
			{
				FlxG.sound.play(Paths.sound('Metronome_Tick'));
				// trace('Ticked');
			}
		}
		lastConductorPos = Conductor.songPosition;
		super.update(elapsed);
	}

	function updateZoom()
	{
		var daZoom:Float = zoomList[curZoom];
		var zoomThing:String = '1 / ' + daZoom;
		if (daZoom < 1)
			zoomThing = Math.round(1 / daZoom) + ' / 1';
		zoomTxt.text = 'Zoom: ' + zoomThing;
		reloadGridLayer();
	}

	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;

	function reloadGridLayer()
	{
		gridLayer.clear();
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 10, Std.int(GRID_SIZE * getSectionBeats() * 4 * zoomList[curZoom]));
		gridBG.x -= 38;

		#if desktop
		if (FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformVoices)
		{
			updateWaveform();
		}
		#end

		updateGrid();

		var leHeight:Int = Std.int(gridBG.height) * -1;
		var foundPrevSec:Bool = false;
		if (sectionStartTime(-1) >= 0)
		{
			prevGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 10, Std.int(GRID_SIZE * getSectionBeats() * 4 * zoomList[curZoom]));
			prevGridBG.x -= 38;
			prevGridBG.color = 0xA9A9A9;
			foundPrevSec = true;
		}
		else
			prevGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		prevGridBG.y = FlxG.save.data.chart_downscroll ? gridBG.y + gridBG.height : gridBG.y - prevGridBG.height;

		var leHeight2:Int = Std.int(gridBG.height);
		var foundNextSec:Bool = false;
		if (sectionStartTime(1) <= FlxG.sound.music.length)
		{
			nextGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 10, Std.int(GRID_SIZE * getSectionBeats() * 4 * zoomList[curZoom]));
			nextGridBG.x -= 38;
			nextGridBG.color = 0xA9A9A9;
			foundNextSec = true;
		}
		else
			nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		nextGridBG.y = FlxG.save.data.chart_downscroll ? gridBG.y - nextGridBG.height : gridBG.height;

		gridLayer.add(prevGridBG);
		gridLayer.add(nextGridBG);
		gridLayer.add(gridBG);

		var line = new FlxSprite().makeGraphic(5, FlxG.height, FlxColor.WHITE);
		line.setPosition(37.5, 0);
		line.scrollFactor.set(1, 0);
		gridLayer.add(line);
		var line = new FlxSprite().makeGraphic(5, FlxG.height, FlxColor.WHITE);
		line.scrollFactor.set(1, 0);
		gridLayer.add(line);
		var line = new FlxSprite().makeGraphic(5, FlxG.height, FlxColor.WHITE);
		line.setPosition((GRID_SIZE * 5) - 2.5, 0);
		line.scrollFactor.set(1, 0);
		gridLayer.add(line);

		lastSecBeats = getSectionBeats();
		if (sectionStartTime(1) > FlxG.sound.music.length)
			lastSecBeatsNext = 0;
		else
			getSectionBeats(curSec + 1);
	}

	function strumLineUpdateY()
	{
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * 16)) / (getSectionBeats() / 4);
	}

	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];

	function updateWaveform()
	{
		#if desktop
		if (waveformPrinted)
		{
			waveformSprite.makeGraphic(Std.int(GRID_SIZE * 8), Std.int(gridBG.height), 0x00FFFFFF);
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, gridBG.width, gridBG.height), 0x00FFFFFF);
		}
		waveformPrinted = false;

		if (!FlxG.save.data.chart_waveformInst && !FlxG.save.data.chart_waveformVoices)
		{
			// trace('Epic fail on the waveform lol');
			return;
		}

		var steps:Int = Math.round(getSectionBeats() * 4);
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);

		inline function emptyWaveData():Array<Array<Array<Float>>>
		{
			return [[[0], [0]], [[0], [0]]];
		}

		if (FlxG.save.data.chart_waveformInst)
		{
			@:privateAccess
			{
				if (FlxG.sound.music != null && FlxG.sound.music._sound != null && FlxG.sound.music._sound.__buffer != null)
				{
					var instBytes:Bytes = FlxG.sound.music._sound.__buffer.data.toBytes();
					var instData = waveformData(FlxG.sound.music._sound.__buffer, instBytes, st, et, 1, emptyWaveData(), Std.int(gridBG.height));
					drawWaveformData(instData, 0, 320, 0xFF2F7DFF, 0);
				}
			}
		}

		if (FlxG.save.data.chart_waveformVoices && vocals != null)
		{
			var swapLanes:Bool;
			var dadTrackX:Float;
			var bfTrackX:Float;
			var laneWidth:Float;

			swapLanes = _song.notes[curSec].mustHitSection;
			dadTrackX = swapLanes ? 160 : 0;
			bfTrackX = swapLanes ? 0 : 160;
			laneWidth = 160;

			var bfSound:FlxSound = @:privateAccess vocals.bfVocals;
			@:privateAccess
			{
				if (bfSound != null && bfSound._sound != null && bfSound._sound.__buffer != null)
				{
					var bfBytes:Bytes = bfSound._sound.__buffer.data.toBytes();
					var bfData = waveformData(bfSound._sound.__buffer, bfBytes, st, et, 1, emptyWaveData(), Std.int(gridBG.height));
					drawWaveformData(bfData, bfTrackX, laneWidth, 0xFF4FA8FF, 0);
				}
			}

			var dadSound:FlxSound = @:privateAccess vocals.dadVocals;
			@:privateAccess
			{
				if (dadSound != null && dadSound._sound != null && dadSound._sound.__buffer != null)
				{
					var dadBytes:Bytes = dadSound._sound.__buffer.data.toBytes();
					var dadData = waveformData(dadSound._sound.__buffer, dadBytes, st, et, 1, emptyWaveData(), Std.int(gridBG.height));
					drawWaveformData(dadData, dadTrackX, laneWidth, 0xFFFF5A5A, 0);
				}
			}
		}

		waveformPrinted = true;
		#end
	}

	function clearWaveformData():Void
	{
		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];
	}

	function drawWaveformData(data:Array<Array<Array<Float>>>, baseX:Float, trackWidth:Float, color:FlxColor, yOffset:Float = 0):Void
	{
		var gSize:Int = Std.int(trackWidth);
		var hSize:Int = Std.int(gSize / 2);
		var size:Float = 1;
		var leftLength:Int = (data[0][0].length > data[0][1].length ? data[0][0].length : data[0][1].length);
		var rightLength:Int = (data[1][0].length > data[1][1].length ? data[1][0].length : data[1][1].length);
		var length:Int = leftLength > rightLength ? leftLength : rightLength;
		var centerX:Float = baseX + (trackWidth / 2);

		if (length <= 0)
		{
			waveformSprite.pixels.fillRect(new Rectangle(centerX, yOffset, 1, gridBG.height), color);
			return;
		}

		for (i in 0...length)
		{
			var lmin:Float = FlxMath.bound(((i < data[0][0].length && i >= 0) ? data[0][0][i] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var lmax:Float = FlxMath.bound(((i < data[0][1].length && i >= 0) ? data[0][1][i] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var rmin:Float = FlxMath.bound(((i < data[1][0].length && i >= 0) ? data[1][0][i] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var rmax:Float = FlxMath.bound(((i < data[1][1].length && i >= 0) ? data[1][1][i] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			var rectLeft:Float = baseX + hSize - (lmin + rmin);
			var rectRight:Float = baseX + hSize + (lmax + rmax);
			var regionLeft:Float = baseX;
			var regionRight:Float = baseX + trackWidth;

			rectLeft = FlxMath.bound(rectLeft, regionLeft, regionRight);
			rectRight = FlxMath.bound(rectRight, regionLeft, regionRight);

			if (rectRight > rectLeft)
			{
				var rowY:Float = FlxG.save.data.chart_downscroll ? (yOffset + gridBG.height - ((i + 1) * size)) : (yOffset + i * size);
				waveformSprite.pixels.fillRect(new Rectangle(rectLeft, rowY, rectRight - rectLeft, size), color);
			}
			else
			{
				var rowY:Float = FlxG.save.data.chart_downscroll ? (yOffset + gridBG.height - ((i + 1) * size)) : (yOffset + i * size);
				waveformSprite.pixels.fillRect(new Rectangle(centerX, rowY, 1, size), color);
			}
		}
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>,
			?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null)
			return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null)
			steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true; // samples > 17200;
		var v1:Bool = false;

		if (array == null)
			array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1))
		{
			if (index >= 0)
			{
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2)
					byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0)
				{
					if (sample > lmax)
						lmax = sample;
				}
				else if (sample < 0)
				{
					if (sample < lmin)
						lmin = sample;
				}

				if (channels >= 2)
				{
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2)
						byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0)
					{
						if (sample > rmax)
							rmax = sample;
					}
					else if (sample < 0)
					{
						if (sample < rmin)
							rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow)
			{
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length)
					array[0][0].push(lRMin);
				else
					array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length)
					array[0][1].push(lRMax);
				else
					array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2)
				{
					if (gotIndex > array[1][0].length)
						array[1][0].push(rRMin);
					else
						array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length)
						array[1][1].push(rRMax);
					else
						array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else
				{
					if (gotIndex > array[1][0].length)
						array[1][0].push(lRMin);
					else
						array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length)
						array[1][1].push(lRMax);
					else
						array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if (gotIndex > steps)
				break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function doCursorlogic()
	{
		for (item in tab_group_note.members)
		{
			if (mainBox.selectedName == 'Note')
			{
				if (FlxG.mouse.overlaps(item))
				{
					if (!Std.isOfType(item, FlxText))
					{
						Cursor.set_cursorMode(Pointer);
					}
				}
			}
		}
		for (item in tab_group_song.members)
		{
			if (mainBox.selectedName == 'Song')
			{
				if (FlxG.mouse.overlaps(item))
				{
					if (Std.isOfType(item, PsychUIInputText))
					{
						Cursor.set_cursorMode(Text);
					}
					else
					{
						if (!Std.isOfType(item, FlxText))
						{
							Cursor.set_cursorMode(Pointer);
						}
					}
				}
			}
		}
		for (item in tab_group_event.members)
		{
			if (mainBox.selectedName == 'Events')
			{
				if (FlxG.mouse.overlaps(item))
				{
					if (!Std.isOfType(item, FlxText))
					{
						Cursor.set_cursorMode(Pointer);
					}
				}
			}
		}
		for (item in tab_group_section.members)
		{
			if (mainBox.selectedName == 'Section')
			{
				if (FlxG.mouse.overlaps(item))
				{
					if (!Std.isOfType(item, FlxText))
					{
						Cursor.set_cursorMode(Pointer);
					}
				}
			}
		}
		for (item in tab_group_chart.members)
		{
			if (mainBox.selectedName == 'Charting')
			{
				if (FlxG.mouse.overlaps(item))
				{
					if (Std.isOfType(item, PsychUISlider) && FlxG.mouse.pressed)
					{
						Cursor.set_cursorMode(Grabbing);
					}
					else
					{
						if (!Std.isOfType(item, FlxText))
						{
							Cursor.set_cursorMode(Pointer);
						}
					}
				}
			}
		}

		if (FlxG.mouse.overlaps(gridBG))
		{
			Cursor.set_cursorMode(Cell);
		}
		if (FlxG.mouse.overlaps(curRenderedNotes))
		{
			Cursor.set_cursorMode(Pointer);
		}
	}

	function assignTabGroup(tabName:String, group:FlxSpriteGroup):Void
	{
		if (group == null)
			return;
		var padding:Float = 8;
		var maxWidth:Float = mainBox.bg.width - padding;
		for (member in group.members)
		{
			if (member == null)
				continue;
			var obj:Dynamic = member;
			if (obj.x != null && obj.width != null)
			{
				var x:Float = obj.x;
				var w:Float = obj.width;
				if (!Math.isNaN(w) && w > 0)
				{
					if (x + w > maxWidth)
					{
						x = maxWidth - w;
						obj.x = x;
					}
					if (x < padding)
					{
						obj.x = padding;
					}
				}
			}
		}
		var tab = mainBox.getTab(tabName);
		if (tab != null)
			tab.menu = group;
	}

	public function UIEvent(id:String, sender:Dynamic):Void
	{
		getEvent(id, sender, null, null);
	}

	function parseEventValue(value:Dynamic):Dynamic
	{
		if (value == null)
			return null;
		if (!Std.isOfType(value, String))
			return value;

		var str:String = Std.string(value).trim();
		if (str.length < 1)
			return '';

		var lower = str.toLowerCase();
		if (lower == 'true')
			return true;
		if (lower == 'false')
			return false;
		if (lower == 'null')
			return null;

		var intRegex:EReg = ~/^-?[0-9]+$/;
		if (intRegex.match(str))
		{
			var parsedInt = Std.parseInt(str);
			if (parsedInt != null)
				return parsedInt;
		}

		var floatRegex:EReg = ~/^-?(?:[0-9]*\.[0-9]+|[0-9]+\.[0-9]*)$/;
		if (floatRegex.match(str))
		{
			var parsedFloat = Std.parseFloat(str);
			if (!Math.isNaN(parsedFloat))
				return parsedFloat;
		}

		return str;
	}

	function recalculateSteps(add:Float = 0):Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();
		resetIdle();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}

		if (vocals != null)
		{
			vocals.pause();
			vocals.time = FlxG.sound.music.time;
		}
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateWaveform();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		justChanged = true;
		if (_song.notes[sec] != null)
		{
			curSec = sec;
			if (updateMusic)
			{
				FlxG.sound.music.pause();
				resetIdle();

				FlxG.sound.music.time = sectionStartTime();
				if (vocals != null)
				{
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
				updateCurStep();
			}

			var blah1:Float = getSectionBeats();
			var blah2:Float = getSectionBeats(curSec + 1);
			if (sectionStartTime(1) > FlxG.sound.music.length)
				blah2 = 0;

			if (blah1 != lastSecBeats || blah2 != lastSecBeatsNext)
			{
				reloadGridLayer();
			}
			else
			{
				updateGrid();
			}
			updateSectionUI();
		}
		else
		{
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		updateWaveform();
		resetIdle();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSec];

		stepperBeats.value = getSectionBeats();
		check_mustHitSection.checked = sec.mustHitSection;
		check_gfSection.checked = sec.gfSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void
	{
		if (_song.notes[curSec].mustHitSection)
		{
			leftIcon.x = playerlocation[0];
			leftIcon.y = playerlocation[1];
			rightIcon.x = opponentlocation[0];
			rightIcon.y = opponentlocation[1];
			if (_song.notes[curSec].gfSection)
				leftIcon.loadGraphic(Paths.image('chartEditor/gf'));
			else
				leftIcon.loadGraphic(Paths.image('chartEditor/opponent'));
		}
		else
		{
			leftIcon.x = opponentlocation[0];
			leftIcon.y = opponentlocation[1];
			rightIcon.x = playerlocation[0];
			rightIcon.y = playerlocation[1];
			if (_song.notes[curSec].gfSection)
				leftIcon.loadGraphic(Paths.image('chartEditor/gf'));
			else
				leftIcon.loadGraphic(Paths.image('chartEditor/opponent'));
		}
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
		{
			var isEvent:Bool = isSelectableEvent(curSelectedNote);

			if (!isEvent && curSelectedNote[2] != null)
			{
				// Normal note UI

				if (curSelectedNote[3] != null)
				{
					if (!notetypeoveride)
					{
						currentType = noteTypeMap.get(curSelectedNote[3]);
						if (currentType <= 0)
						{
							noteTypeDropDown.selectedLabel = '';
						}
						else
						{
							noteTypeDropDown.selectedLabel = currentType + '. ' + curSelectedNote[3];
						}
					}
				}
			}
			else if (isEvent)
			{
				eventDropDown.selectedLabel = getCurrentEventName();
				recycleeventvars(eventDropDown.selectedLabel);
				var selected:Int = eventDropDown.selectedIndex;
				if (selected > 0 && selected < eventStuff.length)
				{
					descText.text = eventStuff[selected][1];
				}
				if (value1InputText != null)
					value1InputText.text = Std.string(getCurrentEventValue(1));
				if (value2InputText != null)
					value2InputText.text = Std.string(getCurrentEventValue(2));

				for (binding in eventValueInputBindings)
				{
					if (binding == null || binding.input == null)
						continue;
					var valueIndex:Int = Std.int(binding.valueIndex);

					var value:String = '';
					value = Std.string(getCurrentEventValue(valueIndex));
					var inputBinding:PsychUIInputText = binding.input;
					inputBinding.text = value;
				}

				for (binding in eventBindings)
				{
					if (binding == null || binding.ui == null)
						continue;
					var value:String = '';
					value = Std.string(getCurrentEventValue(binding.valueIndex));

					switch (binding.type)
					{
						case STRING:
							var inputUi:PsychUIInputText = binding.ui;
							inputUi.text = value;
						case FLOAT:
							var parsed = Std.parseFloat(value);
							if (Math.isNaN(parsed))
								parsed = 0;
							var floatStepper:PsychUINumericStepper = binding.ui;
							floatStepper.value = parsed;
						case BOOL:
							var boolValue = value.toLowerCase();
							var checkUi:PsychUICheckBox = binding.ui;
							checkUi.checked = (boolValue == 'true' || boolValue == '1' || boolValue == 'yes');
						case DROPDOWN:
							var dropdownUi:PsychUIDropDownMenu = binding.ui;
							dropdownUi.selectedLabel = value;
					}
				}
			}

			strumTimeInputText.text = '' + (isEvent ? getEventTime(curSelectedNote) : curSelectedNote[0]);
		}
	}

	function updateGrid():Void
	{
		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedNoteType.clear();
		nextRenderedNotes.clear();
		nextRenderedSustains.clear();
		prevRenderedNotes.clear();
		prevRenderedSustains.clear();

		if (_song.notes[curSec].changeBPM && _song.notes[curSec].bpm > 0)
		{
			Conductor.bpm = _song.notes[curSec].bpm;
			// trace('BPM of this section:');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSec)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.bpm = daBPM;
		}

		// CURRENT SECTION
		var beats:Float = getSectionBeats();
		for (i in _song.notes[curSec].sectionNotes)
		{
			// Skip event notes (they don't have noteData)
			if (Std.isOfType(i[1], Array))
				continue;

			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);

			if (note.sustainLength > 0)
			{
				var sustain = setupSusNote(note, beats);

				curRenderedSustains.add(sustain);
			}

			if (i[3] != null && note.noteType != null && note.noteType.length > 0)
			{
				var typeInt:Null<Int> = noteTypeMap.get(i[3]);
				var theType:String = '' + typeInt;
				if (typeInt == null)
					theType = '?';

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				daText.xAdd = -32;
				daText.yAdd = 6;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}

			note.mustPress = _song.notes[curSec].mustHitSection;
			if (i[1] > 3)
				note.mustPress = !note.mustPress;
		}
		// CURRENT EVENTS
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		inline function buildEventDisplayText(eventLabel:String, strumTime:Float, eventEntries:Array<Dynamic>):String
		{
			var names:Array<String> = [];
			if (eventEntries != null)
			{
				for (entry in eventEntries)
				{
					if (entry != null && entry.length > 0)
						names.push(Std.string(entry[0]));
				}
			}
			return names.length > 0 ? names.join(', ') : 'Unknown';
		}

		var renderedEventTimes:Map<String, Bool> = new Map<String, Bool>();
		for (i in _song.events)
		{
			var eventTime:Float = getEventTime(i);
			if (endThing > eventTime && eventTime >= startThing)
			{
				var eventKey:String = Std.string(eventTime);
				if (renderedEventTimes.exists(eventKey))
					continue;
				renderedEventTimes.set(eventKey, true);

				var entries:Array<Array<Dynamic>> = getEventEntries(i);
				var noteData:Array<Dynamic> = [eventTime, entries];
				var note:Note = setupNoteData(noteData, false);
				curRenderedNotes.add(note);

				var text:String = buildEventDisplayText('Event', note.strumTime, entries);

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
				daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -200;
				daText.borderSize = 1;
				if (note.eventLength > 1)
					daText.yAdd += 8;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
				// trace('test: ' + i[0], 'startThing: ' + startThing, 'endThing: ' + endThing);
			}
		}

		var renderedCameraEventTimes:Map<String, Bool> = new Map<String, Bool>();
		for (i in _song.cameraevents)
		{
			var eventTime:Float = getEventTime(i);
			if (endThing > eventTime && eventTime >= startThing)
			{
				var eventKey:String = Std.string(eventTime);
				if (renderedCameraEventTimes.exists(eventKey))
					continue;
				renderedCameraEventTimes.set(eventKey, true);

				var entries:Array<Array<Dynamic>> = getEventEntries(i);
				var noteData:Array<Dynamic> = [eventTime, entries, 'camera'];
				var note:Note = setupNoteData(noteData, false);
				curRenderedNotes.add(note);

				var text:String = buildEventDisplayText('CameraEvent', note.strumTime, entries);

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
				daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -410;
				daText.borderSize = 1;
				if (note.eventLength > 1)
					daText.yAdd += 8;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
				// trace('test: ' + i[0], 'startThing: ' + startThing, 'endThing: ' + endThing);
			}
		}

		// NEXT SECTION
		var beats:Float = getSectionBeats(1);
		if (curSec < _song.notes.length - 1)
		{
			for (i in _song.notes[curSec + 1].sectionNotes)
			{
				var note:Note = setupNoteData(i, true, false);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					var sustain = setupSusNote(note, beats);

					curRenderedSustains.add(sustain);
				}
			}
		}
		// PREV SECTION
		var beats:Float = getSectionBeats(-1);
		if (curSec > 1)
		{
			for (i in _song.notes[curSec - 1].sectionNotes)
			{
				var note:Note = setupNoteData(i, false, true);
				note.alpha = 0.6;
				prevRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					var sustain = setupSusNote(note, beats);

					curRenderedSustains.add(sustain);
				}
			}
		}

		// NEXT EVENTS
		var startThing:Float = sectionStartTime(1);
		var endThing:Float = sectionStartTime(2);
		var renderedNextEventTimes:Map<String, Bool> = new Map<String, Bool>();
		for (i in _song.events)
		{
			var eventTime:Float = getEventTime(i);
			if (endThing > eventTime && eventTime >= startThing)
			{
				var eventKey:String = Std.string(eventTime);
				if (renderedNextEventTimes.exists(eventKey))
					continue;
				renderedNextEventTimes.set(eventKey, true);

				var note:Note = setupNoteData([eventTime, getEventEntries(i)], true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
			}
		}
		var renderedNextCameraEventTimes:Map<String, Bool> = new Map<String, Bool>();
		for (i in _song.cameraevents)
		{
			var eventTime:Float = getEventTime(i);
			if (endThing > eventTime && eventTime >= startThing)
			{
				var eventKey:String = Std.string(eventTime);
				if (renderedNextCameraEventTimes.exists(eventKey))
					continue;
				renderedNextCameraEventTimes.set(eventKey, true);

				var note:Note = setupNoteData([eventTime, getEventEntries(i), 'camera'], true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
			}
		}
	}

	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool, ?isPrevSection:Bool = false):Note
	{
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];

		var player:Bool = _song.notes[curSec].mustHitSection;

		var note:Note = new Note(daStrumTime, daNoteInfo % 4, null, player, null, true);

		if (daSus != null && !Std.isOfType(i[1], Array))
		{
			if (!Std.isOfType(i[3], String))
			{
				i[3] = noteTypeIntMap.get(i[3]);
			}
			if (i.length > 3 && (i[3] == null || i[3].length < 1))
			{
				i.remove(i[3]);
			}

			note.sustainLength = daSus;
			note.noteType = i[3];
		}

		if (daSus == 'camera')
		{
			note.loadGraphic(Paths.image('cameraArrow'));
			note.shader = null;
			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;
			if (i[1].length < 2)
			{
				note.eventVal1 = i[1][0][1];
				note.eventVal2 = i[1][0][2];
			}
			note.noteData = -2;
			daNoteInfo = -2;
		}

		if (daSus == null && Std.isOfType(i[1], Array))
		{
			note.loadGraphic(Paths.image('eventArrow'));
			note.shader = null;
			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;
			if (i[1].length < 2)
			{
				note.eventVal1 = i[1][0][1];
				note.eventVal2 = i[1][0][2];
			}
			note.noteData = -1;
			daNoteInfo = -1;
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(daNoteInfo * GRID_SIZE) + GRID_SIZE;

		if (isNextSection && _song.notes[curSec].mustHitSection != _song.notes[curSec + 1].mustHitSection)
		{
			if (daNoteInfo > 3)
				note.x -= GRID_SIZE * 4;
			else if (daSus != null)
				note.x += GRID_SIZE * 4;
		}

		if (isPrevSection && _song.notes[curSec].mustHitSection != _song.notes[curSec - 1].mustHitSection)
		{
			if (daNoteInfo > 3)
				note.x -= GRID_SIZE * 4;
			else if (daSus != null)
				note.x += GRID_SIZE * 4;
		}

		var num:Int = 0;
		if (isNextSection)
			num = 1;
		if (isPrevSection)
			num = -1;
		var beats:Float = getSectionBeats(curSec + num);
		note.y = getYfromStrumNotes(daStrumTime - sectionStartTime(), beats);

		return note;
	}

	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if (addedOne)
				retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	function setupSusNote(note:Note, beats:Float):FlxSprite
	{
		var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom])
			+ (GRID_SIZE * zoomList[curZoom])
			- GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);
		if (height < minHeight)
			height = minHeight;
		if (height < 1)
			height = 1; // Prevents error of invalid height
		var sustainY:Float = note.y + GRID_SIZE / 2;
		if (FlxG.save.data.chart_downscroll)
			sustainY -= height;
		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 4, sustainY).makeGraphic(8, height);
		return spr;
	}

	private function addSection(sectionBeats:Float = 4):Void
	{
		var sec:SwagSection = {
			sectionBeats: sectionBeats,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			gfSection: false,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;

		if (noteDataToCheck > -1)
		{
			if (note.mustPress != _song.notes[curSec].mustHitSection)
				noteDataToCheck += 4;
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					curSelectedNote = i;
					break;
				}
			}
		}
		else
		{
			if (noteDataToCheck == -1)
			{
				for (i in _song.events)
				{
					trace('shouldselectevents');
					if (i != curSelectedNote && getEventTime(i) == note.strumTime)
					{
						curSelectedNote = i;

						curEventSelected = Std.int(getCurrentEventLength()) - 1;
						trace(curEventSelected);

						break;
					}
				}
			}

			if (noteDataToCheck == -2)
			{
				trace('shouldselectcamera');
				for (i in _song.cameraevents)
				{
					if (i != curSelectedNote && getEventTime(i) == note.strumTime)
					{
						curSelectedNote = i;
						trace(curSelectedNote);
						trace(Std.int(getCurrentEventLength()) - 1);
						curEventSelected = Std.int(getCurrentEventLength()) - 1;
						trace(curEventSelected);
						break;
					}
				}
			}
		}

		changeEventSelected(0, note.noteData);

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if (noteDataToCheck > -2 && note.mustPress != _song.notes[curSec].mustHitSection)
			noteDataToCheck += 4;

		trace(noteDataToCheck);

		switch (note.noteData)
		{
			default:
				for (i in _song.notes[curSec].sectionNotes)
				{
					if (i[0] == note.strumTime && i[1] == noteDataToCheck)
					{
						if (i == curSelectedNote)
							curSelectedNote = null;
						_song.notes[curSec].sectionNotes.remove(i);
						break;
					}
				}

			case -1:
				var removedSelectedEvent:Bool = false;
				var i:Int = _song.events.length - 1;
				while (i >= 0)
				{
					var eventData = _song.events[i];
					if (eventData != null && Math.abs(eventData.strumTime - note.strumTime) < 0.0001)
					{
						if (eventData == curSelectedNote)
							removedSelectedEvent = true;
						_song.events.remove(eventData);
					}
					i--;
				}
				if (removedSelectedEvent)
				{
					curSelectedNote = null;
					changeEventSelected();
				}

			case -2:
				var removedSelectedCameraEvent:Bool = false;
				var i:Int = _song.cameraevents.length - 1;
				while (i >= 0)
				{
					var eventData = _song.cameraevents[i];
					if (eventData != null && Math.abs(eventData.strumTime - note.strumTime) < 0.0001)
					{
						if (eventData == curSelectedNote)
							removedSelectedCameraEvent = true;
						_song.cameraevents.remove(eventData);
					}
					i--;
				}
				if (removedSelectedCameraEvent)
				{
					curSelectedNote = null;
					changeEventSelected();
				}
		}

		updateGrid();
	}

	public function doANoteThing(cs, d, style)
	{
		var delnote = false;
		if (strumLineNotes.members[d].overlaps(curRenderedNotes))
		{
			curRenderedNotes.forEachAlive(function(note:Note)
			{
				if (note.overlapsPoint(new FlxPoint(strumLineNotes.members[d].x + 1, strumLine.y + 1)) && note.noteData == d % 4)
				{
					// trace('tryin to delete note...');
					if (!delnote)
						deleteNote(note);
					delnote = true;
				}
			});
		}

		if (!delnote)
		{
			addNote(cs, d, style);
		}
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Void
	{
		// curUndoIndex++;
		// var newsong = _song.notes;
		//	undos.push(newsong);
		var noteStrum = getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime();
		var noteData = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);

		var noteSus = 0;
		var daAlt = false;
		var daType:Int = 0;
		trace(currentType);
		if (notetypeoveride)
		{
			daType = noteTypeList.indexOf('No Animation');
		}
		else
		{
			daType = currentType;
		}

		if (strum != null)
			noteStrum = strum;
		if (data != null)
			noteData = data;
		if (type != null)
			daType = type;

		if (noteData > -1)
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, noteData, noteSus, noteTypeIntMap.get(daType)]);
			curSelectedNote = _song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.length - 1];
		}
		if (noteData == -1)
		{
			var eventIndex:Int = eventDropDown.selectedIndex;
			if (eventIndex < 0)
				eventIndex = 0;
			var event = eventDropDown.selectedLabel;
			if (event == null || event.length < 1)
				event = 'none';
			var values:Array<Dynamic> = getEventUiValues();
			_song.events.push(makeSongEvent(noteStrum, event, values));
			curSelectedNote = _song.events[_song.events.length - 1];
			curEventSelected = 0;
		}
		if (noteData == -2)
		{
			var eventIndex:Int = eventDropDown.selectedIndex;
			if (eventIndex < 0)
				eventIndex = 0;
			var event = eventDropDown.selectedLabel;
			if (event == null || event.length < 1)
				event = 'none';
			var values:Array<Dynamic> = getEventUiValues();
			_song.cameraevents.push(makeSongEvent(noteStrum, event, values));
			curSelectedNote = _song.cameraevents[_song.cameraevents.length - 1];
			curEventSelected = 0;

			trace(curSelectedNote);
		}
		changeEventSelected();

		// trace(noteData + ', ' + noteStrum + ', ' + curSec);
		strumTimeInputText.text = '' + (isSelectableEvent(curSelectedNote) ? getEventTime(curSelectedNote) : curSelectedNote[0]);

		updateGrid();
		updateNoteUI();
	}

	// will figure this out l8r
	function redo()
	{
		// _song = redos[curRedoIndex];
	}

	function undo()
	{
		// redos.push(_song);
		undos.pop();
		// _song.notes = undos[undos.length - 1];
		///trace(_song.notes);
		// updateGrid();
	}

	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if (!doZoomCalc)
			leZoom = 1;
		if (FlxG.save.data.chart_downscroll)
			return FlxMath.remapToRange(yPos, gridBG.y + gridBG.height * leZoom, gridBG.y, 0, 16 * Conductor.stepCrochet);
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * leZoom, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if (!doZoomCalc)
			leZoom = 1;
		if (FlxG.save.data.chart_downscroll)
			return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y + gridBG.height * leZoom, gridBG.y);
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height * leZoom);
	}

	function getYfromStrumNotes(strumTime:Float, beats:Float):Float
	{
		var value:Float = strumTime / (beats * 4 * Conductor.stepCrochet);
		var height:Float = GRID_SIZE * beats * 4 * zoomList[curZoom];
		if (FlxG.save.data.chart_downscroll)
			return gridBG.y + height - (height * value);
		return height * value + gridBG.y;
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		var foldertogo:String = 'songs/';
		// shitty null fix, i fucking hate it when this happens
		// make it look sexier if possible
		for (i in 0...Constants.defaultsongtypes.length)
		{
			if (song.toLowerCase().contains(Constants.defaultsongtypes[i]))
			{
				switch (Constants.defaultsongtypes[i])
				{
					case 'default':
						foldertogo += 'default';
					case 'legacy':
						foldertogo += 'legacy';
					case 'pico':
						foldertogo += 'pico';
					default:
						foldertogo += 'default';
				}
			}
		}
		if (!foldertogo.toLowerCase().contains('default'))
		{
			foldertogo += 'default';
			Constants.cursongfolder = foldertogo;
		}

		Constants.cursongfolder = foldertogo;
		trace(foldertogo + song.toLowerCase());
		if (CoolUtil.difficulties[PlayState.storyDifficulty] != CoolUtil.defaultDifficulty)
		{
			if (CoolUtil.difficulties[PlayState.storyDifficulty] == null)
			{
				PlayState.SONG = Song.loadFromJson(song.toLowerCase(), foldertogo + '/' + song.toLowerCase());
			}
			else
			{
				PlayState.SONG = Song.loadFromJson(song.toLowerCase() + "-" + CoolUtil.difficulties[PlayState.storyDifficulty],
					foldertogo + '/' + song.toLowerCase());
			}
		}
		else
		{
			PlayState.SONG = Song.loadFromJson(song.toLowerCase(), foldertogo + '/' + song.toLowerCase());
		}
		MusicBeatState.resetState();
	}

	function autosaveSong():Void
	{
		var json:Dynamic = {
			"song": _song
		};
		json.song.events = serializeEventList(_song.events);
		json.song.cameraevents = serializeEventList(_song.cameraevents);
		FlxG.save.data.autosave = Json.stringify(json);
		FlxG.save.flush();
	}

	function clearEvents()
	{
		_song.events = [];
		updateGrid();
	}

	function clearcamEvents()
	{
		_song.cameraevents = [];
		updateGrid();
	}

	private function saveLevel()
	{
		var json = {
			"song": _song
		};
		json.song.events = serializeEventList(_song.events);
		json.song.cameraevents = serializeEventList(_song.cameraevents);

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			saveTextToFile(Paths.formatToSongPath(_song.song) + ".json", data.trim(), true);
		}
	}

	function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, getEventTime(Obj1), getEventTime(Obj2));
	}

	function serializeEventList(eventList:Array<Song.EventData>):Array<Song.EventData>
	{
		var output:Array<Song.EventData> = [];
		if (eventList == null)
			return output;

		for (eventData in eventList)
		{
			if (eventData == null)
				continue;

			var values:Array<Song.EventValue> = [];
			if (eventData.values != null)
			{
				for (i in 0...eventData.values.length)
				{
					var schemaName:String = 'Value ' + (i + 1);
					var eventSchema = utility.EventHandler.eventmapping.get(eventData.name);
					if (eventSchema != null && eventSchema.eventLogic != null && i < eventSchema.eventLogic.length && eventSchema.eventLogic[i] != null)
					{
						if (eventSchema.eventLogic[i].name != null && eventSchema.eventLogic[i].name.length > 0)
							schemaName = eventSchema.eventLogic[i].name;
						else if (eventSchema.eventLogic[i].title != null && eventSchema.eventLogic[i].title.length > 0)
							schemaName = eventSchema.eventLogic[i].title;
					}

					var eventValue:Dynamic = eventData.values[i];
					if (eventValue == null)
					{
						values.push({name: schemaName, value: ''});
						continue;
					}

					var outValue:Dynamic = eventValue;
					var outName:String = schemaName;
					if (Std.isOfType(eventValue, String) || Std.isOfType(eventValue, Int) || Std.isOfType(eventValue, Float) || Std.isOfType(eventValue, Bool))
					{
						outValue = eventValue;
					}
					else
					{
						if (Reflect.hasField(eventValue, 'name') && Reflect.field(eventValue, 'name') != null)
						{
							var customName:String = Std.string(Reflect.field(eventValue, 'name'));
							if (customName != null && customName.length > 0)
								outName = customName;
						}
						if (Reflect.hasField(eventValue, 'value'))
							outValue = Reflect.field(eventValue, 'value');
					}

					if (outValue == null)
						outValue = '';
					if (!(Std.isOfType(outValue, String) || Std.isOfType(outValue, Int) || Std.isOfType(outValue, Float) || Std.isOfType(outValue, Bool)))
						outValue = Std.string(outValue);

					values.push({
						name: outName,
						value: cast outValue
					});
				}
			}

			output.push({
				strumTime: eventData.strumTime,
				name: eventData.name,
				values: values
			});
		}

		return output;
	}

	function returniconformat(icon:String):Character.IconData
	{
		return {
			healthicon: icon,
			iconOffsets: []
		};
	}

	private function saveEvents()
	{
		if (_song.events != null && _song.events.length > 1)
			_song.events.sort(sortByTime);
		var eventsSong:Dynamic = {
			events: serializeEventList(_song.events)
		};
		var json = {
			"song": eventsSong
		}

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			saveTextToFile("events.json", data.trim(), false);
		}
	}

	private function saveCameraEvents()
	{
		if (_song.cameraevents != null && _song.cameraevents.length > 1)
			_song.cameraevents.sort(sortByTime);
		var cameventsSong:Dynamic = {
			cameraevents: serializeEventList(_song.cameraevents)
		};
		var json = {
			"song": cameventsSong
		}

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			saveTextToFile("cameraevents.json", data.trim(), false);
		}
	}

	private function saveTextToFile(defaultFileName:String, data:String, logLevelSave:Bool):Void
	{
		if (_savingDialog)
			return;
		_savingDialog = true;
		FileDialog.saveFile(Application.current.window, function(path:String, _)
		{
			_savingDialog = false;
			if (path == null || path.length < 1)
				return;
			var extIndex = defaultFileName.lastIndexOf('.');
			if (extIndex > -1)
			{
				var ext = defaultFileName.substr(extIndex);
				if (ext.length > 0 && !path.endsWith(ext))
				{
					path += ext;
				}
			}
			File.saveContent(path, data);
			if (logLevelSave)
				FlxG.log.notice("Successfully saved LEVEL DATA.");
		}, null, defaultFileName);
	}

	function getSectionBeats(?section:Null<Int> = null)
	{
		if (section == null)
			section = curSec;
		var val:Null<Float> = null;

		if (_song.notes[section] != null)
			val = _song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	function resetIdle()
	{
		lilBf.animation.play("idle");
		lilOpp.animation.play("idle");
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}
