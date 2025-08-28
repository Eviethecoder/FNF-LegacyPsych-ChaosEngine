package optimized;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.animation.FlxAnimationController;
import flixel.FlxCamera;
import flixel.FlxBasic;
import flixel.util.FlxColor;
import flixel.FlxSprite;

typedef DataNote = {
    var id:Int;
    var time:Float;
    var length:Float;
    var mustHit:Bool;

    // useless for now
    var type:String;
    var gfNote:Bool; 

    // flags
    var missed:Bool;
    var pressed:Bool;
}; 

class NoteRenderer extends FlxSprite {
    private var __renderFunction:Void->Void;

    public function new(noteRenderFunction:Void->Void) {
        super();

        __renderFunction = noteRenderFunction;
    } 

    override function draw() {
        if(__renderFunction != null)
            __renderFunction();
    }
} 

class NoteStamp extends FlxSprite {
    @:keep public static var stamps:Map<String, NoteStamp> = []; 

    public static function registerNoteSkin(path:String):NoteStamp {
        if(stamps[path] != null)
            return stamps[path];

        var newStamp:NoteStamp = new NoteStamp(); 
        newStamp.loadSkin(path);
        stamps[path] = newStamp;

        return newStamp;
    }

    private var currentID:Int;

    public function new() {
        super(0, 0); 

        antialiasing = ClientPrefs.data.globalAntialiasing;
    } 

    public function loadSkin(skinPath:String) {
        frames = Paths.getSparrowAtlas(skinPath); 

		animation.addByPrefix('0', 'purple0');
		animation.addByPrefix('1', 'blue0');
		animation.addByPrefix('2', 'green0');
		animation.addByPrefix('3', 'red0');
  
        animation.addByPrefix('0end', 'pruple end hold');
        animation.addByPrefix('0l', 'purple hold piece'); 
        animation.addByPrefix('1end', 'blue hold end');
        animation.addByPrefix('1l', 'blue hold piece'); 
        animation.addByPrefix('2end', 'green hold end');
        animation.addByPrefix('2l', 'green hold piece'); 
        animation.addByPrefix('3end', 'red hold end');
        animation.addByPrefix('3l', 'red hold piece'); 
 
        scale.x = 0.7;
        scale.y = 0.7;
		updateHitbox();
    }
 
    public function setID(id:Int) { 
        currentID = id; 
    }

    public function resetNote() {
        scale.x = 0.7;
        scale.y = 0.7;
        alpha = 1;
        updateHitbox();
    }

    public function setNormal() {
        animation.play(Std.string(currentID), true);
    }

    public function setTrail() {
        alpha = 0.8;
        animation.play(currentID + 'l', true);
    }

    public function setEnd() {
        animation.play(currentID + 'end', true);
    }
}