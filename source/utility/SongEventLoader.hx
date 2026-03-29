package utility;

import flixel.util.FlxColor;
import flixel.FlxG;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import flixel.FlxBasic;
import json2object.JsonParser;
import event.BaseEvent;
import flixel.sound.FlxSound;
import macro.ClassMacro;

#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

using StringTools;

/*
 * A class used to Load All song events, 
 * Will be autoloaded into a map to be used anywhere it's needed.
 */

  /**
   * Map of internal handlers for song events.
   * These may be either `ScriptedSongEvents` or built-in classes extending `SongEvent`.
   */
static var  eventCache:Map<String, BaseEvent> = new Map<String, BaseEvent>();
class SongEventLoader extends FlxBasic
{


    /**
   * Every built-in event class must be added to this list.
   * Thankfully, with the power of `ClassMacro`, this is done automatically.
   */
  static final BUILTIN_EVENTS:List<Class<SongEvent>> = ClassMacro.listSubclassesOf(SongEvent);

    public static var eventmap:Map<String, BaseEent> = []; 

    public function new()
    {
        super();
    }

    

}