package chorus.backend.system;

import chorus.backend.assets.Paths;
import chorus.backend.assets.data.WeekData;
import chorus.backend.utils.ClientPrefs;
import chorus.backend.utils.CoolUtil;
import chorus.backend.utils.Characterpreloader;
import chorus.backend.utils.NoteSkinpreloader;
import chorus.states.TitleState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
#if FEATURE_DISCORD_RPC
import chorus.backend.api.Discord.DiscordClient;
#end
import lime.app.Application;
import chorus.backend.debug.Systeminfo;
import chorus.backend.utils.EventHandler;
import chorus.backend.utils.NoteTypepreloader;
import chorus.backend.utils.NoteSkinHelper;
import chorus.backend.system.FunkinMemory;
import flixel.system.debug.log.LogStyle;
import foxlite.renderer.FoxRenderer;
import flixel.util.FlxSignal;
import chorus.backend.utils.SignalDispatcher;

/**
 * Handles initialization of variables when first opening the game.
**/
class InitState extends flixel.FlxState
{
	override function create():Void
	{
		super.create();

		// -- FLIXEL STUFF -- //
		#if FEATURE_DEBUG_TRACY
		Systeminfo.initTracy();
		#end

		// A small jumpstart to the soundtray, it usually sets itself to inactive (somewhere...)
		// but that makes our soundtray not show up on init if we have the game muted.
		// We set it to active so it at least calls it's update function once (see FlxGame.onEnterFrame(), it's called there)
		// and also see FunkinSoundTray.update() to see what we do and how we check if we are muted or not
		FlxG.game.soundTray.active = true;

		FlxG.scaleMode = new FullScreenScaleMode();

		// Set the game to a lower frame rate while it is in the background.
		FlxG.game.focusLostFramerate = 30;
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];
		// Make errors and warnings less annoying.
		LogStyle.WARNING.openConsole = false;
		LogStyle.WARNING.errorSound = null;

		FlxTransitionableState.skipNextTransIn = true;

		// -- SETTINGS -- //

		FlxG.save.bind('Catastrophe', CoolUtil.getSavePath());

		Controls.instance = new Controls();

		ClientPrefs.loadDefaultKeys();
		ClientPrefs.loadPrefs();

		NoteSkinHelper.setupfallback();
		NoteTypepreloader.customNoteTypeLookup();

		// -- MODS -- //

		Paths.pushGlobalMods();

		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();

		// -- -- -- //

		// -- -- -- //

		FoxRenderer.initLibs();

		FunkinMemory.clearStoredMemory();
		FunkinMemory.clearUnusedMemory();
		SignalDispatcher.initializesignals();
		SignalDispatcher.addSignal("BeatHit", new FlxTypedSignal<Int->Void>());
		SignalDispatcher.addSignal("StepHit", new FlxTypedSignal<Float->Void>());

		FunkinMemory.loadPerminateAssets();
		EventHandler.setupAllEventData();

		#if FEATURE_DISCORD_RPC
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
			Application.current.onExit.add(function(exitCode)
			{
				DiscordClient.shutdown();
			});
		}
		#end
		Characterpreloader.charLookup();
		NoteSkinpreloader.noteskinLookup();

		trace("Initialization complete.");
		FlxG.switchState(new TitleState());
	}
}
