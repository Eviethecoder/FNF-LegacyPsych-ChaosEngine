package editors;

import backend.ui.PsychUIBox;
import debug.Consolehandler;
import backend.ui.PsychUIButton;
import backend.ui.PsychUIInputText;
import flixel.FlxG;
import openfl.utils.ByteArray;
import lime.app.Application;
#if desktop
import lime.ui.FileDialog;
import lime.ui.FileDialogFilter;
import sys.io.File;
import sys.FileSystem;
#end
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flash.media.Sound;

class Welcometest extends MusicBeatState
{
	var uiBox:PsychUIBox;
	var uiGroup:FlxSpriteGroup;
	var titleText:FlxText;
	var nameInput:PsychUIInputText;
	var previewSound:FlxSound;

	override function create()
	{
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ebotmenuBG'));
		bg.color = 0xff2a6fff;
		bg.scale.y = FlxG.height / bg.height;
		bg.scale.x = FlxG.width / bg.width;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		bg.scrollFactor.set(0, 0);
		add(bg);

		titleText = new FlxText(12, 12, FlxG.width - 24, 'WELCOME TEST\nPsychUI test window is active.', 20);
		titleText.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, LEFT);
		add(titleText);

		uiBox = new PsychUIBox(30, 90, 360, 220, ['Window']);
		uiBox.scrollFactor.set();
		uiBox.selectedName = 'Window';
		add(uiBox);

		buildTestWindow();

		super.create();
	}

	function buildTestWindow():Void
	{
		uiGroup = new FlxSpriteGroup();

		previewSound = new FlxSound();
		var label = new FlxText(15, 20, 0, 'Enter your name:');
		nameInput = new PsychUIInputText(15, 45, 180, 'Player', 8);

		var greetButton:PsychUIButton = new PsychUIButton(15, 85, 'testload', function()
		{
			#if desktop
			openAudioDialog();
			#else
			titleText.text = 'WELCOME TEST\nFile dialog is desktop-only.';
			#end
		}, 70, 20);

		var backButton:PsychUIButton = new PsychUIButton(95, 85, 'Back', function()
		{
			MusicBeatState.switchState(new MasterEditorMenu());
		}, 70, 20);

		uiGroup.add(label);
		uiGroup.add(nameInput);
		uiGroup.add(greetButton);
		uiGroup.add(backButton);

		var tab = uiBox.getTab('Window');
		if (tab != null)
			tab.menu = uiGroup;
	}

	#if desktop
	function openAudioDialog():Void
	{
		FileDialog.openFile(Application.current.window, (files, filter) ->
		{
			Consolehandler.print("Selected file: " + files);
			playaudio(files[0]);
			trace('Selected file: ' + files[0]);
			if (filter != null)
				trace('Filter used: ' + filter.name);
		}, [
				new FileDialogFilter("SOUND files", "ogg;mp3;wav"),
				new FileDialogFilter("All files", "*")
		], Sys.getCwd());
	}
	#end

	function playaudio(path:String):Void
	{
		previewSound.loadByteArray(ByteArray.fromFile(path));
		previewSound.play(true);
		Consolehandler.print("sound: " + previewSound);
	}

	override function destroy()
	{
		if (previewSound != null)
		{
			previewSound.stop();
			previewSound.destroy();
			previewSound = null;
		}

		super.destroy();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ESCAPE)
		{
			MusicBeatState.switchState(new MasterEditorMenu());
			return;
		}

		super.update(elapsed);
	}
}
