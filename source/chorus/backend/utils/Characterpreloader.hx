package chorus.backend.utils;
import chorus.backend.assets.Paths;

import flixel.util.FlxColor;
import flixel.FlxG;
import chorus.backend.assets.Assets;
import chorus.backend.assets.Assets as LimeAssets;
import chorus.objects.stages.Character.CharacterFile;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import json2object.JsonParser;
import flixel.sound.FlxSound;

#if sys
import sys.io.File;
import sys.FileSystem;
#else
import chorus.backend.assets.Assets;
#end

using StringTools;

/*
 * A class used to preload any characters JSON data.
 * Will be autoloaded into a map to be used anywhere it's needed.
 */
class Characterpreloader
{
    public static var charmap:Map<String,CharacterFile> = [];
    public static function addchartomap(path:String, file:String){
        var rawJson = File.getContent(path);
        var charjsonpraser:JsonParser<CharacterFile> = new JsonParser<CharacterFile>();
        charjsonpraser.fromJson(rawJson, path);
		var json:CharacterFile = charjsonpraser.value;

        validatejson(json, file);
     
    };

    public static function grabchardata(char:String):CharacterFile{
        var json:CharacterFile;
        if (charmap.get(char) == null){

            json = charmap.get(Constants.DEFAULT_CHARACTER);
        }
        else {
            json = charmap.get(char);
        }
        return json;
    }

    public static function validatejson(input:CharacterFile, file:String){
 
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
