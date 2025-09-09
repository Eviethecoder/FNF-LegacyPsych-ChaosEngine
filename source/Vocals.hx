package;
import flixel.sound.FlxSound;
import flixel.FlxG;

// me and the voices at 3:22am (we're having a great time)

class Vocals{
    public var dadVocals:FlxSound;
    public var bfVocals:FlxSound;
    private var usesSingleTrack:Bool = false;

    public function new(song:Null<String> = null){
        if (song != null){
            /*bfVocals = getVoice(song, "Player");
            dadVocals = getVoice(song, "Opponent");
            if (bfVocals.length < 1){ // song couldn't be loaded ;(
                bfVocals = getVoice(song, "Voices");
            }*/

            if (Paths.soundExists('songs', '${Paths.formatToSongPath(song)}/Player')){
                bfVocals = getVoice(song, "Player");
                dadVocals = getVoice(song, "Opponent");
            }
            else{
                usesSingleTrack = true;
                bfVocals = getVoice(song, "Voices");
                dadVocals = new FlxSound();
            }
        }
        else{
            bfVocals = new FlxSound();
            dadVocals = new FlxSound();
        }

        FlxG.sound.list.add(bfVocals);
        FlxG.sound.list.add(dadVocals);
    }

    static function getVoice(song:String, player:String):FlxSound
    {
        var songKey:String = '${Paths.formatToSongPath(song)}/${player}';
        var voices = Paths.returnSound('songs', songKey);
        return new FlxSound().loadEmbedded(voices);
    }


    public var length(get, null):Float;
    public function get_length():Float{
        return bfVocals.length;
    }


    public var time(get, set):Float;
    public function set_time(time:Float):Float{
        bfVocals.time = time;
        dadVocals.time = time;
        return time;
    }
    public function get_time():Float{
        return bfVocals.time;
    }


    public var pitch(get, set):Float;
    public function set_pitch(pitch:Float):Float{
        bfVocals.pitch = pitch;
        dadVocals.pitch = pitch;
        return pitch;
    }
    public function get_pitch():Float{
        return bfVocals.pitch;
    }


    public var volume(get, set):Float;
    public function set_volume(volume:Float):Float{
        bfVocals.volume = _bfVolume * volume;
        dadVocals.volume = _dadVolume * volume;
        return volume;
    }
    public function get_volume():Float{
        return bfVocals.volume;
    }

    private var _bfVolume = 1;
    public var bfVolume(get, set):Float;
    public function set_bfVolume(volume:Float):Float{
        bfVocals.volume = _bfVolume * volume;
        return volume;
    }
    public function get_bfVolume():Float{
        return _bfVolume;
    }

    private var _dadVolume = 1;
    public var dadVolume(get, set):Float;
    public function set_dadVolume(volume:Float):Float{
        dadVocals.volume = _dadVolume * volume;
        return volume;
    }
    public function get_dadVolume():Float{
        return _dadVolume;
    }

    public function muteDad(){
        dadVocals.volume = 0;
    }
    public function unmuteDad(){
        dadVocals.volume = 1;
    }
    public function mutePlayer(){
        bfVolume = 0;
    }
    public function unmutePlayer(){
        bfVolume = 1;
    }
    public function unmuteIfThereIsOnlyOneVoicesFileAndNotASeparateFileForPlayerAndOpponent(){
        if (usesSingleTrack){
            unmutePlayer();
        }
    }


    public function play(){
        bfVocals.play();
        dadVocals.play();
    }
    public function pause(){
        bfVocals.pause();
        dadVocals.pause();
    }
    public function stop(){
        bfVocals.stop();
        dadVocals.stop();
    }
    public function destroy(){
        bfVocals.destroy();
        dadVocals.destroy();
    }
}