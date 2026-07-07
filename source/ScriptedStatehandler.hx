package;

import sys.FileSystem;
import haxe.ds.StringMap;

class ScriptedStatehandler {
    public static var states:Array<String> = [];
    public static var curselectedstate:String; 
 
    public static  var persistantvariables = new StringMap<Dynamic>(); // keys = String, values = Int
    public static function generateStateList(){
        var folderPath = "states";
        var foldersToCheck:Array<String> = [Paths.getPreloadPath('states/'), Paths.modFolders('states/')];
        var files:Array<String> = [];
        trace( ' checking folders: ' +foldersToCheck);
        for (i in 0...foldersToCheck.length){
            if (!FileSystem.exists(foldersToCheck[i] ) || !FileSystem.isDirectory(foldersToCheck[i])) {
                trace('States folder does not exist.');
            }
            else{

                for (file in FileSystem.readDirectory(foldersToCheck[i])) {
                    var filname:String = file.substr(0, file.length - 3);
                    trace('state name is' +filname);
                    files.insert(0,filname);

                }
                states = files;
            }
            trace(states);
        }
       
      
        
    }

     public static function reListStates(){
        states = [];
        generateStateList();
    }
}
