package utility;

import data.HudstyleData;

class Noteskinhelper {
    public static var editorhuddata:HudstyleData;

    public static function geteditorhuddata() {
        
        if (Haxescript.isInPlayState){
                editorhuddata = PlayState.instance.hud.hudData;
        }

        else {
           editorhuddata
        }
    }
    public static function getnotesplashoffsets():Array<Float> {
        var offsets:Array<Float> = [0, 0];
        if (PlayState.instance != null && PlayState.instance.hud != null && PlayState.instance.hud.hudData != null) {
           
        }
        return offsets;
     }

    public static function getNoteskin(player:Bool):String {
        if (PlayState.instance != null && PlayState.instance.hud != null && PlayState.instance.hud.hudData != null) {
            return PlayState.instance.hud.hudData.getNoteskin(player);
        }
        return 'Huds/Noteskins/NOTE_assets';
    }

    public static function getNoteskinnotes(player:Bool):String {
        if (PlayState.instance != null && PlayState.instance.hud != null && PlayState.instance.hud.hudData != null) {
            return PlayState.instance.hud.hudData.getNoteskinnotes(player);
        }
        return 'Huds/Noteskins/NOTE_assets-notes';
    }

    public static function getNoteskinrgb(player:Bool):Array<Array<Int>> {
        if (PlayState.instance != null && PlayState.instance.hud != null && PlayState.instance.hud.hudData != null) {
            return PlayState.instance.hud.hudData.getNoteskinrgb(player);
        }
        return ClientPrefs.data.arrowRGB;
    }

    public static function getNotesplash():String {
        if (PlayState.instance != null && PlayState.instance.hud != null && PlayState.instance.hud.hudData != null) {
            return PlayState.instance.hud.hudData.getNotesplash();
        }
        return 'Huds/NoteSplashes/noteSplashes';
    }
}