package editors;

#if desktop
import Discord.DiscordClient;
#end
import objects.FunkinSprite;
import backend.ui.*;
import objects.FunkinBackdrop;
import flixel.util.FlxAxes;
import data.StageData;
import flixel.FlxObject;
import flixel.FlxCamera;
import backend.ui.PsychUIEventHandler;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.display.BlendMode;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import sys.FileSystem;



using StringTools;

class StageEditorState extends MusicBeatState implements PsychUIEvent
{

	var stageData:StageFile;
	var propLayer:FlxTypedGroup<FunkinSprite>;
	var markerLayer:FlxTypedGroup<FunkinSprite>;
	var markerTextLayer:FlxTypedGroup<FlxText>;
	var stageList:Array<String> = [];
	var ispixelstage:PsychUICheckBox;
	var curStage:String = 'Red Alert';

	var infoText:FlxText;
	var uiBox:PsychUIBox;
	var stageDropDown:PsychUIDropDownMenu;
	var camFollow:FlxObject;
	var stagecam:FlxCamera;
	var hudcam:FlxCamera;
	var stageDirectory: PsychUIInputText;

	override function create()
	{
		reloadStageList();
		if(stageList.length > 0) curStage = stageList[0];

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

		uiBox = new PsychUIBox(20, 80, 560, 410, ['Stage Data', 'Props', 'Characters']);
		uiBox.scrollFactor.set();
		uiBox.selectedName = 'Stage Data';
		add(uiBox);
		uiBox.cameras = [hudcam];
		buildEditorUI();
		loadStageFromData(curStage);

		infoText = new FlxText(12, 12, FlxG.width - 24,
			'STAGE EDITOR (STAGE DATA)\n'
			+ 'This editor previews stage JSON directly from StageData.\n'
			+ 'Use the dropdown to swap stages.\n'
			+ 'ESC: Return to Editor Menu', 20);
		infoText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoText.borderSize = 1;
		infoText.scrollFactor.set();
		infoText.cameras = [hudcam];
		add(infoText);

		#if desktop
		DiscordClient.changePresence("Stage Editor", "Editing: " + curStage);
		#end

		super.create();
	}

	function reloadStageList():Void
	{
		stageList = [];
		var loaded:Map<String, Bool> = new Map();

		#if MODS_ALLOWED
		var dirs:Array<String> = [
			Paths.getPreloadPath('data/stages/')
		];
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
		{
			dirs.unshift(Paths.modFolders('data/stages/'));
		}

		for (dir in dirs)
		{
			if(!FileSystem.exists(dir)) continue;
			for (file in FileSystem.readDirectory(dir))
			{
				if(!file.endsWith('.json')) continue;
				var name:String = file.substr(0, file.length - 5);
				if(!loaded.exists(name))
				{
					loaded.set(name, true);
					stageList.push(name);
				}
			}
		}
		#end

		if(stageList.length < 1)
		{
			stageList = ['test'];
		}
	}

	function buildEditorUI():Void
	{
		var group = new flixel.group.FlxSpriteGroup();

		stageDropDown = new PsychUIDropDownMenu(15, 35, stageList, function(id:Int, selected:String)
		{
			if(selected != null && selected.length > 0)
			{
				curStage = selected;
				loadStageFromData(curStage);
			}
		}, 160);

		var reloadButton:PsychUIButton = new PsychUIButton(190, 32, 'Reload Stage', function()
		{
			loadStageFromData(curStage);
		}, 110, 20);

		stageDirectory = new PsychUIInputText(15, 75, 180, 'unknown');
		ispixelstage = new PsychUICheckBox(15, 190, 'is pixel stage', 120);
		ispixelstage.checked = false;
		var refreshListButton:PsychUIButton = new PsychUIButton(stageDirectory.x,stageDirectory.y +80, 'Refresh List', function()
		{
			reloadStageList();
			stageDropDown.list = stageList;
			if(stageList.indexOf(curStage) < 0)
			{
				curStage = stageList[0];
			}
			stageDropDown.selectedLabel = curStage;
			loadStageFromData(curStage);
		}, 90, 20);
		group.add(stageDropDown);
		group.add(reloadButton);
		group.add(new FlxText(stageDirectory.x, stageDirectory.y - 15, 0, 'Stage Directory'));
		group.add(stageDirectory);
		group.add(refreshListButton);
		group.add(ispixelstage);
		group.cameras = [hudcam];
		for (member in group.members)
		{
			if(member != null) member.cameras = [hudcam];
		}

		var tab = uiBox.getTab('Stage Data');
		if (tab != null) tab.menu = group;

		if(stageDropDown != null && curStage != null)
		{
			stageDropDown.selectedLabel = curStage;
		}
	}

