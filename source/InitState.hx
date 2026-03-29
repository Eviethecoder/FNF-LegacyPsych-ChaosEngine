package;

import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import Discord.DiscordClient;
import lime.app.Application;
import utility.Systeminfo;
/**
 * Handles initialization of variables when first opening the game.
**/
class InitState extends flixel.FlxState {
    override function create():Void {
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

        FlxTransitionableState.skipNextTransIn = true;

        // -- SETTINGS -- //

		FlxG.save.bind('Catastrophe', CoolUtil.getSavePath());

        Controls.instance = new Controls();

        ClientPrefs.loadDefaultKeys();
		ClientPrefs.loadPrefs();

      


        // -- MODS -- //

		Paths.pushGlobalMods();

		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();

        // -- -- -- //

        Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

        
        if (!DiscordClient.isInitialized)
        {
            DiscordClient.initialize();
            Application.current.onExit.add (function (exitCode) {
                DiscordClient.shutdown();
            });
        }
        utility.Characterpreloader.charLookup();
        trace('charmap: ' + utility.Characterpreloader.charmap);
			
        FlxG.switchState(Type.createInstance(Main.initialState, []));
    }
}