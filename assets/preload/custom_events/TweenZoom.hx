
import("flixel.tweens.FlxTween");
import("flixel.tweens.FlxEase");
function triggerEvent(eventName:String, value1:String, value2:String) {
    
    if (eventName == 'TweenZoom'){
        var tozoom:Float;
        var list:Array<String> = value2.split(',');
        if (value2 == '')
              tozoom = 0;
        else{
            tozoom = praseFloatfromString(list[0]);
        }
        if(value1 != ''){
            trace('hasease');
            FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCamZoom + tozoom},praseFloatfromString(list[1]), {ease: easeFromString(value1)});

        }
        else{
            trace('noease');
            FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCamZoom + tozoom},praseFloatfromString(list[1]), {ease: FlxEase.linear,});
        }
         
    }

}