	function loadStageFromData(stageName:String):Void
	{
		if(stageName == null || stageName.length < 1)
		{
			return;
		}

		var file:StageFile = StageData.getStageFile(stageName);
		if(file == null)
		{
			infoText.text = 'STAGE EDITOR (STAGE DATA)\nFailed to load stage: ' + stageName + '\nCheck data/stages/' + stageName + '.json';
			clearPreviewSprites();
			return;
		}

		stageData = file;
		curStage = stageName;
		rebuildPreviewFromJson();

		if(infoText != null)
		{
			var propCount:Int = file.props != null ? file.props.length : 0;
			var hasGF:Bool = !file.hide_girlfriend;
			infoText.text = 'STAGE EDITOR (STAGE DATA)\n'
				+ 'Stage: ' + curStage
				+ ' | Zoom: ' + file.defaultZoom
				+ ' | Props: ' + propCount
				+ ' | Has GF: ' + hasGF
				+ '\nDirectory: ' + file.directory
				+ '\nCamera Focus: ' + file.camera_focus + ' | Focus Offsets: ' + file.focusOffsets
				+ '\nESC: Return to Editor Menu';
		}

		stageDirectory.text = file.directory;
		#if desktop
		DiscordClient.changePresence("Stage Editor", "Editing: " + curStage);
		#end
	}

	function clearPreviewSprites():Void
	{
		for (daprop in propLayer.members)
		{
			if(daprop != null)
			{
				daprop.kill();
				daprop.destroy();
			}
		}
		propLayer.clear();

		for (daprop in markerLayer.members)
		{
			if(daprop != null)
			{
				daprop.kill();
				daprop.destroy();
			}
		}
		markerLayer.clear();

		for (txt in markerTextLayer.members)
		{
			if(txt != null)
			{
				txt.kill();
				txt.destroy();
			}
		}
		markerTextLayer.clear();
	}


	function getBlendmodeFromString(blend:String){
	trace('looking for blend mode: ' + blend);
	switch(blend.toLowerCase()){
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
		if(stageData == null) return;

		if(stageData.props != null)
		{
			for (prop in stageData.props)
		{
			trace('adding prop: ' + prop.name);
			switch(prop.PropType)
			{
				case 'ColorSprite':
					var bgSprite:FunkinSprite = new FunkinSprite(0,0);
					bgSprite.id = prop.name;
					bgSprite.zIndex = prop.zIndex;
					bgSprite.alpha = prop.alpha;
					bgSprite.makeGraphic(Std.int(prop.scale[0]), Std.int(prop.scale[1]), FlxColor.fromString(prop.path));
					bgSprite.velocity.set(prop.velocity[0], prop.velocity[1]); 
					bgSprite.angle = prop.angle;
					if(prop.blend != 'nan' ){
						bgSprite.blend = getBlendmodeFromString(prop.blend);

					}
					propLayer.add(bgSprite);

				case 'BGSprite':
					trace('the prop path is ' + stageData.directory+ '/' + prop.path);
					var bgSprite:BGSprite = new BGSprite(stageData.directory+ '/' + prop.path, prop.position[0], prop.position[1], prop.scroll[0], prop.scroll[1], prop.animations, prop.velocity);
					bgSprite.id = prop.name;
					bgSprite.zIndex = prop.zIndex;
					bgSprite.alpha = prop.alpha;
					bgSprite.scale.set(prop.scale[0], prop.scale[1]);
					bgSprite.angle = prop.angle;
					if(prop.blend != 'nan' ){
						bgSprite.blend = getBlendmodeFromString(prop.blend);

					}
	
					propLayer.add(bgSprite);
				case 'FunkinBackdrop':
					var axsis:FlxAxes = FlxAxes.XY;
					trace('the prop repeat axes is ' + prop.repeatAxes.toLowerCase());
					switch(prop.repeatAxes.toLowerCase())
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
					var bgSprite:FunkinBackdrop = new FunkinBackdrop(stageData.directory+ '/' + prop.path, axsis, prop.spacing[0], prop.spacing[1], prop.animations);

					trace(bgSprite.repeatAxes + ' is the repeat axes compared to ' + prop.repeatAxes);
					bgSprite.x = prop.position[0];
					bgSprite.y = prop.position[1];
					bgSprite.id = prop.name;
					bgSprite.velocity.set(prop.velocity[0], prop.velocity[1]); 
					bgSprite.zIndex = prop.zIndex;
					bgSprite.alpha = prop.alpha;
					bgSprite.scale.set(prop.scale[0], prop.scale[1]);
					bgSprite.angle = prop.angle;
					if(prop.blend != 'nan' ){
						trace('the prop blend mode is ' + prop.blend);
						bgSprite.blend = getBlendmodeFromString(prop.blend);
					}
		
					propLayer.add(bgSprite);
		}
		}

		if(stageData.characters != null)
		{
			addCharacterMarker('dad', stageData.characters.dad, FlxColor.RED);
			addCharacterMarker('boyfriend', stageData.characters.boyfriend, FlxColor.CYAN);
			if(stageData.characters.girlfriend != null)
			{
				addCharacterMarker('girlfriend', stageData.characters.girlfriend, FlxColor.PINK);
			}
		}}
	}

	function addCharacterMarker(name:String, data:CharacterData, color:FlxColor):Void
	{
		if(data == null || data.position == null || data.position.length < 2) return;

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
			if (FlxG.keys.justPressed.R) {
				FlxG.camera.zoom = 1;
			}

			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
				if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
			}
			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
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
