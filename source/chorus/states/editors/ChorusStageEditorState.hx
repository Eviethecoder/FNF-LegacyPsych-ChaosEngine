package chorus.states.editors;

import flixel.FlxG;
import lime.ui.FileDialogFilter;
import imgui.ImGui;
import imgui.ImGui.ImGuiWindowFlags as WindowFlags;
import chorus.objects.misc.FlxImGui;
import imgui.BoolPointer;
import chorus.backend.base.MusicBeatState;
import chorus.backend.assets.Paths;
import chorus.backend.assets.data.StageData;
import chorus.objects.misc.FunkinSprite;
import chorus.objects.stages.BGSprite;
import chorus.objects.stages.FunkinBackdrop;
import chorus.states.MasterEditorMenu;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import sys.FileSystem;
#if FEATURE_DISCORD_RPC
import chorus.backend.api.Discord.DiscordClient;
#end
#if desktop
import lime.app.Application;
import lime.ui.FileDialog;
#end

using StringTools;

class ChorusStageEditorState extends MusicBeatState
{
	var imgui:Int = -1;
	var isBeginningWindowOpen:Bool = true;
	var _savingDialog:Bool = false;
	var curStage:String = "";

	var editorWindowOpen:Bool = false;

	var stageData:StageFile;
	var propLayer:FlxTypedGroup<FunkinSprite>;
	var markerLayer:FlxTypedGroup<FunkinSprite>;
	var markerTextLayer:FlxTypedGroup<FlxText>;
	var stageList:Array<String> = [];
	var stagecam:FlxCamera;
	var camFollow:FlxObject;
	var selectedStage:Int = 0;

	public function new()
	{
		FlxG.mouse.visible = true;
		super();

		editorWindowOpen = false;
		imgui = FlxImGui.register(createWindows);
	}

	override function create()
	{
		reloadStageList();
		if (stageList.length > 0)
			curStage = stageList[selectedStage];

		propLayer = new FlxTypedGroup<FunkinSprite>();
		add(propLayer);
		markerLayer = new FlxTypedGroup<FunkinSprite>();
		add(markerLayer);
		markerTextLayer = new FlxTypedGroup<FlxText>();
		add(markerTextLayer);

		stagecam = new FlxCamera();
		FlxG.cameras.reset(stagecam);
		FlxG.cameras.setDefaultDrawTarget(stagecam, true);

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);
		stagecam.follow(camFollow);

		loadStageFromData(curStage);

		super.create();
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
		FlxImGui.newFrame(elapsed);

		if (!FlxImGui.isImGuiReady())
			return;
	}

	public function createWindows():Void
	{
		if (ImGui.beginMainMenuBar())
		{
			if (ImGui.beginMenu("Editor Window", true))
			{
				if (ImGui.menuItem("Show Editor window", "", editorWindowOpen, true))
					editorWindowOpen = !editorWindowOpen;
				ImGui.endMenu();
			}
			ImGui.endMainMenuBar();
		}
		if (isBeginningWindowOpen)
		{
			if (ImGui.begin("Stage Editor - Welcome", isBeginningWindowOpen, WindowFlags.NoCollapse | WindowFlags.NoResize | WindowFlags.NoMove))
			{
				if (ImGui.button("Open from file test..."))
				{
					#if desktop
					if (_savingDialog)
						return;
					_savingDialog = true;
					FileDialog.openFile(Application.current.window, "Open from file...", function(path:Array<String>, _)
					{
						_savingDialog = false;
						FlxG.log.notice("File open success!!");
					}, [new FileDialogFilter("Chorus Stage File", "pcstg")], curStage + '.pcstg');
					#end
				}
			}
			ImGui.end();
		}
		if (editorWindowOpen)
		{
			renderEditorWindow();
		}
	}

	function renderEditorWindow():Void
	{
		if (ImGui.begin("Editor Window", editorWindowOpen))
		{
			ImGui.textUnformatted("Current stage: " + curStage);
			if (ImGui.button("Reload Stage"))
				loadStageFromData(curStage);
			if (ImGui.button("Refresh Stage List"))
				reloadStageList();
			ImGui.textUnformatted("Stages:");
				if (stageList.length > 0 && ImGui.beginCombo("Stages", stageList[selectedStage], 0))
					{
						for (i in 0...stageList.length)
						{
							var isSelected = selectedStage == i;
							if (ImGui.selectable(stageList[i], isSelected, 0, ImVec2.create()) && selectedStage != i)
							{

								selectedStage = i;
								loadStageFromData(stageList[selectedStage]);
							}
						}
						ImGui.endCombo();
					}
		}
		ImGui.end();
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

	function loadStageFromData(stageName:String):Void
	{
		if (stageName == null || stageName.length < 1)
		{
			return;
		}

		var file:StageFile = StageData.getStageFile(stageName);
		if (file == null)
		{
			FlxG.log.warn('Failed to load stage: ' + stageName + ' (check data/stages/' + stageName + '.json)');
			clearPreviewSprites();
			return;
		}

		stageData = file;
		curStage = stageName;
		rebuildPreviewFromJson();

		#if FEATURE_DISCORD_RPC
		DiscordClient.changePresence("Stage Editor", "Editing: " + curStage);
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
						var axsis:FlxAxes = FlxAxes.NONE;
						switch (prop.repeatAxes.toLowerCase())
						{
							case 'x':
								axsis = FlxAxes.X;
							case 'y':
								axsis = FlxAxes.Y;
							case 'xy':
								axsis = FlxAxes.XY;
							default:
								axsis = FlxAxes.NONE;
						}
						var bgSprite:FunkinBackdrop = new FunkinBackdrop(stageData.directory + '/' + prop.path, axsis, prop.spacing[0], prop.spacing[1],
							prop.animations);

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
}
