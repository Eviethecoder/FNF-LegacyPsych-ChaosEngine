package ;


import lime.app.Application;

/**
 * A store of unchanging, globally relevant values.
 */

class Constants
{

    public static var version:String = 'INDEV';
    public static var curUser:String = 'unknown';
    public static var isdebug:Bool = false;
    public static var debuguserlist:Array<String> = [];



    public static function debugcheck(){


        for (i in 0...debuguserlist.length){
            if (curUser == debuguserlist[i] ){
                isdebug = true;
            }
        }

    }


}
