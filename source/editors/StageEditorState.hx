package editors;

#if desktop
import Discord.DiscordClient;
import lime.app.Application;
import lime.ui.FileDialog;
#end
import objects.FunkinSprite;
import backend.ui.*;
import objects.FunkinBackdrop;
import flixel.util.FlxAxes;
import data.StageData;
import flixel.FlxObject;
import flixel.FlxCamera;
import backend.ui.PsychUIEventHandler;
import backend.ui.Prompt.BasePrompt;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.display.BlendMode;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;

using StringTools;

class StageEditorState extends MusicBeatState implements PsychUIEvent
{
	static final PROP_TYPES:Array<String> = ['BGSprite', 'FunkinBackdrop', 'ColorSprite'];
	static final PROP_BLEND_MODES:Array<String> = [
		'nan',
		'normal',
		'add',
		'alpha',
		'darken',
		'difference',
		'erase',
		'hardlight',
		'invert',
		'layer',
		'lighten',
		'multiply',
		'overlay',
		'screen',
		'shader',
		'subtract'
	];
	static final PROP_REPEAT_AXES:Array<String> = ['none', 'x', 'y', 'xy'];

	var stageData:StageFile;
	var propLayer:FlxTypedGroup<FunkinSprite>;
	var markerLayer:FlxTypedGroup<FunkinSprite>;
	var markerTextLayer:FlxTypedGroup<FlxText>;
	var stageList:Array<String> = [];
	var ispixelstage:PsychUICheckBox;
	var curStage:String = 'Red Alert';

	var helpText:String = 'Stage Editor Help:\n\n- Use the Stage Data tab to select a stage and edit its properties.\n- Use the Props tab to add, edit, or remove props from the stage.\n- Use the Characters tab to manage characters in the stage (if implemented).\n- Save your changes using the Save Stage button.\n- Reload the stage data using the Reload Stage button.\n- Refresh the list of stages using the Refresh List button.\n- Use the upper box menu for additional options like adding new sprites or accessing help.';

	var infoText:FlxText;
	var uiBox:PsychUIBox;
	var stageDropDown:PsychUIDropDownMenu;
	var camFollow:FlxObject;
	var stagecam:FlxCamera;
	var hudcam:FlxCamera;
	var stageDirectory:PsychUIInputText;
	var propDropDown:PsychUIDropDownMenu;
	var propAnimationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var animationNameInputText:PsychUIInputText;
	var animationIndicesInputText:PsychUIInputText;
	var animationNameFramerate:PsychUINumericStepper;
	var animationLoopCheckBox:PsychUICheckBox;
	var propNameInputText:PsychUIInputText;
	var propPositionXStepper:PsychUINumericStepper;
	var propPositionYStepper:PsychUINumericStepper;
	var propScaleXStepper:PsychUINumericStepper;
	var propScaleYStepper:PsychUINumericStepper;
	var propPathInputText:PsychUIInputText;
	var propTypeDropDown:PsychUIDropDownMenu;
	var propBlendDropDown:PsychUIDropDownMenu;
	var propRepeatAxesDropDown:PsychUIDropDownMenu;
	var propZIndexStepper:PsychUINumericStepper;
	var propAlphaStepper:PsychUINumericStepper;
	var propAngleStepper:PsychUINumericStepper;
	var propScrollXStepper:PsychUINumericStepper;
	var propScrollYStepper:PsychUINumericStepper;
	var propVelocityXStepper:PsychUINumericStepper;
	var propVelocityYStepper:PsychUINumericStepper;
	var propSpacingXStepper:PsychUINumericStepper;
	var propSpacingYStepper:PsychUINumericStepper;
	var _savingDialog:Bool = false;
	var upperBox:PsychUIBox;

	override function create()
	{
		reloadStageList();
		if (stageList.length > 0)
			curStage = stageList[0];

		propLayer = new FlxTypedGroup<FunkinSprite>();
		add(propLayer);
		markerLayer = new FlxTypedGroup<FunkinSprite>();
		add(markerLayer);
		markerTextLayer = new FlxTypedGroup<FlxText>();
		add(markerTextLayer);

		stagecam = new FlxCamera();

		hudcam = new FlxCamera();
		hudcam.bgColor.alpha = 0;

		FlxG.cameras.reset(stagecam);
		FlxG.cameras.add(hudcam, false);

		FlxG.cameras.setDefaultDrawTarget(stagecam, true);

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);
		stagecam.follow(camFollow);

		propLayer.cameras = [stagecam];
		markerLayer.cameras = [stagecam];
		markerTextLayer.cameras = [stagecam];

