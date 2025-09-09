import ('Conductor');
import ('TankmenBG');
public var animationNotes:Array<Dynamic> = [];

function onCreate(){
    this.skipDance = true;
	chartloader('picospeaker');
	this.playAnim("shoot1");

}










function Charupdate(elapsed:Float){
    if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
        {
            var noteData:Int = 1;
            if(animationNotes[0][1] > 2) noteData = 3;

            noteData += FlxG.random.int(0, 1);
            this.playAnim('shoot' + noteData, true);
            animationNotes.shift();
        }
        if(this.animation.curAnim.finished) playAnim(this.animation.curAnim.name, false, false, this.animation.curAnim.frames.length - 3);
    
}