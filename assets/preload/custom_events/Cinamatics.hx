
import("flixel.tweens.FlxTween");
import("flixel.tweens.FlxEase");
var upperbar:FlxSprite;
var lowerbar:FlxSprite;
function onCreate(){

    upperbar = new FlxSprite(0,-120);
    upperbar.loadGraphic(Paths.image('eventassets/black'));
    upperbar.cameras = [PlayState.camHUD];
    upperbar.scale.set(50,1);
    PlayState.add(upperbar);
    lowerbar = new FlxSprite(0,720);
    lowerbar.loadGraphic(Paths.image('eventassets/black'));
    lowerbar.cameras = [PlayState.camHUD];
    lowerbar.scale.set(50,1.2);
    PlayState.add(lowerbar);
    //testing cinamatic
    trace('test');
}
function triggerEvent(eventName:String, value1:String, value2:String) {

    if (eventName == 'Cinamatics'){
        switch(value1){
            case 'on':
                	FlxTween.tween(upperbar, {y: 0}, 0.5, {
						ease: FlxEase.linear,
					});
                    FlxTween.tween(lowerbar, {y: 600}, 0.5, {
						ease: FlxEase.linear,
					});
                    switch(ClientPrefs.downScroll){
                        case true:
                            noteTweenY('NOTEMOVE1', 0, 480, 0.5, 'Linear');
	                        noteTweenY('NOTEMOVE2', 1, 480, 0.5, 'Linear');
	                        noteTweenY('NOTEMOVE3', 2, 480, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE4', 3, 480, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE5', 4, 480, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE6', 5, 480, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE7', 6, 480, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE8', 7, 480, 0.5, 'Linear');
                        case false:
                            noteTweenY('NOTEMOVE1', 0, 120, 0.5, 'Linear');	
                            noteTweenY('NOTEMOVE2', 1, 120, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE3', 2, 120, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE4', 3, 120, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE5', 4, 120, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE6', 5, 120, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE7', 6, 120, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE8', 7, 120, 0.5, 'Linear');
                            
                    }
            case 'off':
                	FlxTween.tween(upperbar, {y: -120}, 0.5, {
						ease: FlxEase.linear,
					});
                    FlxTween.tween(lowerbar, {y: 720}, 0.5, {
						ease: FlxEase.linear,
					});
                    switch(ClientPrefs.downScroll){
                        case true:
                            noteTweenY('NOTEMOVE1', 0, 570, 0.5, 'Linear');
	                        noteTweenY('NOTEMOVE2', 1, 570, 0.5, 'Linear');
	                        noteTweenY('NOTEMOVE3', 2, 570, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE4', 3, 570, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE5', 4, 570, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE6', 5, 570, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE7', 6, 570, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE8', 7, 570, 0.5, 'Linear');
                        case false:
                            noteTweenY('NOTEMOVE1', 0, 50, 0.5, 'Linear');	
                            noteTweenY('NOTEMOVE2', 1, 50, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE3', 2, 50, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE4', 3, 50, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE5', 4, 50, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE6', 5, 50, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE7', 6, 50, 0.5, 'Linear');
                            noteTweenY('NOTEMOVE8', 7, 50, 0.5, 'Linear');
                            
                    }

        }
           
    
    }

}