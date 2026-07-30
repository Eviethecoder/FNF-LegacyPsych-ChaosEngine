package editors;

#if desktop
import Discord.DiscordClient;
import lime.app.Application;
import lime.ui.FileDialog;
#end
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import objects.Cursor;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.ui.PsychUIBox;
import backend.ui.PsychUIButton;
import backend.ui.PsychUICheckBox;
import backend.ui.PsychUIDropDownMenu;
import backend.ui.PsychUIInputText;
import backend.ui.PsychUINumericStepper;
import backend.ui.PsychUIEventHandler.PsychUIEvent;
import flixel.ui.FlxSpriteButton;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import haxe.Json;
import Character;
import utility.Characterpreloader;
import flixel.system.debug.Icon;
import lime.system.Clipboard;
import flixel.animation.FlxAnimation;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

/**
	*DEBUG MODE
 */
class CharacterEditorState extends MusicBeatState implements PsychUIEvent
{
	var char:Character;
	var ghostChar:Character;
	var textAnim:FlxText;
	var bgLayer:FlxTypedGroup<FlxSprite>;
	var charLayer:FlxTypedGroup<Character>;
	var cachedframes:Array<String> = [];
	var dumbTexts:FlxTypedGroup<FlxText>;
	var theFrames:FlxAtlasFrames;
	// var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'Catfriend';
	var goToPlayState:Bool = true;
	var camFollow:FlxObject;

	public function new(daAnim:String = 'Catfriend', goToPlayState:Bool = true)
	{
		super();
		this.daAnim = daAnim;
		this.goToPlayState = goToPlayState;
	}

	var mainBox:PsychUIBox;
	var iconBox:PsychUIBox;
	var charBox:PsychUIBox;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;
	var tab_group:FlxSpriteGroup;
	var extra_group:FlxSpriteGroup;
	var anim_group:FlxSpriteGroup;
	var char_group:FlxSpriteGroup;
	var settings_group:FlxSpriteGroup;
	var icon_group:FlxSpriteGroup;

	var leHealthIcon:HealthIcon;
	var ghostHealthIcon:HealthIcon;
	var iconAnimDropDown:PsychUIDropDownMenu;
	var ghostIconDropDown:PsychUIDropDownMenu;
	var iconOffsetXStepper:PsychUINumericStepper;
	var iconOffsetYStepper:PsychUINumericStepper;
	var iconOffsetsData:Array<Character.Iconoffsets> = [];
	var characterList:Array<String> = [];

	var animStyles:Array<String> = ['psych', 'v-slice', 'pause'];

	var cameraFollowPointer:FlxSprite;
	var healthBarBG:FlxSprite;

	var animtype:PsychUIDropDownMenu;

	override function create()
	{
		// FlxG.sound.playMusic(Paths.music('breakfast'), 0.5);

		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);

		bgLayer = new FlxTypedGroup<FlxSprite>();
		add(bgLayer);
		charLayer = new FlxTypedGroup<Character>();
		add(charLayer);

		var pointer:FlxGraphic = FlxGraphic.fromBitmapData(Icon.cross);
		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		add(cameraFollowPointer);

