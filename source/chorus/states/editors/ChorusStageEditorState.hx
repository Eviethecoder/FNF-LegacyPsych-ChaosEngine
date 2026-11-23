package chorus.states.editors;

import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import flixel.FlxG;
import lime.ui.FileDialogFilter;
import haxe.zip.Entry;
import chorus.backend.debug.GameConsole;
import imgui.ImGui;
import chorus.objects.stages.Character.AnimArray;
import imgui.ImGui.ImGuiWindowFlags as WindowFlags;
import chorus.objects.misc.FlxImGui;
import imgui.BoolPointer;
import imgui.TextBuffer;
import chorus.backend.base.MusicBeatState;
import chorus.backend.assets.Paths;
import chorus.backend.assets.data.StageData;
import chorus.objects.misc.FunkinSprite;
import chorus.objects.stages.BGSprite;
import chorus.objects.stages.FunkinBackdrop;
import chorus.states.MasterEditorMenu;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import haxe.io.Bytes;
import json2object.JsonParser;
import openfl.display.BlendMode;
import sys.FileSystem;
import chorus.backend.utils.Ziputil;
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
	var propLayer:FlxTypedGroup<FlxSprite>;
	var markerLayer:FlxTypedGroup<FunkinSprite>;
	var markerTextLayer:FlxTypedGroup<FlxText>;
	var stageList:Array<String> = [];
	var stagecam:FlxCamera;
	var camFollow:FlxObject;
	var propnames:Array<String> = [];
	var selectedProp:Int = 0;

	var proplist:Array<Dynamic> = [];
	var selectedStage:Int = 0;
	var propnamebuffer:TextBuffer = new TextBuffer(256);

	var propZindex:Int = 0;

	var zipassetsmap:Map<String, Dynamic>;
	var zipStagePath:String;

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

		propLayer = new FlxTypedGroup<FlxSprite>();
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
				if (ImGui.button("Open from file test...") && !_savingDialog)
				{
					#if desktop
					_savingDialog = true;
					FileDialog.openFile(Application.current.window, "Open from file...", function(path:Array<String>, _)
					{
						_savingDialog = false;
						if (path == null || path.length == 0)
							return;
						#if sys
						loadStageArchive(path[0]);
						#else
						throw 'Direct file reading by path is not supported on this platform.';
						#end
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
			{
				if (zipStagePath != null)
					loadStageArchive(zipStagePath);
				else
					loadStageFromData(curStage);
			}
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

			if (ImGui.beginTabBar("Stage ", 0))
			{
				// Tab 1: Prop Settings
				if (ImGui.beginTabItem("Prop Settings", null, 0))
				{
					if (propnames.length > 0 && ImGui.beginCombo("Props", propnames[selectedProp], 0))
					{
						for (i in 0...propnames.length)
						{
							var isSelected = selectedProp == i;
							if (ImGui.selectable(propnames[i], isSelected, 0, ImVec2.create()) && selectedProp != i)
							{
								selectedProp = i;
								loadSelectedProp();
								trace('load respected prop info in here: ' + propnames[selectedProp]);
							}
						}
						ImGui.endCombo();
					}

					ImGui.setNextItemWidth(120);
					ImGui.inputInt("Zindex", propZindex);
					ImGui.inputText("Name", propnamebuffer, propnamebuffer.length());
					ImGui.endTabItem();
				}

				// Tab 2: Stage Properties
				if (ImGui.beginTabItem("Stage Properties", null, 0))
				{
					ImGui.textUnformatted("Stage properties go here");
					// Add your stage properties UI here
					ImGui.endTabItem();
				}

				ImGui.endTabBar();
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
		if (selectedStage >= stageList.length)
			selectedStage = 0;
	}

	override function destroy():Void
	{
		if (imgui != -1)
			FlxImGui.unregister(imgui);
		super.destroy();
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

		zipassetsmap = null;
		zipStagePath = null;
		setStageData(stageName, file);
	}

	function loadStageArchive(path:String):Void
	{
		#if sys
		var bytesInput = new haxe.io.BytesInput(sys.io.File.getBytes(path));
		var assets = Ziputil.readStage(haxe.zip.Reader.readZip(bytesInput));
		var json:Bytes = assets.get('json');
		if (json == null)
		{
			FlxG.log.error('Stage archive has no JSON: ' + path);
			return;
		}

		var parser = new JsonParser<StageFile>();
		parser.fromJson(json.toString(), path);
		if (parser.errors.length > 0)
		{
			for (error in parser.errors)
				FlxG.log.error('Failed to parse stage archive ' + path + ': ' + error);
			return;
		}
		if (parser.value == null || parser.value.props == null)
		{
			FlxG.log.error('Stage archive has no valid stage data: ' + path);
			return;
		}

		zipassetsmap = assets;
		zipStagePath = path;
		setStageData(haxe.io.Path.withoutExtension(haxe.io.Path.withoutDirectory(path)), parser.value);
		isBeginningWindowOpen = false;
		editorWindowOpen = true;
		#end
	}

	function setStageData(stageName:String, file:StageFile):Void
	{
		stageData = file;
		curStage = stageName;
		propnames = [];
		proplist = [];
		selectedProp = 0;
		if (stageData.props != null)
		{
			for (prop in stageData.props)
			{
				propnames.push(prop.name);
				proplist.push(prop);
			}
		}
		if (propnames.length > 0)
			loadSelectedProp();
		else
			propnamebuffer = new TextBuffer(256);
		rebuildPreviewFromJson();

		#if FEATURE_DISCORD_RPC
		DiscordClient.changePresence("Stage Editor", "Editing: " + curStage);
		#end
	}

	function loadSelectedProp():Void
	{
		propZindex = proplist[selectedProp].zIndex;
		var name = propnames[selectedProp];
		propnamebuffer = new TextBuffer(Std.int(Math.max(256, name.length + 1)));
		propnamebuffer.set(name);
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
						var bgSprite:BGSprite;
						if (zipassetsmap != null)
						{
							var image = getArchiveImage(prop.path);
							if (image == null)
								continue;
							bgSprite = new BGSprite(null, prop.position[0], prop.position[1], prop.scroll[0], prop.scroll[1], null, prop.velocity);
							loadArchiveGraphic(bgSprite, image, prop.name, null);
							bgSprite.id = prop.name;
							bgSprite.zIndex = prop.zIndex;
							bgSprite.alpha = prop.alpha;
							bgSprite.scale.set(prop.scale[0], prop.scale[1]);
							bgSprite.angle = prop.angle;
						}
						else
							bgSprite = new BGSprite(stageData.directory + '/' + prop.path, prop.position[0], prop.position[1], prop.scroll[0], prop.scroll[1],
								prop.animations, prop.velocity);
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
						var bgSprite:FlxSprite;
						if (zipassetsmap != null)
						{
							var image = getArchiveImage(prop.path);
							if (image == null)
								continue;
							bgSprite = new FlxBackdrop(null, axsis, prop.spacing[0], prop.spacing[1]);
							loadArchiveGraphic(bgSprite, image, prop.name, prop.animations);
						}
						else
							bgSprite = new FunkinBackdrop(stageData.directory + '/' + prop.path, axsis, prop.spacing[0], prop.spacing[1], prop.animations);

						bgSprite.x = prop.position[0];
						bgSprite.y = prop.position[1];
						bgSprite.scrollFactor.set(prop.scroll[0], prop.scroll[1]);
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
			propLayer.sort(function(order:Int, a:FlxSprite, b:FlxSprite):Int return FlxSort.byValues(order, a.zIndex, b.zIndex), FlxSort.ASCENDING);

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

	function getArchiveImage(path:String):BitmapData
	{
		var fileName = haxe.io.Path.withoutDirectory(path);
		if (!fileName.endsWith('.png'))
			fileName += '.png';
		var image:BitmapData = zipassetsmap.get(fileName);
		if (image == null)
			FlxG.log.warn('Missing stage archive image: ' + fileName);
		return image;
	}

	function loadArchiveGraphic(sprite:FlxSprite, image:BitmapData, propName:String, animations:Null<Array<AnimArray>>):Void
	{
		if (animations != null && animations.length > 0)
		{
			var xmlName = propName + '.xml';
			var xml:String = zipassetsmap.get(xmlName);
			if (xml != null)
			{
				sprite.frames = FlxAtlasFrames.fromSparrow(image.clone(), xml);
				sprite.active = true;
				for (anim in animations)
				{
					sprite.animation.addByPrefix(anim.name, anim.anim, anim.fps, anim.loop);
					if (anim.name == 'idle' || anim.name == 'dance' || anim.name == 'bop' || anim.name == 'resting' || anim.name == 'rest')
						sprite.animation.play(anim.name);
				}
				return;
			}
			trace('Missing stage archive atlas: ' + xmlName);
		}
		sprite.loadGraphic(image, false, 0, 0, true);
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
