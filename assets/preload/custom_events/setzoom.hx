
function triggerEvent(eventName:String, value1:String, value2:String) {
    
    if (eventName == 'setzoom'){
       FlxG.camera.zoom = PlayState.defaultCamZoom + praseFloatfromString(value1);
    }

}