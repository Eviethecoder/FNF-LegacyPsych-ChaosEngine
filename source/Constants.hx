
import lime.app.Application;

/**
 * A store of unchanging, globally relevant values/ VALUES ONLY THE SOURCE CODE SHOULD CHANGE!
 */

class Constants
{

    public static var optionscharacter:String = 'X_Soulbound';
    public static var defaultcharacter:String = 'bf';
    public static var version:String = 'INDEV';
    public static var curUser:String = 'unknown';
    public static var DEFAULT_HEALTH_ICON:String = 'face';
    public static var isdebug:Bool = false;
    public static var debuguserlist:Array<String> = ['abysmalcha0s','datkurubot', 'genkeidamava', 'puppet_onetcc', 'luscious', 'frostiiz_', 'birbva'];
    public static var cursongfolder:String = 'songs/default';
    public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place

    public static var defaultsongtypes:Array<String> = ['default', 'legacy', 'pico'];

    public static var pauseMusic:String = 'Empty Eyes Pause Music';


    public static function debugcheck(){


        for (i in 0...debuguserlist.length){
            if (curUser == debuguserlist[i] ){
                isdebug = true;
            }
        }

    }


}
