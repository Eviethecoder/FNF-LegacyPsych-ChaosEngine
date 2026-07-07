package editors;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.text.FlxText;
import ui.Window;
import objects.Cursor;

#if desktop
import Discord.DiscordClient;
#end

class EditorBaseState extends MusicBeatState
{
	// Cameras
	public var camEditor:FlxCamera;
	public var camHUD:FlxCamera;
	public var camMenu:FlxCamera;

	// Camera follow
	public var camFollow:FlxObject;

	// UI
	public var uiBox:FlxUITabMenu;
	public var uiTabs:FlxUITabMenu;
	

	public var testwindow:Window;

	// Input lock
	public var inputTexts:Array<FlxUIInputText> = [];

	override function create()
	{
		setupCameras();
		setupwindow();
		super.create();
	}

	

	function setupCameras()
	{
		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camMenu = new FlxCamera();

		camHUD.bgColor.alpha = 0;
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);
		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);
		FlxG.camera.follow(camFollow);
	}

	

	function setupwindow()
	{
		testwindow = new Window("Confirm Action", "Are you sure you want to continue?", 200, 500);
        testwindow.alpha = 1;
        add(testwindow);

		testwindow.addButton("TEST", function() {
			FlxG.log.add("TEST clicked!");
		});

	}

	

	function editorControls(elapsed:Float)
	{
		if (FlxG.keys.justPressed.R)
			FlxG.camera.zoom = 1;

		if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3)
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom;

		if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1)
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
	}

	function isTyping():Bool
	{
		for (t in inputTexts)
			if (t != null && t.hasFocus)
				return true;
		return false;
	}

	// ---------- CURSOR ----------

	function updateCursor(ui:FlxUI)
	{
		Cursor.set_cursorMode(Default);

		for (item in ui.members)
		{
			if (FlxG.mouse.overlaps(item))
			{
				if (Std.isOfType(item, FlxUIInputText))
					Cursor.set_cursorMode(Text);
				else
					Cursor.set_cursorMode(Pointer);
			}
		}
	}

	

	function updatePresence(title:String, subtitle:String, icon:String)
	{
		#if desktop
		DiscordClient.changePresence(title, subtitle, icon);
		#end
	}

	override function update(elapsed:Float)
	{
		if (!isTyping())
			editorControls(elapsed);

		super.update(elapsed);
	}
}