		uiBox = new PsychUIBox(20, 80, 560, 580, ['Stage Data', 'Props', 'Characters']);
		uiBox.scrollFactor.set();
		uiBox.selectedName = 'Stage Data';
		add(uiBox);
		uiBox.cameras = [hudcam];
		upperBox = new PsychUIBox(0, 40, 200, 300, ['Objects', 'File', 'Help']);
		upperBox.scrollFactor.set();
		upperBox.isMinimized = true;
		upperBox.minimizeOnFocusLost = true;
		upperBox.canMove = false;
		upperBox.bg.visible = false;
		upperBox.selectedName = 'Objects';
		add(upperBox);
		upperBox.cameras = [hudcam];
		buildEditorUI();
		buildPropUI();
		buildUpperBoxUI();
		// buildCharacterUI();
		loadStageFromData(curStage);

		#if desktop
		DiscordClient.changePresence("Stage Editor", "Editing: " + curStage);
		#end

		super.create();
	}

	function buildUpperBoxUI():Void
	{
		var objectsTab = upperBox.getTab('Objects');
		if (objectsTab != null && objectsTab.menu != null)
		{
			var addPropButton = new PsychUIButton(0, 1, '  Add Sprite', function()
			{
				openCreatePropPopup();
			}, Std.int(objectsTab.width));
			addPropButton.text.alignment = LEFT;
			objectsTab.menu.add(addPropButton);
		}

		var helpTab = upperBox.getTab('Help');
		if (helpTab != null && helpTab.menu != null)
		{
			var helpButton = new PsychUIButton(0, 1, '  Help', function()
			{
				// createHelpPopup(helpText, 560, 510);
			}, Std.int(helpTab.width));
			helpButton.text.alignment = LEFT;
			helpTab.menu.add(helpButton);
		}

		var fileTab = upperBox.getTab('File');
		if (fileTab != null && fileTab.menu != null)
		{
			var buttonWidth:Int = Std.int(fileTab.width);
			var saveButton = new PsychUIButton(0, 1, '  Save Stage', saveStage, buttonWidth);
			saveButton.text.alignment = LEFT;
			fileTab.menu.add(saveButton);

			var reloadButton = new PsychUIButton(0, 22, '  Reload Stage', function()
			{
				loadStageFromData(curStage);
			}, buttonWidth);
			reloadButton.text.alignment = LEFT;
			fileTab.menu.add(reloadButton);

			var refreshButton = new PsychUIButton(0, 43, '  Refresh Stage List', function()
			{
				reloadStageList();
				stageDropDown.list = stageList;
				stageDropDown.selectedLabel = curStage;
			}, buttonWidth);
			refreshButton.text.alignment = LEFT;
			fileTab.menu.add(refreshButton);
		}
	}

	function openCreatePropPopup():Void
	{
		if (stageData == null)
			return;

		upperBox.isMinimized = true;
		openSubState(new BasePrompt(560, 510, 'New Stage Sprite', function(prompt:BasePrompt)
		{
			var popupX:Float = prompt.bg.x + 15;
			var popupY:Float = prompt.bg.y + 55;
			var nameInput = new PsychUIInputText(popupX, popupY + 20, 150, 'newProp', 8);
			var pathInput = new PsychUIInputText(popupX, popupY + 70, 250, '', 8);
			var typeDropDown = new PsychUIDropDownMenu(popupX, popupY + 120, PROP_TYPES, null, 150);
			var blendDropDown = new PsychUIDropDownMenu(popupX + 170, popupY + 120, PROP_BLEND_MODES, null, 150);
			var repeatAxesDropDown = new PsychUIDropDownMenu(popupX + 340, popupY + 120, PROP_REPEAT_AXES, null, 100);
			var positionXStepper = new PsychUINumericStepper(popupX, popupY + 170, 5, 0, -10000, 10000, 0);
			var positionYStepper = new PsychUINumericStepper(popupX + 80, popupY + 170, 5, 0, -10000, 10000, 0);
			var scaleXStepper = new PsychUINumericStepper(popupX + 170, popupY + 170, 0.05, 1, -10, 10, 2);
			var scaleYStepper = new PsychUINumericStepper(popupX + 250, popupY + 170, 0.05, 1, -10, 10, 2);
			var zIndexStepper = new PsychUINumericStepper(popupX, popupY + 220, 1, 0, -1000, 1000, 0);
			var alphaStepper = new PsychUINumericStepper(popupX + 80, popupY + 220, 0.05, 1, 0, 1, 2);
			var angleStepper = new PsychUINumericStepper(popupX + 160, popupY + 220, 1, 0, -360, 360, 1);
			var scrollXStepper = new PsychUINumericStepper(popupX, popupY + 270, 0.05, 1, -10, 10, 2);
			var scrollYStepper = new PsychUINumericStepper(popupX + 80, popupY + 270, 0.05, 1, -10, 10, 2);
			var velocityXStepper = new PsychUINumericStepper(popupX + 170, popupY + 270, 1, 0, -1000, 1000, 1);
			var velocityYStepper = new PsychUINumericStepper(popupX + 250, popupY + 270, 1, 0, -1000, 1000, 1);
			var spacingXStepper = new PsychUINumericStepper(popupX + 340, popupY + 270, 1, 0, -1000, 1000, 1);
			var spacingYStepper = new PsychUINumericStepper(popupX + 420, popupY + 270, 1, 0, -1000, 1000, 1);
			var cancelButton = new PsychUIButton(popupX + 280, popupY + 325, 'Cancel', prompt.close, 70, 20);
			var createButton = new PsychUIButton(popupX + 195, popupY + 325, 'Create', function()
			{
				var propName:String = nameInput.text.trim();
				if (propName.length < 1)
					return;
				if (stageData.props == null)
					stageData.props = [];
				stageData.props.push({
					name: propName,
					path: pathInput.text.trim(),
					PropType: typeDropDown.selectedLabel,
					position: [positionXStepper.value, positionYStepper.value],
					scale: [scaleXStepper.value, scaleYStepper.value],
					scroll: [scrollXStepper.value, scrollYStepper.value],
					velocity: [velocityXStepper.value, velocityYStepper.value],
					spacing: [spacingXStepper.value, spacingYStepper.value],
					repeatAxes: repeatAxesDropDown.selectedLabel,
					zIndex: Math.round(zIndexStepper.value),
					alpha: alphaStepper.value,
					angle: angleStepper.value,
					blend: blendDropDown.selectedLabel,
					animations: null
				});
				rebuildPreviewFromJson();
				reloadPropDropDown();
				propDropDown.selectedIndex = stageData.props.length - 1;
				loadSelectedPropUI();
				reloadPropAnimationDropDown();
				prompt.close();
			}, 80, 20);

			prompt.add(new FlxText(popupX, popupY, 0, 'Sprite Name'));
			prompt.add(new FlxText(popupX, popupY + 50, 0, 'Image Path (or ColorSprite color)'));
			prompt.add(new FlxText(popupX, popupY + 100, 0, 'Type'));
			prompt.add(new FlxText(popupX + 170, popupY + 100, 0, 'Blend'));
			prompt.add(new FlxText(popupX + 340, popupY + 100, 0, 'Repeat Axes'));
			prompt.add(new FlxText(popupX, popupY + 150, 0, 'Position X/Y'));
			prompt.add(new FlxText(popupX + 170, popupY + 150, 0, 'Scale X/Y'));
			prompt.add(new FlxText(popupX, popupY + 200, 0, 'Z Index'));
			prompt.add(new FlxText(popupX + 80, popupY + 200, 0, 'Alpha'));
			prompt.add(new FlxText(popupX + 160, popupY + 200, 0, 'Angle'));
			prompt.add(new FlxText(popupX, popupY + 250, 0, 'Scroll X/Y'));
			prompt.add(new FlxText(popupX + 170, popupY + 250, 0, 'Velocity X/Y'));
			prompt.add(new FlxText(popupX + 340, popupY + 250, 0, 'Spacing X/Y'));
			prompt.add(nameInput);
			prompt.add(pathInput);
			prompt.add(positionXStepper);
			prompt.add(positionYStepper);
			prompt.add(scaleXStepper);
			prompt.add(scaleYStepper);
			prompt.add(zIndexStepper);
			prompt.add(alphaStepper);
			prompt.add(angleStepper);
			prompt.add(scrollXStepper);
			prompt.add(scrollYStepper);
			prompt.add(velocityXStepper);
			prompt.add(velocityYStepper);
			prompt.add(spacingXStepper);
			prompt.add(spacingYStepper);
			prompt.add(createButton);
			prompt.add(cancelButton);
			prompt.add(typeDropDown);
			prompt.add(blendDropDown);
			prompt.add(repeatAxesDropDown);
		}));
	}

	function reloadStageList():Void
	{
		stageList = [];
		var loaded:Map<String, Bool> = new Map();

		#if MODS_ALLOWED
		var dirs:Array<String> = [Paths.getPreloadPath('data/stages/')];
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
		{
			dirs.unshift(Paths.modFolders('data/stages/'));
		}

		for (dir in dirs)
		{
			for (file in FileSystem.readDirectory(dir))
			{
				if (!file.endsWith('.json'))
					continue;
				var name:String = file.substr(0, file.length - 5);
				if (!loaded.exists(name))
				{
					loaded.set(name, true);
					stageList.push(name);
				}
			}
		}
		#end

		if (stageList.length < 1)
		{
			stageList = ['test'];
		}
	}

	function buildEditorUI():Void
	{
		var group = new flixel.group.FlxSpriteGroup();

		stageDropDown = new PsychUIDropDownMenu(15, 35, stageList, function(id:Int, selected:String)
		{
			if (selected != null && selected.length > 0)
			{
				curStage = selected;
				loadStageFromData(curStage);
			}
		}, 160);

		var reloadButton:PsychUIButton = new PsychUIButton(190, 32, 'Reload Stage', function()
		{
			loadStageFromData(curStage);
		}, 110, 20);
		var saveButton:PsychUIButton = new PsychUIButton(315, 32, 'Save Stage', function()
		{
			saveStage();
		}, 100, 20);

		stageDirectory = new PsychUIInputText(15, 75, 180, 'unknown');
		ispixelstage = new PsychUICheckBox(15, 190, 'is pixel stage', 120);
		ispixelstage.checked = false;
		var refreshListButton:PsychUIButton = new PsychUIButton(stageDirectory.x, stageDirectory.y + 80, 'Refresh List', function()
		{
			reloadStageList();
			stageDropDown.list = stageList;
			if (stageList.indexOf(curStage) < 0)
			{
				curStage = stageList[0];
			}
			stageDropDown.selectedLabel = curStage;
			loadStageFromData(curStage);
		}, 90, 20);
		group.add(reloadButton);
		group.add(saveButton);
		group.add(new FlxText(stageDirectory.x, stageDirectory.y - 15, 0, 'Stage Directory'));
		group.add(stageDirectory);
		group.add(refreshListButton);
		group.add(ispixelstage);
		group.add(stageDropDown);
		group.cameras = [hudcam];
		for (member in group.members)
		{
			if (member != null)
				member.cameras = [hudcam];
		}

		var tab = uiBox.getTab('Stage Data');
		if (tab != null)
			tab.menu = group;

		if (stageDropDown != null && curStage != null)
		{
			stageDropDown.selectedLabel = curStage;
		}
	}

	function loadStageFromData(stageName:String):Void
	{
		if (stageName == null || stageName.length < 1)
		{
			return;
		}

		var file:StageFile = StageData.getStageFile(stageName);
		if (file == null)
		{
			infoText.text = 'STAGE EDITOR (STAGE DATA)\nFailed to load stage: ' + stageName + '\nCheck data/stages/' + stageName + '.json';
			clearPreviewSprites();
			return;
		}

		stageData = file;
		curStage = stageName;
		rebuildPreviewFromJson();
		reloadPropDropDown();

		if (infoText != null)
		{
			var propCount:Int = file.props != null ? file.props.length : 0;
			var hasGF:Bool = !file.hide_girlfriend;
			infoText.text = 'STAGE EDITOR (STAGE DATA)\n' + 'Stage: ' + curStage + ' | Zoom: ' + file.defaultZoom + ' | Props: ' + propCount + ' | Has GF: '
				+ hasGF + '\nDirectory: ' + file.directory + '\nCamera Focus: ' + file.camera_focus + ' | Focus Offsets: ' + file.focusOffsets
				+ '\nESC: Return to Editor Menu';
		}

		stageDirectory.text = file.directory;
		#if desktop
		DiscordClient.changePresence("Stage Editor", "Editing: " + curStage);
		#end
	}

	function buildPropUI():Void
	{
		var group = new flixel.group.FlxSpriteGroup();
		propDropDown = new PsychUIDropDownMenu(15, 25, ['NO PROPS'], function(selectedProp:Int, pressed:String)
		{
			loadSelectedPropUI();
			reloadPropAnimationDropDown();
		}, 180);
		propAnimationDropDown = new PsychUIDropDownMenu(15, 75, ['NO ANIMATIONS'], function(selectedAnimation:Int, pressed:String)
		{
			loadSelectedPropAnimationUI();
		}, 180);

		propNameInputText = new PsychUIInputText(215, 25, 150, '', 8);
		propNameInputText.onChange = function(old:String, current:String)
		{
			var prop = getSelectedProp();
			if (prop != null)
			{
				prop.name = current;
				reloadPropDropDown();
			}
		};
		propPositionXStepper = new PsychUINumericStepper(215, 75, 5, 0, -10000, 10000, 0);
		propPositionYStepper = new PsychUINumericStepper(295, 75, 5, 0, -10000, 10000, 0);
		propScaleXStepper = new PsychUINumericStepper(215, 125, 0.05, 1, -10, 10, 2);
		propScaleYStepper = new PsychUINumericStepper(295, 125, 0.05, 1, -10, 10, 2);
		propPathInputText = new PsychUIInputText(15, 135, 180, '', 8);
		propTypeDropDown = new PsychUIDropDownMenu(215, 175, PROP_TYPES, null, 150);
		propBlendDropDown = new PsychUIDropDownMenu(15, 175, PROP_BLEND_MODES, null, 180);
		propRepeatAxesDropDown = new PsychUIDropDownMenu(385, 175, PROP_REPEAT_AXES, null, 100);
		propZIndexStepper = new PsychUINumericStepper(15, 225, 1, 0, -1000, 1000, 0);
		propAlphaStepper = new PsychUINumericStepper(95, 225, 0.05, 1, 0, 1, 2);
		propAngleStepper = new PsychUINumericStepper(175, 225, 1, 0, -360, 360, 1);
		propScrollXStepper = new PsychUINumericStepper(15, 275, 0.05, 1, -10, 10, 2);
		propScrollYStepper = new PsychUINumericStepper(95, 275, 0.05, 1, -10, 10, 2);
		propVelocityXStepper = new PsychUINumericStepper(175, 275, 1, 0, -1000, 1000, 1);
		propVelocityYStepper = new PsychUINumericStepper(255, 275, 1, 0, -1000, 1000, 1);
		propSpacingXStepper = new PsychUINumericStepper(335, 275, 1, 0, -1000, 1000, 1);
		propSpacingYStepper = new PsychUINumericStepper(415, 275, 1, 0, -1000, 1000, 1);
		var updateProp = function()
		{
			var prop = getSelectedProp();
			if (prop == null)
				return;
			prop.position = [propPositionXStepper.value, propPositionYStepper.value];
			prop.scale = [propScaleXStepper.value, propScaleYStepper.value];
			prop.path = propPathInputText.text.trim();
			prop.PropType = propTypeDropDown.selectedLabel;
			prop.blend = propBlendDropDown.selectedLabel;
			prop.repeatAxes = propRepeatAxesDropDown.selectedLabel;
			prop.zIndex = Math.round(propZIndexStepper.value);
			prop.alpha = propAlphaStepper.value;
			prop.angle = propAngleStepper.value;
			prop.scroll = [propScrollXStepper.value, propScrollYStepper.value];
			prop.velocity = [propVelocityXStepper.value, propVelocityYStepper.value];
			prop.spacing = [propSpacingXStepper.value, propSpacingYStepper.value];
			rebuildPreviewFromJson();
		};
		propPathInputText.onChange = function(old:String, current:String) updateProp();
		propTypeDropDown.onSelect = function(selected:Int, value:String) updateProp();
		propBlendDropDown.onSelect = function(selected:Int, value:String) updateProp();
		propRepeatAxesDropDown.onSelect = function(selected:Int, value:String) updateProp();
		propPositionXStepper.onValueChange = propPositionYStepper.onValueChange = updateProp;
		propScaleXStepper.onValueChange = propScaleYStepper.onValueChange = updateProp;
		propZIndexStepper.onValueChange = propAlphaStepper.onValueChange = propAngleStepper.onValueChange = updateProp;
		propScrollXStepper.onValueChange = propScrollYStepper.onValueChange = updateProp;
		propVelocityXStepper.onValueChange = propVelocityYStepper.onValueChange = updateProp;
		propSpacingXStepper.onValueChange = propSpacingYStepper.onValueChange = updateProp;

		animationInputText = new PsychUIInputText(15, 335, 150, '', 8);
		animationNameInputText = new PsychUIInputText(15, 385, 220, '', 8);
		animationIndicesInputText = new PsychUIInputText(15, 435, 250, '', 8);
		animationNameFramerate = new PsychUINumericStepper(185, 335, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new PsychUICheckBox(250, 384, 'Should it Loop?', 100);

		var addUpdateButton = new PsychUIButton(75, 485, 'Add/Update', function()
		{
			var prop:PropData = getSelectedProp();
			if (prop == null || animationInputText.text.trim().length < 1)
				return;

			if (prop.animations == null)
				prop.animations = [];
			var indices:Array<Int> = [];
			for (indexText in animationIndicesInputText.text.trim().split(','))
			{
				var index:Null<Int> = Std.parseInt(indexText.trim());
				if (index != null && index >= 0)
					indices.push(index);
			}
			var offsets:Array<Float> = [0, 0, 0, 0];
			for (animation in prop.animations)
			{
				if (animation.anim == animationInputText.text)
				{
					offsets = animation.offsets;
					prop.animations.remove(animation);
					break;
				}
			}
			prop.animations.push({
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: Math.round(animationNameFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: offsets,
				frames: null
			});
			rebuildPreviewFromJson();
			reloadPropAnimationDropDown();
		}, 100, 20);
		var removeButton = new PsychUIButton(195, 485, 'Remove', function()
		{
			var prop:PropData = getSelectedProp();
			var selectedAnimation:Int = propAnimationDropDown.selectedIndex;
			if (prop == null || prop.animations == null || selectedAnimation < 0 || selectedAnimation >= prop.animations.length)
				return;
			prop.animations.splice(selectedAnimation, 1);
			rebuildPreviewFromJson();
			reloadPropAnimationDropDown();
		}, 75, 20);

		group.add(new FlxText(propNameInputText.x, propNameInputText.y - 18, 0, 'Prop name:'));
		group.add(new FlxText(propAnimationDropDown.x, propAnimationDropDown.y - 18, 0, 'Animations:'));
		group.add(new FlxText(propPositionXStepper.x, propPositionXStepper.y - 18, 0, 'Position (X/Y):'));
		group.add(new FlxText(propScaleXStepper.x, propScaleXStepper.y - 18, 0, 'Scale (X/Y):'));
		group.add(new FlxText(propPathInputText.x, propPathInputText.y - 18, 0, 'Path:'));
		group.add(new FlxText(propBlendDropDown.x, propBlendDropDown.y - 18, 0, 'Blend:'));
		group.add(new FlxText(propTypeDropDown.x, propTypeDropDown.y - 18, 0, 'Type:'));
		group.add(new FlxText(propRepeatAxesDropDown.x, propRepeatAxesDropDown.y - 18, 0, 'Repeat Axes:'));
		group.add(new FlxText(propZIndexStepper.x, propZIndexStepper.y - 18, 0, 'Z Index:'));
		group.add(new FlxText(propAlphaStepper.x, propAlphaStepper.y - 18, 0, 'Alpha:'));
		group.add(new FlxText(propAngleStepper.x, propAngleStepper.y - 18, 0, 'Angle:'));
		group.add(new FlxText(propScrollXStepper.x, propScrollXStepper.y - 18, 0, 'Scroll X/Y:'));
		group.add(new FlxText(propVelocityXStepper.x, propVelocityXStepper.y - 18, 0, 'Velocity X/Y:'));
		group.add(new FlxText(propSpacingXStepper.x, propSpacingXStepper.y - 18, 0, 'Spacing X/Y:'));
		group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));
		group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));
		group.add(propNameInputText);
		group.add(propPositionXStepper);
		group.add(propPositionYStepper);
		group.add(propScaleXStepper);
		group.add(propScaleYStepper);
		group.add(propPathInputText);
		group.add(propZIndexStepper);
		group.add(propAlphaStepper);
		group.add(propAngleStepper);
		group.add(propScrollXStepper);
		group.add(propScrollYStepper);
		group.add(propVelocityXStepper);
		group.add(propVelocityYStepper);
		group.add(propSpacingXStepper);
		group.add(propSpacingYStepper);
		group.add(animationInputText);
		group.add(animationNameInputText);
		group.add(animationIndicesInputText);
		group.add(animationNameFramerate);
		group.add(animationLoopCheckBox);
		group.add(addUpdateButton);
		group.add(removeButton);
		group.add(new FlxText(propDropDown.x, propDropDown.y - 18, 0, 'Props:'));
		group.add(propDropDown);
		group.add(propAnimationDropDown);
		group.add(propTypeDropDown);
		group.add(propBlendDropDown);
		group.add(propRepeatAxesDropDown);
		group.cameras = [hudcam];
		for (member in group.members)
		{
			if (member != null)
				member.cameras = [hudcam];
		}

		var tab = uiBox.getTab('Props');
		if (tab != null)
			tab.menu = group;
	}

	function getSelectedProp():PropData
	{
		if (stageData == null || stageData.props == null || propDropDown == null)
			return null;
		var selected:Int = propDropDown.selectedIndex;
		return selected >= 0 && selected < stageData.props.length ? stageData.props[selected] : null;
	}

	function reloadPropDropDown():Void
	{
		if (propDropDown == null)
			return;
		var props:Array<String> = [];
		if (stageData != null && stageData.props != null)
		{
			for (index in 0...stageData.props.length)
			{
				var prop:PropData = stageData.props[index];
				props.push(prop.name != null && prop.name.length > 0 ? prop.name : 'Prop ' + (index + 1));
			}
		}
		if (props.length < 1)
			props.push('NO PROPS');
		propDropDown.list = props;
		propDropDown.selectedIndex = 0;
		loadSelectedPropUI();
		reloadPropAnimationDropDown();
	}

	function reloadPropAnimationDropDown():Void
	{
		if (propAnimationDropDown == null)
			return;
		var names:Array<String> = [];
		var prop:PropData = getSelectedProp();
		if (prop != null && prop.animations != null)
		{
			for (animation in prop.animations)
				names.push(animation.anim);
		}
		if (names.length < 1)
			names.push('NO ANIMATIONS');
		propAnimationDropDown.list = names;
		propAnimationDropDown.selectedIndex = 0;
		loadSelectedPropAnimationUI();
	}

	function createHelpPopup(title:String, message:String)
	{
		// var prompt:BasePrompt = new BasePrompt(400, 300, title);
		// var text:FlxText = new FlxText(prompt.bg.x + 15, prompt.bg.y + 55, prompt.bg.width - 30, message);
		// text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		// text.borderSize = 1;
		// prompt.add(text);
		// var cancelButton = new PsychUIButton(prompt.bg.x + 280, prompt.bg.y + 325, 'Cancel', prompt.close, 70, 20);
		// var createButton = new PsychUIButton(prompt.bg.x + 195, prompt.bg.y + 325, 'Create', function()
		// {
		// 	prompt.close();
		// }, 80, 20);

		// openSubState(prompt);
	}

	function loadSelectedPropUI():Void
	{
		var prop = getSelectedProp();
		if (prop == null || propNameInputText == null)
			return;
		propNameInputText.text = prop.name;
		propPositionXStepper.value = prop.position[0];
		propPositionYStepper.value = prop.position[1];
		propScaleXStepper.value = prop.scale[0];
		propScaleYStepper.value = prop.scale[1];
		propPathInputText.text = prop.path;
		propTypeDropDown.selectedLabel = prop.PropType;
		propBlendDropDown.selectedLabel = prop.blend;
		propRepeatAxesDropDown.selectedLabel = prop.repeatAxes;
		propZIndexStepper.value = prop.zIndex;
		propAlphaStepper.value = prop.alpha;
		propAngleStepper.value = prop.angle;
		propScrollXStepper.value = prop.scroll[0];
		propScrollYStepper.value = prop.scroll[1];
		propVelocityXStepper.value = prop.velocity[0];
		propVelocityYStepper.value = prop.velocity[1];
		propSpacingXStepper.value = prop.spacing[0];
		propSpacingYStepper.value = prop.spacing[1];
	}

	function loadSelectedPropAnimationUI():Void
	{
		var prop = getSelectedProp();
		var selectedAnimation:Int = propAnimationDropDown.selectedIndex;
		if (prop == null || prop.animations == null || selectedAnimation < 0 || selectedAnimation >= prop.animations.length)
			return;
		var animation:Character.AnimArray = prop.animations[selectedAnimation];
		animationInputText.text = animation.anim;
		animationNameInputText.text = animation.name;
		animationLoopCheckBox.checked = animation.loop;
		animationNameFramerate.value = animation.fps;
		var indices:String = animation.indices != null ? animation.indices.toString() : '';
		animationIndicesInputText.text = indices.length > 1 ? indices.substr(1, indices.length - 2) : '';
	}

	function saveStage():Void
	{
		if (stageData == null)
			return;
		var data:String = Json.stringify(stageData, "\t");
		#if desktop
		if (_savingDialog)
			return;
		_savingDialog = true;
		FileDialog.saveFile(Application.current.window, function(path:String, _)
		{
			_savingDialog = false;
			if (path == null || path.length < 1)
				return;
			if (!path.endsWith('.json'))
				path += '.json';
			File.saveContent(path, data);
			FlxG.log.notice('Successfully saved stage: ' + path);
		}, null, curStage + '.json');
		#end
	}

	function clearPreviewSprites():Void
	{
		for (daprop in propLayer.members)
		{
			if (daprop != null)
			{
				daprop.kill();
				daprop.destroy();
			}
		}
		propLayer.clear();

		for (daprop in markerLayer.members)
		{
			if (daprop != null)
			{
				daprop.kill();
				daprop.destroy();
			}
		}
		markerLayer.clear();

		for (txt in markerTextLayer.members)
		{
			if (txt != null)
			{
				txt.kill();
				txt.destroy();
			}
		}
		markerTextLayer.clear();
	}

	function getBlendmodeFromString(blend:String)
	{
		trace('looking for blend mode: ' + blend);
		switch (blend.toLowerCase())
		{
			case 'normal':
				return BlendMode.NORMAL;
			case 'layer':
				return BlendMode.LAYER;
			case 'erase':
				return BlendMode.ERASE;
			case 'subtract':
				return BlendMode.SUBTRACT;
			case 'add':
				return BlendMode.ADD;
			case 'multiply':
				return BlendMode.MULTIPLY;
			case 'alpha':
				return BlendMode.ALPHA;
			case 'darken':
				return BlendMode.DARKEN;
			case 'difference':
				return BlendMode.DIFFERENCE;
			case 'invert':
				return BlendMode.INVERT;
			case 'hardlight', 'hard_light', 'hard-light':
				return BlendMode.HARDLIGHT;
			case 'lighten':
				return BlendMode.LIGHTEN;
			case 'overlay':
				return BlendMode.OVERLAY;
			case 'shader':
				return BlendMode.SHADER;
			case 'screen':
				return BlendMode.SCREEN;
		}
		trace('couldnt find blendmode: ' + blend);
		return BlendMode.ADD;
	}

	function rebuildPreviewFromJson():Void
	{
		clearPreviewSprites();
		if (stageData == null)
			return;

		if (stageData.props != null)
		{
			for (prop in stageData.props)
			{
				trace('adding prop: ' + prop.name);
				switch (prop.PropType)
				{
					case 'ColorSprite':
						var bgSprite:FunkinSprite = new FunkinSprite(0, 0);
						bgSprite.setPosition(prop.position[0], prop.position[1]);
						bgSprite.id = prop.name;
						bgSprite.zIndex = prop.zIndex;
						bgSprite.alpha = prop.alpha;
						bgSprite.makeGraphic(Std.int(prop.scale[0]), Std.int(prop.scale[1]), FlxColor.fromString(prop.path));
						bgSprite.velocity.set(prop.velocity[0], prop.velocity[1]);
						bgSprite.angle = prop.angle;
						if (prop.blend != 'nan')
						{
							bgSprite.blend = getBlendmodeFromString(prop.blend);
						}
						propLayer.add(bgSprite);

					case 'BGSprite':
						trace('the prop path is ' + stageData.directory + '/' + prop.path);
						var bgSprite:BGSprite = new BGSprite(stageData.directory + '/' + prop.path, prop.position[0], prop.position[1], prop.scroll[0],
							prop.scroll[1], prop.animations, prop.velocity);
						bgSprite.id = prop.name;
						bgSprite.zIndex = prop.zIndex;
						bgSprite.alpha = prop.alpha;
						bgSprite.scale.set(prop.scale[0], prop.scale[1]);
						bgSprite.angle = prop.angle;
						if (prop.blend != 'nan')
						{
							bgSprite.blend = getBlendmodeFromString(prop.blend);
						}

						propLayer.add(bgSprite);
					case 'FunkinBackdrop':
						var axsis:FlxAxes = FlxAxes.XY;
						trace('the prop repeat axes is ' + prop.repeatAxes.toLowerCase());
						switch (prop.repeatAxes.toLowerCase())
						{
							case 'x':
								axsis = FlxAxes.X;
							case 'y':
								axsis = FlxAxes.Y;
							case 'xy':
								axsis = FlxAxes.XY;
							case 'none':
								axsis = FlxAxes.NONE;
							default:
								axsis = FlxAxes.NONE;
						}
						var bgSprite:FunkinBackdrop = new FunkinBackdrop(stageData.directory + '/' + prop.path, axsis, prop.spacing[0], prop.spacing[1],
							prop.animations);

						trace(bgSprite.repeatAxes + ' is the repeat axes compared to ' + prop.repeatAxes);
						bgSprite.x = prop.position[0];
						bgSprite.y = prop.position[1];
						bgSprite.id = prop.name;
						bgSprite.velocity.set(prop.velocity[0], prop.velocity[1]);
						bgSprite.zIndex = prop.zIndex;
						bgSprite.alpha = prop.alpha;
						bgSprite.scale.set(prop.scale[0], prop.scale[1]);
						bgSprite.angle = prop.angle;
						if (prop.blend != 'nan')
						{
							trace('the prop blend mode is ' + prop.blend);
							bgSprite.blend = getBlendmodeFromString(prop.blend);
						}

						propLayer.add(bgSprite);
				}
			}

			if (stageData.characters != null)
			{
				addCharacterMarker('dad', stageData.characters.dad, FlxColor.RED);
				addCharacterMarker('boyfriend', stageData.characters.boyfriend, FlxColor.CYAN);
				if (stageData.characters.girlfriend != null)
				{
					addCharacterMarker('girlfriend', stageData.characters.girlfriend, FlxColor.PINK);
				}
			}
		}
	}

	function addCharacterMarker(name:String, data:CharacterData, color:FlxColor):Void
	{
		if (data == null || data.position == null || data.position.length < 2)
			return;

		var marker:FunkinSprite = new FunkinSprite(data.position[0], data.position[1]);
		marker.makeGraphic(24, 24, color);
		marker.alpha = 0.9;
		markerLayer.add(marker);

		var label:FlxText = new FlxText(marker.x, marker.y - 16, 0, name, 12);
		label.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		label.borderSize = 1;
		markerTextLayer.add(label);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		// Event callbacks are handled by per-control lambdas for now.
	}

	public function UIEvent(id:String, sender:Dynamic):Void
	{
		getEvent(id, sender, null, null);
	}

	override function update(elapsed:Float)
	{
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
		if (FlxG.keys.justPressed.ESCAPE)
		{
			MusicBeatState.switchState(new MasterEditorMenu());
			return;
		}

		super.update(elapsed);
	}
}