		loadChar(!daAnim.startsWith('bf'), false);

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);
		dumbTexts.cameras = [camHUD];

		textAnim = new FlxText(300, 36);
		textAnim.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textAnim.borderSize = 1;
		textAnim.size = 32;
		textAnim.scrollFactor.set();
		textAnim.cameras = [camHUD];
		add(textAnim);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		var tipTextArray:Array<String> = "E/Q - Camera Zoom In/Out
		\nR - Reset Camera Zoom
		\nJKLI - Move Camera
		\nW/S - Previous/Next Animation
		\nSpace - Play Animation
		\nArrow Keys - Move Character Offset
		\nT - Reset Current Offset
		\nHold Shift to Move 10x faster\n".split('\n');

		for (i in 0...tipTextArray.length - 1)
		{
			var tipText:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 15 - 16 * (tipTextArray.length - i), 300, tipTextArray[i], 12);
			tipText.cameras = [camHUD];
			tipText.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
		}

		FlxG.camera.follow(camFollow);

		iconBox = new PsychUIBox(FlxG.width - 675, 297, 350, 370, ['Icons']);
		iconBox.cameras = [camMenu];
		iconBox.scrollFactor.set();
		iconBox.selectedName = 'Icons';

		var tabs:Array<String> = ['Character', 'Animations', 'Extras'];
		charBox = new PsychUIBox(FlxG.width - 375, 35, 280, 90, ['Settings']);
		charBox.cameras = [camMenu];
		charBox.scrollFactor.set();
		charBox.selectedName = 'Settings';

		mainBox = new PsychUIBox(FlxG.width - 375, 297, 350, 370, tabs);
		mainBox.cameras = [camMenu];
		mainBox.scrollFactor.set();
		mainBox.selectedName = 'Character';
		add(mainBox);
		add(charBox);
		add(iconBox);

		addIconsUI();
		addSettingsUI();
		addCharacterUI();
		addAnimationsUI();
		addExtrasUI();
		Cursor.show();
		reloadCharacterOptions();

		super.create();
	}

	var onPixelBG:Bool = false;
	var OFFSET_X:Float = 300;

	function reloadBGs()
	{
		var i:Int = bgLayer.members.length - 1;
		while (i >= 0)
		{
			var memb:FlxSprite = bgLayer.members[i];
			if (memb != null)
			{
				memb.kill();
				bgLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		bgLayer.clear();

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set(0, 0);
		bg.color = 0xff45308b;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		bgLayer.add(bg);
	}

	var TemplateCharacter:String = '{
			"animations": [
				{
					"loop": false,
					"offsets": [
						0,
						0
					],
					"fps": 24,
					"anim": "idle",
					"indices": [],
					"name": "Dad idle dance"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singLEFT",
					"loop": false,
					"name": "Dad Sing Note LEFT"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singDOWN",
					"loop": false,
					"name": "Dad Sing Note DOWN"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singUP",
					"loop": false,
					"name": "Dad Sing Note UP"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singRIGHT",
					"loop": false,
					"name": "Dad Sing Note RIGHT"
				}
			],
			"no_antialiasing": false,
			"image": "characters/DADDY_DEAREST",
			"position": [
				0,
				0
			],
			"healthicon": "face",
			"flip_x": false,
			"healthbar_colors": [
				161,
				161,
				161
			],
			"camera_position": [
				0,
				0
			],
			"sing_duration": 6.1,
			"scale": 1
		}';

	var charDropDown:PsychUIDropDownMenu;

	function addIconsUI()
	{
		icon_group = new FlxSpriteGroup();

		leHealthIcon = new HealthIcon(char.icondata, false);
		leHealthIcon.updateHitbox();
		leHealthIcon.x = 10;
		leHealthIcon.y = 10;
		leHealthIcon.autoUpdate = false;
		leHealthIcon.cameras = [camHUD];

		ghostHealthIcon = new HealthIcon(char.icondata, false);
		ghostHealthIcon.updateHitbox();
		ghostHealthIcon.x = leHealthIcon.x;
		ghostHealthIcon.y = leHealthIcon.y;
		ghostHealthIcon.autoUpdate = false;
		ghostHealthIcon.visible = false;
		ghostHealthIcon.alpha = 0.6;
		ghostHealthIcon.color = 0xFF666688;
		ghostHealthIcon.cameras = [camHUD];
		icon_group.add(ghostHealthIcon);
		icon_group.add(leHealthIcon);

		var iconAnimNames:Array<String> = leHealthIcon.animation.getNameList();
		iconAnimDropDown = new PsychUIDropDownMenu(10, 175, iconAnimNames, function(id:Int, animName:String)
		{
			leHealthIcon.playAnimation(animName);
			reloadIconOffsetSteppers();
		}, 160);

		var ghostIconAnims:Array<String> = [''];
		for (name in iconAnimNames)
			ghostIconAnims.push(name);
		ghostIconDropDown = new PsychUIDropDownMenu(iconAnimDropDown.x + 200, iconAnimDropDown.y, ghostIconAnims, function(id:Int, animName:String)
		{
			ghostHealthIcon.visible = false;
			leHealthIcon.alpha = 1;
			if (id > 0)
			{
				ghostHealthIcon.visible = true;
				ghostHealthIcon.playAnimation(animName, null, true);
				leHealthIcon.alpha = 0.85;
			}
			reloadIconOffsetSteppers();
		}, 160);

		iconOffsetXStepper = new PsychUINumericStepper(10, iconAnimDropDown.y + 45, 1, 0, -500, 500, 0);
		iconOffsetYStepper = new PsychUINumericStepper(iconOffsetXStepper.x + 85, iconOffsetXStepper.y, 1, 0, -500, 500, 0);

		healthIconInputText = new PsychUIInputText(10, iconOffsetXStepper.y + 45, 95, leHealthIcon.getCharacter(), 8);
		loadCurrentCharacterIconOffsets();
		syncGhostHealthIconOffsets();

		var decideIconColor:PsychUIButton = new PsychUIButton(healthIconInputText.x + 105, healthIconInputText.y - 3, "Get Icon Color", function()
		{
			var coolColor = FlxColor.fromInt(CoolUtil.dominantColor(leHealthIcon));
			healthColorStepperR.value = coolColor.red;
			healthColorStepperG.value = coolColor.green;
			healthColorStepperB.value = coolColor.blue;
			getEvent(PsychUINumericStepper.CHANGE_EVENT, healthColorStepperR, null);
			getEvent(PsychUINumericStepper.CHANGE_EVENT, healthColorStepperG, null);
			getEvent(PsychUINumericStepper.CHANGE_EVENT, healthColorStepperB, null);
		}, 100, 20);

		icon_group.add(new FlxText(iconAnimDropDown.x, iconAnimDropDown.y - 18, 0, 'Preview Animation:'));
		icon_group.add(new FlxText(ghostIconDropDown.x, ghostIconDropDown.y - 18, 0, 'Animation Ghost:'));
		icon_group.add(new FlxText(iconOffsetXStepper.x, iconOffsetXStepper.y - 18, 0, 'Icon Offset X/Y:'));
		icon_group.add(new FlxText(healthIconInputText.x, healthIconInputText.y - 18, 0, 'Health icon name:'));
		icon_group.add(ghostIconDropDown);
		icon_group.add(iconOffsetXStepper);
		icon_group.add(iconOffsetYStepper);
		icon_group.add(healthIconInputText);
		icon_group.add(decideIconColor);
		icon_group.add(iconAnimDropDown);

		assignTabGroup('Icons', icon_group, iconBox);
	}

	function addSettingsUI()
	{
		settings_group = new FlxSpriteGroup();

		var check_player = new PsychUICheckBox(10, 50, "Playable Character", 100);
		check_player.checked = daAnim.startsWith('bf');
		check_player.onClick = function()
		{
			char.isPlayer = !char.isPlayer;
			char.flipX = !char.flipX;
			updatePointerPos();
			reloadBGs();
			ghostChar.flipX = char.flipX;
		};

		charDropDown = new PsychUIDropDownMenu(30, 30, [''], function(id:Int, character:String)
		{
			daAnim = characterList[id];
			check_player.checked = daAnim.startsWith('bf');
			loadChar(!check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
		}, 120);
		charDropDown.selectedLabel = daAnim;
		reloadCharacterDropDown();

		var reloadCharacter:PsychUIButton = new PsychUIButton(170, 20, "Reload Char", function()
		{
			loadChar(!check_player.checked);
			reloadCharacterDropDown();
		}, 95, 20);

		var templateCharacter:PsychUIButton = new PsychUIButton(170, 50, "Load Template", function()
		{
			var parsedJson:CharacterFile = cast Json.parse(TemplateCharacter);
			var characters:Array<Character> = [char, ghostChar];
			for (character in characters)
			{
				character.animOffsets.clear();
				character.animationsArray = parsedJson.animations;
				for (anim in character.animationsArray)
				{
					character.addOffset(anim.anim, anim.offsets);
					if (anim.frames != null)
					{
						cachedframes.push(anim.frames);
						var sheetAtlas = Paths.getSparrowAtlas(anim.frames);
						if (theFrames == null)
							theFrames = sheetAtlas;
						else
							theFrames.addAtlas(sheetAtlas);

						var mainAtlas = Paths.getSparrowAtlas(character.imageFile);
						if (theFrames == null)
							theFrames = mainAtlas;
						else
							theFrames.addAtlas(mainAtlas);

						character.frames = theFrames;
					}
				}
				if (character.animationsArray[0] != null)
				{
					character.playAnim(character.animationsArray[0].anim, true);
				}

				character.singDuration = parsedJson.sing_duration;
				character.positionArray = parsedJson.position;
				character.cameraPosition = parsedJson.camera_position;

				character.imageFile = parsedJson.image;
				character.jsonScale = parsedJson.scale;
				character.noAntialiasing = parsedJson.no_antialiasing;
				character.originalFlipX = parsedJson.flip_x;
				character.healthColorArray = parsedJson.healthbar_colors;
				character.setPosition(character.positionArray[0] + OFFSET_X + 100, character.positionArray[1]);
			}

			reloadCharacterImage();
			reloadCharacterDropDown();
			reloadCharacterOptions();

			updatePointerPos();
			genBoyOffsets();
		}, 95, 20);
		templateCharacter.color = FlxColor.RED;

		settings_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		settings_group.add(check_player);
		settings_group.add(reloadCharacter);
		settings_group.add(charDropDown);
		settings_group.add(templateCharacter);
		assignTabGroup('Settings', settings_group, charBox);
	}

	var imageInputText:PsychUIInputText;
	var imagesInputText:PsychUIInputText;
	var healthIconInputText:PsychUIInputText;

	var singDurationStepper:PsychUINumericStepper;
	var scaleStepper:PsychUINumericStepper;
	var positionXStepper:PsychUINumericStepper;
	var positionYStepper:PsychUINumericStepper;
	var positionCameraXStepper:PsychUINumericStepper;
	var positionCameraYStepper:PsychUINumericStepper;

	var flipXCheckBox:PsychUICheckBox;
	var noAntialiasingCheckBox:PsychUICheckBox;

	var healthColorStepperR:PsychUINumericStepper;
	var healthColorStepperG:PsychUINumericStepper;
	var healthColorStepperB:PsychUINumericStepper;

	function addExtrasUI()
	{
		extra_group = new FlxSpriteGroup();

		animtype = new PsychUIDropDownMenu(healthIconInputText.x + 200, healthIconInputText.y - 10, animStyles, function(id:Int, character:String)
		{
			char.animstyle = character;
		}, 120);
		if (char.animstyle != null)
			animtype.selectedLabel = char.animstyle;
		extra_group.add(animtype);
		assignTabGroup('Extras', extra_group);
		trace('should be added');
	}

	function addCharacterUI()
	{
		char_group = new FlxSpriteGroup();

		imageInputText = new PsychUIInputText(15, 30, 200, 'characters/BOYFRIEND', 8);
		var reloadImage:PsychUIButton = new PsychUIButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			char.imageFile = imageInputText.text;
			reloadCharacterImage();
			if (char.animation.curAnim != null)
			{
				char.playAnim(char.animation.curAnim.name, true);
			}
		}, 95, 20);

		singDurationStepper = new PsychUINumericStepper(15, imageInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new PsychUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 1);

		flipXCheckBox = new PsychUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, "Flip X", 50);
		flipXCheckBox.checked = char.flipX;
		if (char.isPlayer)
			flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.onClick = function()
		{
			char.originalFlipX = !char.originalFlipX;
			char.flipX = char.originalFlipX;
			if (char.isPlayer)
				char.flipX = !char.flipX;

			ghostChar.flipX = char.flipX;
		};

		noAntialiasingCheckBox = new PsychUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = char.noAntialiasing;
		noAntialiasingCheckBox.onClick = function()
		{
			char.antialiasing = false;
			if (!noAntialiasingCheckBox.checked && ClientPrefs.data.globalAntialiasing)
			{
				char.antialiasing = true;
			}
			char.noAntialiasing = noAntialiasingCheckBox.checked;
			ghostChar.antialiasing = char.antialiasing;
		};

		positionXStepper = new PsychUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, char.positionArray[0], -9000, 9000, 0);
		positionYStepper = new PsychUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, char.positionArray[1], -9000, 9000, 0);

		positionCameraXStepper = new PsychUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, char.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new PsychUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, char.cameraPosition[1], -9000, 9000, 0);

		var saveCharacterButton:PsychUIButton = new PsychUIButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function()
		{
			saveCharacter();
		}, 100, 20);

		healthColorStepperR = new PsychUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, char.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new PsychUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, char.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new PsychUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, char.healthColorArray[2], 0, 255, 0);

		char_group.add(new FlxText(15, imageInputText.y - 18, 0, 'Image file name:'));
		char_group.add(new FlxText(15, singDurationStepper.y - 18, 0, 'Sing Animation length:'));
		char_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
		char_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		char_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		char_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 0, 'Health bar R/G/B:'));
		char_group.add(imageInputText);
		char_group.add(reloadImage);

		char_group.add(singDurationStepper);
		char_group.add(scaleStepper);
		char_group.add(flipXCheckBox);
		char_group.add(noAntialiasingCheckBox);
		char_group.add(positionXStepper);
		char_group.add(positionYStepper);
		char_group.add(positionCameraXStepper);
		char_group.add(positionCameraYStepper);
		char_group.add(healthColorStepperR);
		char_group.add(healthColorStepperG);
		char_group.add(healthColorStepperB);
		char_group.add(saveCharacterButton);
		assignTabGroup('Character', char_group);
	}

	var ghostDropDown:PsychUIDropDownMenu;
	var animationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var animationNameInputText:PsychUIInputText;
	var animationIndicesInputText:PsychUIInputText;
	var animationNameFramerate:PsychUINumericStepper;
	var animationLoopCheckBox:PsychUICheckBox;

	function addAnimationsUI()
	{
		anim_group = new FlxSpriteGroup();

		animationInputText = new PsychUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new PsychUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationNameFramerate = new PsychUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, "Should it Loop?", 100);
		imagesInputText = new PsychUIInputText(animationIndicesInputText.x, animationIndicesInputText.y + 50, 250, '', 8);

		animationDropDown = new PsychUIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String)
		{
			var anim:AnimArray = char.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationNameFramerate.value = anim.fps;
			imagesInputText.text = (anim.frames != null) ? anim.frames : '';

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		}, 130);

		ghostDropDown = new PsychUIDropDownMenu(animationDropDown.x + 150, animationDropDown.y, [''], function(selectedAnimation:Int, pressed:String)
		{
			ghostChar.visible = false;
			char.alpha = 1;
			if (selectedAnimation > 0)
			{
				ghostChar.visible = true;
				ghostChar.playAnim(ghostChar.animationsArray[selectedAnimation - 1].anim, true);
				char.alpha = 0.85;
			}
		}, 130);

		var addUpdateButton:PsychUIButton = new PsychUIButton(70, imagesInputText.y + 30, "Add/Update", function()
		{
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			var animationFrames:String = imagesInputText.text.trim();
			if (animationFrames.length < 1 || animationFrames == char.imageFile)
			{
				animationFrames = null;
			}
			if (indicesStr.length > 1)
			{
				for (i in 0...indicesStr.length)
				{
					var index:Int = Std.parseInt(indicesStr[i]);
					if (indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1)
					{
						indices.push(index);
					}
				}
			}

			var lastAnim:String = '';
			if (char.animationsArray[curAnim] != null)
			{
				lastAnim = char.animationsArray[curAnim].anim;
			}

			var lastOffsets:Array<Float> = [0, 0, 0, 0];
			for (anim in char.animationsArray)
			{
				if (animationInputText.text == anim.anim)
				{
					lastOffsets = anim.offsets;
					if (char.animation.getByName(animationInputText.text) != null)
					{
						char.animation.remove(animationInputText.text);
					}
					char.animationsArray.remove(anim);
				}
			}

			var newAnim:AnimArray = {
				anim: animationInputText.text,
				frames: animationFrames,
				name: animationNameInputText.text,
				fps: Math.round(animationNameFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: lastOffsets
			};
			if (indices != null && indices.length > 0)
			{
				char.animation.addByIndices(newAnim.anim, newAnim.name, newAnim.indices, "", newAnim.fps, newAnim.loop);
			}
			else
			{
				char.animation.addByPrefix(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop);
			}

			if (!char.animOffsets.exists(newAnim.anim))
			{
				char.addOffset(newAnim.anim, [0, 0, 0, 0]);
			}
			char.animationsArray.push(newAnim);

			if (lastAnim == animationInputText.text)
			{
				var leAnim:FlxAnimation = char.animation.getByName(lastAnim);
				if (leAnim != null && leAnim.frames.length > 0)
				{
					char.playAnim(lastAnim, true);
				}
				else
				{
					for (i in 0...char.animationsArray.length)
					{
						if (char.animationsArray[i] != null)
						{
							leAnim = char.animation.getByName(char.animationsArray[i].anim);
							if (leAnim != null && leAnim.frames.length > 0)
							{
								char.playAnim(char.animationsArray[i].anim, true);
								curAnim = i;
								break;
							}
						}
					}
				}
			}

			reloadAnimationDropDown();
			genBoyOffsets();
			trace('Added/Updated animation: ' + animationInputText.text);
		}, 100, 20);

		var removeButton:PsychUIButton = new PsychUIButton(180, imagesInputText.y + 30, "Remove", function()
		{
			for (anim in char.animationsArray)
			{
				if (animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if (char.animation.curAnim != null && anim.anim == char.animation.curAnim.name)
						resetAnim = true;

					if (char.animation.getByName(anim.anim) != null)
					{
						char.animation.remove(anim.anim);
					}
					if (char.animOffsets.exists(anim.anim))
					{
						char.animOffsets.remove(anim.anim);
					}
					char.animationsArray.remove(anim);

					if (resetAnim && char.animationsArray.length > 0)
					{
						char.playAnim(char.animationsArray[0].anim, true);
					}
					reloadAnimationDropDown();
					genBoyOffsets();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
			}
		}, 75, 20);

		var applySheetsButton:PsychUIButton = new PsychUIButton(70, imagesInputText.y + 55, "Apply Sheets", function()
		{
			var selectedAnimation:Int = animationDropDown.selectedIndex;
			if (selectedAnimation < 0 || selectedAnimation >= char.animationsArray.length)
			{
				trace('No animation selected to apply spritesheet.');
				return;
			}

			var cleaned:String = imagesInputText.text.trim();
			if (cleaned.length < 1 || cleaned == char.imageFile)
			{
				cleaned = null;
			}
			char.animationsArray[selectedAnimation].frames = cleaned;
			imagesInputText.text = (cleaned != null) ? cleaned : '';
			reloadCharacterImage();

			if (char.animation.curAnim != null)
			{
				char.playAnim(char.animation.curAnim.name, true);
			}

			trace('Applied animation spritesheet: ' + ((cleaned != null) ? cleaned : 'default'));
		}, 100, 20);

		anim_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		anim_group.add(new FlxText(ghostDropDown.x, ghostDropDown.y - 18, 0, 'Animation Ghost:'));
		anim_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		anim_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		anim_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));
		anim_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));
		anim_group.add(new FlxText(imagesInputText.x, imagesInputText.y - 18, 0, 'Animation spritesheet (optional):'));

		anim_group.add(animationInputText);
		anim_group.add(animationNameInputText);
		anim_group.add(animationIndicesInputText);
		anim_group.add(animationNameFramerate);
		anim_group.add(animationLoopCheckBox);
		anim_group.add(addUpdateButton);
		anim_group.add(removeButton);
		anim_group.add(ghostDropDown);
		anim_group.add(animationDropDown);
		anim_group.add(imagesInputText);
		anim_group.add(applySheetsButton);
		assignTabGroup('Animations', anim_group);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == PsychUIInputText.CHANGE_EVENT && (sender is PsychUIInputText))
		{
			if (sender == healthIconInputText)
			{
				leHealthIcon.changeIcon(returniconformat(healthIconInputText.text));
				ghostHealthIcon.changeIcon(returniconformat(healthIconInputText.text));
				leHealthIcon.animOffsets.clear();
				ghostHealthIcon.animOffsets.clear();
				for (entry in iconOffsetsData)
				{
					if (entry != null && entry.animname != null && entry.offsets != null && entry.offsets.length > 1)
					{
						leHealthIcon.addOffset(entry.animname, entry.offsets[0], entry.offsets[1]);
					}
				}
				var iconAnimNames:Array<String> = leHealthIcon.animation.getNameList();
				iconAnimDropDown.list = iconAnimNames;
				var ghostIconAnims:Array<String> = [''];
				for (name in iconAnimNames)
					ghostIconAnims.push(name);
				ghostIconDropDown.list = ghostIconAnims;
				if (iconAnimDropDown != null)
					iconAnimDropDown.selectedLabel = 'Neutral';
				ghostIconDropDown.selectedLabel = '';
				ghostHealthIcon.visible = false;
				leHealthIcon.alpha = 1;
				reloadIconOffsetSteppers();
				syncGhostHealthIconOffsets();
				char.icondata.healthicon = healthIconInputText.text;
				updatePresence();
			}
			else if (sender == imageInputText)
			{
				char.imageFile = imageInputText.text;
			}
			else if (sender == imagesInputText)
			{
				var selectedAnimation:Int = animationDropDown.selectedIndex;
				if (selectedAnimation >= 0 && selectedAnimation < char.animationsArray.length)
				{
					var cleaned:String = imagesInputText.text.trim();
					if (cleaned.length < 1 || cleaned == char.imageFile)
						cleaned = null;
					char.animationsArray[selectedAnimation].frames = cleaned;
				}
			}
		}
		else if (id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper))
		{
			if (sender == scaleStepper)
			{
				reloadCharacterImage();
				char.jsonScale = sender.value;
				char.setGraphicSize(Std.int(char.width * char.jsonScale));
				char.updateHitbox();
				ghostChar.setGraphicSize(Std.int(ghostChar.width * char.jsonScale));
				ghostChar.updateHitbox();
				reloadGhost();
				updatePointerPos();

				if (char.animation.curAnim != null)
				{
					char.playAnim(char.animation.curAnim.name, true);
				}
			}
			else if (sender == positionXStepper)
			{
				char.positionArray[0] = positionXStepper.value;
				char.x = char.positionArray[0] + OFFSET_X + 100;
				updatePointerPos();
			}
			else if (sender == singDurationStepper)
			{
				char.singDuration = singDurationStepper.value; // ermm you forgot this??
			}
			else if (sender == positionYStepper)
			{
				char.positionArray[1] = positionYStepper.value;
				char.y = char.positionArray[1];
				updatePointerPos();
			}
			else if (sender == positionCameraXStepper)
			{
				char.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
			}
			else if (sender == positionCameraYStepper)
			{
				char.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
			}
			else if (sender == healthColorStepperR)
			{
				char.healthColorArray[0] = Math.round(healthColorStepperR.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}
			else if (sender == healthColorStepperG)
			{
				char.healthColorArray[1] = Math.round(healthColorStepperG.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}
			else if (sender == healthColorStepperB)
			{
				char.healthColorArray[2] = Math.round(healthColorStepperB.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}
			else if (sender == iconOffsetXStepper || sender == iconOffsetYStepper)
			{
				var animName = getCurrentIconAnimName();
				if (animName != null && animName.length > 0)
				{
					leHealthIcon.addOffset(animName, iconOffsetXStepper.value, iconOffsetYStepper.value);
					leHealthIcon.playAnimation(animName, null, false);
					syncIconOffsetDataFromHealthIcon();
					syncGhostHealthIconOffsets();
				}
			}
		}
	}

	function getCurrentIconAnimName():String
	{
		if (iconAnimDropDown != null && iconAnimDropDown.selectedLabel != null && iconAnimDropDown.selectedLabel.length > 0)
		{
			return iconAnimDropDown.selectedLabel;
		}

		return leHealthIcon.getCurrentAnimation();
	}

	function loadCurrentCharacterIconOffsets():Void
	{
		iconOffsetsData = [];
		if (leHealthIcon != null)
		{
			leHealthIcon.animOffsets.clear();
		}
		if (ghostHealthIcon != null)
		{
			ghostHealthIcon.animOffsets.clear();
		}
		if (daAnim == null || daAnim.length < 1)
		{
			return;
		}

		var characterData:Character.CharacterFile = Characterpreloader.charmap.get(daAnim);
		if (characterData == null
			|| characterData.iconData == null
			|| characterData.iconData.iconOffsets == null
			|| characterData.iconData.iconOffsets.length < 1)
		{
			return;
		}

		for (entry in characterData.iconData.iconOffsets)
		{
			if (entry == null || entry.animname == null || entry.offsets == null || entry.offsets.length < 2)
			{
				continue;
			}

			iconOffsetsData.push({
				animname: entry.animname,
				offsets: [entry.offsets[0], entry.offsets[1]]
			});
			leHealthIcon.addOffset(entry.animname, entry.offsets[0], entry.offsets[1]);
		}
	}

	function reloadIconOffsetSteppers():Void
	{
		if (iconOffsetXStepper == null || iconOffsetYStepper == null || leHealthIcon == null)
		{
			return;
		}

		var animName = getCurrentIconAnimName();
		if (animName != null && leHealthIcon.animOffsets.exists(animName))
		{
			var values = leHealthIcon.animOffsets.get(animName);
			if (values != null && values.length > 1)
			{
				iconOffsetXStepper.value = values[0];
				iconOffsetYStepper.value = values[1];
				return;
			}
		}

		iconOffsetXStepper.value = 0;
		iconOffsetYStepper.value = 0;
	}

	function syncIconOffsetDataFromHealthIcon():Void
	{
		iconOffsetsData = [];
		for (name => values in leHealthIcon.animOffsets)
		{
			if (name == null || values == null || values.length < 2)
			{
				continue;
			}

			iconOffsetsData.push({
				animname: name,
				offsets: [values[0], values[1]]
			});
		}
	}

	function syncGhostHealthIconOffsets():Void
	{
		if (ghostHealthIcon == null || leHealthIcon == null)
		{
			return;
		}

		ghostHealthIcon.animOffsets.clear();
		for (name => values in leHealthIcon.animOffsets)
		{
			if (name == null || values == null || values.length < 2)
			{
				continue;
			}

			ghostHealthIcon.addOffset(name, values[0], values[1]);
		}

		if (ghostHealthIcon.visible)
		{
			var ghostAnim = ghostIconDropDown != null ? ghostIconDropDown.selectedLabel : null;
			if (ghostAnim != null && ghostAnim.length > 0)
			{
				ghostHealthIcon.playAnimation(ghostAnim, null, false);
			}
		}
	}

	function reloadCharacterImage()
	{
		var lastAnim:String = '';
		if (theFrames != null)
		{
			theFrames = null;
		};
		if (char.animation.curAnim != null)
		{
			lastAnim = char.animation.curAnim.name;
		}
		var anims:Array<AnimArray> = char.animationsArray.copy();
		if (Paths.fileExists('images/' + char.imageFile + '/Animation.json', TEXT))
		{
			char.frames = AtlasFrameMaker.construct(char.imageFile);
		}
		else if (Paths.fileExists('images/' + char.imageFile + '.txt', TEXT))
		{
			char.frames = Paths.getPackerAtlas(char.imageFile);
		}
		else
		{
			var sheets:Array<String> = [];
			if (char.animationsArray != null)
			{
				for (anim in char.animationsArray)
				{
					if (anim.frames != null)
					{
						var cleaned:String = anim.frames.trim();
						if (cleaned.length > 0 && cleaned != char.imageFile && sheets.indexOf(cleaned) == -1)
						{
							sheets.push(cleaned);
						}
					}
				}
			}

			if (sheets.length > 0)
			{
				for (img in sheets)
				{
					if (img == null || img.trim().length < 1 || img == char.imageFile)
					{
						continue;
					}

					var atlas = Paths.getSparrowAtlas(img.trim());
					if (theFrames == null)
						theFrames = atlas;
					else
						theFrames.addAtlas(atlas);
				}

				var mainAtlas = Paths.getSparrowAtlas(char.imageFile);
				if (theFrames == null)
				{
					theFrames = mainAtlas;
				}
				else
				{
					theFrames.addAtlas(mainAtlas);
				}
				char.frames = theFrames;
			}
			else
			{
				char.frames = Paths.getSparrowAtlas(char.imageFile);
			}
		}

		if (char.animationsArray != null && char.animationsArray.length > 0)
		{
			for (anim in char.animationsArray)
			{
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; // Bruh
				var animIndices:Array<Int> = anim.indices;
				if (animIndices != null && animIndices.length > 0)
				{
					char.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				}
				else
				{
					char.animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
			}
		}
		else
		{
			char.quickAnimAdd('idle', 'BF idle dance');
		}

		if (lastAnim != '')
		{
			char.playAnim(lastAnim, true);
		}
		else
		{
			char.dance();
		}
		if (ghostDropDown != null)
		{
			ghostDropDown.selectedLabel = '';
		}
		reloadGhost();
	}

	function genBoyOffsets():Void
	{
		var daLoop:Int = 0;

		var i:Int = dumbTexts.members.length - 1;
		while (i >= 0)
		{
			var memb:FlxText = dumbTexts.members[i];
			if (memb != null)
			{
				memb.kill();
				dumbTexts.remove(memb);
				memb.destroy();
			}
			--i;
		}
		dumbTexts.clear();

		for (anim => offsets in char.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			text.cameras = [camHUD];

			daLoop++;
		}

		textAnim.visible = true;
		if (dumbTexts.length < 1)
		{
			var text:FlxText = new FlxText(10, 38, 0, "ERROR! No animations found.", 15);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			textAnim.visible = false;
		}
	}

	function doCursorlogic()
	{
		Cursor.set_cursorMode(Default);

		for (item in char_group.members)
		{
			if (mainBox.selectedName == 'Character')
			{
				if (FlxG.mouse.overlaps(item))
				{
					if (!Std.isOfType(item, PsychUIInputText))
					{
						Cursor.set_cursorMode(Pointer);
					}
					else
					{
						Cursor.set_cursorMode(Text);
					}
				}
			}
		}
		for (item in extra_group.members)
		{
			if (mainBox.selectedName == 'Extras')
			{
				if (FlxG.mouse.overlaps(item))
				{
					if (!Std.isOfType(item, PsychUIInputText))
					{
						Cursor.set_cursorMode(Pointer);
					}
					else
					{
						Cursor.set_cursorMode(Text);
					}
				}
			}
		}
		for (item in anim_group.members)
		{
			if (mainBox.selectedName == 'Animations')
			{
				if (FlxG.mouse.overlaps(item))
				{
					if (!Std.isOfType(item, PsychUIInputText))
					{
						Cursor.set_cursorMode(Pointer);
					}
					else
					{
						Cursor.set_cursorMode(Text);
					}
				}
			}
		}
		for (item in icon_group.members)
		{
			if (iconBox.selectedName == 'Icons')
			{
				if (FlxG.mouse.overlaps(item))
				{
					if (!Std.isOfType(item, PsychUIInputText))
					{
						Cursor.set_cursorMode(Pointer);
					}
					else
					{
						Cursor.set_cursorMode(Text);
					}
				}
			}
		}
	}

	function assignTabGroup(tabName:String, group:FlxSpriteGroup, box:PsychUIBox = null):Void
	{
		if (group == null)
			return;
		var targetBox:PsychUIBox = (box != null ? box : mainBox);
		var padding:Float = 8;
		var maxWidth:Float = targetBox.bg.width - padding;
		group.cameras = [camMenu];
		for (member in group.members)
		{
			if (member == null)
				continue;
			var basic:FlxBasic = cast member;
			basic.cameras = [camMenu];

			var obj:Dynamic = member;
			if (Reflect.hasField(obj, 'x') && Reflect.hasField(obj, 'width'))
			{
				var x:Float = Reflect.field(obj, 'x');
				var w:Float = Reflect.field(obj, 'width');
				if (!Math.isNaN(w) && w > 0)
				{
					if (x + w > maxWidth)
					{
						x = maxWidth - w;
						Reflect.setField(obj, 'x', x);
					}
					if (x < padding)
					{
						Reflect.setField(obj, 'x', padding);
					}
				}
			}
		}
		var tab = targetBox.getTab(tabName);
		if (tab != null)
			tab.menu = group;
	}

	public function UIEvent(id:String, sender:Dynamic):Void
	{
		getEvent(id, sender, null, null);
	}

	function loadChar(isDad:Bool, blahBlahBlah:Bool = true)
	{
		var i:Int = charLayer.members.length - 1;
		while (i >= 0)
		{
			var memb:Character = charLayer.members[i];
			if (memb != null)
			{
				memb.kill();
				charLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		charLayer.clear();
		ghostChar = new Character(0, 0, daAnim, !isDad);
		ghostChar.debugMode = true;
		ghostChar.alpha = 0.6;

		char = new Character(0, 0, daAnim, !isDad);
		char.debugMode = true;

		charLayer.add(ghostChar);
		charLayer.add(char);

		char.setPosition(char.positionArray[0] + OFFSET_X + 100, char.positionArray[1]);

		if (blahBlahBlah)
		{
			genBoyOffsets();
		}
		reloadCharacterOptions();
		reloadBGs();
		updatePointerPos();
		reloadCharacterImage();
	}

	function updatePointerPos()
	{
		var x:Float = char.getMidpoint().x;
		var y:Float = char.getMidpoint().y;
		if (!char.isPlayer)
		{
			x += 150 + char.cameraPosition[0];
		}
		else
		{
			x -= 100 + char.cameraPosition[0];
		}
		y -= 100 - char.cameraPosition[1];

		x -= cameraFollowPointer.width / 2;
		y -= cameraFollowPointer.height / 2;
		cameraFollowPointer.setPosition(x, y);
	}

	function findAnimationByName(name:String):AnimArray
	{
		for (anim in char.animationsArray)
		{
			if (anim.anim == name)
			{
				return anim;
			}
		}
		return null;
	}

	function returniconformat(icon:String):Character.IconData
	{
		var iconData:Character.IconData = {
			healthicon: icon,
			iconOffsets: []
		};
		return iconData;
	}

	function reloadCharacterOptions()
	{
		if (mainBox != null)
		{
			imageInputText.text = char.imageFile;
			imagesInputText.text = '';
			if (char.animationsArray[curAnim] != null && char.animationsArray[curAnim].frames != null)
			{
				imagesInputText.text = char.animationsArray[curAnim].frames;
			}
			healthIconInputText.text = char.icondata.healthicon;
			singDurationStepper.value = char.singDuration;
			scaleStepper.value = char.jsonScale;
			flipXCheckBox.checked = char.originalFlipX;
			noAntialiasingCheckBox.checked = char.noAntialiasing;
			leHealthIcon.changeIcon(returniconformat(healthIconInputText.text));
			ghostHealthIcon.changeIcon(returniconformat(healthIconInputText.text));
			positionXStepper.value = char.positionArray[0];
			positionYStepper.value = char.positionArray[1];
			positionCameraXStepper.value = char.cameraPosition[0];
			positionCameraYStepper.value = char.cameraPosition[1];
			if (animtype != null && char.animstyle != null)
				animtype.selectedLabel = char.animstyle;
			loadCurrentCharacterIconOffsets();
			if (iconAnimDropDown != null)
				iconAnimDropDown.selectedLabel = 'Neutral';
			if (ghostIconDropDown != null)
			{
				ghostIconDropDown.selectedLabel = '';
				ghostHealthIcon.visible = false;
				leHealthIcon.alpha = 1;
				var iconAnimNames:Array<String> = leHealthIcon.animation.getNameList();
				iconAnimDropDown.list = iconAnimNames;
				var ghostIconAnims:Array<String> = [''];
				for (name in iconAnimNames)
					ghostIconAnims.push(name);
				ghostIconDropDown.list = ghostIconAnims;
			}
			reloadIconOffsetSteppers();
			syncGhostHealthIconOffsets();
			reloadAnimationDropDown();
			updatePresence();
		}
	}

	function reloadAnimationDropDown()
	{
		var anims:Array<String> = [];
		var ghostAnims:Array<String> = [''];
		for (anim in char.animationsArray)
		{
			anims.push(anim.anim);
			ghostAnims.push(anim.anim);
		}
		if (anims.length < 1)
			anims.push('NO ANIMATIONS'); // Prevents crash

		animationDropDown.list = anims;
		ghostDropDown.list = ghostAnims;
		reloadGhost();
	}

	function reloadGhost()
	{
		ghostChar.frames = char.frames;
		for (anim in char.animationsArray)
		{
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; // Bruh
			var animIndices:Array<Int> = anim.indices;
			if (animIndices != null && animIndices.length > 0)
			{
				ghostChar.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
			}
			else
			{
				ghostChar.animation.addByPrefix(animAnim, animName, animFps, animLoop);
			}

			if (anim.offsets != null && anim.offsets.length > 1)
			{
				ghostChar.addOffset(anim.anim, anim.offsets);
			}
		}

		char.alpha = 0.85;
		ghostChar.visible = true;
		if (ghostDropDown == null || ghostDropDown.selectedLabel == '')
		{
			ghostChar.visible = false;
			char.alpha = 1;
		}
		ghostChar.color = 0xFF666688;
		ghostChar.antialiasing = char.antialiasing;
	}

	function reloadCharacterDropDown()
	{
		var charsLoaded:Map<String, Bool> = new Map();

		characterList = [];
		var directories:Array<String> = [
			Paths.mods('data/characters/'),
			Paths.mods(Paths.currentModDirectory + '/data/characters/'),
			Paths.getPreloadPath('data/characters/')
		];
		for (mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/data/characters/'));
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var charToCheck:String = file.substr(0, file.length - 5);
						if (!charsLoaded.exists(charToCheck))
						{
							characterList.push(charToCheck);
							charsLoaded.set(charToCheck, true);
						}
					}
				}
			}
		}

		charDropDown.list = characterList;
		charDropDown.selectedLabel = daAnim;
	}

	function updatePresence()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + daAnim, leHealthIcon.getCharacter());
		#end
	}

	override function update(elapsed:Float)
	{
		MusicBeatState.camBeat = FlxG.camera;
		if (char.animationsArray[curAnim] != null)
		{
			textAnim.text = char.animationsArray[curAnim].anim;

			var curAnim:FlxAnimation = char.animation.getByName(char.animationsArray[curAnim].anim);
			if (curAnim == null || curAnim.frames.length < 1)
			{
				textAnim.text += ' (ERROR!)';
			}
		}
		else
		{
			textAnim.text = '';
		}

		var inputTexts:Array<PsychUIInputText> = [
			animationInputText,
			imageInputText,
			healthIconInputText,
			animationNameInputText,
			animationIndicesInputText,
			imagesInputText
		];
		for (i in 0...inputTexts.length)
		{
			if (PsychUIInputText.focusOn == inputTexts[i])
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				super.update(elapsed);
				return;
			}
		}

		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;

		if (!Std.isOfType(PsychUIInputText.focusOn, PsychUIDropDownMenu))
		{
			if (FlxG.keys.justPressed.ESCAPE)
			{
				if (goToPlayState)
				{
					MusicBeatState.switchState(new PlayState());
				}
				else
				{
					MusicBeatState.switchState(new editors.MasterEditorMenu());
				}

				return;
			}

			if (FlxG.keys.justPressed.R)
			{
				FlxG.camera.zoom = 1;
			}

			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3)
			{
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
				if (FlxG.camera.zoom > 3)
					FlxG.camera.zoom = 3;
			}
			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1)
			{
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				if (FlxG.camera.zoom < 0.1)
					FlxG.camera.zoom = 0.1;
			}

			if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
			{
				var addToCam:Float = 500 * elapsed;
				if (FlxG.keys.pressed.SHIFT)
					addToCam *= 4;

				if (FlxG.keys.pressed.I)
					camFollow.y -= addToCam;
				else if (FlxG.keys.pressed.K)
					camFollow.y += addToCam;

				if (FlxG.keys.pressed.J)
					camFollow.x -= addToCam;
				else if (FlxG.keys.pressed.L)
					camFollow.x += addToCam;
			}

			if (char.animationsArray.length > 0)
			{
				if (FlxG.keys.justPressed.W)
				{
					curAnim -= 1;
				}

				if (FlxG.keys.justPressed.S)
				{
					curAnim += 1;
				}

				if (curAnim < 0)
					curAnim = char.animationsArray.length - 1;

				if (curAnim >= char.animationsArray.length)
					curAnim = 0;

				if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
				{
					char.playAnim(char.animationsArray[curAnim].anim, true);
					genBoyOffsets();
				}
				if (FlxG.keys.justPressed.T)
				{
					char.animationsArray[curAnim].offsets = [0, 0];

					char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets);
					ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets);
					genBoyOffsets();
				}

				var controlArray:Array<Bool> = [
					FlxG.keys.justPressed.LEFT,
					FlxG.keys.justPressed.RIGHT,
					FlxG.keys.justPressed.UP,
					FlxG.keys.justPressed.DOWN
				];

				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
					{ // this code is shit - god DAM is this hardn to edit - kuru
						var holdShift = FlxG.keys.pressed.SHIFT;
						var multiplier = 1;
						if (holdShift)
							multiplier = 10;

						var arrayVal = 0;
						if (char.flipX)
						{
							arrayVal = 2;
						}
						if (i > 1)
						{
							trace("modifying y axis");
							arrayVal = 1;
							if (char.flipX)
							{
								arrayVal = 3;
							}
						}

						var negaMult:Int = 1;
						if (i % 2 == 1)
							negaMult = -1;

						char.animationsArray[curAnim].offsets[arrayVal] += negaMult * multiplier;
						trace("modifying " + char.animationsArray[curAnim].offsets[arrayVal] + "axis by " + (negaMult * multiplier));

						char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets);
						ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets);

						char.playAnim(char.animationsArray[curAnim].anim, false);
						if (ghostChar.animation.curAnim != null
							&& char.animation.curAnim != null
							&& char.animation.curAnim.name == ghostChar.animation.curAnim.name)
						{
							ghostChar.playAnim(char.animation.curAnim.name, false);
						}
						genBoyOffsets();
					}
				}
			}
		}
		// camMenu.zoom = FlxG.camera.zoom;
		ghostChar.setPosition(char.x, char.y);
		super.update(elapsed);
	}

	#if desktop
	var _savingDialog:Bool = false;
	#end

	/*private function saveOffsets()
		{
			var data:String = '';
			for (anim => offsets in char.animOffsets) {
				data += anim + ' ' + offsets[0] + ' ' + offsets[1] + '\n';
			}

			if (data.length > 0)
			{
				_file = new FileReference();
				_file.addEventListener(Event.COMPLETE, onSaveComplete);
				_file.addEventListener(Event.CANCEL, onSaveCancel);
				_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
				_file.save(data, daAnim + "Offsets.txt");
			}
	}*/
	function saveCharacter():Void
	{
		syncIconOffsetDataFromHealthIcon();
		if (char.icondata == null)
		{
			char.icondata = returniconformat(healthIconInputText != null ? healthIconInputText.text : Constants.DEFAULT_HEALTH_ICON);
		}
		if (char.icondata.iconOffsets == null)
		{
			char.icondata.iconOffsets = [];
		}
		char.icondata.healthicon = healthIconInputText.text;
		char.icondata.iconOffsets = iconOffsetsData.copy();
		var json = {
			"animations": char.animationsArray,
			"image": char.imageFile,
			"scale": char.jsonScale,
			"sing_duration": char.singDuration,
			"iconData": char.icondata,
			"animtype": char.animstyle,

			"position": char.positionArray,
			"camera_position": char.cameraPosition,

			"flip_x": char.originalFlipX,
			"no_antialiasing": char.noAntialiasing,
			"healthbar_colors": char.healthColorArray
		};

		var data:String = Json.stringify(json, "\t");

		if (data != null && data.length > 0)
		{
			#if desktop
			saveTextToFile(daAnim + ".json", data);
			#end
		}
	}

	#if desktop
	private function saveTextToFile(defaultFileName:String, data:String):Void
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
					path += ext;
			}
			File.saveContent(path, data);
			FlxG.log.notice("Successfully saved character: " + path);
		}, null, defaultFileName);
	}
	#end

	function ClipboardAdd(prefix:String = ''):String
	{
		if (prefix.toLowerCase().endsWith('v')) // probably copy paste attempt
		{
			prefix = prefix.substring(0, prefix.length - 1);
		}

		var text:String = prefix + Clipboard.text.replace('\n', '');
		return text;
	}
}
