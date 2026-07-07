package utility;

import flixel.util.FlxColor;
import flixel.FlxG;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import json2object.JsonParser;
import flixel.sound.FlxSound;

#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

using StringTools;

/*
 * A class used to preload any characters JSON data.
 * Will be autoloaded into a map to be used anywhere it's needed.
 */
class Characterpreloader
{
    public static var charmap:Map<String,Character.CharacterFile > = [];
    public static function addchartomap(path:String, file:String){
        var rawJson = File.getContent(path);
        var charjsonpraser:JsonParser<Character.CharacterFile> = new JsonParser<Character.CharacterFile>();
        charjsonpraser.fromJson(rawJson, path);
		var json:Character.CharacterFile = charjsonpraser.value;

        validatejson(json, file);
     
    };

    public static function grabchardata(char:String):Character.CharacterFile{
        var json:Character.CharacterFile;
        if (charmap.get(char) == null){

            json = charmap.get(Constants.DEFAULT_CHARACTER);
        }
        else {
            json = charmap.get(char);
        }
        return json;
    }

    public static function validatejson(input:Character.CharacterFile, file:String){
 
        if(input.image == null){  //once more 100 percent required json variables are here add them

            return;
        }
        else{
            charmap.set(file.replace('.json', ''), input);
            
        }
    }
    public static function charLookup()
    {
        var directories:Array<String> = [Paths.getPreloadPath('data/characters')];
        for (mod in Paths.getGlobalMods()) 
        {
            trace('mod to test: ' + mod);
            directories.insert(0, Paths.mods(mod + '/data/characters/'));
        }
        trace('directories: ' + directories);
        lookup(directories);

        
}
public static function lookup(directories:Array<String>){
    for (i in 0...directories.length)
        {
            var directory = directories[i];
            if (sys.FileSystem.exists(directory))
            {

                for (file in sys.FileSystem.readDirectory(directory))
                {
                    var path = haxe.io.Path.join([directory, file]);
                    if (!sys.FileSystem.isDirectory(path))
                    {
                    
                        if (path.endsWith('.json')){

                            addchartomap(path,file);
                        }
                        // do something with file
                    }
                    else
                    {
                        var subDirectory = haxe.io.Path.addTrailingSlash(path);
                        directories.push(subDirectory);
                        
                    }
                }
            }
            else
            {
            }
        }
    }
}
