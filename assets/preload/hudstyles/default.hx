function BarCreatePost(){
    trace('scriptworks');
}

function updateHealth(){
    trace('this should WORK: ' +this.healthBar.valueFunction);
}

function update(){
    trace('flxgroupupdate');
}


function updagetbargraphics(barnum:Int){
    trace('getbargraphics called with: ' + barnum);
    return this.bars.healthbar.image[barnum];
}