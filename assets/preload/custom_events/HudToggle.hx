
import("flixel.tweens.FlxTween");
import("flixel.tweens.FlxEase");
function triggerEvent(eventName:String, value1:String, value2:String) {
    
    if (eventName == 'HudToggle'){
        trace(value1);
        trace(value2);
        switch(value1){

            case 'on':
                FlxTween.tween(PlayState.camHUD, {alpha: 1}, praseIntfromString(value2), {
							ease: FlxEase.quadInOut,
							
						});
                FlxTween.tween(PlayState.camNotes, {alpha: 1},  praseIntfromString(value2), {
                        ease: FlxEase.quadInOut,
                        
                    });

            case 'off':
                FlxTween.tween(PlayState.camHUD, {alpha: 0},  praseIntfromString(value2), {
							ease: FlxEase.quadInOut,
							
						});
                FlxTween.tween(PlayState.camNotes, {alpha: 0},  praseIntfromString(value2), {
                        ease: FlxEase.quadInOut,
                        
                    });

        

        }
        
    }

}
