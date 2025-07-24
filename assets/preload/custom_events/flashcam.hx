function triggerEvent(eventName:String, value1:String, value2:String) {
    
    if (eventName == 'flashcam'){
        if(!ClientPrefs.flashing){
            var duration:Float;
            if(value2 !=''){
                duration = 1;
            }
            else{
                duration = praseFloatfromString(value2);
            }
            FlxG.camera.flash(colorFromString(value1),duration);
            }
    }
}
