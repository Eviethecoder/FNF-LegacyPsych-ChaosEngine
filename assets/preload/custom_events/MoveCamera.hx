
function triggerEvent(eventName:String, value1:String, value2:String) {
    
    if (eventName == 'MoveCamera'){
        trace(value1);
        switch(value1){
            default:
                trace('warning. no character set'):
            case 'Boyfriend':
               
                
                PlayState.moveCamera(false); 
                
                
            case 'Dad':
                PlayState.moveCamera(true); 
                
            case 'Gf':
                PlayState.moveCamera(false,true); 
                

        }
        
    }

}